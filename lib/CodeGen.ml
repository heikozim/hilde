(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Id
open Identifier
open Type
open EnvTypes
open Env
open EnvUtils
open MonoType
open MonoTypeBindings
open Stages.Tast
open Stages.Mtast
open MtastUtil
open CRepr
open Util
open Escape
open Error

(* Codegen implementation notes:

   A union like this:

       union Optional_Int is
           case Present is
               value: Integer_32;
           case Absent;
       end union;

   Is represented like this:

       enum Optional_Int_Tag {
           PRESENT,
           ABSENT
       }

       typedef struct {
           Optional_Int_Tag tag;
           union {
               struct { int32_t value; } Present;
               struct {} Absent;
           } data;
       } Optional_Int;

   A case statement like:

       case e of
           when Present(value: Integer_32) do
               f();
           when Absent do
               g();
       end case;

   Is represented like this:

       Optional_Int tmp_0 = e;
       switch (tmp_0.tag) {
           case Optional_Int_Tag.PRESENT:
                int32_t value = tmp_0.data.Present.value;
	        f();
                break;
           case Optional_Int_Tag.ABSENT:
                g();
                break;
       }

*)

(* Name generation *)

let counter = ref 0

let new_variable _: string =
  let v = "tmp" ^ (string_of_int !counter) in
  counter := !counter + 1;
  v

(* Text of this many bytes or more does not go into a string literal: C17
   asks a compiler to take only 4095 characters in one, and gcc and clang
   say so under -Wpedantic.  Such text becomes an array of bytes at file
   scope, which has no such limit and lives as long as the programme, as a
   literal does.  The arrays wait here until gen_module puts them in front
   of the code of their module. *)
let long_text_limit = 4095

let long_texts: c_decl list ref = ref []

let long_text_counter = ref 0

let hoist_long_text (bytes: string): string =
  let name = "hilde_text_" ^ (string_of_int !long_text_counter) in
  long_text_counter := !long_text_counter + 1;
  long_texts := CByteArrayDefinition (Desc "Long text", name, bytes) :: !long_texts;
  name

(* Bindings the generated code never reads

   A destructuring, a case with bindings and a borrow all declare a name and
   give it a field access or an address.  Where the body never mentions that
   name, the C compiler reports an unused variable, and there is nothing to
   run: the initialiser reads a variable, takes its address or reaches into a
   struct, and evaluating it has no effect anyone can observe.  Such a
   declaration is left out.

   The question "does this body mention that name" is asked of the GENERATED C
   and not of the typed tree, so the answer is about the text that will
   actually be compiled.  An embed carries C the compiler does not parse, so
   its text is searched as a string: that can answer "used" too often, never
   too rarely, and answering too often only keeps a declaration. *)

let text_mentions (text: string) (name: string): bool =
  try
    let _ = Str.search_forward (Str.regexp_string name) text 0 in
    true
  with Not_found ->
    false

let rec c_expr_uses (name: string) (expr: c_expr): bool =
  let u = c_expr_uses name in
  match expr with
  | CBool _ | CInt _ | CFloat _ | CString _ | CSizeOf _ ->
     false
  | CVar v ->
     v = name
  | CFuncall (f, args) ->
     f = name || List.exists u args
  | CFptrCall (fn, _, _, args) ->
     u fn || List.exists u args
  | CCast (e, _) ->
     u e
  | CArithmetic (_, l, r) | CComparison (_, l, r)
  | CConjunction (l, r) | CDisjunction (l, r) | CIndex (l, r) ->
     u l || u r
  | CNegation e | CAddressOf e | CDeref e ->
     u e
  | CIfExpression (c, t, f) ->
     u c || u t || u f
  | CStructInitializer args ->
     List.exists (fun (_, v) -> u v) args
  | CStructAccessor (e, _) | CPointerStructAccessor (e, _) | CPath (e, _) ->
     u e
  | CEmbed (_, text, args) ->
     text_mentions text name || List.exists u args

let rec c_stmt_uses (name: string) (stmt: c_stmt): bool =
  let u = c_expr_uses name
  and s = c_stmt_uses name in
  match stmt with
  | CLet (_, _, value) ->
     (match value with
      | Some e -> u e
      | None -> false)
  | CAssign (lvalue, value) ->
     u lvalue || u value
  | CDiscarding e ->
     u e
  | CIf (c, t, f) ->
     u c || s t || s f
  | CSwitch (value, cases) ->
     u value
     || List.exists (fun (CSwitchCase (e, body)) -> u e || s body) cases
  | CIntSwitch (value, arms, other) ->
     u value
     || List.exists (fun (labels, body) -> List.exists u labels || s body) arms
     || s other
  | CWhile (c, body) ->
     u c || s body
  | CFor (v, final, body) ->
     v = name || u final || s body
  | CReturn e ->
     u e
  | CBlock ss | CExplicitBlock ss ->
     List.exists s ss
  | CLocalFunctionDeclaration (n, _, _, _) ->
     n = name

(* An initialiser that may be left out together with its binding: it reads a
   variable, takes an address or reaches into a struct, and nothing else.  A
   call or an embed stays, because either may do something. *)
let rec init_is_droppable (expr: c_expr): bool =
  match expr with
  | CVar _ ->
     true
  | CAddressOf e | CDeref e | CStructAccessor (e, _)
  | CPointerStructAccessor (e, _) | CPath (e, _) ->
     init_is_droppable e
  | _ ->
     false

(* Keep a declaration when the body reads it, or when leaving it out would
   skip an initialiser that might do something. *)
let binding_is_read (body: c_stmt) (decl: c_stmt): bool =
  match decl with
  | CLet (name, _, Some init) ->
     c_stmt_uses name body || not (init_is_droppable init)
  | _ ->
     true

(* Identifiers *)

let hilde_prefix: string = ""

let gen_ident (i: identifier): string =
  hilde_prefix ^ (ident_string i)

(* A parameter or a local variable.  It carries a prefix of its own, so that
   no name of the programme meets a macro of the C library: on OpenBSD stdin
   is a macro of stdio.h, and a parameter of that name stopped every
   programme at cc.  A slot, a case and a qualified name keep gen_ident; an
   embed reaches its arguments only through $1, $2 and so on. *)
let local_prefix: string = "v_"

let gen_local (i: identifier): string =
  local_prefix ^ (ident_string i)

let gen_module_name (n: module_name): string =
  hilde_prefix ^ replace_char (mod_name_string n) '.' "__"

let gen_qident (i: qident): string =
  (gen_module_name (source_module_name i)) ^ "____" ^ (gen_ident (original_name i))

let gen_sident (mn: module_name) (i: identifier): string =
  (gen_module_name mn) ^ "____" ^ (gen_ident i)

(* Readable names in the generated C

   decl_N, mono_N and meth_N say nothing about what they are; the source
   construct stood only in a comment above each definition, and a comment is
   not where a debugger, a profiler, a linker map or a core dump looks.  A
   name now carries the module and the declaration it came from, and keeps
   the number:

       decl_9   ->  Hilde__Pervasive__abort__d9
       mono_18  ->  Hilde__Memory__store__m18
       meth_132 ->  Hilde__Pervasive__printSpan__i132

   The number stays on purpose, and it is what makes the scheme
   collision-free without a table of names already handed out: two
   monomorphs of one generic function carry the same source name and differ
   only in their id, and a scheme that dropped the number would have to
   invent a difference.  It also keeps the way back to the compiler's own
   ids readable.  The letter before it names the family, so that a
   declaration and a monomorph with the same number cannot meet.

   Everything outside [A-Za-z0-9_] becomes an underscore.  A C keyword
   cannot come out of this -- every name ends in the family letter and a
   number -- so CRenderer.avoid_ckw has nothing left to do for these.

   The environment is what the lookup needs, and the three functions below
   are called from places that carry none, so gen_module leaves it here.
   Without an environment, or for an id the environment does not know, the
   old form is used: a name is never invented. *)

let current_env: env option ref = ref None

let sanitise_c_name (s: string): string =
  String.map
    (fun c ->
      match c with
      | 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> c
      | _ -> '_')
    s

let module_prefix (env: env) (mod_id: mod_id): string =
  match get_module_by_id env mod_id with
  | Some (ModRec { name; _ }) ->
     (gen_module_name name) ^ "__"
  | None ->
     ""

let readable_decl_name (env: env) (id: decl_id): string option =
  match get_decl_by_id env id with
  | Some decl ->
     (match decl_name decl with
      | Some name ->
         Some (sanitise_c_name
                 ((module_prefix env (decl_mod_id decl)) ^ (ident_string name)))
      | None ->
         None)
  | None ->
     None

let readable_ins_meth_name (env: env) (id: ins_meth_id): string option =
  match get_instance_method env id with
  | Some (InsMethRec { name; instance_id; _ }) ->
     let prefix =
       match get_decl_by_id env instance_id with
       | Some decl -> module_prefix env (decl_mod_id decl)
       | None -> ""
     in
     Some (sanitise_c_name (prefix ^ (ident_string name)))
  | None ->
     None

let with_env (f: env -> string option) (fallback: string) (suffix: string): string =
  match !current_env with
  | None ->
     fallback
  | Some env ->
     (match f env with
      | Some name -> name ^ suffix
      | None -> fallback)

let gen_decl_id (id: decl_id): string =
  let (DeclId i) = id in
  with_env
    (fun env -> readable_decl_name env id)
    (hilde_prefix ^ "decl_" ^ (string_of_int i))
    ("__d" ^ (string_of_int i))

let gen_mono_id (id: mono_id): string =
  let (MonoId i) = id in
  let name_of (env: env): string option =
    match get_monomorph env id with
    | Some (MonoRecordDefinition { type_id; _ }) ->
       readable_decl_name env type_id
    | Some (MonoUnionDefinition { type_id; _ }) ->
       readable_decl_name env type_id
    | Some (MonoFunction { function_id; _ }) ->
       readable_decl_name env function_id
    | Some (MonoInstanceMethod { method_id; _ }) ->
       readable_ins_meth_name env method_id
    | None ->
       None
  in
  with_env
    name_of
    (hilde_prefix ^ "mono_" ^ (string_of_int i))
    ("__m" ^ (string_of_int i))

let gen_ins_meth_id (id: ins_meth_id): string =
  let (InsMethId i) = id in
  with_env
    (fun env -> readable_ins_meth_name env id)
    (hilde_prefix ^ "meth_" ^ (string_of_int i))
    ("__i" ^ (string_of_int i))

(* Types *)

let fn_type: c_ty = CNamedType "hilde_fnptr_t"

let rec gen_type (ty: mono_ty): c_ty =
  match ty with
  | MonoUnit ->
     CNamedType "hilde_unit_t"
  | MonoNever ->
     CNamedType "hilde_unit_t"
  | MonoBoolean ->
     CNamedType "hilde_bool_t"
  | MonoInteger (s, w) ->
     let sgn: string =
       match s with
       | Unsigned -> "hilde_nat"
       | Signed -> "hilde_int"
     in
     let name: string =
       match w with
       | Width8 -> sgn ^ "8_t"
       | Width16 -> sgn ^ "16_t"
       | Width32 -> sgn ^ "32_t"
       | Width64 -> sgn ^ "64_t"
       | WidthByteSize -> "size_t"
       | WidthIndex -> "hilde_index_t"
     in
     CNamedType name
  | MonoSingleFloat ->
     CNamedType "float"
  | MonoDoubleFloat ->
     CNamedType "double"
  | MonoNamedType id ->
     CNamedType (gen_mono_id id)
  | MonoRegionTy _ ->
     CNamedType "hilde_region_t"
  | MonoReadRef (t, _) ->
     CPointer (gen_type t)
  | MonoWriteRef (t, _) ->
     CPointer (gen_type t)
  | MonoSpan _ ->
     CNamedType "hilde_span_t"
  | MonoSpanMut _ ->
     CNamedType "hilde_span_t"
  | MonoAddress t ->
     CPointer (gen_type t)
  | MonoPointer t ->
     CPointer (gen_type t)
  | MonoFnPtr _ ->
     fn_type
  | MonoRegionTyVar _ ->
     internal_err "Invalid C type"

(* Expressions *)

let c_string_type = CPointer (CNamedType "uint8_t")

let union_type_id = function
  | MonoNamedType id ->
     id
  | MonoReadRef (MonoNamedType id, _) ->
     id
  | MonoWriteRef (MonoNamedType id, _) ->
     id
  | _ ->
     internal_err "Union is not a named type?"

(* Given the ID of a union type, returns the name of the
   union's tag enum. *)
let union_tag_enum_name (id: mono_id): string =
  (gen_mono_id id) ^ "_tag"

let local_union_tag_enum_name_from_id (id: mono_id): string =
  (gen_mono_id id) ^ "_tag"

(* Given a union type and the name of a case, return the
   value of the tag enum for that case. *)
let union_tag_value (ty: mono_ty) (case_name: identifier): c_expr =
  CVar ((union_tag_enum_name (union_type_id ty)) ^ "_" ^ (gen_ident case_name))

(* The C return type of a function: one that returns Never is marked as
   one that does not return, for the C standard and for cppcheck, which
   reads only the attribute. *)
let gen_return_type (rt: mono_ty): c_ty =
  match rt with
  | MonoNever ->
     CNamedType "_Noreturn __attribute__((noreturn)) hilde_unit_t"
  | _ ->
     gen_type rt

let rec is_never (e: mexpr): bool =
  match e with
  | MConcreteFuncall (_, _, _, MonoNever) | MGenericFuncall (_, _, MonoNever)
  | MConcreteMethodCall (_, _, _, MonoNever) | MGenericMethodCall (_, _, _, MonoNever)
  | MFptrCall (_, _, MonoNever) | MEmbed (MonoNever, _, _) ->
     true
  | MIfExpression (_, t, f) ->
     is_never t && is_never f
  | _ ->
     false

let unreachable: c_stmt = CDiscarding (CFuncall ("__builtin_unreachable", []))

let rec gen_exp (mn: module_name) (e: mexpr): c_expr =
  let g = gen_exp mn in
  match e with
  | MNilConstant ->
     CBool false
  | MBoolConstant b ->
     CBool b
  | MIntConstant i ->
     CInt i
  | MFloatConstant f ->
     CFloat f
  | MStringConstant s ->
     let bytes = escaped_to_string s in
     let data =
       if String.length bytes >= long_text_limit then
         CCast (CVar (hoist_long_text bytes), CPointer (CNamedType "const char"))
       else
         CString s
     in
     CFuncall (
         "hilde_make_span_from_string",
         [
           data;
           CInt (string_of_int (String.length bytes))
         ]
       )
  | MConstVar (n, _) ->
     CVar (gen_qident n)
  | MParamVar (n, _) ->
     CVar (gen_local n)
  | MLocalVar (n, _) ->
     CVar (gen_local n)
  | MTemporary (n, _) ->
     CVar (gen_local n)
  | MGenericFunVar (id, _) ->
     CCast (CVar (gen_mono_id id), fn_type)
  | MConcreteFunVar (id, _) ->
     CCast (CVar (gen_decl_id id), fn_type)
  | MConcreteFuncall (id, _, args, _) ->
     CFuncall (gen_decl_id id, List.map g args)
  | MGenericFuncall (id, args, _) ->
     CFuncall (gen_mono_id id, List.map g args)
  | MConcreteMethodCall (id, _, args, _) ->
     CFuncall (gen_ins_meth_id id, List.map g args)
  | MGenericMethodCall (_, id, args, _) ->
     CFuncall (gen_mono_id id, List.map g args)
  | MFptrCall (name, args, ty) ->
     let argtys: mono_ty list = List.map get_type args in
     CFptrCall (CVar (gen_local name), gen_type ty, List.map gen_type argtys, List.map g args)
  | MCast (e, t) ->
     CCast (g e, gen_type t)
  | MComparison (op, lhs, rhs) ->
     CComparison (op, g lhs, g rhs)
  | MConjunction (lhs, rhs) ->
     CConjunction (g lhs, g rhs)
  | MDisjunction (lhs, rhs) ->
     CDisjunction (g lhs, g rhs)
  | MNegation e ->
     CNegation (g e)
  | MIfExpression (c, t, f) ->
     (* A branch that does not come back is the call, then a zero of the
        type of the other branch, which C needs and never reaches. *)
     let branch (x: mexpr) (other: mexpr): c_expr =
       if is_never x && not (is_never other) then
         CEmbed (None, "($1, (" ^ CRenderer.render_type (gen_type (get_type other)) ^ "){0})", [g x])
       else
         g x
     in
     CIfExpression (g c, branch t f, branch f t)
  | MRecordConstructor (ty, values) ->
     CCast (CStructInitializer (List.map (fun (n, v) -> (gen_ident n, g v)) values), gen_type ty)
  | MUnionConstructor (ty, case_name, values) ->
     let args = CStructInitializer (List.map (fun (n, v) -> (gen_ident n, g v)) values) in
     CCast (CStructInitializer [
                ("tag", union_tag_value ty case_name);
                ("data", CStructInitializer [(gen_ident case_name, args)])
              ], gen_type ty)
  | MEmbed (ty, expr, args) ->
     (* The value of an embed is cast to its type, so that a C integer of
        another width becomes the Hilde one.  A struct is not cast: C has no
        cast between structs, and one to the same struct is refused by ISO
        C, which gcc reports under -Wpedantic. *)
     let cast =
       match ty with
       | MonoNamedType _ | MonoSpan _ | MonoSpanMut _ -> None
       | _ -> Some (gen_type ty)
     in
     CEmbed (cast, expr, List.map g args)
  | MDeref e ->
     CDeref (g e)
  | MTypecast (e, ty) ->
     CCast (g e, gen_type ty)
  | MSizeOf ty ->
     CSizeOf (gen_type ty)
  | MSlotAccessor (expr, slot, _) ->
     let expr = g expr in
     CAddressOf (CStructAccessor (CDeref expr, gen_ident slot))
  | MPointerSlotAccessor (expr, slot, _) ->
     let expr = g expr in
     CAddressOf (CPointerStructAccessor (CDeref expr, gen_ident slot))
  | MArrayIndex (expr, idx, ty) ->
     let expr = g expr
     and idx = g idx in
     let elem_ty = begin
         match ty with
         | MonoReadRef (ty, _) ->
            ty
         | MonoWriteRef (ty, _) ->
            ty
         | _ ->
            internal_err "Internal error"
       end
     in
     let elem_ty = gen_type elem_ty in
     CCast (
         CFuncall ("hilde_array_index", [expr; idx; CSizeOf elem_ty]),
         CPointer elem_ty
       )
  | MSpanIndex (expr, idx, ty) ->
     let expr = g expr
     and idx = g idx in
     let elem_ty = begin
         match ty with
         | MonoReadRef (ty, _) ->
            ty
         | MonoWriteRef (ty, _) ->
            ty
         | _ ->
            internal_err "Internal error"
       end
     in
     let elem_ty = gen_type elem_ty in
     CCast (
         CFuncall ("hilde_array_index", [CAddressOf expr; idx; CSizeOf elem_ty]),
         CPointer elem_ty
       )

(* Statements *)

let rec gen_stmt (mn: module_name) (stmt: mstmt): c_stmt =
  let ge = gen_exp mn
  and gs = gen_stmt mn
  in
  (* A value that does not come back is not stored or returned: the call
     stands as a statement and the rest of the path is unreachable. *)
  let never_stmt (e: mexpr): c_stmt = CBlock [CDiscarding (ge e); unreachable] in
  (* A variable bound to a value that does not come back is declared with
     the call and a zero of its type, so that no reader of the C, cppcheck
     among them, sees a variable read that was never set. *)
  let never_init (ty: mono_ty) (e: mexpr): c_expr =
    CEmbed (None, "($1, (" ^ CRenderer.render_type (gen_type ty) ^ "){0})", [ge e])
  in
  match stmt with
  | MLet (n, t, MBlock (MInitialAssign (a, v), rest))
       when is_never v && gen_local (local_name a) = gen_local n ->
     CBlock [CLet (gen_local n, gen_type t, Some (never_init t v)); unreachable; gs rest]
  | MAssign (_, rvalue) when is_never rvalue -> never_stmt rvalue
  | MAssignVar (_, rvalue) when is_never rvalue -> never_stmt rvalue
  | MInitialAssign (_, rvalue) when is_never rvalue -> never_stmt rvalue
  | MAssignTmp (_, value) when is_never value -> never_stmt value
  | MLetTmp (name, ty, expr) when is_never expr ->
     CBlock [CLet (gen_local name, gen_type ty, Some (never_init ty expr)); unreachable]
  | MReturn e when is_never e -> never_stmt e
  | MDiscarding e when is_never e -> never_stmt e
  | MSkip ->
     CBlock []
  | MLet (n, t, b) ->
     let l = CLet (gen_local n, gen_type t, None) in
     CBlock [l; gs b]
  | MDestructure (bs, e, b) ->
     let tmp = new_variable () in
     let vardecl = CLet (tmp, gen_type (get_type e), Some (ge e))
     and bs' = List.map (fun (MonoBinding { name; ty; rename; }) -> CLet (gen_local rename, gen_type ty, Some (CStructAccessor (CVar tmp, gen_ident name)))) bs
     and b' = gs b
     in
     (* A destructuring names every slot, and a body is free to read none of
        them.  Those bindings are left out.
        The temporary is NOT left out, even when nothing reads it any more.
        Dropping it was measured and it moves warnings rather than removing
        them: the temporary is often the only reader of the parameter that
        was destructured, so 215 lines turn from an unused variable into an
        unused parameter -- a class that needs a way to say "deliberately
        unused" in the language and is on the decision list. *)
     let bs'' = List.filter (binding_is_read b') bs' in
     CBlock (List.concat [[vardecl]; bs''; [b']])
  | MAssign (lvalue, rvalue) ->
     CAssign (CDeref (ge lvalue), ge rvalue)
  | MAssignVar (name, rvalue) ->
     CAssign (CVar (gen_local (local_name name)), ge rvalue)
  | MInitialAssign (name, rvalue) ->
     CAssign (CVar (gen_local (local_name name)), ge rvalue)
  | MLetTmp (name, ty, expr) ->
    let l = CLet (gen_local name, gen_type ty, Some (ge expr)) in
    l
  | MAssignTmp (name, value) ->
    CAssign (CVar (gen_local name), ge value)
  | MUnreachable ->
     (* hilde_case_unreachable is defined in lib/prelude.c. *)
     CDiscarding (CFuncall ("hilde_case_unreachable", []))
  | MIf (c, tb, fb) ->
     CIf (ge c, gs tb, gs fb)
  | MCase (e, whens, case_ref) ->
     gen_case mn e whens case_ref
  | MSwitch (e, arms, other) ->
     (* Each arm in braces of its own, so that a declaration may follow
        its labels. *)
     CIntSwitch (ge e,
                 List.map (fun (labels, b) -> (List.map (fun l -> CInt l) labels, CExplicitBlock [gs b])) arms,
                 CExplicitBlock [gs other])
  | MWhile (c, b) ->
     CWhile (ge c, gs b)
  | MFor (v, i, f, b) ->
     CExplicitBlock [
         CLet (gen_local v, CNamedType "size_t", Some (ge i));
         CFor (gen_local v, ge f, gs b)
       ]
  | MBorrow { original; rename; orig_type; body; mode; _ } ->
     let is_pointer =
       (match orig_type with
        | MonoAddress _ ->
           true
        | _ ->
           false)
     in
     if is_pointer then
       let l = CLet (gen_local rename, gen_type orig_type, Some (CVar (gen_local original))) in
       CBlock [l; gs body]
     else
       (* A read borrow of a write reference is the pointer the
          write reference holds, as a reborrow is. *)
       let through =
         match (mode, orig_type) with
         | (Read, MonoWriteRef _) -> true
         | _ -> false
       in
       let e = begin
           match mode with
           | Read ->
              if through then
                CVar (gen_local original)
              else
                CAddressOf (CVar (gen_local original))
           | PathRead ->
              CAddressOf (CVar (gen_local original))
           | Write ->
              CAddressOf (CVar (gen_local original))
           | Reborrow ->
              CVar (gen_local original)
         end
       in
       let ty = begin
           match mode with
           | Read ->
              if through then
                gen_type orig_type
              else
                CPointer (gen_type orig_type)
           | PathRead ->
              CPointer (gen_type orig_type)
           | Write ->
              CPointer (gen_type orig_type)
           | Reborrow ->
              gen_type orig_type
         end
       in
       let l = CLet (gen_local rename, ty, Some e) in
       CBlock [l; gs body]
  | MBlock (a, b) ->
     CBlock [gs a; gs b]
  | MDiscarding e ->
     CDiscarding (ge e)
  | MReturn e ->
     CReturn (ge e)
  | MRaise kind ->
     (* The raise stops the programme the way abort does, with the
        kind as its message.  The message is a plain C string: the kind is
        a name the compiler held, not data the programme built. *)
     let message = Escape.escaped_of_raw kind in
     CDiscarding (CFuncall ("hilde_abort",
                            [CFuncall ("hilde_make_span_from_string",
                                       [CString message;
                                        CInt (string_of_int (String.length kind))])]))

and gen_case (mn: module_name) (e: mexpr) (whens: mtyped_when list) (case_ref: case_ref): c_stmt =
  (* Code gen for a case statement: generate a variable, and assign the value
     being pattern-matched to that variable. Generate a switch statement over
     the tag enum. Each when statement that has bindings needs to generate some
     variable assignments for those bindings from the generated variable. *)
  let ty = get_type e
  and var = new_variable () in
  let cases = List.map (when_to_case mn ty var case_ref) whens in
  let accessor =
    match case_ref with
    | CasePlain ->
       CStructAccessor (CVar var, "tag")
    | CaseRef ->
       CPointerStructAccessor (CVar var, "tag")
  in
  let switch = CSwitch (accessor, cases) in
  CBlock [
      CLet (var, gen_type ty, Some (gen_exp mn e));
      switch
    ]

and when_to_case (mn: module_name) (ty: mono_ty) (var: string) (case_ref: case_ref) (MTypedWhen (n, bindings, body)): c_switch_case =
  let case_name = gen_ident n
  and tag_value = union_tag_value ty n
  in
  let get_binding binding_name =
    match case_ref with
    | CasePlain ->
       CStructAccessor (CStructAccessor (CStructAccessor (CVar var, "data"), case_name), gen_ident binding_name)
    | CaseRef ->
       CAddressOf (CStructAccessor (CStructAccessor (CStructAccessor (CDeref (CVar var), "data"), case_name), gen_ident binding_name))
  in
  let f (MonoBinding { name; ty; rename; }) =
    let ty =
      match case_ref with
      | CasePlain ->
         gen_type ty
      | CaseRef ->
         CPointer (gen_type ty)
    in
    CLet (gen_local rename, ty, Some (get_binding name))
  in
  let bindings' = List.map f bindings in
  let body' = gen_stmt mn body in
  (* Same as a destructuring: a when may bind a slot the body never reads. *)
  let bindings'' = List.filter (binding_is_read body') bindings' in
  let body'' = CExplicitBlock (List.append bindings'' [body']) in
  CSwitchCase (tag_value, body'')

(* Declarations *)

let gen_params mn params =
  let _ = mn in
  List.map (fun (MValueParameter (n, t)) -> CValueParam (gen_local n, gen_type t)) params

let gen_slots (slots: mono_slot list) =
  List.map (fun (MonoSlot (n, t)) -> CSlot (gen_ident n, gen_type t)) slots

let gen_cases (cases: mono_case list) =
  List.map (fun (MonoCase (n, ss)) -> CSlot (gen_ident n, CStructType (CStruct (None, gen_slots ss)))) cases

let gen_method (mn: module_name) (MConcreteMethod (id, _, params, rt, body)) =
  let d = Desc "Method" in
  CFunctionDefinition (d, gen_ins_meth_id id, gen_params mn params, gen_return_type rt, gen_stmt mn body)

(* `#line' directives, off unless the caller asks.
   Off by default because they are for a reader of the generated C, and
   every one of them is a line in a file that is already large; a flag that
   defaults to on would move the frame hash of every build. *)
let line_directives: bool ref = ref false

let set_line_directives (on: bool): unit =
  line_directives := on

(* A description that carries the declaration's position, when the flag is
   on and the position is known.  Nothing is an ordinary answer: a built-in
   module's declarations never went through the extraction pass, and a
   caller cannot be made to pretend they did. *)
let desc_at (id: decl_id) (text: string): desc =
  if not !line_directives then
    Desc text
  else
    match DeclSpans.find_decl id with
    | Some (Span { filename; startp = Position { line; _ }; _ }) ->
       (* An EMPTY filename is not a file.  The built-in modules are compiled
          from strings inside the binary, so their spans carry `pos_fname =
          ""', and `#line 12 ""' points at nothing -- which is worse than no
          directive at all; every monomorph of Hilde.Pervasive would carry
          one. *)
       if filename = "" then
         Desc text
       else
         DescAt (text, line, filename)
    | None ->
       Desc text

(* The name of the function a monomorph was made from. *)
let get_original_function_name (env: env) (id: mono_id): identifier =
  match get_monomorph env id with
  | Some (MonoFunction { function_id; _ }) ->
     (match get_decl_by_id env function_id with
      | Some (Function { name; _ }) -> name
      | _ -> internal_err "Couldn't get function")
  | _ ->
     internal_err "Couldn't get monomorph"

let get_original_module_name (env: env) (id: mono_id): module_name =
  match get_monomorph env id with
  | Some (MonoFunction { function_id; _ }) ->
     (match get_decl_by_id env function_id with
      | Some (Function { mod_id; _ }) ->
         (match get_module_by_id env mod_id with
          | Some (ModRec { name; _ }) ->
             name
          | _ ->
             internal_err "Couldn't get module record")
      | _ ->
         internal_err "Couldn't get function")
  | _ ->
     internal_err "Couldn't get monomorph"

(* The same for a monomorph, which has no position of its own -- it is made,
   not written -- so it takes the one of the generic it was made from, which
   is the line a reader wants. *)
let desc_at_mono (env: env) (id: mono_id) (text: string): desc =
  if not !line_directives then
    Desc text
  else
    match get_monomorph env id with
    | Some (MonoFunction { function_id; _ }) ->
       desc_at function_id text
    | _ ->
       Desc text

let rec mono_desc (env: env) (id: mono_id): string =
  let mono = get_mono_or_die env id in
  match mono with
  | MonoRecordDefinition { type_id; tyargs; _ } ->
     render_mono env type_id tyargs
  | MonoUnionDefinition { type_id; tyargs; _ } ->
     render_mono env type_id tyargs
  | MonoFunction { function_id; tyargs; _ } ->
     render_mono env function_id tyargs
  | MonoInstanceMethod _ ->
     ""

and get_mono_or_die (env: env) (id: mono_id): monomorph =
  match get_monomorph env id with
  | Some mono ->
     mono
  | None ->
     internal_err "Couldn't get monomorph"

and get_decl_name_or_die (env: env) (id: decl_id): string =
  match get_decl_by_id env id with
  | Some decl ->
     (match (decl_name decl) with
      | Some name ->
         (ident_string name)
      | None ->
         internal_err "decl has no name")
  | None ->
     internal_err "Couldn't find decl"

and tyargs_string (args: mono_type_bindings): string =
  "["
  ^ (String.concat ", " (List.map (fun (_, ty) -> show_mono_ty ty) (mono_bindings_as_list args)))
  ^ "]"

and render_mono (env: env) (id: decl_id) (tyargs: mono_type_bindings): string =
  (get_decl_name_or_die env id) ^ (tyargs_string tyargs)

let gen_decl (env: env) (mn: module_name) (decl: mdecl): c_decl list =
  match decl with
  | MConstant (_, n, _, e) ->
     let d = Desc "Constant" in
     [
       (* CConstantDefinition (d, gen_sident mn n, gen_type ty, gen_exp mn e) *)
       CMacro (d, gen_sident mn n, gen_exp mn e)
     ]
  | MRecord _ ->
     []
  | MRecordMonomorph (id, slots) ->
     let d = Desc ("Record monomorph: " ^ (mono_desc env id))
     and id = gen_mono_id id in
     [
       CStructForwardDeclaration (d, id);
       CNamedStructDefinition (d, id, gen_slots slots)
     ]
  | MUnion _ ->
     []
  | MUnionMonomorph (id, cases) ->
     let mono_id = gen_mono_id id in
     let enum_d = Desc ("Union monomorph tag enum: " ^ (mono_desc env id)) in
     let union_d = Desc ("Union monomorph: " ^ (mono_desc env id)) in
     let enum_def = CEnumDefinition (
                        enum_d,
                        local_union_tag_enum_name_from_id id,
                        List.map (fun (MonoCase (n', _)) -> (gen_mono_id id) ^ "_tag_" ^ (gen_ident n')) cases
                      )
     and union_def = CNamedStructDefinition (
                         union_d,
                         mono_id,
                         [
                           CSlot ("tag", CNamedType (local_union_tag_enum_name_from_id id));
                           CSlot ("data", CUnionType (gen_cases cases))
                         ]
                       )
     in
     [
       enum_def;
       CStructForwardDeclaration (union_d, mono_id);
       union_def
     ]
  | MFunction (id, name, params, rt, body) ->
     let d = desc_at id "Function" in
     let c_name: string = gen_decl_id id
     and c_params: c_param list = gen_params mn params
     and c_rt: c_ty = gen_return_type rt in
     (* A slot's own body is its default, written under a name of its own;
        the function of the slot's name forwards when the programme is
        complete. *)
     if Slots.is_slot mn name then begin
       Slots.note_slot_emitted (Slots.full_name mn name)
         { Slots.c_name; c_params; c_rt; never = (rt = MonoNever) };
       [CFunctionDefinition (d, Slots.default_c_name c_name, c_params, c_rt, gen_stmt mn body)]
     end else begin
       if Slots.implements mn name then Slots.note_impl_emitted (Slots.full_name mn name) c_name;
       [CFunctionDefinition (d, c_name, c_params, c_rt, gen_stmt mn body)]
     end
  | MFunctionMonomorph (id, params, rt, body) ->
     (* Load-bearing hack: prefix parameters not with the current module name,
        but with the name of the module the monomorph's declaration is from. *)
     let mn': module_name = get_original_module_name env id in
     let d = desc_at_mono env id ("Function monomorph: " ^ (mono_desc env id)) in
     let c_name: string = gen_mono_id id in
     let c_params = gen_params mn' params in
     let c_rt = gen_return_type rt in
     (* A slot or an implementation generic over regions has one monomorph,
        and it is written as a concrete slot or implementation is. *)
     let name: identifier = get_original_function_name env id in
     if Slots.is_slot mn' name then begin
       Slots.note_slot_emitted (Slots.full_name mn' name)
         { Slots.c_name; c_params; c_rt; never = (rt = MonoNever) };
       [CFunctionDefinition (d, Slots.default_c_name c_name, c_params, c_rt, gen_stmt mn body)]
     end else begin
       if Slots.implements mn' name then Slots.note_impl_emitted (Slots.full_name mn' name) c_name;
       [CFunctionDefinition (d, c_name, c_params, c_rt, gen_stmt mn body)]
     end
  | MForeignFunction (id, _, params, rt, underlying) ->
     let def_d = Desc "Foreign function" in
     let param_type_to_c_type (t: mono_ty): c_ty =
       (match t with
        | MonoUnit ->
           internal_err "Not allowed"
        | MonoNever ->
           internal_err "Not allowed"
        | MonoBoolean ->
           gen_type t
        | MonoInteger _ ->
           gen_type t
        | MonoSingleFloat ->
           gen_type t
        | MonoDoubleFloat ->
           gen_type t
        | MonoNamedType _ ->
           internal_err "Not allowed"
        | MonoRegionTy _ ->
           internal_err "Not allowed"
        | MonoReadRef _ ->
           internal_err "Not allowed"
        | MonoWriteRef _ ->
           internal_err "Not allowed"
        | MonoSpan (ty, _) ->
           CPointer (gen_type ty)
        | MonoSpanMut (ty, _) ->
           CPointer (gen_type ty)
        | MonoAddress _ ->
           gen_type t
        | MonoPointer _ ->
           gen_type t
        | MonoFnPtr _ ->
           gen_type t
        | MonoRegionTyVar _ ->
           internal_err "Not allowed")
     in
     (* A Unit result is C's void: the extern declaration says
        void, the call is a statement, and the wrapper returns nil.  A Unit
        PARAMETER stays refused above -- C has no such thing. *)
     let return_type_to_c_type t =
       match t with
       | MonoUnit ->
          CNamedType "void"
       | _ ->
          param_type_to_c_type t
     in
     let ff_params = List.map (fun (MValueParameter (n, t)) -> CValueParam (gen_local n, param_type_to_c_type t)) params
     and ff_rt = return_type_to_c_type rt in
     let ff_local_decl = CLocalFunctionDeclaration (underlying, ff_params, ff_rt, LinkageExternal) in
     let make_param (n: identifier) (t: mono_ty) =
       if (gen_type t) = (CNamedType "hilde_span_t") then
         (* Extract the pointer from the Array struct *)
         CStructAccessor (CVar (gen_local n), "data")
       else
         CVar (gen_local n)
     in
     let args = List.map (fun (MValueParameter (n, t)) -> make_param n t) params in
     let funcall = CFuncall (underlying, args) in
     let body =
       if rt = MonoUnit then
         CBlock [
             ff_local_decl;
             CDiscarding funcall;
             CReturn (CBool false)
           ]
       else
         CBlock [
             ff_local_decl;
             CReturn funcall
           ]
     in
     let def = CFunctionDefinition (def_d, gen_decl_id id, gen_params mn params, gen_type rt, body) in
     [def]
  | MConcreteInstance (_, _, _, methods) ->
     List.map (gen_method mn) methods
  | MMethodMonomorph (id, params, rt, body) ->
     let d = Desc ("Method monomorph: " ^ (mono_desc env id)) in
     [
       CFunctionDefinition (d, gen_mono_id id, gen_params mn params, gen_return_type rt, gen_stmt mn body)
     ]

(* Extract types into forward type declarations *)

let rec gen_type_decls decls =
  List.filter_map gen_type_decl decls

and gen_type_decl decl =
  (*let d n = Some (CStructForwardDeclaration (gen_decl_id n)) in*)
  match decl with
  (*| MRecord (id, _, _) ->
     d id*)
  (*| MUnion (id, _, _) ->
     d id*)
  | _ ->
     None

(* Extract functions into forward function declarations *)

let rec gen_fun_decls mn decls =
  List.filter_map (gen_fun_decl mn) decls

and gen_fun_decl mn decl =
  match decl with
  | MFunction (id, _, p, rt, _) ->
     let d = Desc "Function forward declaratioon" in
     Some [CFunctionDeclaration (d, gen_decl_id id, gen_params mn p, gen_return_type rt, LinkageInternal)]
  | MFunctionMonomorph (id, p, rt, _) ->
     let d = Desc "Function monomorph forward declaration" in
     Some [CFunctionDeclaration (d, gen_mono_id id, gen_params mn p, gen_return_type rt, LinkageInternal)]
  | MForeignFunction (id, _, p, rt, _) ->
     let d = Desc "Foreign function forward declaration" in
     Some [CFunctionDeclaration (d, gen_decl_id id, gen_params mn p, gen_return_type rt, LinkageInternal)]
  | MConcreteInstance (_, _, _, ms) ->
     Some (List.map (gen_method_decl mn) ms)
  | MMethodMonomorph (id, p, rt, _) ->
     let d = Desc "Method monomorph forward declaration" in
     Some [CFunctionDeclaration (d, gen_mono_id id, gen_params mn p, gen_return_type rt, LinkageInternal)]
  | _ ->
     None

and gen_method_decl mn (MConcreteMethod (id, _, params, rt, _)) =
  let d = Desc "Method forward declaration" in
  CFunctionDeclaration (d, gen_ins_meth_id id, gen_params mn params, gen_return_type rt, LinkageInternal)

(* Codegen a module *)

let decl_order = function
  | CEnumDefinition _ ->
     0
  | CStructForwardDeclaration _ ->
     1
  | CStructDefinition _ ->
     2
  | CNamedStructDefinition _ ->
     3
  | CTypeDefinition _ ->
     4
  | CConstantDefinition _ ->
     5
  | CByteArrayDefinition _ ->
     5
  | CMacro _ ->
     5
  | CFunctionDeclaration _ ->
     6
  | CFunctionDefinition _ ->
     7

(* the following code is used to sort declarations in dependency order, so that
   the C compiler doesn't complain about types being incomplete *)

let rec slot_depth decls (slot: c_slot) =
  match slot with
  | CSlot (_, CNamedType name) -> name_depth name decls
  | CSlot (_, CStructType (CStruct (_,slots))) -> slots_depth slots decls
  | CSlot (_, CUnionType slots) -> slots_depth slots decls
  | _ -> 0

and get_slots name decl =
  match decl with
  | CNamedStructDefinition (_, decl_name, slots) ->
     if name = decl_name then
       Some slots
     else
       None
  | _ -> None

and name_depth name decls =
  let slots =
    match (List.filter_map (get_slots name) decls) with
    | hd :: _ -> hd
    | _ -> [] in
  slots_depth slots decls

and slots_depth slots decls =
  let deps = List.map (slot_depth decls) slots in
  let dep_depth = List.fold_left max 0 deps in
  let depth = 1 + dep_depth in
  depth

let detail_compare decls a b =
  match (a, b) with
  | (CNamedStructDefinition (_, _, s1), CNamedStructDefinition (_, _, s2)) ->
     (slots_depth s1 decls) - (slots_depth s2 decls)
  | _ ->
     compare (decl_order a) (decl_order b)

(* end declaration sorting code *)

let gen_module (env: env) (MonoModule (name, decls)) =
  (* The name functions above need this and are called from places that do
     not carry one.  It is set here rather than threaded through every one
     of them, in the same spirit as the counter for temporaries. *)
  current_env := Some env;
  let type_decls = gen_type_decls decls
  and fun_decls = List.concat (gen_fun_decls name decls)
  and decls = List.concat (List.map (gen_decl env name) decls) in
  let texts = List.rev !long_texts in
  long_texts := [];
  let decls = List.concat [type_decls; fun_decls; texts; decls] in
  let sorted_decls = List.sort (detail_compare decls) decls in
  CUnit (mod_name_string name, sorted_decls)
