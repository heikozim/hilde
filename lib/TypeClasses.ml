(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

open Id
open Identifier
open IdentifierSet
open Type
open TypeParameters
open TypeParser
open TypeSystem
open Env
open EnvTypes
open EnvExtras
open EnvUtils
open Error
open BuiltIn

module Errors = struct
  let broken_orphan_rule () =
    hilde_raise (H 6032) GenericError [
      Text "Orphan rule broken: typeclass and type are both foreign."
    ]

  let duplicate_tyvars () =
    hilde_raise (H 2032) DeclarationError [
      Text "Generic instances can only use each type parameter once in the argument."
    ]

  let leftovers () =
    hilde_raise (H 2033) DeclarationError [
      Text "The number of type parameters in the instance declaration must be the same as the number of type variables applied to the argument."
    ]

  let lone_tyvar () =
    hilde_raise (H 2034) DeclarationError [
      Text "Typeclass arguments cannot be lone type parameters."
    ]

  let not_a_tyvar ty =
    hilde_raise (H 2035) DeclarationError [
      Text "The type ";
      Type ty;
      Text " is not a type parameter, but generic instances must use either all type parameters or none of them in the argument.";
      Break;
      Text "Consider adding another generic parameter with universe ";
      Code (type_universe ty |> universe_string)
    ]

  let region_arg () =
    internal_raise [
      Text "Typeclass arguments cannot be regions."
    ]

  let shadowing_typeclass_param name =
    hilde_raise (H 2037) DeclarationError [
      Text "The type parameters in a generic instance declaration cannot have the same name as the type parameter in the corresponding typeclass. The colliding name is ";
      Code (ident_string name);
      Text ".";
      Break;
      Text "Give the type parameter of the instance another name."
    ]

  let wrong_universe ~ty ~expected ~actual =
    hilde_raise (H 3007) TypeError [
      Text "Cannot define an instance with argument ";
      Type ty;
      Text " because it should belong to the ";
      Code (universe_string expected);
      Text " universe, but it is actually in the ";
      Code (universe_string actual);
      Text " universe."
    ]
end

let check_instance_argument_has_right_universe (universe: universe) (arg: ty): unit =
  if universe_compatible universe (type_universe arg) then
    ()
  else
    Errors.wrong_universe
      ~ty:arg
      ~expected:universe
      ~actual:(type_universe arg)

let check_instance_argument_has_right_shape (typarams: typarams) (arg: ty): unit =
  let is_tyvar (ty: ty): type_var =
    match ty with
    | TyVar tv ->
       tv
    | _ ->
       Errors.not_a_tyvar ty
  and all_distinct (tyvars: type_var list): unit =
    let names: identifier list = List.map (fun (TypeVariable (name, _, _, _)) -> name) tyvars in
    let set: IdentifierSet.t = IdentifierSet.of_list names in
    if List.length tyvars = IdentifierSet.cardinal set then
      ()
    else
      Errors.duplicate_tyvars ()
  (* Assert the number of type parameters *)
  and no_leftovers (n: int): unit =
    if (typarams_size typarams) = n then
      ()
    else
      Errors.leftovers ()
  in
  match arg with
  | Unit -> ()
  | Never -> ()
  | Boolean -> ()
  | Integer _ -> ()
  | SingleFloat -> ()
  | DoubleFloat -> ()
  | NamedType (_, args, _) ->
     let _ = all_distinct (List.map is_tyvar args) in
     let _ = no_leftovers (List.length args) in
     ()
  | RegionTy _ ->
     Errors.region_arg ()
  | ReadRef (ty, r) ->
     let _ = all_distinct [is_tyvar ty; is_tyvar r] in
     let _ = no_leftovers 2 in
     ()
  | WriteRef (ty, r) ->
     let _ = all_distinct [is_tyvar ty; is_tyvar r] in
     let _ = no_leftovers 2 in
     ()
  | Span (ty, r) ->
     let _ = all_distinct [is_tyvar ty; is_tyvar r] in
     let _ = no_leftovers 2 in
     ()
  | SpanMut (ty, r) ->
     let _ = all_distinct [is_tyvar ty; is_tyvar r] in
     let _ = no_leftovers 2 in
     ()
  | TyVar _ ->
     Errors.lone_tyvar ()
  | Address ty ->
     let _ = is_tyvar ty in
     let _ = no_leftovers 1 in
     ()
  | Pointer ty ->
     let _ = is_tyvar ty in
     let _ = no_leftovers 1 in
     ()
  | FnPtr (args, ty) ->
     let args' = ty :: args in
     let _ = all_distinct (List.map is_tyvar args') in
     let _ = no_leftovers (List.length args') in
     ()
  | MonoTy _ ->
     internal_err "Not allowed"

let overlapping_instances (a: ty) (b: ty): bool =
  match a with
  | Unit ->
     (match b with
      | Unit -> true
      | _ -> false)
  | Never ->
     (match b with
      | Never -> true
      | _ -> false)
  | Boolean ->
     (match b with
      | Boolean -> true
      | _ -> false)
  | Integer (s, w) ->
     (match b with
      | Integer (s', w') ->
         (equal_signedness s s')
         && (equal_integer_width w w')
      | _ ->
         false)
  | SingleFloat ->
     (match b with
      | SingleFloat -> true
      | _ -> false)
  | DoubleFloat ->
     (match b with
      | DoubleFloat -> true
      | _ -> false)
  | NamedType (name, _, _) ->
     (match b with
      | NamedType (name', _, _) ->
         equal_qident name name'
      | _ ->
         false)
  | RegionTy _ ->
     internal_err "Not allowed"
  | ReadRef _ ->
     (match b with
      | ReadRef _ -> true
      | _ -> false)
  | WriteRef _ ->
     (match b with
      | WriteRef _ -> true
      | _ -> false)
  | Span _ ->
     (match b with
      | Span _ -> true
      | _ -> false)
  | SpanMut _ ->
     (match b with
      | SpanMut _ -> true
      | _ -> false)
  | TyVar _ ->
     internal_err "Not allowed"
  | Address _ ->
     (match b with
      | Address _ -> true
      | _ -> false)
  | Pointer _ ->
     (match b with
      | Pointer _ -> true
      | _ -> true)
  | FnPtr _ ->
     (match b with
      | FnPtr _ -> true
      | _ -> false)
  | MonoTy _ ->
     internal_err "Not allowed"

(* Hilde: this check used to run against the instances of ONE module
   (lib/ExtractionPass.ml passed `module_instances env mod_id`), so a second
   instance for a type that already had one in another module went through.
   lib/TypeMatch.ml resolves a method by filtering the visible instances and
   calls internal_err when more than one matches, an assumption that only
   holds if uniqueness is program-wide.  It is now. *)
let check_instance_unique_in_program (env: env) (mod_id: mod_id) (instances: decl list) (argument: ty): unit =
  let pred (decl: decl): bool =
    match decl with
    | Instance { argument=argument'; _ } ->
       overlapping_instances argument argument'
    | _ ->
       false
  in
  match List.find_opt pred instances with
  | Some (Instance { mod_id=other_mod_id; _ }) ->
     TypeErrors.overlapping_instances
       ~existing:(mod_name_string (module_name_from_id env other_mod_id))
       ~added:(mod_name_string (module_name_from_id env mod_id))
       ~ty:argument
  | Some _ ->
     internal_err "An instance predicate matched a declaration that is not an instance."
  | None ->
     ()

let rec check_instance_orphan_rules (env: env) (mod_id: mod_id) (typeclass_mod_id: mod_id) (ty: ty): unit =
  let tc_local: bool = equal_mod_id mod_id typeclass_mod_id
  and ty_local: bool = is_type_local env mod_id ty
  in
  if (not tc_local) && (not ty_local) then
    begin
      (* Hilde: the same fourth case, but say which kind of foreign it is.
         A reader who wrote `instance TrappingNegation(Nat8)` does not
         think of Nat8 as foreign, and "both foreign" leaves them looking
         for the module Nat8 came from. *)
      if is_builtin_type ty then
        TypeErrors.instance_for_builtin_type ty
      else
        Errors.broken_orphan_rule ()
    end
  else
    ()

(** The types the language itself owns: the ones that exist without any
    module declaring them. *)
and is_builtin_type (ty: ty): bool =
  match ty with
  | Unit | Never | Boolean | Integer _ | SingleFloat | DoubleFloat ->
     true
  | _ ->
     false

(** The modules the compiler injects, lib/BuiltIn.ml. *)
and is_builtin_module (env: env) (mod_id: mod_id): bool =
  let name: module_name = module_name_from_id env mod_id in
  (equal_module_name name pervasive_module_name)
  || (equal_module_name name memory_module_name)

and is_type_local (env: env) (mod_id: mod_id) (ty: ty): bool =
  match ty with
  | Unit | Never | Boolean | Integer _ | SingleFloat | DoubleFloat ->
     (* Hilde: these five used to be local in EVERY module, so any module
        could give any built-in type an instance of any foreign typeclass
        -- the orphan rule never saw a fourth case for them.  A built-in
        type belongs to the language, so it is local only where the
        language declares it. *)
     is_builtin_module env mod_id
  | NamedType (name, _, _) ->
     let type_mod_id: mod_id = decl_mod_id (get_decl_by_name_or_die env (qident_to_sident name)) in
     equal_mod_id mod_id type_mod_id
  | RegionTy _ ->
     (* Not applicable. *)
     false
  | ReadRef _ ->
     true
  | WriteRef _ ->
     true
  | Span _ ->
     true
  | SpanMut _ ->
     true
  | TyVar _ ->
     (* Not applicable. *)
     false
  | Address _ ->
     true
  | Pointer _ ->
     true
  | FnPtr _ ->
     true
  | MonoTy _ ->
     (* Not applicable. *)
     false

let check_disjoint_typarams (name: identifier) (typarams: typarams): unit =
  match get_typaram typarams name with
  | Some _ ->
     Errors.shadowing_typeclass_param name
  | None ->
     (* No collision *)
     ()
