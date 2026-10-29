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
open TypeBindings
open TypeParameter
open TypeParameters
open Stages.Tast
open TastUtil
open Env
open EnvTypes
open EnvExtras
open Reporter
open Error
open ErrorText

module Errors = struct
  let type_mismatch a b =
    hilde_raise (H 3060) TypeError [
      Text "Expected a value of type ";
      Type a;
      Text ", but got a value of type ";
      Type b;
      Text "."
    ]

  (* elsewhere is the module of an instance that would match but is not
     visible from the module being checked: an instance is visible where a
     name of its module is imported. *)
  let unsatisfied_constraint (tv: type_var) (ty: ty) (constraint_typeclass_name: sident) (elsewhere: module_name option) =
    let (TypeVariable (tv_name, _, _, _)) = tv in
    let tc: string = ident_string (sident_name constraint_typeclass_name) in
    hilde_raise (H 3061) TypeError ([
        Text "Type constraint not satisfied: the type ";
        Type ty;
        Text " does not implement the typeclass ";
        Code tc;
        Text ".";
        Break;
        Text "This constraint is for the type variable ";
        Code (ident_string tv_name);
        Text "."
    ] @ (match elsewhere with
         | Some mn -> [
             Break;
             Text "An instance of ";
             Code tc;
             Text " for this type is declared in the module ";
             Code (mod_name_string mn);
             Text ", and an instance is visible only where a name of its module is imported. Import one, as in ";
             Code ("import " ^ (mod_name_string mn) ^ " (" ^ tc ^ ");");
             Text "."
           ]
         | None -> []))

  (* A constraint names a typeclass that the module does not import. *)
  (* home is the module that declares a typeclass of that name, when one
     does. *)
  let typeclass_not_imported (name: sident) (home: module_name option) =
    let tc: string = ident_string (sident_name name) in
    hilde_raise (H 3105) TypeError ([
        Text "The typeclass ";
        Code tc;
        Text " of a constraint is not imported here. A module, its interface too, imports every typeclass its constraints name"
      ] @ (match home with
           | Some mn -> [
               Text ", as in ";
               Code ("import " ^ (mod_name_string mn) ^ " (" ^ tc ^ ");");
               Text "."
             ]
           | None -> [Text "."]))
end

type ctx = env * module_name

let ctx_env (env, _) = env

let ctx_mn (_, mn) = mn

let rec match_type (ctx: ctx) (a: ty) (b: ty): type_bindings =
  pt ("A", a);
  pt ("B", b);
  (* An expression of type Never does not come back, so it stands where
     any value is expected, and binds no type variable: Never is never the
     argument of a type. *)
  match b with
  | Never ->
     empty_bindings
  | _ ->
  match a with
  | Never ->
     Errors.type_mismatch a b
  | Unit ->
     (match b with
      | Unit ->
         empty_bindings
      | _ ->
         Errors.type_mismatch a b)
  | Boolean ->
     (match b with
      | Boolean ->
         empty_bindings
      | _ ->
         Errors.type_mismatch a b)
  | Integer (s, w) ->
     (match b with
      | Integer (s', w') ->
         if (s = s') && (w = w') then
           empty_bindings
         else
           Errors.type_mismatch a b
      | _ ->
         Errors.type_mismatch a b)
  | SingleFloat ->
     (match b with
      | SingleFloat ->
         empty_bindings
      | _ ->
         Errors.type_mismatch a b)
  | DoubleFloat ->
     (match b with
      | DoubleFloat ->
         empty_bindings
      | _ ->
         Errors.type_mismatch a b)
  | NamedType (n, args, _) ->
     (match b with
      | NamedType (n', args', _) ->
         (* We ignore the universe, since the type system is nominal.  The
            names are compared by module and original name (equal_qident),
            not with `=': a qident carries the LOCAL name too, and a type
            imported under a nickname (`Regex as RegexLinear') would
            otherwise never match itself under its own name.  Upstream
            compares with `='; docs/differences-from-austral.md. *)
         if equal_qident n n' then
           match_type_list ctx args args'
         else
           Errors.type_mismatch a b
      | _ ->
         Errors.type_mismatch a b)
  | RegionTy r ->
     (match b with
      | RegionTy r' ->
         if r = r' then
           empty_bindings
         else
           Errors.type_mismatch a b
      | _ ->
         Errors.type_mismatch a b)
  | ReadRef (t, r) ->
     (match b with
      | ReadRef (t', r') ->
         let bindings = match_type ctx t t' in
         let bindings' = match_type ctx r r' in
         merge_bindings bindings bindings'
      | _ ->
         Errors.type_mismatch a b)
  | WriteRef (t, r) ->
     (match b with
      | WriteRef (t', r') ->
         let bindings = match_type ctx t t' in
         let bindings' = match_type ctx r r' in
         merge_bindings bindings bindings'
      | _ ->
         Errors.type_mismatch a b)
  | Span (t, r) ->
     (match b with
      | Span (t', r') ->
         let bindings = match_type ctx t t' in
         let bindings' = match_type ctx r r' in
         merge_bindings bindings bindings'
      | _ ->
         Errors.type_mismatch a b)
  | SpanMut (t, r) ->
     (match b with
      | SpanMut (t', r') ->
         let bindings = match_type ctx t t' in
         let bindings' = match_type ctx r r' in
         merge_bindings bindings bindings'
      | _ ->
         Errors.type_mismatch a b)
  | TyVar tyvar ->
     match_type_var ctx tyvar b
  | Address t ->
     (match b with
      | Address t' ->
         match_type ctx t t'
      | _ ->
         Errors.type_mismatch a b)
  | Pointer t ->
     (match b with
      | Pointer t' ->
         match_type ctx t t'
      | _ ->
         Errors.type_mismatch a b)
  | FnPtr (args, rt) ->
     (match b with
      | FnPtr (args', rt') ->
         match_type_list ctx (rt :: args) (rt' :: args')
      | _ ->
         Errors.type_mismatch a b)
  | MonoTy _ ->
     internal_err "match_type called with MonoTy argument"

and match_type_var (ctx: ctx) (tv: type_var) (ty: ty): type_bindings =
  let (TypeVariable (name, universe, from, constraints)) = tv in
  (* Check if the argument type is a variable. *)
  match ty with
  | (TyVar (TypeVariable (i', u', from', constraints'))) ->
     (* When the argument type is a type variable, check if the variables have
        the same name and provenance. *)
     if (equal_identifier name i') && (universe = u') && (equal_qident from from') then
       (* If so, the parameter is bound to itself.  Upstream returned no
          binding here ("we don't want circular bindings"), and that left the
          parameter unbound: a generic function that calls itself passes its
          own `T' back as `T', and check_bindings then refused the call with
          "No binding for this parameter" -- as for the regex compiler of
          Standard.Regex, whose tree walk recurses over a region
          parameter.  The binding is not circular in any way that matters:
          replace_variables applies bindings in one pass, so T := T is the
          identity. *)
       add_binding empty_bindings (tyvar_to_typaram tv) ty
     else
       (* Check that the tyvar implements the type variable's constraints, if any. *)
       let _ = check_tyvar_implements_constraints constraints constraints' in
       (* Otherwise, add a new binding.

          The idea here is: suppose we have a function `f` that accepts an
          argument of a generic type `T`. Now we're type-checking a function `g`
          that accepts an argument `x` of generic type `U`. If we encounter a
          function call `f(x)`, then the parameter type is `T` and the argument
          type is `U`, so we create a binding `T -> U`.  *)
       add_binding empty_bindings (tyvar_to_typaram tv) ty
  | _ ->
     (* Check that the type implements the type variable's constraints, if any. *)
     check_type_implements_constraints ctx tv ty constraints;
     (* If the constraints are satisfied, add a straightforward binding. *)
     add_binding empty_bindings (tyvar_to_typaram tv) ty

and check_tyvar_implements_constraints (param: sident list) (arg: sident list): bool =
  (* Check that the param is a subset of the param. *)
  let param: SIdentSet.t = SIdentSet.of_list param
  and arg: SIdentSet.t = SIdentSet.of_list arg
  in
  SIdentSet.subset param arg

and check_type_implements_constraints (ctx: ctx) (tv: type_var) (ty: ty) (constraints: sident list): unit =
  with_frame "Check type implements constraints"
    (fun _ ->
      pt ("Type", ty);
      ps ("Constraints", "[" ^ (String.concat ", " (List.map show_sident constraints)) ^ "]");
      (* If there are no constraints, do nothing. *)
      if constraints = [] then
        ()
      else
        (* If there are constraints, make them into a set. *)
        let constraints: SIdentSet.t = SIdentSet.of_list constraints in
        (* Try to find an instance for this type for each of the constraints. *)
        List.iter (try_constraint ctx tv ty) (List.of_seq (SIdentSet.to_seq constraints)))

and try_constraint (ctx: ctx) (tv: type_var) (ty: ty) (typeclass_name: sident): unit =
  (* Find the typeclass. *)
  match get_decl_by_name (ctx_env ctx) typeclass_name with
  | Some (TypeClass { id; _ }) ->
     (* Try to find an instance for the given typeclass name that implements this type. *)
     (match get_instance (ctx_env ctx) (ctx_mn ctx) ty id with
      | Some _ ->
         ()
      | None ->
         let elsewhere: module_name option =
           try
             (match get_instance_anywhere (ctx_env ctx) (ctx_mn ctx) ty id with
              | Some (Instance { mod_id; _ }, _) -> Some (module_name_from_id (ctx_env ctx) mod_id)
              | _ -> None)
           with Hilde_error _ -> None
         in
         Errors.unsatisfied_constraint tv ty typeclass_name elsewhere)
  | Some _ ->
     internal_err "Type parameter constraint refers to a declaration which is not a typeclass."
  | None ->
     let home: module_name option =
       match modules_with_typeclass (ctx_env ctx) (sident_name typeclass_name) with
       | m :: _ -> Some (module_name_from_id (ctx_env ctx) m)
       | [] -> None
     in
     Errors.typeclass_not_imported typeclass_name home

and get_instance (env: env) (source_module_name: module_name) (dispatch_ty: ty) (typeclass: decl_id): (decl * type_bindings) option =
  let mod_id: mod_id =
    let (ModRec { id; _ }) = Option.get (get_module_by_name env source_module_name) in
    id
  in
  instance_among env source_module_name dispatch_ty typeclass (visible_instances env mod_id)

(* Hilde: the same search over every instance of the program, for the
   monomorphizer (Monomorphize.unmono_type). *)
and get_instance_anywhere (env: env) (source_module_name: module_name) (dispatch_ty: ty) (typeclass: decl_id): (decl * type_bindings) option =
  instance_among env source_module_name dispatch_ty typeclass (all_instances env)

and instance_among (env: env) (source_module_name: module_name) (dispatch_ty: ty) (typeclass: decl_id) (candidates: decl list): (decl * type_bindings) option =
  with_frame "Typeclass Resolution"
    (fun _ ->
      ps ("In module", (mod_name_string source_module_name));
      ps ("Typeclass", (get_decl_name_or_die env typeclass));
      pt ("Dispatch type", dispatch_ty);
      let pred (decl: decl): (decl * type_bindings) option =
        match decl with
        | Instance { typeclass_id; argument; _ } ->
           if equal_decl_id typeclass_id typeclass then
             let _ = pt ("Trying instance with argument", argument) in
             try
               let bindings = match_type (env, source_module_name) argument dispatch_ty in
               ps ("Resolution", "Success");
               Some (decl, bindings)
             with
               Hilde_error _ ->
               (* Does not match, just skip to the next instance, *)
               ps ("Resolution", "Failure");
               None
           else
             None
        | _ ->
           None
      in
      let filtered: (decl * type_bindings) list =
        with_frame "Filtering instances"
          (fun _ -> List.filter_map pred candidates)
      in
      match filtered with
      | [a] ->
         Some a
      | _::_ ->
         internal_err "Multiple instances satisfy this call. The compiler should validate that there are no overlapping instances."
      | [] ->
         None)

and match_type_list ctx tys tys' =
  let bs = List.map2 (match_type ctx) tys tys' in
  List.fold_left merge_bindings empty_bindings bs

let match_typarams (ctx: ctx) (typarams: typarams) (args: ty list): type_bindings =
  let typarams' = List.map (fun tp -> TyVar (typaram_to_tyvar tp)) (typarams_as_list typarams) in
  match_type_list ctx typarams' args

let parse_bigint (s: string): Z.t =
  try
    Z.of_string s
  with
    | Invalid_argument _ ->
      internal_err ("Failed to parse '" ^ s ^ "' as a big int. This is a bug in the parser.")

(* Check the given value fits in the given type.

   WidthByteSize has the bounds of `size_t' here, which lib/CodeGen.ml
   renders it as.  Austral's table gives it the bounds of a BYTE -- 0 to
   255 unsigned -- so every ByteSize literal above 255 is refused there,
   `sizeof' returns a ByteSize, and a capacity of 4096 cannot be written
   down; the name is the trap, "byte size" read as "size of a byte". *)
(* The values of an integer type, both ends included.  One table for the
   literal check below and for the patterns of a case.  ByteSize and Index
   are size_t and ssize_t: 32 bits on wasm32, 64 bits on the other targets,
   so a literal that does not fit the target's size_t is refused there
   instead of being cut by the C compiler. *)
let int_bounds (signed : signedness) (width : integer_width) : Z.t * Z.t =
  let narrow: bool = Util.current_target () = "wasm" in
  match signed, width with
    | Unsigned, (WidthByteSize | WidthIndex) when narrow -> (Z.zero, Z.of_string "4294967295")
    | Signed, (WidthByteSize | WidthIndex) when narrow -> (Z.of_string "-2147483648", Z.of_string "2147483647")
    | Unsigned, Width8        -> (Z.zero, Z.of_string "255")
    | Unsigned, Width16       -> (Z.zero, Z.of_string "65535")
    | Unsigned, Width32       -> (Z.zero, Z.of_string "4294967295")
    | Unsigned, Width64       -> (Z.zero, Z.of_string "18446744073709551615")
    | Unsigned, WidthByteSize -> (Z.zero, Z.of_string "18446744073709551615")
    | Unsigned, WidthIndex    -> (Z.zero, Z.of_string "18446744073709551615")
    | Signed, Width8          -> (Z.of_string "-128", Z.of_string "127")
    | Signed, Width16         -> (Z.of_string "-32768", Z.of_string "32767")
    | Signed, Width32         -> (Z.of_string "-2147483648", Z.of_string "2147483647")
    | Signed, Width64         -> (Z.of_string "-9223372036854775808", Z.of_string "9223372036854775807")
    | Signed, WidthByteSize   -> (Z.of_string "-9223372036854775808", Z.of_string "9223372036854775807")
    | Signed, WidthIndex      -> (Z.of_string "-9223372036854775808", Z.of_string "9223372036854775807")

let fits (signed : signedness) (width : integer_width) (n : Z.t) : bool =
  let min_bound, max_bound = int_bounds signed width in
  Z.compare min_bound n <= 0 && Z.compare n max_bound <= 0

let match_int_type_with_value (signedness: signedness) (width: integer_width) (value: string): type_bindings =
   (* Parse the constant as a big integer. *)
   let i: Z.t = parse_bigint value in
   (* Check that it fits *)
   if fits signedness width i then
      empty_bindings
   else
      hilde_raise (H 3062) TypeError [
         Text "The integer ";
         Code value;
         Text" does not fit the type ";
         Type (Integer (signedness, width));
         Text "."
      ]

let match_type_with_value (ctx: ctx) (ty: ty) (expr: texpr): type_bindings =
  (* Like type_match, but gentler with integer constants. *)
  match ty with
  | Integer (signedness, width) ->
     (match expr with
      | TIntConstant value ->
         match_int_type_with_value signedness width value
      | TCast (TIntConstant value, _) ->
         match_int_type_with_value signedness width value
      | _ ->
         match_type ctx ty (get_type expr))
  | SingleFloat ->
     (match expr with
      | TFloatConstant _ ->
         empty_bindings
      | TCast (TFloatConstant _, _) ->
         empty_bindings
      | _ ->
         match_type ctx ty (get_type expr))
  | DoubleFloat ->
     (match expr with
      | TFloatConstant _ ->
         empty_bindings
      | TCast (TFloatConstant _, _) ->
         empty_bindings
      | _ ->
         match_type ctx ty (get_type expr))
  | _ ->
     match_type ctx ty (get_type expr)
