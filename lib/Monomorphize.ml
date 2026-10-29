(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

open Identifier
open Env
open EnvTypes
open EnvUtils
open Type
open TypeStripping
open MonoType
open MonoTypeBindings
open TypeBindings
open TypeReplace
open TypeParameter
open TypeParameters
open TypeMatch
open Stages.Tast
open Stages.Mtast
open Stages.Linked
open Id
open Reporter
open Region
open Error

(* The argument a task is started with must not hold a borrow.

   A task can run after the statement that started it has ended -- until its
   scope closes -- and a reference in its argument would then point at
   whatever the borrow was of, which may already be gone.  The type system
   cannot say "this argument outlives the borrow" at `spawn', because
   nothing ties a Scope to a region.  So the argument type is refused
   outright when it holds a reference or a span, at any depth of records
   and unions, and the check is made HERE, on the instantiated type, so that
   a generic caller cannot pass one through a type variable.

   This names one function of one module on purpose: it is the one place in
   the language where a value can outlive the statement it was handed over
   in.  Raw pointers are not refused: they exist only in unsafe modules,
   whose marking is the whole of their guarantee. *)
let rec check_task_argument (env: env) (decl_id: decl_id) (pairs: (type_parameter * ty) list): unit =
  match get_decl_by_id env decl_id with
  | Some (Function { mod_id; name; _ }) ->
     if (mod_name_string (module_name_from_id env mod_id) = "Standard.Task")
        && (ident_string name = "spawn") then
       List.iter
         (fun (tp, ty) ->
           if (ident_string (typaram_name tp) = "A") && (type_holds_reference env [] ty) then
             (* The type is not printed: at this stage it carries the
                compiler's internal region numbers, which say nothing to a
                reader and change with every unrelated edit. *)
             hilde_raise (H 3002) TypeError [
                 Text "The argument of a task holds a reference or a span.";
                 Break;
                 Text "A task can outlive the borrow the reference comes from, so what is handed to ";
                 Code "Standard.Task.spawn";
                 Text " must own everything it points at.  Move the value in, or copy what the task needs."
               ]
           else if (ident_string (typaram_name tp) = "A") && (type_holds_lending env [] ty) then
             (* A lending scope holds no reference, so
                the check above lets it pass; but a task that held one
                could keep it open after the borrow it lends from has
                ended.  Made here, on the instantiated type, so that a
                generic caller cannot pass one through a type variable;
                spawnLending refuses it earlier, in the type checker. *)
             hilde_raise (H 3070) TypeError [
                 Text "The argument of a task holds a lending scope.";
                 Break;
                 Text "A task that held the scope could keep it open after the borrow it lends from has ended.  Close the scope where it was opened."
               ]
           else
             ())
         pairs
     else
       ()
  | _ ->
     ()

and type_holds_reference (env: env) (seen: string list) (ty: ty): bool =
  match ty with
  | ReadRef _ | WriteRef _ | Span _ | SpanMut _ ->
     true
  | NamedType (name, args, _) ->
     if List.exists (type_holds_reference env seen) args then
       true
     else
       let key: string = qident_debug_name name in
       if List.mem key seen then
         false
       else
         let seen' = key :: seen in
         let slot_holds (TypedSlot (_, t)) = type_holds_reference env seen' t in
         (match get_decl_by_name env (qident_to_sident name) with
          | Some (Record { slots; _ }) ->
             List.exists slot_holds slots
          | Some (Union { id; _ }) ->
             List.exists
               (fun c ->
                 match c with
                 | UnionCase { slots; _ } -> List.exists slot_holds slots
                 | _ -> false)
               (get_union_cases env id)
          | _ ->
             false)
  | _ ->
     false

and type_holds_lending (env: env) (seen: string list) (ty: ty): bool =
  match ty with
  | ReadRef (t, _) | WriteRef (t, _) | Span (t, _) | SpanMut (t, _) | Address t | Pointer t ->
     type_holds_lending env seen t
  | NamedType (name, args, _) ->
     if (mod_name_string (source_module_name name) = "Standard.Task")
        && (ident_string (original_name name) = "Lending") then
       true
     else if List.exists (type_holds_lending env seen) args then
       true
     else
       let key: string = qident_debug_name name in
       if List.mem key seen then
         false
       else
         let seen' = key :: seen in
         let slot_holds (TypedSlot (_, t)) = type_holds_lending env seen' t in
         (match get_decl_by_name env (qident_to_sident name) with
          | Some (Record { slots; _ }) ->
             List.exists slot_holds slots
          | Some (Union { id; _ }) ->
             List.exists
               (fun c ->
                 match c with
                 | UnionCase { slots; _ } -> List.exists slot_holds slots
                 | _ -> false)
               (get_union_cases env id)
          | _ ->
             false)
  | _ ->
     false


let make_substs2 (bindings: type_bindings) (typarams: typarams): type_bindings =
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

(* Monomorphize type specifiers *)

let rec monomorphize_ty (env: env) (ty: stripped_ty): (mono_ty * env) =
  match ty with
  | SUnit ->
     (MonoUnit, env)
  | SNever ->
     (MonoNever, env)
  | SBoolean ->
     (MonoBoolean, env)
  | SInteger (s, w) ->
     (MonoInteger (s, w), env)
  | SSingleFloat ->
     (MonoSingleFloat, env)
  | SDoubleFloat ->
     (MonoDoubleFloat, env)
  (* A region that stands as a TYPE ARGUMENT -- the `R' of `Lending[R]',
     of `Job[R]' -- is erased as well, for the reason given below for the
     region of a reference.  Without it the same record is two monomorphs,
     `Lending[rho]' in the caller and `Lending[Static]' in the generic
     function that returns it (the region parameters of a generic function
     all become Static, make_substs2),
     and the C compiler refuses the output: "passing argument 1 ... from
     incompatible pointer type".  Upstream has the same line,
     `upstream:lib/Monomorphize.ml:56-57'. *)
  | SRegionTy _ ->
     (MonoRegionTy static_region, env)
  (* The region of a reference is ERASED here, to one
     canonical value, before the type can become part of a monomorph key.

     Without this, `Option[&![Cell, R]]` at a call site and the same type
     inside the generic function that returns it are two different keys --
     one carries the borrow's own region, the other the region the
     function's own `R` collapses to -- and the compiler emits two structs
     for one type.  The type checker accepts the programme and the C
     compiler refuses the output, which is the worst shape a defect can
     have.

     It is sound because a region has no run-time representation: of the
     sixteen places outside this file and
     MonoType.ml that match on a mono reference, ZERO bind the region to
     anything but `_` -- lib/CodeGen.ml renders `&[T, R]` and `&![T, R]`
     as `T*` and never looks at the second argument.

     What is lost is that `mono_to_ty` now maps a reference back with the
     static region rather than the original one.  Its single caller is
     `make_bindings` below, which re-instantiates a generic body AFTER the
     type checker has run and has already decided every region question. *)
  | SReadRef (ty, _) ->
     let (ty, env) = monomorphize_ty env ty in
     (MonoReadRef (ty, MonoRegionTy static_region), env)
  | SWriteRef (ty, _) ->
     let (ty, env) = monomorphize_ty env ty in
     (MonoWriteRef (ty, MonoRegionTy static_region), env)
  | SSpan (ty, _) ->
     let (ty, env) = monomorphize_ty env ty in
     (MonoSpan (ty, MonoRegionTy static_region), env)
  | SSpanMut (ty, _) ->
     let (ty, env) = monomorphize_ty env ty in
     (MonoSpanMut (ty, MonoRegionTy static_region), env)
  | SAddress ty ->
     let (ty, env) = monomorphize_ty env ty in
     (MonoAddress ty, env)
  | SPointer ty ->
     let (ty, env) = monomorphize_ty env ty in
     (MonoPointer ty, env)
  | SNamedType (name, args) ->
     let (args, env) = monomorphize_ty_list env args in
     (match get_decl_by_name env (qident_to_sident name) with
      | Some decl ->
         (match decl with
          | Record { id; typarams; _ } ->
             let typarams: type_parameter list = typarams_as_list typarams in
             let pairs: (type_parameter * mono_ty) list = List.map2 (fun tp mt -> (tp, mt)) typarams args in
             let bindings: mono_type_bindings = mono_bindings_from_list pairs in
             let (env, mono_id) = add_or_get_record_monomorph env id bindings in
             (MonoNamedType mono_id, env)
          | Union { id; typarams; _ } ->
             let typarams: type_parameter list = typarams_as_list typarams in
             let pairs: (type_parameter * mono_ty) list = List.map2 (fun tp mt -> (tp, mt)) typarams args in
             let bindings: mono_type_bindings = mono_bindings_from_list pairs in
             let (env, mono_id) = add_or_get_union_monomorph env id bindings in
             (MonoNamedType mono_id, env)
          | _ ->
             internal_err ("named type `" ^ (qident_debug_name name) ^ "`points to something that isn't a type"))
      | None ->
         internal_err ("Couldn't get declaration for named type `" ^ (qident_debug_name name) ^ "`."))
  | SFnPtr (args, rt) ->
     let (args, env) = monomorphize_ty_list env args in
     let (rt, env) = monomorphize_ty env rt in
     (MonoFnPtr (args, rt), env)
  | SMonoTy id ->
     (MonoNamedType id, env)
  | SRegionTyVar (name, source) ->
     (MonoRegionTyVar (name, source), env)

and monomorphize_ty_list (env: env) (tys: stripped_ty list): (mono_ty list * env) =
  match tys with
  | first::rest ->
     let (first, env) = monomorphize_ty env first in
     let (rest, env) = monomorphize_ty_list env rest in
     (first :: rest, env)
  | [] ->
     ([], env)

let strip_and_mono (env: env) (ty: ty): (mono_ty * env) =
  let ty = strip_type ty in
  monomorphize_ty env ty

let strip_and_mono_list (env: env) (tys: ty list): (mono_ty list * env) =
  let tys = List.map strip_type tys in
  monomorphize_ty_list env tys

(* Monomorphize expressions *)

(* Hilde: the named type a monomorph id stands for.

   A generic function with a typeclass constraint calls a method through a
   type variable (TVarMethodCall), and the instance is chosen only here,
   after the variable has been replaced by the monomorphized argument.  For
   a named type that replacement is `MonoTy id' (mono_to_ty, "SPECIAL
   CASE"), and get_instance -> match_type refuses a MonoTy (H6046, caught
   there as "does not match").  So only a built-in type could be
   dispatched on: a sort of Strings, or of a record with an instance of its
   own, stopped with H6021 "Typeclass resolution failed".

   The same call looked only among the instances the GENERIC function's
   module sees.  An instance for a record of the caller's own -- a module
   Standard.Sort does not import -- was not among them.  The call site has
   already checked, with its own visible instances, that the type has the
   instance (the constraint of the type parameter), and instances are
   unique across the program (the compiler checks that across modules),
   so the search here runs over all of them:
   get_instance_anywhere.  See docs/differences-from-austral.md. *)
let rec unmono_type (env: env) (ty: ty): ty =
  let r = unmono_type env in
  match ty with
  | MonoTy id -> named_type_of_monomorph env id
  | NamedType (n, args, u) -> NamedType (n, List.map r args, u)
  | ReadRef (t, g) -> ReadRef (r t, r g)
  | WriteRef (t, g) -> WriteRef (r t, r g)
  | Span (t, g) -> Span (r t, r g)
  | SpanMut (t, g) -> SpanMut (r t, r g)
  | Address t -> Address (r t)
  | Pointer t -> Pointer (r t)
  | FnPtr (args, rt) -> FnPtr (List.map r args, r rt)
  | Unit | Never | Boolean | Integer _ | SingleFloat | DoubleFloat | RegionTy _ | TyVar _ -> ty

and named_type_of_monomorph (env: env) (id: mono_id): ty =
  let (type_id, tyargs) =
    match get_monomorph env id with
    | Some (MonoRecordDefinition { type_id; tyargs; _ }) -> (type_id, tyargs)
    | Some (MonoUnionDefinition { type_id; tyargs; _ }) -> (type_id, tyargs)
    | _ -> internal_err "A MonoTy names no record or union monomorph."
  in
  match get_decl_by_id env type_id with
  | Some (Record { mod_id; name; typarams; universe; _ })
  | Some (Union { mod_id; name; typarams; universe; _ }) ->
     let qname: qident = make_qident (module_name_from_id env mod_id, name, name) in
     let arg (tp: type_parameter): ty =
       match get_mono_binding tyargs tp with
       | Some mt -> unmono_mono env mt
       | None -> internal_err "A monomorph lacks the argument of a type parameter."
     in
     NamedType (qname, List.map arg (typarams_as_list typarams), universe)
  | _ ->
     internal_err "The type id of a monomorph names no record or union."

and unmono_mono (env: env) (mt: mono_ty): ty =
  let r = unmono_mono env in
  match mt with
  | MonoUnit -> Unit
  | MonoNever -> Never
  | MonoBoolean -> Boolean
  | MonoInteger (s, w) -> Integer (s, w)
  | MonoSingleFloat -> SingleFloat
  | MonoDoubleFloat -> DoubleFloat
  | MonoNamedType id -> named_type_of_monomorph env id
  | MonoRegionTy g -> RegionTy g
  | MonoReadRef (t, g) -> ReadRef (r t, r g)
  | MonoWriteRef (t, g) -> WriteRef (r t, r g)
  | MonoSpan (t, g) -> Span (r t, r g)
  | MonoSpanMut (t, g) -> SpanMut (r t, r g)
  | MonoAddress t -> Address (r t)
  | MonoPointer t -> Pointer (r t)
  | MonoFnPtr (args, rt) -> FnPtr (List.map r args, r rt)
  | MonoRegionTyVar (name, source) -> TyVar (TypeVariable (name, RegionUniverse, source, []))

(* The bindings of a function generic over regions only: each region bound
   to the static region, as the region of every reference and span is
   erased.  Such a function has one monomorph. *)
let region_bindings (typarams: typarams): mono_type_bindings =
  mono_bindings_from_list
    (List.map (fun tp -> (tp, MonoRegionTy static_region)) (typarams_as_list typarams))

(* The monomorph of a call of a slot or an implementation, which may be
   generic over regions only: the one monomorph of region_bindings.  A
   slot's monomorph brings the one of its implementation, because the C of
   the slot calls it although no call of the programme names it.  None for
   any other function. *)
let slot_monomorph (env: env) (decl_id: decl_id): (env * mono_id) option =
  match get_decl_by_id env decl_id with
  | Some (Function { mod_id; name; typarams; _ }) ->
     (match get_module_by_id env mod_id with
      | Some (ModRec { name = mn; _ }) ->
         if Slots.is_slot mn name then
           let (env, mono_id) = add_or_get_function_monomorph env decl_id (region_bindings typarams) in
           let env: env =
             match Slots.implementation_of (Slots.full_name mn name) with
             | Some i ->
                (match get_decl_by_name env (make_sident i.Slots.impl_module i.Slots.impl_name) with
                 | Some (Function { id = impl_id; typarams = impl_typarams; _ }) ->
                    if typarams_size impl_typarams > 0 then
                      fst (add_or_get_function_monomorph env impl_id (region_bindings impl_typarams))
                    else
                      env
                 | _ ->
                    env)
             | None ->
                env
           in
           Some (env, mono_id)
         else if Slots.implements mn name then
           Some (add_or_get_function_monomorph env decl_id (region_bindings typarams))
         else
           None
      | _ ->
         None)
  | _ ->
     None

(* A generic implementation of a slot, met in its own module, which is
   compiled after the slot's: its monomorph and the slot's.  The slot's
   module may have called the slot before the implementation was known, and
   the C of the slot calls the implementation. *)
let implementation_monomorphs (env: env) (decl_id: decl_id): env =
  match get_decl_by_id env decl_id with
  | Some (Function { mod_id; name; typarams; _ }) ->
     (match get_module_by_id env mod_id with
      | Some (ModRec { name = mn; _ }) ->
         (match Slots.slot_implemented_by mn name with
          | Some s ->
             let (env, _) = add_or_get_function_monomorph env decl_id (region_bindings typarams) in
             (match get_decl_by_name env (make_sident s.Slots.slot_module s.Slots.slot_name) with
              | Some (Function { id = slot_id; typarams = slot_typarams; _ }) ->
                 fst (add_or_get_function_monomorph env slot_id (region_bindings slot_typarams))
              | _ ->
                 env)
          | None ->
             env)
      | _ ->
         env)
  | _ ->
     env

let function_monomorph (env: env) (decl_id: decl_id) (substs: mono_type_bindings): (env * mono_id) =
  match slot_monomorph env decl_id with
  | Some found -> found
  | None -> add_or_get_function_monomorph env decl_id substs

let rec monomorphize_expr (env: env) (expr: texpr): (mexpr * env) =
  match expr with
  | TNilConstant ->
     (MNilConstant, env)
  | TBoolConstant b ->
     (MBoolConstant b, env)
  | TIntConstant i ->
     (MIntConstant i, env)
  | TFloatConstant f ->
     (MFloatConstant f, env)
  | TStringConstant s ->
     (MStringConstant s, env)
  | TConstVar (name, ty) ->
     let (ty, env) = strip_and_mono env ty in
     (MConstVar (name, ty), env)
  | TParamVar (name, ty) ->
     let (ty, env) = strip_and_mono env ty in
     (MParamVar (name, ty), env)
  | TLocalVar (name, ty) ->
     let (ty, env) = strip_and_mono env ty in
     (MLocalVar (name, ty), env)
  | TTemporary (name, ty) ->
     let (ty, env) = strip_and_mono env ty in
     (MTemporary (name, ty), env)
  | TFunVar (decl_id, ty, bindings) ->
     (* Monomorphize the type. *)
     let (rt, env) = strip_and_mono env ty in
     (* Does the funcall have a substitution list? *)
     if List.length (bindings_list bindings) > 0 then
       (* The function is generic. *)
       (* Monomorphize the tyargs *)
       let typarams = List.map (fun (tp, _) -> tp) (bindings_list bindings) in
       let tyargs = List.map (fun (_, ty) -> strip_type ty) (bindings_list bindings) in
       let (tyargs, env) = monomorphize_ty_list env tyargs in
       let substs: mono_type_bindings = mono_bindings_from_list (List.map2 (fun tp mt -> (tp, mt)) typarams tyargs) in
       (* A function VALUE of spawn is checked too, or calling it through a
          pointer would go round the check below. *)
       check_task_argument env decl_id (bindings_list bindings);
       let (env, mono_id) = function_monomorph env decl_id substs in
       (MGenericFunVar (mono_id, rt), env)
     else
       (* The function is concrete. *)
       (MConcreteFunVar (decl_id, rt), env)
  | TFuncall (decl_id, name, args, rt, substs) ->
     let substs_ty = substs in
     (* Monomorphize the return type. *)
     let (rt, env) = strip_and_mono env rt in
     (* Monomorphize the arglist *)
     let (args, env) = monomorphize_expr_list env args in
     (* Does the funcall have a substitution list? *)
     if List.length (bindings_list substs) > 0 then
       (* The function is generic. *)
       (* Monomorphize the tyargs *)
       let typarams = List.map (fun (tp, _) -> tp) (bindings_list substs) in
       let tyargs = List.map (fun (_, ty) -> strip_type ty) (bindings_list substs) in
       let (tyargs, env) = monomorphize_ty_list env tyargs in
       let substs: mono_type_bindings = mono_bindings_from_list (List.map2 (fun tp mt -> (tp, mt)) typarams tyargs) in
       check_task_argument env decl_id (bindings_list substs_ty);
       let (env, mono_id) = function_monomorph env decl_id substs in
       (MGenericFuncall (mono_id, args, rt), env)
     else
       (* The function is concrete. *)
       (MConcreteFuncall (decl_id, name, args, rt), env)
  | TMethodCall (ins_meth_id, name, typarams, args, rt, substs) ->
     with_frame "Monomorphizing method call"
       (fun _ ->
         (* Monomorphize the return type. *)
         let (rt, env) = strip_and_mono env rt in
         (* Monomorphize the arglist *)
         let (args, env) = monomorphize_expr_list env args in
         (* Does the funcall have a list of type params? *)
         if typarams_size typarams > 0 then
           (* The instance is generic. *)
           (* Monomorphize the tyargs *)
           let typarams = List.map (fun (tp, _) -> tp) (bindings_list substs) in
           let tyargs = List.map (fun (_, ty) -> strip_type ty) (bindings_list substs) in
           let (tyargs, env) = monomorphize_ty_list env tyargs in
           let substs: mono_type_bindings = mono_bindings_from_list (List.map2 (fun tp mt -> (tp, mt)) typarams tyargs) in
           let (env, mono_id) = add_or_get_instance_method_monomorph env ins_meth_id substs in
           (MGenericMethodCall (ins_meth_id, mono_id, args, rt), env)
         else
           (* The instance is concrete. *)
           (MConcreteMethodCall (ins_meth_id, name, args, rt), env))
  | TVarMethodCall { dispatch_ty; typeclass_id; source_module_name; params; args; bindings; method_name; rt; } ->
     (* Continue the instance resolution process we halted in the typing pass. *)
     let (instance, instance_bindings): decl * type_bindings =
       (match get_instance_anywhere env source_module_name (unmono_type env dispatch_ty) typeclass_id with
        | Some (i, b) -> (i, b)
        | None ->
           internal_err ("Typeclass resolution failed. Dispatch type: "
                ^ (type_string (unmono_type env dispatch_ty))))
     in
     let params' = List.map (fun (ValueParameter (n, t)) -> ValueParameter (n, replace_variables instance_bindings t)) params in
     let arguments' = TypeCheckExpr.cast_arguments instance_bindings params' args in
     let typarams = (match instance with
                     | Instance { typarams; _ } -> typarams
                     | _ -> internal_err ("Couldn't find instance for var method call `"
                                          ^ (qident_debug_name method_name)
                                          ^ "` with typeclass ID `"
                                          ^ (show_decl_id typeclass_id)
                                          ^ "`."))
     in
     let instance_id: decl_id = decl_id instance in
     let meth_id: ins_meth_id =
       (match get_instance_method_from_instance_id_and_method_name env instance_id (original_name method_name) with
        | Some (InsMethRec { id; _ }) -> id
        | None -> internal_err ("Couldn't find instance method from instance ID `"
                                ^ (show_decl_id instance_id)
                                ^ "` and method name `"
                                ^ (method_name |> original_name |> ident_string)
                                ^ "`."))
     in
     ps ("Bindings", show_bindings bindings);
     let substs = make_substs2 instance_bindings typarams in
     let mcall = TMethodCall (meth_id, method_name, typarams, arguments', rt, substs) in
     monomorphize_expr env mcall
  | TFptrCall (name, args, ty) ->
     let (args, env) = monomorphize_expr_list env args in
     let (ty, env) = strip_and_mono env ty in
     (MFptrCall (name, args, ty), env)
  | TCast (expr, ty) ->
     let (ty, env) = strip_and_mono env ty in
     let (expr, env) = monomorphize_expr env expr in
     (MCast (expr, ty), env)
  | TComparison (oper, lhs, rhs) ->
     (* The type checker let a type variable through; here it stands for a
        type, and C compares scalars and pointers only. *)
     let declared: ty = TastUtil.get_type lhs in
     let (instance, env) = strip_and_mono env declared in
     (match instance with
      | MonoSpan _ | MonoSpanMut _ | MonoNamedType _ | MonoRegionTy _ | MonoRegionTyVar _ ->
         TypeErrors.comparison_instance_not_defined oper declared
      | _ -> ());
     let (lhs, env) = monomorphize_expr env lhs in
     let (rhs, env) = monomorphize_expr env rhs in
     (MComparison (oper, lhs, rhs), env)
  | TConjunction (lhs, rhs) ->
     let (lhs, env) = monomorphize_expr env lhs in
     let (rhs, env) = monomorphize_expr env rhs in
     (MConjunction (lhs, rhs), env)
  | TDisjunction (lhs, rhs) ->
     let (lhs, env) = monomorphize_expr env lhs in
     let (rhs, env) = monomorphize_expr env rhs in
     (MDisjunction (lhs, rhs), env)
  | TNegation expr ->
     let (expr, env) = monomorphize_expr env expr in
     (MNegation expr, env)
  | TIfExpression (c, t, f) ->
     let (c, env) = monomorphize_expr env c in
     let (t, env) = monomorphize_expr env t in
     let (f, env) = monomorphize_expr env f in
     (MIfExpression (c, t, f), env)
  | TRecordConstructor (ty, args) ->
     let (ty, env) = strip_and_mono env ty in
     let (args, env) = monomorphize_named_expr_list env args in
     (MRecordConstructor (ty, args), env)
  | TUnionConstructor (ty, case_name, args) ->
     let (ty, env) = strip_and_mono env ty in
     let (args, env) = monomorphize_named_expr_list env args in
     (MUnionConstructor (ty, case_name, args), env)
  | TEmbed (ty, fmt, args) ->
     let (ty, env) = strip_and_mono env ty in
     let (args, env) = monomorphize_expr_list env args in
     (MEmbed (ty, fmt, args), env)
  | TDeref expr ->
     let (expr, env) = monomorphize_expr env expr in
     (MDeref expr, env)
  | TSizeOf ty ->
     let (ty, env) = strip_and_mono env ty in
     (MSizeOf ty, env)
  | TSlotAccessor (expr, name, ty) ->
     let (expr, env) = monomorphize_expr env expr in
     let (ty, env) = strip_and_mono env ty in
     (MSlotAccessor (expr, name, ty), env)
  | TPointerSlotAccessor (expr, name, ty) ->
     let (expr, env) = monomorphize_expr env expr in
     let (ty, env) = strip_and_mono env ty in
     (MPointerSlotAccessor (expr, name, ty), env)
  | TArrayIndex (expr, idx, ty) ->
     let (expr, env) = monomorphize_expr env expr in
     let (idx, env) = monomorphize_expr env idx in
     let (ty, env) = strip_and_mono env ty in
     (MArrayIndex (expr, idx, ty), env)
   | TSpanIndex (expr, idx, ty) ->
     let (expr, env) = monomorphize_expr env expr in
     let (idx, env) = monomorphize_expr env idx in
     let (ty, env) = strip_and_mono env ty in
     (MSpanIndex (expr, idx, ty), env)

and monomorphize_expr_list (env: env) (exprs: texpr list): (mexpr list * env) =
  match exprs with
  | first::rest ->
     let (first, env) = monomorphize_expr env first in
     let (rest, env) = monomorphize_expr_list env rest in
     (first :: rest, env)
  | [] ->
     ([], env)

and monomorphize_named_expr_list (env: env) (exprs: (identifier * texpr) list): ((identifier * mexpr) list * env) =
  match exprs with
  | (name, first)::rest ->
     let (first, env) = monomorphize_expr env first in
     let (rest, env) = monomorphize_named_expr_list env rest in
     ((name, first) :: rest, env)
  | [] ->
     ([], env)

(* Monomorphize statements *)

let rec monomorphize_stmt (env: env) (stmt: tstmt): (mstmt * env) =
  match stmt with
  | TSkip _ ->
     (MSkip, env)
  | TLet (_, _, name, ty, body) ->
     let (ty, env) = strip_and_mono env ty in
     let (body, env) = monomorphize_stmt env body in
     (MLet (name, ty, body), env)
  | TDestructure (_, _, bindings, value, body) ->
     let (bindings, env) = monomorphize_binding_list env (List.map (fun (TypedBinding { name; ty; rename; }) -> (name, strip_type ty, rename)) bindings) in
     let (value, env) = monomorphize_expr env value in
     let (body, env) = monomorphize_stmt env body in
     (MDestructure (bindings, value, body), env)
  | TAssign (_, lvalue, rvalue) ->
     let (lvalue, env) = monomorphize_expr env lvalue in
     let (rvalue, env) = monomorphize_expr env rvalue in
     (MAssign (lvalue, rvalue), env)
  | TAssignVar (_, name, rvalue) ->
     let (rvalue, env) = monomorphize_expr env rvalue in
     (MAssignVar (name, rvalue), env)
  | TInitialAssign (name, rvalue) ->
     let (rvalue, env) = monomorphize_expr env rvalue in
     (MInitialAssign (name, rvalue), env)
  | TIf (_, c, t, f) ->
     let (c, env) = monomorphize_expr env c in
     let (t, env) = monomorphize_stmt env t in
     let (f, env) = monomorphize_stmt env f in
     (MIf (c, t, f), env)
  | TCase (_, value, whens, case_ref) ->
     let (value, env) = monomorphize_expr env value in
     let (whens, env) = monomorphize_whens env whens in
     (MCase (value, whens, case_ref), env)
  | TSwitch (_, value, arms, other) ->
     let (value, env) = monomorphize_expr env value in
     let (arms, env) =
       List.fold_left (fun (acc, env) (labels, body) ->
           let (body, env) = monomorphize_stmt env body in
           ((labels, body) :: acc, env))
         ([], env) arms
     in
     let (other, env) = monomorphize_stmt env other in
     (MSwitch (value, List.rev arms, other), env)
  | TWhile (_, value, body) ->
     let (value, env) = monomorphize_expr env value in
     let (body, env) = monomorphize_stmt env body in
     (MWhile (value, body), env)
  | TFor (_, name, start, final, body) ->
     let (start, env) = monomorphize_expr env start in
     let (final, env) = monomorphize_expr env final in
     let (body, env) = monomorphize_stmt env body in
     (MFor (name, start, final, body), env)
  | TBorrow { span; original; rename; region; orig_type; ref_type; body; mode } ->
     let _ = span in
     let (orig_type, env) = strip_and_mono env orig_type in
     let (ref_type, env) = strip_and_mono env ref_type in
     let (body, env) = monomorphize_stmt env body in
     (MBorrow { original = original; rename = rename; region = region; orig_type = orig_type; ref_type = ref_type; body = body; mode = mode }, env)
  | TBlock (_, a, b) ->
     let (a, env) = monomorphize_stmt env a in
     let (b, env) = monomorphize_stmt env b in
     (MBlock (a, b), env)
  | TDiscarding (_, value) ->
     let (value, env) = monomorphize_expr env value in
     (MDiscarding value, env)
  | TReturn (_, value) ->
     let (value, env) = monomorphize_expr env value in
     (MReturn value, env)
  | TRaise (_, kind) ->
     (MRaise kind, env)
  | TLetTmp (name, ty, expr) ->
     let (ty, env) = strip_and_mono env ty in
     let (expr, env) = monomorphize_expr env expr in
     (MLetTmp (name, ty, expr), env)
  | TAssignTmp (name, value) ->
     let (value, env) = monomorphize_expr env value in
     (MAssignTmp (name, value), env)
  | TUnreachable _ ->
     (MUnreachable, env)

and monomorphize_whens (env: env) (whens: typed_when list): (mtyped_when list * env) =
  match whens with
  | first::rest ->
     let (first, env) = monomorphize_when env first in
     let (rest, env) = monomorphize_whens env rest in
     (first :: rest, env)
  | [] ->
     ([], env)

and monomorphize_when (env: env) (w: typed_when): (mtyped_when * env) =
  let (TypedWhen (name, params, body)) = w in
  let (bindings, env) = monomorphize_bindings env params in
  let (body, env) = monomorphize_stmt env body in
  (MTypedWhen (name, bindings, body), env)

and monomorphize_bindings (env: env) (bindings: typed_binding list): (mono_binding list * env) =
  match bindings with
  | first::rest ->
     let (TypedBinding { name; ty; rename; }) = first in
     let (ty, env) = monomorphize_ty env (strip_type ty) in
     let (rest, env) = monomorphize_bindings env rest in
     let binding = MonoBinding { name; ty; rename; } in
     (binding :: rest, env)
  | [] ->
     ([], env)

and monomorphize_binding_list (env: env) (bs: (identifier * stripped_ty * identifier) list): (mono_binding list * env) =
  match bs with
  | first::rest ->
     let (name, ty, rename) = first in
     let (ty, env) = monomorphize_ty env ty in
     let (rest, env) = monomorphize_binding_list env rest in
     let binding = MonoBinding { name; ty; rename; } in
     (binding :: rest, env)
  | [] ->
     ([], env)

(* Monomorphize declarations *)

let rec monomorphize_decl (env: env) (decl: typed_decl): (mdecl option * env) =
  match decl with
  | TConstant (id, _, name, ty, value, _) ->
     (* Constant are intrinsically monomorphic, and can be monomorphized
        painlessly. *)
     let (ty, env) = strip_and_mono env ty in
     let (value, env) = monomorphize_expr env value in
     let decl = MConstant (id, name, ty, value) in
     (Some decl, env)
  | TRecord (id, _, name, typarams, _, slots, _) ->
     (* Concrete records are monomorphized immediately. Generic records are
        monomorphized on demand. *)
     if (typarams_size typarams) = 0 then
       let (env, slots) = monomorphize_slots env slots in
       let decl = MRecord (id, name, slots) in
       (Some decl, env)
     else
       (None, env)
  | TUnion (id, _, name, typarams, _, cases, _) ->
     (* Concrete unions are monomorphized immediately. Generic unions are
        monomorphized on demand. *)
     if (typarams_size typarams) = 0 then
       let (env, cases) = Util.map_with_context (fun (e, c) -> monomorphize_case e c) env cases in
       let decl = MUnion (id, name, cases) in
       (Some decl, env)
     else
       (None, env)
  | TFunction (id, _, name, typarams, value_params, rt, body, _, _) ->
     (* Concrete functions are monomorphized immediately. Generic functions are
        monomorphized on demand. *)
     with_frame ("Monomorphizing function: " ^ (ident_string name))
       (fun _ ->
         if (typarams_size typarams) = 0 then
           let (env, params) = monomorphize_params env value_params in
           let (rt, env) = strip_and_mono env rt in
           let (body, env) = monomorphize_stmt env body in
           let decl = MFunction (id, name, params, rt, body) in
           (Some decl, env)
         else
           (None, implementation_monomorphs env id))
  | TForeignFunction (id, _, name, params, rt, underlying, _) ->
     (* Foreign functions are intrinsically monomorphic. *)
     let (env, params) = monomorphize_params env params in
     let (rt, env) = strip_and_mono env rt in
     let decl = MForeignFunction (id, name, params, rt, underlying) in
     (Some decl, env)
  | TTypeClass _ ->
     (* Type classes are purely "informative" declarations: they have no physical
        existence in the code. *)
     (None, env)
  | TInstance (decl_id, _, name, typarams, argument, methods, _) ->
     (* Concrete instances can be monomorphized immediately. *)
     if (typarams_size typarams) = 0 then
       let (argument, env) = strip_and_mono env argument in
       let (env, methods) = monomorphize_methods env methods in
       let decl = MConcreteInstance (decl_id, name, argument, methods) in
       (Some decl, env)
     else
       (None, env)

and monomorphize_slot (env: env) (slot: typed_slot): (env * mono_slot) =
  let (TypedSlot (name, ty)) = slot in
  let (ty, env) = strip_and_mono env ty in
  (env, MonoSlot (name, ty))

and monomorphize_slots (env: env) (slots: typed_slot list): (env * mono_slot list) =
  Util.map_with_context (fun (e, s) -> monomorphize_slot e s) env slots

and monomorphize_case (env: env) (case: linked_case): (env * mono_case) =
  let (LCase (_, name, slots)) = case in
  let (env, slots) = monomorphize_slots env slots in
  (env, MonoCase (name, slots))

and monomorphize_param (env: env) (param: value_parameter): (env * mvalue_parameter) =
  let (ValueParameter (name, ty)) = param in
  let (ty, env) = strip_and_mono env ty in
  (env, MValueParameter (name, ty))

and monomorphize_params (env: env) (params: value_parameter list): (env * mvalue_parameter list) =
  Util.map_with_context (fun (e, p) -> monomorphize_param e p) env params

and monomorphize_methods (env: env) (methods: typed_method_def list): (env * concrete_method list) =
  Util.map_with_context (fun (e, m) -> monomorphize_method e m) env methods

and monomorphize_method (env: env) (meth: typed_method_def): (env * concrete_method) =
  let (TypedMethodDef (id, name, params, rt, body)) = meth in
  let (env, params) = monomorphize_params env params in
  let (rt, env) = strip_and_mono env rt in
  let (body, env) = monomorphize_stmt env body in
  (env, MConcreteMethod (id, name, params, rt, body))

(* Monomorphize modules *)

let rec monomorphize (env: env) (m: typed_module): (env * mono_module) =
  with_frame "Monomorphizing module"
    (fun _ ->
      (* Monomorphize what we can: concrete definitions. *)
      let (TypedModule (module_name, decls)) = m in
      let (env, declopts) =
        Util.map_with_context (fun (e, d) -> let (d, e) = monomorphize_decl e d in (e, d)) env decls in
      let decls: mdecl list = List.filter_map (fun x -> x) declopts in
      (* Recursively collect and instantiate monomorphs until everything's instantiated. *)
      let (env, decls'): (env * mdecl list) = instantiate_monomorphs_until_exhausted env in
      (env, MonoModule (module_name, decls @ decls')))

and instantiate_monomorphs_until_exhausted (env: env): (env * mdecl list) =
  with_frame "Instantiating monomorphs until exhausted"
    (fun _ ->
      (* Get uninstantiated monomorphs from the environment. *)
      let monos: monomorph list = get_uninstantiated_monomorphs env in
      match monos with
      | first::rest ->
         (* If there are uninstantiated monomorphs, instantite them, and repeat the
            process. *)
         let (env, decls): (env * mdecl list) = instantiate_monomorphs env (first::rest) in
         let (env, decls') : (env * mdecl list) = instantiate_monomorphs_until_exhausted env in
         (env, decls @ decls')
      | [] ->
         (* If there are no uninstantiated monomorphs, we're done. *)
         (env, []))

and instantiate_monomorphs (env: env) (monos: monomorph list): (env * mdecl list) =
  (* Instantiate a list of monomorphs. *)
  Util.map_with_context (fun (e, m) -> instantiate_monomorph e m) env monos

and instantiate_monomorph (env: env) (mono: monomorph): (env * mdecl) =
  match mono with
  | MonoRecordDefinition { id; type_id; tyargs; _ } ->
     with_frame "Instantiating record monomorph"
       (fun _ ->
         ps ("Monomorph ID", show_mono_id id);
         (* Find the record definition and extract the type parameters and the slot
            list. *)
         let (typarams, slots) = get_record_definition env type_id in
         ps ("Type parameters", String.concat ", " (List.map show_type_parameter (typarams_as_list typarams)));
         (* Search/replace the type variables in the slot list with the type
            arguments from this monomorph. *)
         let slots: typed_slot list =
           List.map
             (fun (TypedSlot (name, ty)) ->
               (* TODO: extract decl name, make it a qname, pass that here *)
               TypedSlot (name, replace_type_variables typarams tyargs ty))
             slots
         in
         (* Strip and monomorphize the slot list. *)
         let (env, slots): (env * mono_slot list) = monomorphize_slot_list env slots in
         (* Store the monomorphic slot list in the environment. *)
         let env = store_record_monomorph_definition env id slots in
         (* Construct a monomorphic record decl. *)
         let decl: mdecl = MRecordMonomorph (id, slots) in
         (* Return the new environment and the declaration. *)
         (env, decl))
  | MonoUnionDefinition { id; type_id; tyargs; _ } ->
     (* Find the list of type parameters from the union definition. *)
     let typarams = get_union_typarams env type_id in
     (* Find the list of cases from the env. *)
     let cases: typed_case list = get_union_typed_cases env type_id in
     (* Search/replace the type variables in the case list with the type
        arguments from this monomorph. *)
     let cases: typed_case list =
       List.map
         (fun (TypedCase (name, slots)) ->
           let slots: typed_slot list =
             List.map
               (fun (TypedSlot (name, ty)) ->
                 TypedSlot (name, replace_type_variables typarams tyargs ty))
               slots
           in
           TypedCase (name, slots))
         cases
     in
     (* Strip and monomorphize the case list. *)
     let (env, cases): (env * mono_case list) = monomorphize_case_list env cases in
     (* Store the monomorphic slot list in the environment. *)
     let env = store_union_monomorph_definition env id cases in
     (* Construct a monomorphic record decl. *)
     let decl: mdecl = MUnionMonomorph (id, cases) in
     (* Return the new environment and the declaration. *)
     (env, decl)
  | MonoFunction { id; function_id; tyargs; _ } ->
     (* Find the function's type parameters, value parameters, return type, and
        body. *)
     let (typarams, params, rt, body) = get_function_definition env function_id in
     (* Search/replace the type variables in the parameter list with the type
        arguments. *)
     let params: value_parameter list =
       List.map
         (fun (ValueParameter (name, ty)) ->
           ValueParameter (name, replace_type_variables typarams tyargs ty))
         params
     in
     (* Monomorphize the parameter list. *)
     let (env, params) = monomorphize_params env params in
     (* Search/replace the type variables in the return type. *)
     let rt: ty = replace_type_variables typarams tyargs rt in
     (* Monomorphize the return type. *)
     let (rt, env) = strip_and_mono env rt in
     (* Search/replace the type variables in the body with the type
        arguments. *)
     let bindings = make_bindings typarams tyargs in
     let body = replace_tyvars_stmt bindings body in
     (* Monomorphize the body *)
     let (body, env) = monomorphize_stmt env body in
     (* Store the monomorphic body in the environment. *)
     let env = store_function_monomorph_definition env id body in
     (* Construct a monomorphic record decl. *)
     let decl: mdecl = MFunctionMonomorph (id, params, rt, body) in
     (* Return the new environment and the declaration. *)
     (env, decl)
  | MonoInstanceMethod { id; method_id; tyargs; _ } ->
     with_frame "Instantiating instance method monomorph"
       (fun _ ->
         (* Find the methods's type parameters, value parameters, return type, and
            body. *)
         let (typarams, params, rt, body) = get_method_definition env method_id in
         (* Search/replace the type variables in the parameter list with the type
            arguments. *)
         let params: value_parameter list =
           List.map
             (fun (ValueParameter (name, ty)) ->
               ValueParameter (name, replace_type_variables typarams tyargs ty))
             params
         in
         (* Monomorphize the parameter list. *)
         let (env, params) = monomorphize_params env params in
         (* Search/replace the type variables in the return type. *)
         let rt = replace_type_variables typarams tyargs rt in
         (* Monomorphize the return type. *)
         let (rt, env) = strip_and_mono env rt in
         (* Search/replace the type variables in the body with the type
            arguments. *)
         let bindings = make_bindings typarams tyargs in
         let body = replace_tyvars_stmt bindings body in
         (* Monomorphize the body *)
         let (body, env) = monomorphize_stmt env body in
         (* Store the monomorphic body in the environment. *)
         let env = store_instance_method_monomorph_definition env id body in
         (* Construct a monomorphic record decl. *)
         let decl: mdecl = MMethodMonomorph (id, params, rt, body) in
         (* Return the new environment and the declaration. *)
         (env, decl))

(* Utils *)


and get_record_definition (env: env) (id: decl_id): (typarams * typed_slot list) =
  match get_decl_by_id env id with
  | Some (Record { typarams; slots; _ }) ->
     (typarams, slots)
  | _ ->
     internal_err ("couldn't get record definition for ID `" ^ (show_decl_id id) ^ "`.")

and get_union_typarams (env: env) (id: decl_id): typarams =
  match get_decl_by_id env id with
  | Some (Union { typarams; _ }) ->
     typarams
  | _ ->
     internal_err ("couldn't get union typeparams for ID `" ^ (show_decl_id id) ^ "`.")

and get_union_typed_cases (env: env) (union_id: decl_id): typed_case list =
  let cases: decl list = get_union_cases env union_id in
  let mapper (decl: decl): typed_case =
    match decl with
    | UnionCase { name; slots; _ } ->
       TypedCase (name, slots)
    | _ ->
       internal_err ("ID `" ^ (show_decl_id union_id) ^ "` is not a union")
  in
  List.map mapper cases

and get_function_definition (env: env) (id: decl_id): (typarams * value_parameter list * ty * tstmt) =
  match get_decl_by_id env id with
  | Some (Function { name; typarams; value_params; rt; body; _ }) ->
     (match body with
      | Some body ->
         (typarams, value_params, rt, body)
      | None ->
         internal_err ("function `" ^ (ident_string name) ^ "` has no body"))
  | _ ->
     internal_err ("ID `" ^ (show_decl_id id) ^ "is not a function")

and get_method_definition (env: env) (id: ins_meth_id): (typarams * value_parameter list * ty * tstmt) =
  match get_instance_method env id with
  | Some (InsMethRec { instance_id; value_params; rt; body; _ }) ->
     (match get_decl_by_id env instance_id with
      | Some (Instance { typarams; _ }) ->
         (match body with
          | Some body ->
             (typarams, value_params, rt, body)
          | None ->
             internal_err ("method with ID `" ^ (show_decl_id instance_id) ^ "` has no body"))
      | _ ->
         internal_err ("ID `" ^ (show_decl_id instance_id) ^ "`not an instance"))
  | _ ->
     internal_err ("ID `" ^ (show_ins_meth_id id) ^ "`not an instance method")

and monomorphize_slot_list (env: env) (slots: typed_slot list): (env * mono_slot list) =
  let names: identifier list = List.map (fun (TypedSlot (n, _)) -> n) slots in
  let (tys, env): (mono_ty list * env) = strip_and_mono_list env (List.map (fun (TypedSlot (_, t)) -> t) slots) in
  let (slots: mono_slot list) = List.map2 (fun name ty -> MonoSlot (name, ty)) names tys in
  (env, slots)

and monomorphize_case_list (env: env) (cases: typed_case list): (env * mono_case list) =
  Util.map_with_context
    (fun (env, TypedCase (name, slots)) ->
      let (env, slots) = monomorphize_slot_list env slots in
      (env, MonoCase (name, slots)))
    env
    cases

and replace_type_variables (typarams: typarams) (args: mono_type_bindings) (ty: ty): ty =
  with_frame "Replacing type variables"
    (fun _ ->
      let bindings: type_bindings = make_bindings typarams args in
      replace_variables bindings ty)

and make_bindings (typarams: typarams) (args: mono_type_bindings): type_bindings =
  with_frame "Make bindings"
    (fun _ ->
      let typarams = typarams_as_list typarams in
      if (List.length typarams) = (List.length (mono_bindings_as_list args)) then
        let pairs: (type_parameter * ty) list =
          List.map (fun tp ->
              (match get_mono_binding args tp with
               | Some ty ->
                  (tp, mono_to_ty ty)
               | None ->
                  internal_err "Parameter not found."))
            typarams
        in
        let _ = ps ("Pairs", String.concat ", " (List.map (fun (tp, t) -> "(" ^ (show_type_parameter tp) ^ ", " ^ (show_ty t) ^ ")") pairs)) in
        let b = bindings_from_list pairs in
        ps ("Bindings", show_bindings b);
        b
      else
        internal_err ("Parameter list and argument list don't have the same length:\n\nparameters:\n"
             ^ (String.concat ", " (List.map show_type_parameter typarams))
             ^ "\narguments:\n"
             ^ (String.concat ", " (List.map (fun (_, ty) -> show_mono_ty ty) (mono_bindings_as_list args)))))

and mono_to_ty (ty: mono_ty): ty =
  let r = mono_to_ty in
  match ty with
  | MonoUnit -> Unit
  | MonoNever -> Never
  | MonoBoolean -> Boolean
  | MonoInteger (s, w) -> Integer (s, w)
  | MonoSingleFloat -> SingleFloat
  | MonoDoubleFloat -> DoubleFloat
  | MonoNamedType mono_id ->
     (* SPECIAL CASE *)
     MonoTy mono_id
  | MonoRegionTy r ->
     RegionTy r
  | MonoReadRef (ty, region) ->
     ReadRef (r ty, r region)
  | MonoWriteRef (ty, region) ->
     WriteRef (r ty, r region)
  | MonoSpan (ty, region) ->
     Span (r ty, r region)
  | MonoSpanMut (ty, region) ->
     SpanMut (r ty, r region)
  | MonoAddress ty ->
     Address (r ty)
  | MonoPointer ty ->
     Pointer (r ty)
  | MonoFnPtr (args, rt) ->
     FnPtr (List.map r args, r rt)
  | MonoRegionTyVar (name, source) ->
     TyVar (TypeVariable (name, RegionUniverse, source, []))

(* The bindings of an exported function's monomorph.  An exported function
   may be generic over regions only (the extraction pass refuses any other
   type parameter, H2018), and each region is bound to the static region,
   as the region of every reference and span is erased: a region has
   no run-time representation.  Used here and by ExportInstantiation, so
   that the wrapper finds the monomorph made here. *)
let export_bindings (typarams: typarams): mono_type_bindings =
  mono_bindings_from_list
    (List.map (fun tp -> (tp, MonoRegionTy static_region)) (typarams_as_list typarams))

let monomorphize_wrapper (env: env) (id: decl_id): env =
  match get_decl_by_id env id with
  | Some (Function { id; typarams; _ }) ->
     let (env, _) = add_or_get_function_monomorph env id (export_bindings typarams) in
     env
  | _ ->
     internal_err "Didn't find wrapper in env."

let monomorphize_wrappers (env: env): env * mdecl list =
  (* Get the IDs of all the wrapper functions. *)
  let ids: decl_id list = List.map (fun (id, _) -> id) (get_export_functions env) in
  (* Monomorphize wrappers. *)
  let env: env = Util.iter_with_context (fun env id -> monomorphize_wrapper env id) env ids in
  (* Instantiate monomorphs *)
  let (env, decls): (env * mdecl list) = instantiate_monomorphs_until_exhausted env in
  (env, decls)
