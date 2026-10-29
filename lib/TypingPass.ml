(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

open Identifier
open Span
open Common
open Type
open TypeSystem
open TypeBindings
open TypeMatch
open TypeParser
open TypeParameter
open TypeParameters
open Region
open RegionMap
open LexEnv
open Env
open EnvTypes
open EnvUtils
open Stages.AstDB
open Stages.Tast
open TastUtil
open Stages.Linked
open Util
open Reporter
open Error

module Errors = TypeErrors

type stmt_ctx = StmtCtx of module_name * env * region_map * typarams * lexenv * ty

(* Option and Either carry a failure the caller is meant to look
   at, and throwing one away in silence is what this recognises.

   The test is on the NAME and not on the universe, because the universe
   cannot tell: Option[Int32] is in the Free universe, exactly like Int32,
   which is why the discard_linear test above lets it through.

   What it does NOT catch, said here rather than discovered later: a type
   variable that happens to be instantiated to an Option.  This runs before
   monomorphisation, and inside a generic body the type is a TyVar; the
   check is on the type as WRITTEN. *)
let is_result_type (ty: ty): bool =
  match ty with
  | NamedType (name, _, _) ->
     ((mod_name_string (source_module_name name)) = "Hilde.Pervasive")
     && (let n = ident_string (original_name name) in
         (n = "Option") || (n = "Either"))
  | _ ->
     false

let update_lexenv (StmtCtx (mn, menv, rm, typarams, _, rt)) (lexenv: lexenv): stmt_ctx =
  StmtCtx (mn, menv, rm, typarams, lexenv, rt)

let update_rm (StmtCtx (mn, menv, _, typarams, lexenv, rt)) (rm: region_map): stmt_ctx =
  StmtCtx (mn, menv, rm, typarams, lexenv, rt)

(* Since the extraction pass has already happened, we can simplify the call to
   `parse_type` by passing an empty list of local type signatures. *)
let parse_typespec (env: env) (rm: region_map) (typarams: typarams) (ty: qtypespec): ty =
  parse_type env [] rm typarams ty

let augment_expr (module_name: module_name) (env: env) (rm: region_map) (typarams: typarams) (lexenv: lexenv) (asserted_ty: ty option) (expr: aexpr): texpr =
  let ctx: TypeCheckExpr.expr_ctx = TypeCheckExpr.make_ctx module_name env rm typarams lexenv in
  TypeCheckExpr.augment_expr ctx asserted_ty expr

(** Copied from TypeCheckExpr *)
let get_record_definition (env: env) (name: qident) (ty: ty): (module_name * type_vis * typarams * typed_slot list) =
  match get_decl_by_name env (qident_to_sident name) with
  | (Some (Record { mod_id; vis; typarams; slots; _ })) ->
     let mod_name: module_name = module_name_from_id env mod_id in
     (mod_name, vis, typarams, slots)
  | Some _ ->
     Errors.path_not_record ty
  | None ->
     internal_err ("No record with this name: " ^ (ident_string (original_name name)))

let stmt_kind (stmt: astmt): string =
  match stmt with
  | ASkip _ -> "skip"
  | ALet _ -> "let"
  | ADestructure _ -> "let (destructure)"
  | AAssign _ -> "assign"
  | AIf _ -> "if"
  | AWhen _ -> "if (no else)"
  | ACase _ -> "case"
  | APatternCase _ -> "case (patterns)"
  | ALetInfer _ -> "let"
  | AUnreachable _ -> "unreachable"
  | AWhile _ -> "while"
  | AFor _ -> "for"
  | ABorrow _ -> "borrow"
  | ABlock _ -> "block"
  | ADiscarding _ -> "discard"
  | AReturn _ -> "return"
  | ARaise _ -> "raise"
  | LetTmp _ -> "let"
  | AssignTmp _ -> "assign"
  | AAssignVar _ -> "assign"
  | AInitialAssign _ -> "assign"

let is_boolean = function
  | Boolean -> true
  | _ -> false

let is_compatible_with_index_type = function
  | TIntConstant _ ->
     true
  | e ->
     (get_type e) = index_type

(* Upstream defect 16.  Inside a generic function its own type
   parameters are fixed: the caller chooses them, not the body.  match_type
   binds a type variable to whatever stands opposite it, which is right for a
   call, where the variables are the callee's, and wrong where a value of the
   body meets a type written in this function -- a return, a declared let,
   an assignment.  There `return &x;' against `&[T, R]' bound R to the region
   of the borrow of x, and a reference to a local variable left the
   function.  A binding of one of the function's own parameters to anything
   but itself is refused here. *)
let same_typaram (a: type_parameter) (b: type_parameter): bool =
  (equal_identifier (typaram_name a) (typaram_name b))
  && (equal_qident (typaram_source a) (typaram_source b))

let rigid_typarams (typarams: typarams) (bindings: type_bindings): unit =
  let own = typarams_as_list typarams in
  List.iter
    (fun (tp, ty) ->
      if List.exists (same_typaram tp) own then
        match ty with
        | TyVar tv when same_typaram (tyvar_to_typaram tv) tp ->
           ()
        | _ ->
           if typaram_universe tp = RegionUniverse then
             hilde_raise (H 3094) TypeError [
                 Text "A reference made inside this function cannot be handed out as ";
                 Code (ident_string (typaram_name tp));
                 Text ".";
                 Break;
                 Code (ident_string (typaram_name tp));
                 Text " is a region parameter of the function: the caller chooses it, and it outlives the call.  The reference here has the region ";
                 Type ty;
                 Text ", which ends inside the function."
               ]
           else
             hilde_raise (H 3095) TypeError [
                 Text "The type parameter ";
                 Code (ident_string (typaram_name tp));
                 Text " would have to be ";
                 Type ty;
                 Text " here.";
                 Break;
                 Text "The caller chooses the type parameters of a function; its body cannot fix one."
               ])
    (bindings_list bindings)

type case_mode =
  | NormalCaseMode
  | ReadRefCaseMode of ty
  | WriteRefCaseMode of ty

(* The first span a statement has that is not empty, or the empty one. *)
let rec first_span (stmt: astmt): span =
  let pick (s: span) (rest: astmt list): span =
    if s <> empty_span then s
    else
      match List.find_opt (fun r -> first_span r <> empty_span) rest with
      | Some r -> first_span r
      | None -> empty_span
  in
  match stmt with
  | ASkip s | AAssign (s, _, _) | AAssignVar (s, _, _) | ADiscarding (s, _) | AReturn (s, _) -> s
  | ALet (s, _, _, _, b) | ADestructure (s, _, _, _, b) | AWhen (s, _, b) | AWhile (s, _, b) -> pick s [b]
  | AIf (s, _, a, b) -> pick s [a; b]
  | ACase (s, _, _) | APatternCase (s, _, _) -> s
  | AFor { span; body; _ } -> pick span [body]
  | ABorrow { span; body; _ } -> pick span [body]
  | ABlock (s, a, b) -> pick s [a; b]
  | _ -> empty_span

let check_var_doesnt_collide_with_decl (ctx: stmt_ctx) (name: identifier) =
  let (StmtCtx (module_name, env, _, _, _, _)) = ctx in
  let sname: sident = make_sident module_name name in
  match get_decl_by_name env sname with
  | Some _ ->
     Errors.var_collides_with_decl name
  | None ->
     ()

(* The ? operator -- three helpers, then two statement arms.

   The operator is an early return out of the enclosing function, so it is
   allowed only where that return is visible on its own line: as the whole
   right-hand side of a `let` binding, and as a whole statement.  Anywhere
   else TypeCheckExpr refuses it by name.  Why not everywhere: an expression
   in an arbitrary position is not a place a statement can be put -- the
   lifting pass turns a nested expression into a temporary whose scope would
   then be INSIDE the case branch this builds, which is a scoping bug rather
   than a restriction. *)

(* `let x: T := e?;` arrives as AInitialAssign with the rvalue wrapped in a
   Typecast, because that is how the abstraction pass reshapes a let.  This
   looks through the cast, so both shapes are recognised. *)
let question_operand (e: aexpr): (span * aexpr) option =
  let rec go (e: aexpr): (span * aexpr) option =
    match e with
    | Question (s, inner) ->
       Some (s, inner)
    | Typecast (inner, _) ->
       go inner
    | _ ->
       None
  in
  go e

(* Is this Hilde.Pervasive's Option or Either, and with which arguments? *)
let pervasive_result (ty: ty) (name: string): ty list option =
  match ty with
  | NamedType (qname, args, _) ->
     if ((mod_name_string (source_module_name qname)) = "Hilde.Pervasive")
        && ((ident_string (original_name qname)) = name) then
       Some args
     else
       None
  | _ ->
     None

(* Build the case statement the operator stands for.  `rest` is given the
   type of the success value and the name it is bound to, and returns the
   statement that uses it -- which is the statement the operator was written
   in, with the operand replaced by that name.

   The failure branch is a TReturn, so the LINEARITY of the early return
   needs no rule of its own here: LinearityCheck's TReturn branch already
   requires every linear variable to be consumed at the point of return, and
   a program that has one live gets its ordinary message about that
   variable.

   The whens are built in the order the union declares its cases, None
   before Some and Left before Right, so that nothing downstream has to
   reorder them. *)
let augment_question (ctx: stmt_ctx) (span: span) (operand: aexpr)
      (rest: ty -> identifier -> tstmt): tstmt =
  let (StmtCtx (module_name, env, rm, typarams, lexenv, rt)) = ctx in
  adorn_error_with_span span
    (fun _ ->
      let operand': texpr = augment_expr module_name env rm typarams lexenv None operand in
      let ety: ty = get_type operand' in
      let ok: identifier = fresh_ident () in
      match pervasive_result ety "Option" with
      | Some [payload] ->
         (match pervasive_result rt "Option" with
          | Some [_] ->
             TCase (span, operand',
                    [ TypedWhen (make_ident "None", [],
                                 TReturn (span, TUnionConstructor (rt, make_ident "None", [])));
                      TypedWhen (make_ident "Some",
                                 [TypedBinding { name = make_ident "value"; ty = payload; rename = ok }],
                                 rest payload ok) ],
                    CasePlain)
          | _ ->
             Errors.question_wrong_return_type ~operand:ety ~rt)
      | _ ->
         (match pervasive_result ety "Either" with
          | Some [fail_ty; payload] ->
             (match pervasive_result rt "Either" with
              | Some [rt_fail; _] ->
                 if equal_ty rt_fail fail_ty then
                   let bad: identifier = fresh_ident () in
                   TCase (span, operand',
                          [ TypedWhen (make_ident "Left",
                                       [TypedBinding { name = make_ident "left"; ty = fail_ty; rename = bad }],
                                       TReturn (span,
                                                TUnionConstructor (rt, make_ident "Left",
                                                                   [(make_ident "left", TLocalVar (bad, fail_ty))])));
                            TypedWhen (make_ident "Right",
                                       [TypedBinding { name = make_ident "right"; ty = payload; rename = ok }],
                                       rest payload ok) ],
                          CasePlain)
                 else
                   Errors.question_wrong_return_type ~operand:ety ~rt
              | _ ->
                 Errors.question_wrong_return_type ~operand:ety ~rt)
          | _ ->
             Errors.question_not_a_result ety))

let rec augment_stmt (ctx: stmt_ctx) (stmt: astmt): tstmt =
  with_frame ("Augment statement: " ^ (stmt_kind stmt))
    (fun _ ->
      let (StmtCtx (module_name, env, rm, typarams, lexenv, rt)) = ctx in
      match stmt with
      | ASkip span ->
         TSkip span
      | ALet (span, mut, name, ty, body) ->
         pi ("Name", name);
         adorn_error_with_span span
           (fun _ ->
             let _ = check_var_doesnt_collide_with_decl ctx name in
             let ty = parse_typespec env rm typarams ty in
             pt ("Type", ty);
             let plain (body: astmt): tstmt =
               let lexenv' = push_var lexenv name ty (VarLocal mut) in
               let body' = augment_stmt (update_lexenv ctx lexenv') body in
               remove_var lexenv name;
               TLet (span, mut, name, ty, body')
             in
             (* A `let` whose right-hand side is `e?` becomes a
                case, and the BINDING goes INSIDE the success branch rather
                than around the case.

                That is not tidiness.  If the binding stood outside, the
                failure branch's return would see a variable that is declared
                and not yet assigned, and for a LINEAR type the linearity
                checker refuses the program with a message about a variable
                that does not exist yet on that path: `let r: R := make(n)?;`
                with R linear would be refused with "The variable `r` is not
                consumed by the time of the return statement".  Inside the branch there is no such
                variable on the failure path, and the program compiles.

                What stays refused, and must: an UNRELATED linear value that
                is live across the operator.  The early return would lose it,
                LinearityCheck's TReturn says so, and the message names that
                variable -- which is the right one. *)
             match body with
             | ABlock (bspan, AInitialAssign (aname, _, rvalue), rest) ->
                (match question_operand rvalue with
                 | Some (qspan, operand) ->
                    augment_question ctx qspan operand
                      (fun payload bound ->
                        let value: texpr = TLocalVar (bound, payload) in
                        let _ = rigid_typarams typarams (match_type_with_value (env, module_name) ty value) in
                        let lexenv' = push_var lexenv name ty (VarLocal mut) in
                        let rest' = augment_stmt (update_lexenv ctx lexenv') rest in
                        remove_var lexenv name;
                        TLet (span, mut, name, ty,
                              TBlock (bspan, TInitialAssign (aname, value), rest')))
                 | None ->
                    plain body)
             | _ ->
                plain body)
      | LetTmp (name, value) ->
         let value = augment_expr module_name env rm typarams lexenv None value in
         let ty = get_type value in
         let _ = push_var lexenv name ty (VarLocal Mutable) in
         TLetTmp (name, ty, value)
      | AssignTmp (name, value) ->
         let value = augment_expr module_name env rm typarams lexenv None value in
         begin
           match get_var lexenv name with
           | Some (ty, _) ->
              let _ = match_type (env, module_name) ty (get_type value) in
              TAssignTmp (name, value)
           | None ->
              internal_err "Unknown temporary."
         end
      | ADestructure (span, mut, bindings, value, body) ->
         adorn_error_with_span span
           (fun _ ->
             let _ =
               List.map (fun (Stages.Ast.QBinding { rename; _ }) -> check_var_doesnt_collide_with_decl ctx rename) bindings
             in
             let value' = augment_expr module_name env rm typarams lexenv None value in
             (* Check: the value must be a public record type *)
             let rec_ty = get_type value' in
             (match rec_ty with
              | (NamedType (name, _, u)) ->
                 let (source_module, vis, record_typarams, slots) = get_record_definition env name rec_ty in
                 let orig_type = NamedType (
                                     make_qident (source_module, original_name name, original_name name),
                                     List.map (fun tp -> TyVar (typaram_to_tyvar tp)) (typarams_as_list record_typarams),
                                     u
                                   )
                 in
                 let typebindings = match_type (env, module_name) orig_type rec_ty in
                 if (vis = TypeVisPublic) || (module_name = source_module) then
                   (* Find the set of slot names and the set of binding names, and compare them *)
                   let binding_names = List.map (fun (Stages.Ast.QBinding { name; _}) -> name) bindings
                   and slot_names = List.map (fun (TypedSlot (n, _)) -> n) slots in
                   if ident_set_eq binding_names slot_names then
                     let bindings': (identifier * qtypespec * ty * identifier) list =
                       group_bindings_slots bindings slots
                     in
                     let bindings'': (identifier * ty * ty * identifier) list
                       = List.map (fun (n, ty, actual, rename) -> (n, parse_typespec env rm typarams ty, replace_variables typebindings actual, rename)) bindings'
                     in
                     let newvars: (identifier * ty * var_source) list =
                       List.map (fun (_, ty, actual, rename) ->
                           let _ = match_type (env, module_name) ty actual in
                           (rename, ty, VarLocal mut))
                         bindings''
                     in
                     let lexenv' = push_vars lexenv newvars in
                     let body' = augment_stmt (update_lexenv ctx lexenv') body in
                     remove_vars lexenv' (List.map (fun (n, _, _) -> n) newvars);
                     TDestructure (
                         span,
                         mut,
                         List.map (fun (name, _, ty, rename) -> TypedBinding { name; ty; rename; }) bindings'',
                         value',
                         body'
                       )
                   else
                     Errors.destructure_wrong_slots rec_ty
                 else
                   Errors.destructure_not_public rec_ty
              | _ ->
                 Errors.destructure_non_record rec_ty))
      | AAssign (span, lvalue, rvalue) ->
         adorn_error_with_span span
           (fun _ ->
             (* Augment both sides. *)
             let lvalue: texpr = augment_expr module_name env rm typarams lexenv None lvalue
             and rvalue: texpr = augment_expr module_name env rm typarams lexenv None rvalue in
             (* The type of the lvalue must be a read reference. *)
             let lvalue_ty: ty = get_type lvalue in
             let pointed_ty: ty = begin
                 match lvalue_ty with
                 | WriteRef (ty, _) ->
                    ty
                 | _ ->
                    err (H 6054) ("Can't assign: lvalue is not a mutable reference: " ^ (type_string lvalue_ty))
               end
             in
             (* The pointed to type and the type of the rvalue must match. *)
             let _ = rigid_typarams typarams (match_type_with_value (env, module_name) pointed_ty rvalue) in
             (* The pointed-to type must be in the free universe. *)
             let _ =
               if (type_universe pointed_ty) = FreeUniverse then
                 ()
               else
                 hilde_raise (H 4014) LinearityError [
                     Text "Cannot assign to a path that ends in a type, ";
                     Type pointed_ty;
                     Text ", not in the Free universe."
                   ]
             in
             (* Construct the assignment. *)
             TAssign (span, lvalue, rvalue))
      | AAssignVar (span, name, rvalue) ->
         adorn_error_with_span span
           (fun _ ->
             (* Augment the rvalue. *)
             let rvalue: texpr = augment_expr module_name env rm typarams lexenv None rvalue in
             (* Get the type of the lvalue. *)
             let lvalue_ty: ty = begin
                 let name: identifier = original_name name in
               match get_var lexenv name with
               | (Some (orig_ty, src)) -> begin
                   let _ =
                     match src with
                     | VarLocal Mutable ->
                        ()
                     | VarLocal Immutable ->
                        Errors.cant_assign_to_immutable_var name
                     | VarConstant ->
                        Errors.cannot_assign_to_constant name
                     | VarParam ->
                        Errors.cannot_assign_to_parameter name
                   in
                   orig_ty
                 end
               | None ->
                  Errors.unknown_name ~kind:"variable" ~name:name
               end
             in
             (* Types must match. *)
             let _ = rigid_typarams typarams (match_type_with_value (env, module_name) lvalue_ty rvalue) in
             (* Construct the assignment. *)
             TAssignVar (span, name, rvalue))
      | AInitialAssign (name, ty, rvalue) ->
         (match question_operand rvalue with
          | Some (qspan, operand) ->
             (* `let x: T := e?;`.  The declared type is checked
                against the SUCCESS type, so a wrong one is an ordinary type
                mismatch and not a message about the operator. *)
             augment_question ctx qspan operand
               (fun payload bound ->
                 let ty = parse_typespec env rm typarams ty in
                 let value: texpr = TLocalVar (bound, payload) in
                 let _ = rigid_typarams typarams (match_type_with_value (env, module_name) ty value) in
                 TInitialAssign (name, value))
          | None ->
             let rvalue: texpr = augment_expr module_name env rm typarams lexenv None rvalue in
             let ty = parse_typespec env rm typarams ty in
             let _ = rigid_typarams typarams (match_type_with_value (env, module_name) ty rvalue) in
             TInitialAssign (name, rvalue))
      | AIf (span, c, t, f) ->
         adorn_error_with_span span
           (fun _ ->
             let c' = augment_expr module_name env rm typarams lexenv None c in
             if is_boolean (get_type c') then
               TIf (span, c', augment_stmt ctx t, augment_stmt ctx f)
             else
               Errors.condition_not_boolean
                 ~kind:"if"
                 ~form:"statement"
                 ~ty:(get_type c'))
      | AWhen (span, c, t) ->
         adorn_error_with_span span
           (fun _ ->
             let c = augment_expr module_name env rm typarams lexenv None c in
             if is_boolean (get_type c) then
               TIf (span, c, augment_stmt ctx t, TSkip span)
             else
               Errors.condition_not_boolean
                 ~kind:"if"
                 ~form:"statement"
                 ~ty:(get_type c))
      | ACase (span, expr, whens) ->
         augment_case ctx span expr whens
      | APatternCase (span, expr, whens) ->
         augment_pattern_case ctx span expr whens
      | ALetInfer (span, name, value, body) ->
         (* Generated for a pattern case only. *)
         adorn_error_with_span span
           (fun _ ->
             let value' = augment_expr module_name env rm typarams lexenv None value in
             let ty = get_type value' in
             let lexenv' = push_var lexenv name ty (VarLocal Immutable) in
             let body' = augment_stmt (update_lexenv ctx lexenv') body in
             remove_var lexenv name;
             TLet (span, Immutable, name, ty,
                   TBlock (span, TInitialAssign (make_qident (module_name, name, name), value'), body')))
      | AUnreachable span ->
         TUnreachable span
      | AWhile (span, c, body) ->
         adorn_error_with_span span
           (fun _ ->
             let c' = augment_expr module_name env rm typarams lexenv None c in
             if is_boolean (get_type c') then
               TWhile (span, c', augment_stmt ctx body)
             else
               Errors.condition_not_boolean
                 ~kind:"while"
                 ~form:"statement"
                 ~ty:(get_type c'))
      | AFor { span; name; initial; final; body; } ->
         adorn_error_with_span span
           (fun _ ->
             let i' = augment_expr module_name env rm typarams lexenv None initial
             and f' = augment_expr module_name env rm typarams lexenv None final in
             if is_compatible_with_index_type i' then
               if is_compatible_with_index_type f' then
                 let lexenv' = push_var lexenv name index_type (VarLocal Immutable) in
                 let b' = augment_stmt (update_lexenv ctx lexenv') body in
                 remove_var lexenv name;
                 TFor (span, name, i', f', b')
               else
                 Errors.for_bounds_non_integral ~bound:"final" ~ty:(get_type f')
             else
               Errors.for_bounds_non_integral ~bound:"initial" ~ty:(get_type i'))
      | ABorrow { span; original; rename; region; body; mode; } ->
         adorn_error_with_span span
           (fun _ ->
             let _ = check_var_doesnt_collide_with_decl ctx rename in
             (match get_var lexenv original with
              | (Some (orig_ty, src)) ->
                 (* Check we can borrow the variable. *)
                 let _ =
                   match (src, mode) with
                   | (_, Read) ->
                      (* Anything can be borrowed immutably. *)
                      ()
                   | (VarLocal Immutable, Write) ->
                      (* Immutable variables cannot be borrowed mutably,
                         unless they hold a write reference: the name of a
                         borrow statement that borrows for writing is one,
                         and an assignment `name->slot := v' borrows it for
                         writing to write through it, as it does a parameter
                         that holds one.  What the path ends in must still
                         be Free (H4014), so no reference is overwritten. *)
                      (match orig_ty with
                       | WriteRef _ ->
                          ()
                       | _ ->
                          Errors.cannot_borrow_immutable_var_mutably original)
                   | (VarParam, Write) ->
                      (* Parameters cannot be borrowed mutably, unless they're mutable references. *)
                      let is_mut = begin
                        match orig_ty with
                        | WriteRef _ -> true
                        | _ -> false
                      end
                      in
                      if is_mut then
                        ()
                      else
                        Errors.cannot_borrow_param_mutably original orig_ty
                   | _ ->
                      (* And anything else is fine. *)
                      ()
                 in
                 let region_obj = fresh_region () in
                 name_region region_obj region;
                 let refty =
                   (match mode with
                    | Read ->
                       (* A read borrow of a write reference reads
                          what it points to.  The write reference is borrowed
                          for the scope -- the linearity check marks it -- so
                          nothing writes through it while this one lives. *)
                       (match orig_ty with
                        | WriteRef (pointed_ty, _) ->
                           ReadRef (pointed_ty, RegionTy region_obj)
                        | _ ->
                           ReadRef (orig_ty, RegionTy region_obj))
                    | PathRead ->
                       ReadRef (orig_ty, RegionTy region_obj)
                    | Write ->
                       WriteRef (orig_ty, RegionTy region_obj)
                    | Reborrow ->
                       let pointed_ty = begin
                           match orig_ty with
                           | WriteRef (pointed_ty, _) ->
                              pointed_ty
                           | _ ->
                              err (H 6055) ("Cannot reborrow something that is not a mutable reference: " ^ (type_string orig_ty))
                         end
                       in
                       WriteRef (pointed_ty, RegionTy region_obj))
                 in
                 let lexenv' = push_var lexenv rename refty (VarLocal Immutable) in
                 let rm' = add_region rm region region_obj in
                 let ctx' = update_lexenv ctx lexenv' in
                 let ctx''= update_rm ctx' rm' in
                 let body = augment_stmt ctx'' body in
                 remove_var lexenv rename;
                 TBorrow {
                     span=span;
                     original=original;
                     rename=rename;
                     region=region;
                     orig_type=orig_ty;
                     ref_type=refty;
                     body=body;
                     mode=mode
                   }
              | None ->
                 (* The borrow a path is read through has no span of its
                    own; the statement inside it has one. *)
                 adorn_error_with_span (first_span body)
                   (fun _ ->
                     match get_decl_by_name env (make_sident module_name original) with
                     | Some (Constant _) -> Errors.path_of_constant original
                     | _ -> Errors.unknown_name ~kind:"variable" ~name:original)))
      | ABlock (span, LetTmp (tmp, value), (AAssignVar (_, name, Temporary tmp') as assign))
           when equal_identifier tmp tmp' ->
         (* The value of an assignment is lifted into a temporary.  The
            temporary takes the type of the variable it is assigned to, as
            the value of a let takes the declared type: x := 1 with x a
            Nat64 assigns a Nat64, and Right(right => v) a value of the
            variable's Either. *)
         adorn_error_with_span span
           (fun _ ->
             let target: ty option =
               match get_var lexenv (original_name name) with
               | Some (ty, _) -> Some ty
               | None -> None
             in
             let a = typed_let_tmp ctx tmp value target in
             let b = augment_stmt ctx assign in
             TBlock (span, a, b))
      | ABlock (span, LetTmp (tmp, value), (AAssign (_, lvalue, Temporary tmp') as assign))
           when equal_identifier tmp tmp' ->
         (* The same for a path: the temporary takes the type the path
            points to. *)
         adorn_error_with_span span
           (fun _ ->
             let target: ty option =
               match get_type (augment_expr module_name env rm typarams lexenv None lvalue) with
               | WriteRef (ty, _) -> Some ty
               | _ -> None
             in
             let a = typed_let_tmp ctx tmp value target in
             let b = augment_stmt ctx assign in
             TBlock (span, a, b))
      | ABlock (span, f, r) ->
         (* An error that has no span of its own gets the block's: the
            blocks LiftControlPass makes around a lifted temporary carry
            the span of their statement.  A block with the empty
            span leaves an error as it is. *)
         adorn_error_with_span span
           (fun _ ->
             let a = augment_stmt ctx f in
             let b = augment_stmt ctx r in
             TBlock (span, a, b))
      | ADiscarding (span, e) ->
         adorn_error_with_span span
           (fun _ ->
             let discard (ty: ty) (value: texpr): tstmt =
               let u = type_universe ty in
               if ((u = LinearUniverse) || (u = TypeUniverse)) then
                 Errors.discard_linear u
               else if is_result_type ty then
                 (* Before this line a call whose Option or Either
                    result was thrown away compiled in silence. *)
                 Errors.discard_result ty
               else
                 TDiscarding (span, value)
             in
             match question_operand e with
             | Some (qspan, operand) ->
                (* `e?;`.  The failure is propagated; what is left
                   is the SUCCESS value, and the discard rules above apply to
                   that -- so `f()?;` where f succeeds with an Option is
                   refused in its turn. *)
                augment_question ctx qspan operand
                  (fun payload bound -> discard payload (TLocalVar (bound, payload)))
             | None ->
                let e' = augment_expr module_name env rm typarams lexenv None e in
                ps ("Expression", show_texpr e');
                discard (get_type e') e')
      | AReturn (span, e) ->
         adorn_error_with_span span
           (fun _ ->
             (match rt with
              | Never -> NeverCheck.Errors.return_in_never ()
              | _ -> ());
             let e' = augment_expr module_name env rm typarams lexenv (Some rt) e in
             pt ("Type", get_type e');
             let _ = rigid_typarams typarams (match_type_with_value (env, module_name) rt e') in
             TReturn (span, e'))
      (* The raise names its kind; the clause of the function being typed
         must hold it.  The kind stands in the statement, so the check
         needs no callee and no message text: it compares the name the
         programme wrote with the names the signature wrote. *)
      | ARaise (span, kind) ->
         adorn_error_with_span span
           (fun _ ->
             let allowed = Option.value !Common.current_raises ~default:[] in
             if not (List.mem kind allowed) then
               Errors.raise_not_named ~kind ~allowed;
             TRaise (span, kind)))

(* The temporary of an assignment, typed with the type of its target when
   that is known: the value is checked with the target as the asserted type,
   and a literal is cast to it, as a let casts one. *)
and typed_let_tmp (ctx: stmt_ctx) (tmp: identifier) (value: aexpr) (target: ty option): tstmt =
  let (StmtCtx (module_name, env, rm, typarams, lexenv, _)) = ctx in
  let value = augment_expr module_name env rm typarams lexenv target value in
  let value =
    match (target, value) with
    | (Some (Integer _ as ty), TIntConstant _) ->
       let _ = match_type_with_value (env, module_name) ty value in
       TCast (value, ty)
    | (Some ((SingleFloat | DoubleFloat) as ty), TFloatConstant _) ->
       TCast (value, ty)
    | _ ->
       value
  in
  let ty = get_type value in
  let _ = push_var lexenv tmp ty (VarLocal Mutable) in
  TLetTmp (tmp, ty, value)

and augment_case (ctx: stmt_ctx) (span: span) (expr: aexpr) (whens: abstract_when list): tstmt =
  let (StmtCtx (module_name, env, rm, typarams, lexenv, _)) = ctx in
  (* Type checking a case statement:

     1. Ensure the value is of a union type (or reference to a union).
     2. Ensure the union type is public or it is defined in this module.
     3. Ensure the set of case names in the case statement equals the set of cases in the union definition.
     4. Iterate over the cases, and ensure the bindings are correct.
   *)
  adorn_error_with_span span
    (fun _ ->
      let expr' = augment_expr module_name env rm typarams lexenv None expr in
      let ty = get_type expr' in
      let ty, mode =
        (match ty with
         | NamedType _ ->
            (ty, NormalCaseMode)
         | ReadRef (ty, r) ->
            (ty, ReadRefCaseMode r)
         | WriteRef (ty, r) ->
            (ty, WriteRefCaseMode r)
         | _ ->
            hilde_raise (H 3065) TypeError [
                Text "The type for the expression in a case statement must be a union or a reference to a union, but I got ";
                Type ty
        ])
      in
      let case_ref: case_ref =
        (match mode with
         | NormalCaseMode -> CasePlain
         | ReadRefCaseMode _ -> CaseRef
         | WriteRefCaseMode _ -> CaseRef)
      in
      pt ("Case type", ty);
      let (union_ty, cases) = get_union_type_definition module_name env ty in
      let typebindings = match_type (env, module_name) union_ty ty in
      let case_names = List.map (fun (TypedCase (n, _)) -> n) (List.map union_case_to_typed_case cases) in
      let when_names = List.map abstract_when_name whens in
      if ident_set_eq case_names when_names then
        (* Group the cases and whens *)
        let whens' = group_cases_whens cases whens in
        let whens'' = List.map (fun (c, w) -> augment_when ctx typebindings w c mode) whens' in
        TCase (span, expr', whens'', case_ref)
      else
        Errors.case_non_exhaustive ())

and get_union_type_definition (importing_module: module_name) (env: env) (ty: ty): (ty * decl list) =
  let name: qident = (match ty with
                      | NamedType (n, _, _) ->
                         n
                      | _ ->
                         Errors.case_non_union ty) in
  match get_decl_by_name env (qident_to_sident name) with
  | Some (Union { id; vis; name; mod_id; typarams; universe; _ }) ->
     let module_name = module_name_from_id env mod_id in
     if (vis = TypeVisPublic) || (importing_module = module_name) then
       let n = make_qident (module_name, name, name)
       and args = List.map (fun tp -> TyVar (typaram_to_tyvar tp)) (typarams_as_list typarams)
       in
       let ty = NamedType (n, args, universe)
       and cases = get_union_cases env id in
       (ty, cases)
     else
       Errors.case_non_public ()
  | _ ->
     Errors.case_non_union ty

and group_cases_whens (cases: decl list) (whens: abstract_when list): (typed_case * abstract_when) list =
  List.map (fun (TypedCase (n, s)) -> (TypedCase (n, s), List.find (fun w -> n = abstract_when_name w) whens))
    (List.map union_case_to_typed_case cases)

and abstract_when_name (w: abstract_when): identifier =
  match w with
  | AbstractWhen (n, _, _) -> n
  | AbstractWhenSlots (n, _, _) -> n

(* A pattern case.  The patterns are typed and checked
   (lib/PatternCase.ml), and the statement is replaced by the ordinary
   statements PatternCase.generate writes, which are then checked here as
   any others are. *)
and augment_pattern_case (ctx: stmt_ctx) (span: span) (expr: aexpr) (whens: pattern_when list): tstmt =
  let (StmtCtx (module_name, env, rm, typarams, lexenv, _)) = ctx in
  adorn_error_with_span span
    (fun _ ->
      let scrutinee: identifier =
        (match expr with
         | Temporary t -> t
         | _ -> internal_err "The value of a pattern case is lifted into a temporary.")
      in
      let expr' = augment_expr module_name env rm typarams lexenv None expr in
      let ty = get_type expr' in
      let lk: PatternCase.lookup = { PatternCase.union_of = pattern_union_of module_name env } in
      PatternCase.check_scrutinee lk ty;
      let typed =
        List.map (fun (PatternWhen (wspan, pats, body)) ->
            adorn_error_with_span wspan
              (fun _ ->
                let alts =
                  List.map (fun p ->
                      let (tp, bs) = PatternCase.type_pattern lk true ty p in
                      (PatternCase.pattern_span p, tp, bs))
                    pats
                in
                PatternCase.check_alternatives alts;
                (alts, body)))
          whens
      in
      PatternCase.check_case lk ty
        (List.map (fun (alts, _) -> List.map (fun (s, tp, _) -> (s, tp)) alts) typed);
      match PatternCase.switch_labels ty (List.map (fun (alts, _) -> List.map (fun (_, tp, _) -> tp) alts) typed) with
      | Some labels ->
         (* A switch: each when but the last is an arm with its body typed
            once, the last is the default and binds its variable, if it has
            one, to the value. *)
         let rec split (l: 'a list): 'a list * 'a =
           match l with
           | [x] -> ([], x)
           | x :: rest -> let (init, last) = split rest in (x :: init, last)
           | [] -> internal_err "A switch without whens."
         in
         let (arm_whens, (last_alts, last_body)) = split typed in
         let arms =
           List.map2 (fun ls (_, body) -> (List.map Z.to_string ls, augment_stmt ctx body))
             labels arm_whens
         in
         let bound =
           List.find_map (fun (_, tp, _) ->
               match tp with
               | PatternCase.TAny (Some name) -> Some name
               | _ -> None)
             last_alts
         in
         let other =
           match bound with
           | Some name -> augment_stmt ctx (ALetInfer (span, name, Temporary scrutinee, last_body))
           | None -> augment_stmt ctx last_body
         in
         TSwitch (span, expr', arms, other)
      | None ->
         let clauses =
           List.concat_map (fun (alts, body) ->
               List.mapi (fun i (_, tp, _) ->
                   (tp, if i = 0 then body else PatternCase.refresh_temporaries body))
                 alts)
             typed
         in
         augment_stmt ctx (PatternCase.generate module_name lk span ty scrutinee clauses))

(* The variants of a union, each with its slots and their types, the type
   arguments of [ty] applied; None when [ty] is not a union. *)
and pattern_union_of (module_name: module_name) (env: env) (ty: ty): (identifier * (identifier * ty) list) list option =
  match ty with
  | NamedType (n, _, _) ->
     (match get_decl_by_name env (qident_to_sident n) with
      | Some (Union _) ->
         let (union_ty, cases) = get_union_type_definition module_name env ty in
         let typebindings = match_type (env, module_name) union_ty ty in
         (* The environment lists the newest declaration first; the ids
            count up as the union is read, so sorting by them gives the
            order the union declares its variants in -- the order a message
            lists them in and a missing one is chosen from.  Unsorted, a
            message lists them in an order the union does not have. *)
         let case_id (d: decl): int =
           match d with
           | UnionCase { id = Id.DeclId n; _ } -> n
           | _ -> internal_err "A union case that is not a UnionCase."
         in
         let cases = List.sort (fun a b -> compare (case_id a) (case_id b)) cases in
         Some (List.map (fun (TypedCase (cname, slots)) ->
                   (cname, List.map (fun (TypedSlot (sname, sty)) -> (sname, replace_variables typebindings sty)) slots))
                 (List.map union_case_to_typed_case cases))
      | _ ->
         None)
  | _ ->
     None

and group_bindings_slots (bindings: qbinding list) (slots: typed_slot list): (identifier * qtypespec * ty * identifier) list =
  let f (binding: qbinding): (identifier * qtypespec * ty * identifier) =
    let Stages.Ast.QBinding { name; ty; rename; } = binding in
    let (TypedSlot (_, ty')) = List.find (fun (TypedSlot (n', _)) -> equal_identifier name n') slots in
    (name, ty, ty', rename)
  in
  List.map f bindings

and augment_when (ctx: stmt_ctx) (typebindings: type_bindings) (w: abstract_when) (c: typed_case) (mode: case_mode): typed_when =
  match w with
  | AbstractWhen (name, bindings, body) ->
     augment_named_when ctx typebindings name bindings body c mode
  | AbstractWhenSlots (name, pairs, body) ->
     (* Generated for a pattern case.  Every slot is
        bound, under the given name, with the slot's own type -- a
        reference to it when the case is over a reference. *)
     with_frame "Augment generated when"
       (fun _ ->
         let (StmtCtx (_, _, _, _, lexenv, _)) = ctx in
         let (TypedCase (_, slots)) = c in
         let typed =
           List.map (fun (TypedSlot (sname, sty)) ->
               match List.find_opt (fun (s, _) -> equal_identifier s sname) pairs with
               | Some (_, rename) -> (sname, rename, replace_variables typebindings sty)
               | None -> internal_err "A generated when leaves a slot unbound.")
             slots
         in
         let newvars =
           List.map (fun (_, rename, ty) ->
               let ty' =
                 (match mode with
                  | NormalCaseMode -> ty
                  | ReadRefCaseMode r -> ReadRef (ty, r)
                  | WriteRefCaseMode r -> WriteRef (ty, r))
               in
               (rename, ty', VarLocal Immutable))
             typed
         in
         let lexenv' = push_vars lexenv newvars in
         let body' = augment_stmt (update_lexenv ctx lexenv') body in
         remove_vars lexenv (List.map (fun (n, _, _) -> n) newvars);
         TypedWhen (name, List.map (fun (sname, rename, ty) -> TypedBinding { name = sname; ty; rename }) typed, body'))

and augment_named_when (ctx: stmt_ctx) (typebindings: type_bindings) (name: identifier) (bindings: qbinding list) (body: astmt) (c: typed_case) (mode: case_mode): typed_when =
  with_frame "Augment when"
    (fun _ ->
      let (StmtCtx (_, menv, rm, typarams, lexenv, _)) = ctx in
      let (TypedCase (_, slots)) = c in
      pi ("Case name", name);
      (* Check the set of binding names is the same as the set of slots *)
      let binding_names = List.map (fun (Stages.Ast.QBinding { name; _ }) -> name) bindings
      and slot_names = List.map (fun (TypedSlot (n, _)) -> n) slots in
      if ident_set_eq binding_names slot_names then
        (* Check the type of each binding matches the type of the slot *)
        let bindings' = group_bindings_slots bindings slots in
        let bindings'' = List.map (fun (n, ty, actual, rename) -> (n, parse_typespec menv rm typarams ty, replace_variables typebindings actual, rename)) bindings' in
        let newvars = List.map (fun (_, user_ty, decl_ty, rename) ->
                          (* Depending on what 'mode' of case statement this is,
                             we may have to modify the slot type. If we're just
                             accessing a union by value, we don't have to do
                             anything, but if we're accessing a union by
                             reference, we don't have access to the slot
                             _values_, we instead get _references_ to those
                             values. Just like when doing `val->x` with `val`
                             having a reference-to-record type gives us a
                             reference to the field `x`, case statements on
                             references give us references to their interior
                             values. *)
                          let decl_ty =
                            (match mode with
                             | NormalCaseMode ->
                                decl_ty
                             | ReadRefCaseMode r ->
                                ReadRef (decl_ty, r)
                             | WriteRefCaseMode r ->
                                WriteRef (decl_ty, r))
                          in
                          if equal_ty decl_ty user_ty then
                            let _ = pi ("Binding name", rename)
                            in
                            pt ("Binding type",  decl_ty);
                            (rename, decl_ty, VarLocal Immutable)
                          else
                            Errors.slot_wrong_type
                              ~name:rename
                              ~expected:decl_ty
                              ~actual:user_ty)
                        bindings'' in
        let lexenv' = push_vars lexenv newvars in
        let body' = augment_stmt (update_lexenv ctx lexenv') body in
        remove_vars lexenv (List.map (fun (n, _, _) -> n) newvars);
        TypedWhen (name, List.map (fun (name, _, ty, rename) -> TypedBinding { name; ty; rename}) bindings'', body')
      else
        Errors.case_wrong_slots (List.map ident_string binding_names, List.map ident_string slot_names))

let rec validate_constant_expression (expr: texpr): unit =
  if is_constant expr then
    ()
  else
    Errors.expression_not_constant ()

and is_constant = function
  | TNilConstant ->
     true
  | TBoolConstant _ ->
     true
  | TIntConstant _ ->
     true
  | TFloatConstant _ ->
     true
  | TStringConstant _ ->
     true
  | TConstVar _ ->
     true
  | TParamVar _ ->
     false
  | TLocalVar _ ->
     false
  | TTemporary _ ->
     false
  | TFunVar _ ->
     true
  | TFuncall _ ->
     false
  | TMethodCall _ ->
     false
  | TVarMethodCall _ ->
     false
  | TFptrCall _ ->
     false
  | TCast _ ->
     true
  | TComparison (_, lhs, rhs) ->
     (is_constant lhs) && (is_constant rhs)
  | TConjunction (lhs, rhs) ->
     (is_constant lhs) && (is_constant rhs)
  | TDisjunction (lhs, rhs) ->
     (is_constant lhs) && (is_constant rhs)
  | TNegation e ->
     is_constant e
  | TIfExpression (c, t, f) ->
     (is_constant c) && (is_constant t) && (is_constant f)
  | TRecordConstructor (_, values) ->
     List.for_all (fun (_, v) -> is_constant v) values
  | TUnionConstructor (_, _, values) ->
     List.for_all (fun (_, v) -> is_constant v) values
  | TEmbed _ ->
     true
  | TDeref _ ->
     false
  | TSizeOf _ ->
     true
  | TSlotAccessor _ ->
     true
  | TPointerSlotAccessor _ ->
     true
  | TArrayIndex (_, idx, _) ->
     is_constant idx
  | TSpanIndex (_, idx, _) ->
     is_constant idx

let rec augment_decl (module_name: module_name) (kind: module_kind) (env: env) (decl: linked_definition): typed_decl =
  with_frame "Augment declaration"
    (fun _ ->
      let rm = empty_region_map in
      match decl with
      | LConstant (decl_id, vis, name, ty, expr, doc) ->
         ps ("Kind", "Constant");
         let expr' = augment_expr module_name env rm empty_typarams (empty_lexenv ()) (Some ty) expr in
         let _ = match_type_with_value (env, module_name) ty expr' in
         let _ = validate_constant_expression expr' in
         TConstant (decl_id, vis, name, ty, expr', doc)
      | LRecord (decl_id, vis, name, typarams, universe, slots, doc) ->
         ps ("Kind", "Record");
         TRecord (decl_id, vis, name, typarams, universe, slots, doc)
      | LUnion (decl_id, vis, name, typarams, universe, cases, doc) ->
         ps ("Kind", "Union");
         TUnion (decl_id, vis, name, typarams, universe, cases, doc)
      | LFunction (decl_id, vis, name, typarams, params, rt, body, doc, raises, pragmas) ->
         ps ("Kind", "Function");
         pi ("Name", name);
         let ctx = StmtCtx (module_name, env, rm, typarams, (lexenv_from_params params), rt) in
         (* The kinds this body may end with, from its clause; a
            foreign function has no body to check. *)
         let saved_raises = !Common.current_raises in
         let () = Common.current_raises :=
             (match pragmas with
              | [ForeignImportPragma _] -> None
              | _ -> Some raises)
         in
         let _ =
           List.map (fun (ValueParameter (name, _)) -> check_var_doesnt_collide_with_decl ctx name) params
         in
         (match pragmas with
          | [ForeignImportPragma s] ->
             if typarams_size typarams = 0 then
               if kind = UnsafeModule then
                 (match rt with
                  | Boolean ->
                     Errors.foreign_bool_result ()
                  | _ ->
                     TForeignFunction (decl_id, vis, name, params, rt, s, doc))
               else
                 Errors.foreign_in_safe_module ()
             else
               Errors.foreign_type_parameters ()
          | [ForeignExportPragma _] ->
             let body' = augment_stmt ctx body in
             TFunction (decl_id, vis, name, typarams, params, rt, body', doc, raises)
          | [] ->
             let body' = augment_stmt ctx body in
             TFunction (decl_id, vis, name, typarams, params, rt, body', doc, raises)
          | _ ->
             Errors.fun_invalid_pragmas ())
         |> fun decl -> Common.current_raises := saved_raises; decl
      | LTypeclass (decl_id, vis, name, typaram, methods, doc) ->
         ps ("Kind", "Typeclass");
         TTypeClass (decl_id, vis, name, typaram, List.map (augment_method_decl env rm typaram) methods, doc)
      | LInstance (decl_id, vis, name, typarams, arg, methods, doc) ->
         ps ("Kind", "Instance");
         (* TODO: the universe of the type parameter matches the universe of the type argument *)
         (* TODO: Check the methods in the instance match the methods in the class *)
         let method_raises (LMethodDef (_, name, _, _, _, _)): string list =
           match get_decl_by_id env decl_id with
           | Some (Instance { typeclass_id; _ }) ->
              (match get_method_from_typeclass_id_and_name env typeclass_id name with
               | Some (TypeClassMethod { raises; _ }) -> raises
               | _ -> [])
           | _ -> []
         in
         TInstance (decl_id, vis, name, typarams, arg,
                    List.map (fun m -> augment_method_def module_name env rm typarams (method_raises m) m) methods, doc))

and lexenv_from_params (params: value_parameter list): lexenv =
  match params with
  | (ValueParameter (n, t))::rest ->
     push_var (lexenv_from_params rest) n t VarParam
  | [] ->
     empty_lexenv ()

(* A method must name the parameter of its class in a parameter or in its
   result: a call finds its instance through that type. *)
and augment_method_decl _ _ typaram (LMethodDecl (decl_id, name, params, rt, _, _)) =
  let mentions (ty: ty): bool =
    TypeVarSet.TypeVarSet.exists
      (fun (TypeVariable (n, _, _, _)) -> equal_identifier n (typaram_name typaram))
      (type_variables ty)
  in
  if (mentions rt) || (List.exists (fun (ValueParameter (_, ty)) -> mentions ty) params) then
    TypedMethodDecl (decl_id, name, params, rt)
  else
    Errors.method_without_class_parameter name (typaram_name typaram)

(* An instance method is typed like a function, its kinds from the
   typeclass's declaration of the method; every instance implements
   the same signature and inherits the clause. *)
and augment_method_def module_name menv rm typarams method_raises (LMethodDef (ins_meth_id, name, params, rt, _, body)) =
  let ctx = StmtCtx (module_name, menv, rm, typarams, (lexenv_from_params params), rt) in
  let _ =
    List.map (fun (ValueParameter (name, _)) -> check_var_doesnt_collide_with_decl ctx name) params
  in
  let saved_raises = !Common.current_raises in
  let () = Common.current_raises := Some method_raises in
  let body' = augment_stmt ctx body in
  let () = Common.current_raises := saved_raises in
  TypedMethodDef (ins_meth_id, name, params, rt, body')

let augment_module menv (LinkedModule { name; decls; kind; _ }) =
  with_frame "Typing pass"
    (fun _ ->
      let decls' = List.map (augment_decl name kind menv) decls in
      TypedModule (name, decls'))
