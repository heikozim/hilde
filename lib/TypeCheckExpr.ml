(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
 *)
open Identifier
open Common
open BuiltIn
open Id
open Env
open EnvTypes
open EnvUtils
open EnvExtras
open Region
open RegionMap
open Type
open TypeSystem
open TypeParser
open Stages.AstDB
open Stages.Tast
open TastUtil
open TypeParameter
open TypeParameters
open TypeVarSet
open LexEnv
open TypeBindings
open TypeMatch
open Reporter
open Error
open Util

module Errors = TypeErrors

(* Expression Context *)

type expr_ctx =
  ExpressionContext of {
      module_name: module_name;
      (** The name of the module being type-checked. *)
      env: env;
      (** The environment. *)
      rm: region_map;
      (** The region map, mapping the names of regions defined in
          borrow statements to region objects. *)
      typarams: typarams;
      (** Type parameters of the function or method containing this expression. *)
      lexenv: lexenv;
      (** The lexical environment. *)
    }

let make_ctx (module_name: module_name) (env: env) (rm: region_map) (typarams: typarams) (lexenv: lexenv): expr_ctx =
  ExpressionContext { module_name; env; rm; typarams; lexenv }

let ctx_module_name (ctx: expr_ctx): module_name =
  let (ExpressionContext { module_name; _ }) = ctx in
  module_name

let ctx_env (ctx: expr_ctx): env =
  let (ExpressionContext { env; _ }) = ctx in
  env

let ctx_region_map (ctx: expr_ctx): region_map =
  let (ExpressionContext { rm; _ }) = ctx in
  rm

let ctx_typarams (ctx: expr_ctx): typarams =
  let (ExpressionContext { typarams; _ }) = ctx in
  typarams

let ctx_lexenv (ctx: expr_ctx): lexenv =
  let (ExpressionContext { lexenv; _ }) = ctx in
  lexenv

(** The kind of the module being type-checked.  The extraction pass adds
    the module to the environment together with its kind
    ({!ExtractionPass}), and it runs before this pass ({!Compiler}), so
    the lookup is answered for the module we are inside of. *)
let ctx_module_kind (ctx: expr_ctx): module_kind =
  let mn: module_name = ctx_module_name ctx in
  match get_module_by_name (ctx_env ctx) mn with
  | Some (ModRec { kind; _ }) ->
     kind
  | None ->
     internal_err ("No module record for " ^ (mod_name_string mn)
                   ^ " while type-checking its own body.")

(** [@embed] pastes C into the output and the compiler does not check
    that C, so it is allowed only in a module that carries
    [pragma Unsafe_Module;].  The other two places that read the module
    kind are {!ImportResolution} (an import from Hilde.Memory) and
    {!TypingPass} (a foreign function); neither is changed by this. *)
let check_embed_allowed (ctx: expr_ctx): unit =
  match ctx_module_kind ctx with
  | UnsafeModule -> ()
  | SafeModule -> Errors.embed_in_safe_module ()

(* Whether the C text calls the function w: its name, not after . or ->
   and not inside a longer name, followed by an opening bracket. *)
let calls_name (text: string) (w: string): bool =
  let ident c = (c = '_') || (('a' <= c) && (c <= 'z')) || (('A' <= c) && (c <= 'Z')) || (('0' <= c) && (c <= '9')) in
  let n = String.length text in
  let k = String.length w in
  let rec at i =
    if i + k > n then false
    else if (String.sub text i k = w)
            && ((i = 0) || not ((ident text.[i - 1]) || (text.[i - 1] = '.') || (text.[i - 1] = '>')))
            && (calls (i + k)) then true
    else at (i + 1)
  and calls (j: int): bool =
    if j >= n then false
    else if (text.[j] = ' ') || (text.[j] = '\t') then calls (j + 1)
    else text.[j] = '('
  in
  (k > 0) && (at 0)

(* The C text of an @embed calls a function the programme imports from C.
   The compiler declares such a function itself, under a name of its own,
   so the C name is undeclared in the text and cc refuses the programme.
   A function of the runtime that lib/prelude.h declares is declared under
   its C name as well, so an @embed may call it while another module
   imports it. *)
let check_embed_names (ctx: expr_ctx) (text: string): unit =
  let undeclared (c: string): bool =
    (calls_name text c) && not (calls_name BuiltInModules.prelude_h c)
  in
  match List.find_opt (fun (c, _) -> undeclared c) (imported_functions (ctx_env ctx)) with
  | Some (c, hilde) -> Errors.embed_names_import ~c ~hilde
  | None -> ()

(* Utilities *)

(** Wrapper around match_type. *)
let match_type_ctx (ctx: expr_ctx) (expected: ty) (actual: ty): type_bindings =
  let env: env = ctx_env ctx
  and module_name: module_name = ctx_module_name ctx in
  match_type (env, module_name) expected actual

(** Wrapper around match_type_with_value. *)
let match_type_with_value_ctx (ctx: expr_ctx) (expected: ty) (value: texpr): type_bindings =
  let env: env = ctx_env ctx
  and module_name: module_name = ctx_module_name ctx in
  match_type_with_value (env, module_name) expected value

(** Wrapper around match_typarams_ctx. *)
let match_typarams_ctx (ctx: expr_ctx) (typarams: typarams) (type_args: ty list): type_bindings =
  match_typarams (ctx_env ctx, ctx_module_name ctx) typarams type_args

(** Is this expression of boolean type? *)
let is_bool (e: texpr): bool =
  match get_type e with
  | Boolean -> true
  | _ -> false

(** Is this expression an integer constant? *)
let is_int_constant (e: aexpr): bool =
  match e with
  | IntConstant _ -> true
  | _ -> false

(** Is this expression a float constant? *)
let is_float_constant (e: aexpr): bool =
  match e with
  | FloatConstant _ -> true
  | _ -> false

(** Is this an integer type? *)
let is_int_type (ty: ty): bool =
  match ty with
  | Integer _ -> true
  | _ -> false

(** Is this a floating point type? *)
let is_float_type (ty: ty): bool =
  match ty with
  | SingleFloat | DoubleFloat -> true
  | _ -> false

(* Since the extraction pass has already happened, we can simplify the call to
   `parse_type` by passing an empty list of local type signatures. *)
let parse_typespec (ctx: expr_ctx) (ty: qtypespec): ty =
  parse_type (ctx_env ctx) [] (ctx_region_map ctx) (ctx_typarams ctx) ty

let get_record_definition (env: env) (name: qident) (ty: ty): (module_name * type_vis * typarams * typed_slot list) =
  match get_decl_by_name env (qident_to_sident name) with
  | (Some (Record { mod_id; vis; typarams; slots; _ })) ->
     let mod_name: module_name = module_name_from_id env mod_id in
     (mod_name, vis, typarams, slots)
  | Some _ ->
     Errors.path_not_record ty
  | None ->
     internal_err ("No record with this name: " ^ (ident_string (original_name name)))

let get_slot_with_name type_name slots slot_name =
  match List.find_opt (fun (TypedSlot (n, _)) -> n = slot_name) slots with
  | Some s -> s
  | None ->
     Errors.no_such_slot
       ~type_name:(original_name type_name)
       ~slot_name

(* Check that there are as many bindings as there are type parameters, and that
   every type parameter is satisfied. *)
and check_bindings (typarams: typarams) (bindings: type_bindings): unit =
  let check (tp: type_parameter): unit =
    let n = typaram_name tp
    and u = typaram_universe tp
    in
    (match get_binding bindings tp with
     | Some ty ->
        if universe_compatible u (type_universe ty) then
          ()
        else
          internal_err ("Mismatched universes: expected "
               ^ (show_universe u)
               ^ " and got "
               ^ (show_universe (type_universe ty)))
     | None ->
        internal_err ("No binding for this parameter: " ^ (ident_string n)))
  in
  let _ = List.map check (typarams_as_list typarams) in
  ()


(* Argument List Checking *)

(* Given a list of type parameters, and a list of arguments, check that the
   lists have the same length and each argument satisfies each corresponding
   parameter. Return the resulting set of type bindings. *)
let rec check_argument_list ?(hint: type_bindings = empty_bindings) (ctx: expr_ctx) (name: identifier) (params: value_parameter list) (args: texpr list): type_bindings =
  (* Check that the number of parameters is the same as the number of
     arguments. *)
  check_arity name params args;
  (* Check arguments against parameters *)
  check_argument_list' ~hint ctx empty_bindings params args

and check_arity (name: identifier) (params: value_parameter list) (args: texpr list): unit =
  let nparams = List.length params
  and nargs = List.length args in
  if nparams = nargs then
    ()
  else
    (* The call site a function with a requires takes is added to every
       call by the compiler and is no argument the programme wrote; it is
       counted on neither side. *)
    let hidden = if takes_call_site params then 1 else 0 in
    Errors.call_wrong_arity ~name ~expected:(nparams - hidden) ~actual:(nargs - hidden)

(* Whether the last parameter is the call site of a function with a
   requires. *)
and takes_call_site (params: value_parameter list): bool =
  match List.rev params with
  | (ValueParameter (n, _)) :: _ -> String.equal (ident_string n) Names.contract_site_param
  | [] -> false

(* Precondition: both lists have the same length.  A literal does not fix a
   type parameter that another argument fixes: the arguments that are not
   literals are matched first, and a literal is matched against its
   parameter with their bindings put in, so that pick(v, 4) with v an Int64
   makes the 4 an Int64.  A literal whose parameter no other argument binds
   still binds it to Int32 or Float64. *)
and check_argument_list' ?(hint: type_bindings = empty_bindings) (ctx: expr_ctx) (bindings: type_bindings) (params: value_parameter list) (args: texpr list): type_bindings =
  if List.length params <> List.length args then
    check_argument_list'' ctx bindings params args
  else
    let is_literal (arg: texpr): bool =
      match arg with
      | TIntConstant _ | TFloatConstant _ -> true
      | _ -> false
    in
    let pairs = List.combine params args in
    let (literals, others) = List.partition (fun (_, arg) -> is_literal arg) pairs in
    let bindings' =
      List.fold_left
        (fun b (param, arg) -> merge_bindings b (match_parameter ctx param arg))
        bindings others
    in
    (* A literal whose parameter is a type variable the other arguments
       left open takes the type the asserted type gives that variable. *)
    List.fold_left
      (fun b (ValueParameter (n, ty), arg) ->
        let ty' = replace_variables b ty in
        let hinted = replace_variables hint ty' in
        match ty' with
        | TyVar _ when not (equal_ty hinted ty') ->
           let b = merge_bindings b (match_type_ctx ctx ty' hinted) in
           merge_bindings b (match_parameter ctx (ValueParameter (n, hinted)) arg)
        | _ ->
           merge_bindings b (match_parameter ctx (ValueParameter (n, ty')) arg))
      bindings' literals

and check_argument_list'' (ctx: expr_ctx) (bindings: type_bindings) (params: value_parameter list) (args: texpr list): type_bindings =
  match (params, args) with
  | ((first_param::rest_params), (first_arg::rest_args)) ->
     let bindings' = merge_bindings bindings (match_parameter ctx first_param first_arg) in
     check_argument_list'' ctx bindings' rest_params rest_args
  | ([], []) ->
     bindings
  | _ ->
     internal_err ("couldn't check argument list in module `"
                   ^ (mod_name_string (ctx_module_name ctx))
                   ^ "` with bindings: "
                   ^ (show_type_bindings bindings)
                   ^ ",\n params: `{ "
                   ^ (String.concat ", " (List.map show_value_parameter params))
                   ^ " }`,\n and args: `{ "
                   ^ (String.concat ", " (List.map show_texpr args))
                   ^ "}`")

and match_parameter (ctx: expr_ctx) (param: value_parameter) (arg: texpr): type_bindings =
  let (ValueParameter (_, ty)) = param in
  match_type_with_value_ctx ctx ty arg

let make_substs (bindings: type_bindings) (typarams: typarams): type_bindings =
  let f (tp: type_parameter): (type_parameter * ty) option =
    if (typaram_universe tp) = RegionUniverse then
      Some (tp, RegionTy static_region)
    else
      match get_binding bindings tp with
      | Some ty ->
         Some (tp, ty)
      | None ->
         None
  in
  bindings_from_list (List.filter_map f (typarams_as_list typarams))

(* A string literal handed to Standard.Regex's compile
   is parsed here, by a port of the module's own parser (lib/RegexCheck.ml),
   and a pattern the module would refuse is refused now rather than when the
   programme runs.  Only a literal: any other argument is not known until
   then.  test/RegexCheckTest.ml holds the port against the module. *)
let check_regex_literal (name: qident) (arguments: texpr list): unit =
  if (mod_name_string (source_module_name name)) = "Standard.Regex"
     && (ident_string (original_name name)) = "compile" then
    match arguments with
    | [TStringConstant s] ->
       (match RegexCheck.check (Escape.escaped_to_string s) with
        | Some message -> Errors.regex_pattern_refused message
        | None -> ())
    | _ -> ()

(* The argument of a task started in a LENDING scope
   (Standard.Task.spawnLending) may hold read references and spans of the
   scope's region, or of Static, and nothing else that borrows.  The check
   is made here and not beside check_task_argument in lib/Monomorphize.ml:
   there, every region parameter of a generic function has already become
   Static, and two regions could not be told apart.

   A `Lending[R]' names its region, so it cannot leave the borrow that
   binds R, and closeLending waits for every task of the scope -- so a
   reference of region R in a task's argument outlives the task.  What
   would break that is refused: a reference of another region (the task
   could outlive THAT borrow), a write reference or a mutable span (two
   tasks would hold the same thing to write), a type variable (its
   instantiation is not known here, and by monomorphization the regions
   are gone), and a lending scope itself (a task holding the scope could
   keep it open past the borrow). *)
let check_lending_argument (env: env) (name: qident) (bindings: type_bindings): unit =
  if (mod_name_string (source_module_name name)) = "Standard.Task"
     && (ident_string (original_name name)) = "spawnLending" then
    let find (n: string): ty option =
      List.find_map
        (fun (tp, ty) -> if ident_string (typaram_name tp) = n then Some ty else None)
        (bindings_list bindings)
    in
    match (find "A", find "R") with
    | (Some argument, Some region) ->
       let is_lending (q: qident): bool =
         (mod_name_string (source_module_name q)) = "Standard.Task"
         && (ident_string (original_name q)) = "Lending"
       in
       let region_ok (r: ty): unit =
         match r with
         | RegionTy reg when equal_region reg static_region -> ()
         | _ ->
            if equal_ty r region then
              ()
            else
              hilde_raise (H 3066) TypeError [
                  Text "The argument of a task in a lending scope holds a reference of another region.";
                  Break;
                  Text "A task started with ";
                  Code "Standard.Task.spawnLending";
                  Text " may be lent only what the scope's own borrow lends -- the region the scope was opened for -- because only that borrow is sure to outlive the task."
                ]
       in
       let write_refused (): unit =
         hilde_raise (H 3067) TypeError [
             Text "The argument of a task in a lending scope holds a write reference or a mutable span.";
             Break;
             Text "Tasks of a lending scope may only read what they are lent; two tasks holding the same thing to write would each see the other's half-done change."
           ]
       in
       (* `in_slot': inside the slots of a record or union declaration,
          where a region is the declaration's own parameter -- its value is
          one of the type's arguments, which are checked where they
          stand. *)
       let rec walk (seen: string list) (in_slot: bool) (ty: ty): unit =
         match ty with
         | ReadRef (t, r) | Span (t, r) ->
            if not in_slot then region_ok r;
            walk seen in_slot t
         | WriteRef _ | SpanMut _ ->
            write_refused ()
         | RegionTy _ ->
            if not in_slot then region_ok ty
         | TyVar (TypeVariable (_, RegionUniverse, _, _)) ->
            if not in_slot then region_ok ty
         | TyVar _ ->
            if not in_slot then
              hilde_raise (H 3068) TypeError [
                  Text "The argument of a task in a lending scope is of a type variable's type.";
                  Break;
                  Text "What a type variable stands for is not known where ";
                  Code "Standard.Task.spawnLending";
                  Text " is called, so it cannot be checked for references of another region.  Call it where the argument's type is written out."
                ]
         | NamedType (q, args, _) ->
            if is_lending q then
              hilde_raise (H 3069) TypeError [
                  Text "The argument of a task holds a lending scope.";
                  Break;
                  Text "A task that held the scope could keep it open after the borrow it lends from has ended.  Close the scope where it was opened."
                ];
            List.iter (walk seen in_slot) args;
            let key: string = qident_debug_name q in
            if not (List.mem key seen) then
              let seen' = key :: seen in
              let slot (TypedSlot (_, t)) = walk seen' true t in
              (match get_decl_by_name env (qident_to_sident q) with
               | Some (Record { slots; _ }) ->
                  List.iter slot slots
               | Some (Union { id; _ }) ->
                  List.iter
                    (fun c ->
                      match c with
                      | UnionCase { slots; _ } -> List.iter slot slots
                      | _ -> ())
                    (get_union_cases env id)
               | _ ->
                  ())
         | _ ->
            ()
       in
       walk [] false argument
    | _ ->
       ()
  else
    ()

(* Type Checking: Function Calls *)

let rec augment_call (ctx: expr_ctx) (name: qident) (args: typed_arglist) (asserted_ty: ty option): texpr =
  (* First, check if the callable name is a variable. *)
  match get_var (ctx_lexenv ctx) (local_name name) with
  | Some (ty, _) ->
     augment_fptr_call ctx (local_name name) ty asserted_ty args
  | None ->
     (* Otherwise, find a callable from the environment. *)
     (match get_callable (ctx_env ctx) (ctx_module_name ctx) (qident_to_sident name) with
      | Some callable ->
         augment_callable ctx name callable asserted_ty args
      | None ->
         let n: identifier = original_name name in
         let here: mod_id option =
           Option.map (fun (ModRec { id; _ }) -> id)
             (get_module_by_name (ctx_env ctx) (ctx_module_name ctx))
         in
         (match List.filter (fun m -> Some m <> here) (modules_with_function (ctx_env ctx) n) with
          | m :: _ -> Errors.callable_not_imported n (module_name_from_id (ctx_env ctx) m)
          | [] -> Errors.unknown_name ~kind:"callable" ~name:n))

and augment_fptr_call (ctx: expr_ctx) (name: identifier) (fn_ptr_ty: ty) (asserted_ty: ty option) (args: typed_arglist): texpr =
  (* Because function pointers don't preserve value parameter names, we can't
     accept named argument lists. *)
  let args: texpr list =
    match args with
    | TPositionalArglist args -> args
    | TNamedArglist _ ->
       Errors.fun_pointer_named_args ()
  in
  (* We extract the parameter types and return type from the function pointer
     type. *)
  let (paramtys, rt): (ty list * ty) =
    match fn_ptr_ty with
    | FnPtr (paramtys, rt) -> (paramtys, rt)
    | _ -> Errors.call_non_callable fn_ptr_ty
  in
  (* Then, we synthesize a parameter list from the function pointer type. The
     parameter names are fake, but this is so we can reuse the arity-checking,
     value parameter list-checking infrastructure we use elsewhere. *)
  let params: value_parameter list = List.map (fun paramty -> ValueParameter (make_ident "fake", paramty)) paramtys in
  (* Check synthetic parameter list against argument list. *)
  let bindings = check_argument_list ctx name params args in
  (* Use the bindings to get the effective return type *)
  let rt' = replace_variables bindings rt in
  let (bindings', rt'') = handle_return_type_polymorphism ctx name params rt rt' asserted_ty bindings in
  let arguments = cast_arguments bindings' params args in
  TFptrCall (name, arguments, rt'')

and augment_callable (ctx: expr_ctx) (name: qident) (callable: callable) (asserted_ty: ty option) (args: typed_arglist) =
  with_frame "Augment callable"
    (fun _ ->
      match callable with
      | FunctionCallable (id, typarams, params, rt) ->
         augment_function_call ctx id name typarams params rt asserted_ty args
      | RecordConstructor (_, typarams, universe, slots) ->
         augment_record_constructor ctx name typarams universe slots asserted_ty args
      | UnionConstructor { union_id; type_params; universe; case } ->
         let type_name: qident = (match get_decl_by_id (ctx_env ctx) union_id with
                                  | Some (Union { name; mod_id; _ }) ->
                                     (* TODO: constructing a fake qident *)
                                     make_qident (module_name_from_id (ctx_env ctx) mod_id, name, name)
                                  | _ ->
                                     internal_err ("no type name found for ID `" ^ (show_decl_id union_id) ^ "`"))
         in
         augment_union_constructor ctx type_name type_params universe case asserted_ty args
      | MethodCallable { typeclass_id; value_parameters; return_type; _ } ->
         let param = (match get_decl_by_id (ctx_env ctx) typeclass_id with
                      | Some (TypeClass { param; _ }) ->
                         param
                      | _ ->
                         internal_err ("no type parameter found for ID `" ^ (show_decl_id typeclass_id) ^ "`"))
         in
         augment_method_call ctx typeclass_id param name value_parameters return_type asserted_ty args)

(* A call may not carry a kind the caller's clause does not name.  The
   kinds of the callee stand in the environment; the kinds of the caller
   are the ref TypingPass set.  A callee with no clause promises nothing
   and cannot be exceeded; a callee with a clause must be named in full.
   abort and the compiler's own contract failures
   carry no clause: they are panics, not kinds, and no signature names
   them.  A raise is not a call here: its kind rides the TRaise statement
   and TypingPass holds it against the clause where the statement is
   typed. *)
and raises_of_callee (env: env) (id: decl_id): string list =
  match get_decl_by_id env id with
  | Some (Function { raises; _ }) -> raises
  | Some (TypeClassMethod { raises; _ }) -> raises
  | _ -> []

(* The decl_id of the typeclass's declaration of the method a call names. *)
and typeclass_method_id (env: env) (typeclass_id: decl_id) (name: qident): decl_id option =
  match get_method_from_typeclass_id_and_name env typeclass_id (original_name name) with
  | Some (TypeClassMethod { id; _ }) -> Some id
  | _ -> None

and check_raises (ctx: expr_ctx) (callee_id: decl_id) (callee_name: qident): unit =
  match !Common.current_raises with
  | None -> ()
  | Some allowed ->
     let callee = raises_of_callee (ctx_env ctx) callee_id in
     if callee <> [] then
       let unmet = List.filter (fun k -> not (List.mem k allowed)) callee in
       if unmet <> [] then
         let (cm, cn) = (source_module_name callee_name, original_name callee_name) in
         let callee_text = (mod_name_string cm) ^ "." ^ (ident_string cn) in
         Errors.raises_exceeded ~callee:callee_text ~unmet ~allowed

and augment_function_call (ctx: expr_ctx) (id: decl_id) name typarams params rt asserted_ty args =
  with_frame "Augment function call"
    (fun _ ->
      pqi ("Name", name);
      check_raises ctx id name;
      (* For simplicity, and to reduce duplication of code, we convert the argument
         list to a positional list. *)
      let param_names = List.map (fun (ValueParameter (n, _)) -> n) params in
      let arguments: texpr list = arglist_to_positional (args, param_names) in
      (* Check the list of params against the list of arguments *)
      let bindings = check_argument_list ~hint:(asserted_hint ctx rt asserted_ty) ctx (original_name name) params arguments in
      (* Use the bindings to get the effective return type *)
      let rt' = replace_variables bindings rt in
      let (bindings', rt'') = handle_return_type_polymorphism ctx (local_name name) params rt rt' asserted_ty bindings in
      (* Check: the set of bindings equals the set of type parameters *)
      let bindings'' = merge_bindings bindings bindings' in
      check_bindings typarams bindings'';
      check_regex_literal name arguments;
      check_lending_argument (ctx_env ctx) name bindings'';
      let arguments' = cast_arguments bindings'' params arguments in
      let substs = make_substs bindings'' typarams in
      ps ("Bindings", show_bindings bindings'');
      pt ("Return type", rt'');
      TFuncall (id, name, arguments', rt'', substs))

and augment_record_constructor (ctx: expr_ctx) (name: qident) (typarams: typarams) (universe: universe) (slots: typed_slot list) (asserted_ty: ty option) (args: typed_arglist) =
  (* Check: the argument list must be named *)
  let args' = (match args with
               | TPositionalArglist l ->
                  if l = [] then
                    []
                  else
                    Errors.constructor_not_named "record"
               | TNamedArglist a ->
                  a) in
  (* Check: the set of slots matches the set of param names *)
  let slot_names: identifier list = List.map (fun (TypedSlot (name, _)) -> name) slots in
  let argument_names: identifier list = List.map (fun (n, _) -> n) args' in
  if not (ident_set_eq slot_names argument_names) then
    Errors.constructor_wrong_args "record"
  else
    (* Convert args to positional *)
    let arguments = arglist_to_positional (args, slot_names) in
    (* Check the list of params against the list of arguments *)
    let params = List.map (fun (TypedSlot (n, t)) -> ValueParameter (n, t)) slots in
    let bindings = check_argument_list ctx (original_name name) params arguments in
    (* Use the bindings to get the effective return type *)
    let rt = NamedType (name,
                        List.map (fun tp -> TyVar (typaram_to_tyvar tp)) (typarams_as_list typarams),
                        universe)
    in
    let rt' = replace_variables bindings rt in
    let (bindings', rt'') = handle_return_type_polymorphism ctx (local_name name) params rt rt' asserted_ty bindings in
    (* Check: the set of bindings equals the set of type parameters *)
    check_bindings typarams (merge_bindings bindings bindings');
    (* Check the resulting type is in the correct universe *)
    if universe_compatible universe (type_universe rt'') then
      TRecordConstructor (rt'', List.map2 (fun a b -> (a, b)) slot_names arguments)
    else
      internal_err "Universe mismatch"

and augment_union_constructor (ctx: expr_ctx) (type_name: qident) (typarams: typarams) (universe: universe) (case: typed_case) (asserted_ty: ty option) (args: typed_arglist) =
  with_frame "Augment union constructor"
    (fun _ ->
      pqi ("Type name", type_name);
      let args' = (match args with
                   | TPositionalArglist l ->
                      if l = [] then
                        []
                      else
                        Errors.constructor_not_named "union"
                   | TNamedArglist a ->
                      a) in
      (* Check: the set of slots matches the set of param names *)
      let (TypedCase (case_name, slots)) = case in
      pi ("Case name", case_name);
      let slot_names: identifier list = List.map (fun (TypedSlot (name, _)) -> name) slots in
      let argument_names: identifier list = List.map (fun (n, _) -> n) args' in
      if not (ident_set_eq slot_names argument_names) then
        Errors.constructor_wrong_args "union"
      else
        (* Convert args to positional *)
        let arguments = arglist_to_positional (args, slot_names) in
        (* Check the list of params against the list of arguments *)
        let params = List.map (fun (TypedSlot (n, t)) -> ValueParameter (n, t)) slots in
        ps ("Params", String.concat "\n" (List.map (fun (ValueParameter (n, t)) -> (ident_string n) ^ ": " ^ (type_string t)) params));
        ps ("Arguments", String.concat "\n" (List.map show_texpr arguments));
        (* Use the bindings to get the effective return type *)
        let rt = NamedType (type_name,
                            List.map (fun tp -> TyVar (typaram_to_tyvar tp)) (typarams_as_list typarams),
                            universe)
        in
        let bindings = check_argument_list ~hint:(asserted_hint ctx rt asserted_ty) ctx case_name params arguments in
        pt ("Type", rt);
        ps ("Bindings", show_bindings bindings);
        let rt' = replace_variables bindings rt in
        pt ("Type'", rt');
        let (bindings', rt'') = handle_return_type_polymorphism ctx case_name params rt rt' asserted_ty bindings in
        (* Check: the set of bindings equals the set of type parameters *)
        check_bindings typarams (merge_bindings bindings bindings');
        (* Check the resulting type is in the correct universe *)
        if universe_compatible universe (type_universe rt'') then
          let _ = pt ("Type''", rt'')
          in
          TUnionConstructor (rt'', case_name, List.map2 (fun a b -> (a, b)) slot_names arguments)
        else
          internal_err "Universe mismatch")

and augment_method_call (ctx: expr_ctx) (typeclass_id: decl_id) (typaram: type_parameter) (callable_name: qident) (params: value_parameter list) (rt: ty) (asserted_ty: ty option) (args: typed_arglist): texpr =
  with_frame "Augmenting method call"
    (fun _ ->
      pqi ("Callable name", callable_name);
      (match typeclass_method_id (ctx_env ctx) typeclass_id callable_name with
       | Some callee_id -> check_raises ctx callee_id callable_name
       | None -> ());
      (* At this point, we know the method's name and the typeclass it belongs
         to. We pull the parameter list from the typeclass, and compare that against
         the argument list. *)
      (* For simplicity, and to reduce duplication of code, we convert the argument
         list to a positional list. *)
      let param_names = List.map (fun (ValueParameter (n, _)) -> n) params in
      let arguments: texpr list = arglist_to_positional (args, param_names) in
      (* Check the list of params against the list of arguments *)
      let bindings = check_argument_list ctx (original_name callable_name) params arguments in
      (* Use the bindings to get the effective return type *)
      let rt' = replace_variables bindings rt in
      let (bindings', rt'') = handle_return_type_polymorphism ctx (local_name callable_name) params rt rt' asserted_ty bindings in
      let bindings'' = merge_bindings bindings bindings' in
      ps ("Bindings", show_bindings bindings'');
      (* Check: the set of bindings equals the set of type parameters *)
      check_bindings (typarams_from_list [typaram]) bindings'';
      match get_binding bindings'' typaram with
      | (Some dispatch_ty) ->
         pt ("Dispatch Type", dispatch_ty);
         (* Is the dispatch type a type variable? *)
         (match dispatch_ty with
          | TyVar (TypeVariable (typaram, _, _, constraints)) ->
             (* If so, check if the constraints say that it implements the typeclass. *)
             let tc_name: sident = get_decl_sident_or_die (ctx_env ctx) typeclass_id in
             if List.exists (fun c -> equal_sident tc_name c) constraints then
               (* If it's a tyvar that implements the typeclass, we have to
                  proceed differently. Essentially we can't go on with instance
                  resolution, because we don't have a type to resolve an
                  instance for. So we have to freeze the process. *)
               TVarMethodCall {
                   source_module_name = (ctx_module_name ctx);
                   typeclass_id = typeclass_id;
                   params = params;
                   method_name = callable_name;
                   args = arguments;
                   dispatch_ty = dispatch_ty;
                   rt = rt'';
                   bindings = bindings'';
                 }
             else
               (* If it doesn't, that's an error *)
               Errors.unconstrained_type_parameter
                 ~typeclass:(sident_name tc_name)
                 ~typaram
          | _ ->
             (* If it's not a type variable, continue normal instance resolution. *)
             let (instance, instance_bindings): decl * type_bindings =
               (match get_instance (ctx_env ctx) (ctx_module_name ctx) dispatch_ty typeclass_id with
                | Some (i, b) -> (i, b)
                | None ->
                   let tc_name: sident = get_decl_sident_or_die (ctx_env ctx) typeclass_id in
                   Errors.no_suitable_instance
                     ~typeclass:(sident_name tc_name)
                     ~ty:dispatch_ty)
             in
             ps ("Instance bindings", show_bindings instance_bindings);
             let params' = List.map (fun (ValueParameter (n, t)) -> ValueParameter (n, replace_variables instance_bindings t)) params in
             let arguments' = cast_arguments instance_bindings params' arguments in
             let typarams = (match instance with
                             | Instance { typarams; _ } -> typarams
                             | _ -> internal_err "Couldn't get instance while getting type parameters")
             in
             let instance_id: decl_id = decl_id instance in
             let meth_id: ins_meth_id =
               (match get_instance_method_from_instance_id_and_method_name (ctx_env ctx) instance_id (original_name callable_name) with
                | Some (InsMethRec { id; _ }) -> id
                | None -> internal_err ("Couldn't get instance method for `"
                                        ^ (ident_string (original_name callable_name))
                                        ^ "`"))
             in
             ps ("Bindings", show_bindings bindings'');
             let substs = make_substs instance_bindings typarams in
             TMethodCall (meth_id, callable_name, typarams, arguments', rt'', substs))
      | None ->
         internal_err "couldn't extract dispatch type.")

(* The bindings the asserted type gives the variables of a return type, or
   none when it gives none or does not fit; a type error stays for the
   check that comes after. *)
and asserted_hint (ctx: expr_ctx) (rt: ty) (asserted_ty: ty option): type_bindings =
  match asserted_ty with
  | Some a -> (try match_type_ctx ctx rt a with Hilde_error _ -> empty_bindings)
  | None -> empty_bindings

and cast_arguments (bindings: type_bindings) (params: value_parameter list) (arguments: texpr list): texpr list =
  let f (ValueParameter (_, expected)) value =
    let expected' = replace_variables bindings expected in
    match expected' with
    | Integer _ ->
       (* Cast integer types *)
       TCast (value, expected')
    | _ ->
       value
  in
  List.map2 f params arguments

(* `original_rt' is the callee's return type as DECLARED, `rt' the same type
   with the bindings from the arguments already put in.  Whether the return
   type is polymorphic is a question about the callee, so it is asked of the
   declared one.  Asking it of `rt' -- as
   Austral does -- counts the CALLER's type variables as the callee's
   unbound ones, because the check compares type variables by name: a call
   of `nullCheck' on an `Address[Cell[A, T]]' inside a function generic in A
   and T was refused as "generic but unconstrained", since A is not a type
   parameter of nullCheck.  docs/differences-from-austral.md lists it as
   not reported upstream. *)
and handle_return_type_polymorphism (ctx: expr_ctx) (name: identifier) (params: value_parameter list) (original_rt: ty) (rt: ty) (asserted_ty: ty option) (bindings: type_bindings): (type_bindings * ty) =
  if is_return_type_polymorphic params original_rt then
    match asserted_ty with
    | (Some asserted_ty') ->
       let bindings' = match_type_ctx ctx rt asserted_ty' in
       let bindings'' = merge_bindings bindings bindings' in
       (bindings'', replace_variables bindings'' rt)
    | None ->
       Errors.unconstrained_generic_function name rt
  else
    (empty_bindings, replace_variables bindings rt)

(* Given a function's parameter list and return type, check if the return type
   of a function is polymorphic. *)
and is_return_type_polymorphic (params: value_parameter list) (rt: ty): bool =
  (* Find the set of type variables in the return type. *)
  let rt_type_vars: TypeVarSet.t = type_variables rt in
  (* Find the set of type variables in each of the parameters. *)
  let param_type_vars: TypeVarSet.t list = List.map (fun (ValueParameter (_, ty)) -> type_variables ty) params in
  (* Union the type variables of the parameters into one set of all type
     variables in the parameter list. *)
  let param_type_vars: TypeVarSet.t = List.fold_left TypeVarSet.union TypeVarSet.empty param_type_vars in
  (* Find the set of type variables that are in the return type set but not in
     the parameter set. *)
  let vars_not_params: TypeVarSet.t =
    let param_ty_vars: type_var list = TypeVarSet.elements param_type_vars
    in
    let var_name_in_typarams (n: identifier): bool =
      List.exists (fun (TypeVariable (n', _, _, _)) -> equal_identifier n n') param_ty_vars
    in
    TypeVarSet.of_list (List.filter (fun (TypeVariable (n, _, _, _)) -> not (var_name_in_typarams n)) (TypeVarSet.elements rt_type_vars))
  in
  (TypeVarSet.cardinal vars_not_params) > 0

(* Type Checking: Interface *)

let rec augment_expr (ctx: expr_ctx) (asserted_ty: ty option) (expr: aexpr): texpr =
  (* Dispatch on the AST *)
  match expr with
  | NilConstant ->
     TNilConstant
  | BoolConstant b ->
     TBoolConstant b
  | IntConstant i ->
     TIntConstant i
  | FloatConstant f ->
     TFloatConstant f
  | StringConstant s ->
     TStringConstant s
  | Variable name ->
     augment_variable ctx name asserted_ty
  | Temporary name ->
     augment_temporary ctx name
  | FunctionCall (name, args) ->
     let arglist: typed_arglist = augment_arglist_expecting ctx name asserted_ty args in
     augment_call ctx name arglist asserted_ty
  | ArithmeticExpression (op, lhs, rhs) ->
     augment_arithmetic ctx op lhs rhs asserted_ty
  | Comparison (op, lhs, rhs) ->
     augment_comparison ctx op lhs rhs
  | Conjunction (lhs, rhs) ->
     augment_conjunction ctx lhs rhs
  | Disjunction (lhs, rhs) ->
     augment_disjunction ctx lhs rhs
  | Negation e ->
     augment_negation ctx e
  | ArithNegation e ->
     augment_arith_negation ctx e asserted_ty
  | IfExpression (c, t, f) ->
     augment_if_expr ctx c t f
  | Embed (span, ty, expr, args) ->
     let _ = adorn_error_with_span span (fun _ -> check_embed_allowed ctx) in
     let _ = adorn_error_with_span span (fun _ -> check_embed_names ctx expr) in
     TEmbed (
         parse_typespec ctx ty,
         expr,
         List.map (fun e -> aug ctx e) args
       )
  | Deref expr ->
     augment_deref ctx expr
  | Typecast (expr, ty) ->
     augment_typecast ctx expr ty
  | SizeOf ty ->
     TSizeOf (parse_typespec ctx ty)
  | Question (span, _) ->
     (* Reaching this means the operator was written somewhere
        other than the statement positions TypingPass handles, and the
        message says which those are. *)
     adorn_error_with_span span (fun _ -> Errors.question_in_expression ())
  | SlotAccessor (expr, slot_name) ->
     augment_slot_access ctx expr slot_name
  | PointerSlotAccessor (expr, slot_name) ->
     augment_pointer_slot_access ctx expr slot_name
  | ArrayIndex (expr, index) ->
     augment_array_index ctx expr index
  | RefTransform (mode, path) ->
     augment_ref_transform ctx mode path

(* Type Checking: Internals *)

(* &(path) is a read reference to the part the path names, and
   &!(path) a write reference to it; both have the region of the reference
   the path starts from.  The chain of accessors inside is typed as before,
   and carries the kind of the head's reference down; this function makes
   it the kind that was written.  A read reference from a write reference
   is the cast that augment_typecast allows (same type, same region), so
   the write reference is used up by it, as by the cast; a write reference
   needs a write reference to start from. *)
and augment_ref_transform (ctx: expr_ctx) (mode: borrowing_mode) (path: aexpr): texpr =
  let path': texpr = aug ctx path in
  match (mode, get_type path') with
  | (ReadBorrow, WriteRef (ty, region)) ->
     TCast (path', ReadRef (ty, region))
  | (ReadBorrow, _) ->
     path'
  | (WriteBorrow, WriteRef _) ->
     path'
  | (WriteBorrow, ty) ->
     hilde_raise (H 3093) TypeError [
         Text "A write reference to part of a value needs a write reference to the value, but the path gives ";
         Type ty;
         Text ".";
         Break;
         Text "Start the path from a write reference, or take a read reference with ";
         Code "&(...)";
         Text "."
       ]

and augment_variable (ctx: expr_ctx) (name: qident) (asserted_ty: ty option): texpr =
  let env = ctx_env ctx in
  let imported: bool =
    not (equal_module_name (source_module_name name) (ctx_module_name ctx))
  in
  (* A local or a parameter named like an imported declaration means the
     local inside its function: the name was qualified with the module it
     is imported from, and the declaration of that module was taken, which
     made a parameter start beside an imported function start a function
     pointer.  A local named like a declaration of the module itself is
     refused where it is bound, so it never comes here. *)
  match (if imported then get_var (ctx_lexenv ctx) (original_name name) else None) with
  | Some (ty, VarLocal _) -> TLocalVar ((original_name name), ty)
  | Some (ty, VarParam) -> TParamVar ((original_name name), ty)
  | _ ->
  (* Does this name a declaration? *)
  match get_decl_by_name env (qident_to_sident name) with
  | Some (Function { value_params; _ }) when takes_call_site value_params ->
     (* A requires names the caller at fault, and a call through a
        pointer has no call site the compiler can write down. *)
     hilde_raise (H 3101) TypeError [
         Text "The function ";
         Code (ident_string (original_name name));
         Text " has a requires and cannot be taken as a function pointer.";
         Break;
         Text "A violated requires names the call that broke it, and a call through a pointer has no place the compiler can name.  Call the function directly, or write a function without a requires that calls it."
       ]
  | Some (Function { raises; _ }) when raises <> [] ->
     (* A call through a pointer would bypass the kinds check. *)
     Errors.raises_as_pointer ~name:(ident_string (original_name name))
  | Some (Function { id; typarams; value_params; rt; _ }) ->
     let arg_tys: ty list = List.map (fun (ValueParameter (_, ty)) -> ty) value_params in
     let fn_ty: ty = FnPtr (arg_tys, rt) in
     if (typarams_size typarams > 0) then
       (* Function is generic, need an asserted type. *)
       (match asserted_ty with
        | Some asserted_ty ->
           let bindings: type_bindings = match_type_ctx ctx fn_ty asserted_ty in
           let rt: ty = replace_variables bindings rt
           and arg_tys: ty list = List.map (replace_variables bindings) arg_tys in
           let effective_fn_ty: ty = FnPtr (arg_tys, rt) in
           (* A function VALUE of spawnLending is checked as a call is, or
              calling it through the pointer would go round the check. *)
           check_lending_argument env name bindings;
           TFunVar (id, effective_fn_ty, bindings)
        | None ->
           Errors.unconstrained_generic_function (original_name name) fn_ty)
     else
       (* Function is concrete. *)
       TFunVar (id, fn_ty, empty_bindings)
  | _ ->
     (match get_variable (ctx_env ctx) (ctx_lexenv ctx) name with
      | Some (ty, src) ->
         (match src with
          | VarConstant ->
             TConstVar (name, ty)
          | VarParam ->
             TParamVar ((original_name name), ty)
          | VarLocal _ ->
             TLocalVar ((original_name name), ty))
      | None ->
         Errors.unknown_name
           ~kind:"variable"
           ~name:(original_name name))

and augment_temporary (ctx: expr_ctx) (name: identifier): texpr =
  match get_var (ctx_lexenv ctx) name with
  | Some (ty, _) ->
     TTemporary (name, ty)
  | None ->
     internal_err ("Temporary variable does not exist in lexenv: " ^ (ident_string name))

and augment_comparison ctx op lhs rhs =
  let lhs' = aug ctx lhs
  and rhs' = aug ctx rhs in
  let _ = match_type_with_value_ctx ctx (get_type lhs') rhs' in
  (* The comparison becomes the C operator, which takes scalars and
     pointers only.  A type variable is checked where the function is
     instantiated, once the type it stands for is known. *)
  (match get_type lhs' with
   | Unit | Boolean | Integer _ | SingleFloat | DoubleFloat
   | ReadRef _ | WriteRef _ | Address _ | Pointer _ | FnPtr _ | TyVar _ -> ()
   | ty -> Errors.comparison_not_defined op ty);
  TComparison (op, lhs', rhs')

and augment_conjunction ctx lhs rhs =
  let lhs': texpr = aug ctx lhs
  and rhs': texpr = aug ctx rhs in
  if ((is_bool lhs') && (is_bool rhs')) then
    TConjunction (lhs', rhs')
  else
    Errors.logical_operands_not_boolean
      ~operator:"conjunction"
      ~types:[get_type lhs'; get_type rhs']

and augment_disjunction ctx lhs rhs =
  let lhs': texpr = aug ctx lhs
  and rhs': texpr = aug ctx rhs in
  if ((is_bool lhs') && (is_bool rhs')) then
    TDisjunction (lhs', rhs')
  else
    Errors.logical_operands_not_boolean
      ~operator:"disjunction"
      ~types:[get_type lhs'; get_type rhs']

and augment_negation ctx e =
  let e' = aug ctx e in
  if is_bool e' then
    TNegation e'
  else
    Errors.logical_operands_not_boolean
      ~operator:"negation"
      ~types:[get_type e']

and augment_if_expr ctx c t f =
  let c' = aug ctx c
  and t' = aug ctx t
  and f' = aug ctx f in
  if is_bool c' then
    let either_never: bool =
      (match (get_type t', get_type f') with
       | (Never, _) | (_, Never) -> true
       | _ -> false)
    in
    if either_never || (get_type t') = (get_type f') then
      TIfExpression (c', t', f')
    else
      Errors.if_inequal
        ~lhs:(get_type t')
        ~rhs:(get_type f')
  else
    Errors.condition_not_boolean
      ~kind:"if"
      ~form:"expression"
      ~ty:(get_type c')

and augment_deref (ctx: expr_ctx) (expr: aexpr): texpr =
  (* The type of the expression being dereferenced must be either a read-only
     reference or a write reference. *)
  let expr' = aug ctx expr in
  let ty = get_type expr' in
  (match ty with
   | ReadRef (ty', _) ->
      if type_universe ty' = FreeUniverse then
        TDeref expr'
      else
        Errors.dereference_non_free ty'
   | WriteRef (ty', _) ->
      if type_universe ty' = FreeUniverse then
        TDeref expr'
      else
        Errors.dereference_non_free ty'
   | _ ->
      Errors.dereference_non_reference ty)

and augment_slot_access (ctx: expr_ctx) (expr: aexpr) (slot_name: identifier): texpr =
  (* The type of the expression is a reference. *)
  let expr: texpr = aug ctx expr in
  let ty, region, mode =
    match (get_type expr) with
    | ReadRef (ty, reg) ->
       (ty, reg, ReadBorrow)
    | WriteRef (ty, reg) ->
       (ty, reg, WriteBorrow)
    | _ ->
       Errors.ref_transform_needs_ref (get_type expr)
  in
  (* The pointed-to type is a record. *)
  let (type_name, type_args): qident * ty list = begin
      match ty with
      | NamedType (name, args, _) ->
         (name, args)
      | _ ->
         Errors.cant_access_slot_not_record slot_name ty
    end
  in
  let (source_module, vis, typarams, slots) = get_record_definition (ctx_env ctx) type_name ty in
  (* We can access that record. *)
  let _ =
    if (vis = TypeVisPublic) || ((ctx_module_name ctx) = source_module) then
      (* The record is public, or it is defined in the same module as we are. *)
      ()
    else
      Errors.path_not_public
        ~type_name:(original_name type_name)
        ~slot_name:slot_name
  in
  (* Get the slot with the given name. *)
  let (TypedSlot (_, slot_ty)) = get_slot_with_name type_name slots slot_name in
  (* Make the slot type. *)
  let bindings: type_bindings = match_typarams_ctx ctx typarams type_args in
  let slot_ty: ty = replace_variables bindings slot_ty in
  (* The result ty is a reference to the type of the slot. *)
  let ty: ty =
    match mode with
    | ReadBorrow -> ReadRef (slot_ty, region)
    | WriteBorrow -> WriteRef (slot_ty, region)
  in
  (* Return *)
  TSlotAccessor (expr, slot_name, ty)

and augment_pointer_slot_access (ctx: expr_ctx) (expr: aexpr) (slot_name: identifier): texpr =
  (* The type of the expression is a reference... *)
  let expr: texpr = aug ctx expr in
  let ty1: ty = get_type expr in
  let ty2, region =
    match ty1 with
    | ReadRef (ty2, reg) ->
       (ty2, reg)
    | WriteRef (ty2, reg) ->
       (ty2, reg)
    | _ ->
       Errors.ref_transform_needs_ref (get_type expr)
  in
  (* ... to a reference... *)
  let (ty3, mode): ty * borrowing_mode =
    match ty2 with
    | ReadRef (ty3, _) ->
       (ty3, ReadBorrow)
    | WriteRef (ty3, _) ->
       (ty3, WriteBorrow)
    | _ ->
       hilde_raise (H 3005) TypeError [
           Text "The type ";
           Type ty2;
           Text " is not a reference."
         ]
  in
  (* ... to a record. *)
  let (type_name, type_args): qident * ty list = begin
      match ty3 with
      | NamedType (name, args, _) ->
         (name, args)
      | _ ->
         Errors.cant_access_slot_not_record slot_name ty3
    end
  in
  let (source_module, vis, typarams, slots) = get_record_definition (ctx_env ctx) type_name ty3 in
  (* We can access that record. *)
  let _ =
    if (vis = TypeVisPublic) || ((ctx_module_name ctx) = source_module) then
      (* The record is public, or it is defined in the same module as we are. *)
      ()
    else
      Errors.path_not_public
        ~type_name:(original_name type_name)
        ~slot_name:slot_name
  in
  (* Get the slot with the given name. *)
  let (TypedSlot (_, slot_ty)) = get_slot_with_name type_name slots slot_name in
  (* Make the slot type. *)
  let bindings: type_bindings = match_typarams_ctx ctx typarams type_args in
  let slot_ty: ty = replace_variables bindings slot_ty in
  (* The result ty is a reference to the type of the slot. *)
  let ty: ty =
    match mode with
    | ReadBorrow -> ReadRef (slot_ty, region)
    | WriteBorrow -> WriteRef (slot_ty, region)
  in
  (* Return *)
  TPointerSlotAccessor (expr, slot_name, ty)

and augment_array_index (ctx: expr_ctx) (expr: aexpr) (index_expr: aexpr): texpr =
  (* Augment the expression and the index expression. *)
  let expr: texpr = aug ctx expr
  and index_expr: texpr = aug ctx index_expr in
  (* The type of the expression is a reference to a span, or a span.

     Through a reference, an element of a read span is a read
     reference with the span's own region: the span is Free and its data
     is not changed for as long as that region, whoever holds the span.
     Upstream gave the reference's region, and a write reference to the
     span gave a WRITE reference into data the span may only read.  An
     element of a write span, which is linear and the only way to its data,
     is a write reference only through a write reference, and keeps the
     region of that reference: after it the span may write again. *)
  match (get_type expr) with
  | ReadRef (ty, reg) -> begin
      match ty with
      | Span (elem_ty, span_reg) ->
         TArrayIndex (expr, index_expr, ReadRef (elem_ty, span_reg))
      | SpanMut (elem_ty, _) ->
         TArrayIndex (expr, index_expr, ReadRef (elem_ty, reg))
      | _ ->
         Errors.cant_index_not_span ty
    end
  | WriteRef (ty, reg) -> begin
      match ty with
      | Span (elem_ty, span_reg) ->
         TArrayIndex (expr, index_expr, ReadRef (elem_ty, span_reg))
      | SpanMut (elem_ty, _) ->
         TArrayIndex (expr, index_expr, WriteRef (elem_ty, reg))
      | _ ->
         Errors.cant_index_not_span ty
    end
  | Span (ty, reg) ->
     TSpanIndex (expr, index_expr, ReadRef (ty, reg))
  | SpanMut (ty, reg) ->
     TSpanIndex (expr, index_expr, WriteRef (ty, reg))
  | _ ->
     internal_raise [
         Text "Expected the head of an array indexing operator to be a reference, but found the type ";
         Type (get_type expr)
       ]


and augment_typecast (ctx: expr_ctx) (expr: aexpr) (ty: qtypespec): texpr =
  (* The typecast operator has four uses:

     1. Clarifying the type of integer and floating point literals.

     2. Converting write references to read references.

     3. Clarifying the type of return type polymorphic functions.

   *)
  let is_int_expr = function
    | TIntConstant _ -> true
    | _ -> false
  and is_float_expr = function
    | TFloatConstant _ -> true
    | _ -> false

  and is_int_type = function
    | Integer _ -> true
    | _ -> false

  and is_float_type = function
    | SingleFloat -> true
    | DoubleFloat -> true
    | _ -> false
  in
  let target_type = parse_typespec ctx ty in
  (* By passing target_type as the asserted type we're covering use 3. *)
  let expr' = augment_expr ctx (Some target_type) expr in
  (* For 1: if the expression is an int literal and the target type is an
     int type, do the conversion. Similarly, if the expression is a float
     constant and the target type is a float, do the conversion. *)
  if (is_int_expr expr') && (is_int_type target_type) then
    TCast (expr', target_type)
  else
    if (is_float_expr expr') && (is_float_type target_type) then
      TCast (expr', target_type)
    else
      (* Otherwise, if the expression has a mutable reference type and the
         target type is a read reference, and they point to the same underlying
         type and underlying region, just convert it to a read ref. This covers
         use 2. *)
      (match (get_type expr') with
       | WriteRef (underlying_ty, region) ->
          (match target_type with
           | ReadRef (underlying_ty', region') ->
              if ((equal_ty underlying_ty underlying_ty') && (equal_ty region region')) then
                TCast (expr', target_type)
              else
                Errors.cast_different_references
                  ~different_types:(not (equal_ty underlying_ty underlying_ty'))
                  ~different_regions:(not (equal_ty region region'))
           | WriteRef (underlying_ty', region')
                when (equal_ty underlying_ty underlying_ty') && (equal_ty region region') ->
              (* A write reference to its own type is no conversion.  A let
                 or a var that names the type of a write reference casts its
                 value to that type (AbstractionPass.let_reshape), so without
                 this a write reference could not be bound to a name.  The
                 reference is moved, as it is when it is passed on. *)
              expr'
           | _ ->
              Errors.cast_write_ref_to_non_ref ())
       | _ ->
          (try
             let _ = match_type_ctx ctx target_type (get_type expr') in
             expr'
           with Hilde_error _ ->
             Errors.cast_invalid
               ~target:target_type
               ~source:(get_type expr')))

(* The arguments of a call, each checked alone, with no type asserted.  An
   argument that is refused only because it is a generic call nothing decides
   (H3055), as None() is, is checked once more with the type of its parameter
   as the asserted type, when that type is known: written out in the callee,
   or decided by the type asserted of the whole call.  So
   `Right(right => None())' returned from a function of `Either[E, Option[T]]'
   and `f(None())' for a parameter of `Option[Int32]' need no variable declared
   for the inner value.  An argument that checks alone is never checked again,
   so no programme that was taken before is checked differently; when the
   second check fails too, the first refusal stands. *)
and augment_arglist_expecting (ctx: expr_ctx) (name: qident) (asserted_ty: ty option) (args: abstract_arglist): typed_arglist =
  (* The parameters of the callee, its return type and its own type
     parameters; None where the callee is a local function pointer or a
     method. *)
  let callee: (value_parameter list * ty * typarams) option =
       (match get_var (ctx_lexenv ctx) (local_name name) with
        | Some _ -> None
        | None ->
           (match get_callable (ctx_env ctx) (ctx_module_name ctx) (qident_to_sident name) with
            | Some (FunctionCallable (_, typarams, params, rt)) ->
               Some (params, rt, typarams)
            | Some (RecordConstructor (_, typarams, universe, slots)) ->
               let rt = NamedType (name,
                                   List.map (fun tp -> TyVar (typaram_to_tyvar tp)) (typarams_as_list typarams),
                                   universe) in
               Some (List.map (fun (TypedSlot (n, t)) -> ValueParameter (n, t)) slots, rt, typarams)
            | Some (UnionConstructor { union_id; type_params; universe; case }) ->
               (match get_decl_by_id (ctx_env ctx) union_id with
                | Some (Union { name = union_name; mod_id; _ }) ->
                   let type_name: qident = make_qident (module_name_from_id (ctx_env ctx) mod_id, union_name, union_name) in
                   let rt = NamedType (type_name,
                                       List.map (fun tp -> TyVar (typaram_to_tyvar tp)) (typarams_as_list type_params),
                                       universe) in
                   let (TypedCase (_, slots)) = case in
                   Some (List.map (fun (TypedSlot (n, t)) -> ValueParameter (n, t)) slots, rt, type_params)
                | _ -> None)
            | _ -> None))
  in
  (* The type of a parameter, once the asserted type has put in what it
     decides; None while one of the callee's own type parameters is open. *)
  let expected (param: value_parameter option): ty option =
    match (callee, param) with
    | (Some (_, rt, typarams), Some (ValueParameter (_, t))) ->
       let hint: type_bindings = asserted_hint ctx rt asserted_ty in
       let t' = replace_variables hint t in
       let own = TypeVarSet.of_list (List.map typaram_to_tyvar (typarams_as_list typarams)) in
       if TypeVarSet.is_empty (TypeVarSet.inter (type_variables t') own) then Some t' else None
    | _ -> None
  in
  let params: value_parameter list = match callee with Some (ps, _, _) -> ps | None -> [] in
  let check (param: value_parameter option) (a: aexpr): texpr =
    try aug ctx a with
    | Hilde_error (HildeError { code = H 3055; _ }) as refused ->
       (match expected param with
        | Some t -> (try augment_expr ctx (Some t) a with Hilde_error _ -> raise refused)
        | None -> raise refused)
  in
  match args with
  | Positional args' ->
     TPositionalArglist (List.mapi (fun i a -> check (List.nth_opt params i) a) args')
  | Named pairs ->
     let param_named (n: identifier): value_parameter option =
       List.find_opt (fun (ValueParameter (n', _)) -> equal_identifier n n') params
     in
     TNamedArglist (List.map (fun (n, v) -> (n, check (param_named n) v)) pairs)

and augment_arithmetic (ctx: expr_ctx) (op: arithmetic_operator) (lhs: aexpr) (rhs: aexpr) (asserted_ty: ty option): texpr =
  (* Augment operands. *)
  let lhs' = aug ctx lhs
  and rhs' = aug ctx rhs in
  (* Get the types.  A literal takes the type of the other operand, on
     either side: 55 + i with i an Index is an Index, as i + 55 is.  When
     the literal stood on the left its Int32 was the type of the operation,
     and the other operand was cast to it, narrowing an operand wider than
     Int32 without a word. *)
  let rhs_ty = get_type rhs' in
  let lhs_ty =
    if ((is_int_constant lhs) && not (is_int_constant rhs) && (is_int_type rhs_ty))
       || ((is_float_constant lhs) && not (is_float_constant rhs) && (is_float_type rhs_ty)) then
      rhs_ty
    else
      match asserted_ty with
      | Some (Integer _ as ty) when (is_int_constant lhs) && (is_int_constant rhs) -> ty
      | _ -> get_type lhs'
  in
  let augment_arithmetic_call _ =
    (* Because method calls don't implement the lenient type checking
       rules for arithmetic, we have to cast the arguments to their
       expected types, so that constants are allowed to be used as
       arguments. This means we have to transform a `ty` into a type
       specifier. *)
    let op_name =
      match op with
      | Add ->
         "trappingAdd"
      | Subtract ->
         "trappingSubtract"
      | Multiply ->
         "trappingMultiply"
      | Divide ->
         "trappingDivide"
    in
    let op_qname = make_qident (pervasive_module_name, make_ident op_name, make_ident op_name) in
    let args: typed_arglist = TPositionalArglist [
                                  TCast (lhs', lhs_ty);
                                  TCast (rhs', lhs_ty);
                                ]
    in
    augment_call ctx op_qname args asserted_ty
  in
  (* Are the types the same? *)
  if lhs_ty = rhs_ty then
    (* If the types are the same type, check it is a numeric type. *)
    if (is_numeric lhs_ty) then
      augment_arithmetic_call ()
    else
      Errors.arithmetic_not_numeric lhs_ty
  else
    (* If the types are different, check if at least one operator is a constant.*)
    let are_int_constants = (is_int_constant lhs) || (is_int_constant rhs)
    and are_float_constants = (is_float_constant lhs) || (is_float_constant rhs) in
    if (are_int_constants || are_float_constants) then
      (* If either operand is a constant, let it pass *)
      augment_arithmetic_call ()
    else
      Errors.arithmetic_incompatible_types ~lhs:lhs_ty ~rhs:rhs_ty

(** Negation is its own operation, not a subtraction from zero.

    Parsed as `0 - x` it inherited the type of the zero, which is Int32, so
    it was a type error for every other signed width and meant nothing at
    all for the unsigned ones.  As its own operation it means the same
    thing at every width, and where it means nothing it says so. *)
and augment_arith_negation (ctx: expr_ctx) (operand: aexpr) (asserted_ty: ty option): texpr =
  let operand' = aug ctx operand in
  let ty = get_type operand' in
  (* An instance always wins.  This rule used to decide on the operand
     type and raise before the class was resolved, so a user could write
     `instance TrappingNegation(Money)`, have it accepted, and never have
     it consulted -- a declared control that the runtime did not perform.
     The resolver is asked first; the type rule speaks only where there is
     no instance, and then it gives the reason that applies. *)
  if has_trapping_negation ctx ty then
    let op_qname = make_qident (pervasive_module_name, make_ident "trappingNegate", make_ident "trappingNegate") in
    let arg: texpr =
      (match ty with
       | Integer _ | SingleFloat | DoubleFloat ->
          (* The cast is what fixes the type of a numeric literal.  A value
             of a user type already has exactly this type, and casting
             between user types is not the same operation. *)
          TCast (operand', ty)
       | _ ->
          operand')
    in
    let args: typed_arglist = TPositionalArglist [ arg ] in
    augment_call ctx op_qname args asserted_ty
  else
    (match ty with
     | Integer (Unsigned, _) ->
        Errors.negation_of_unsigned ty
     | SingleFloat ->
        Errors.negation_not_defined ty
     | _ ->
        Errors.negation_no_instance ty)

(** Is there an instance of Hilde.Pervasive's TrappingNegation for this
    type that is visible from the module being checked?  This is the
    resolver the negation rule asks before it decides anything itself. *)
and has_trapping_negation (ctx: expr_ctx) (ty: ty): bool =
  let name: sident = make_sident pervasive_module_name (make_ident "TrappingNegation") in
  match get_decl_by_name (ctx_env ctx) name with
  | Some (TypeClass { id; _ }) ->
     (match get_instance (ctx_env ctx) (ctx_module_name ctx) ty id with
      | Some _ -> true
      | None -> false)
  | _ ->
     (* No TrappingNegation in the environment at all: only possible while
        Hilde.Pervasive itself is being built, where nothing negates. *)
     false

(* Further utilities, these have to be defined here because of `let rec and`
   bullshit. *)

(** `aug` is a shorthand for `augment_expr` with `None` as the asserted type. *)
and aug (ctx: expr_ctx) (expr: aexpr): texpr =
  augment_expr ctx None expr
