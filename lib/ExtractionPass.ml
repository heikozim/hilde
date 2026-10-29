(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open ModuleNameSet
open Common
open Type
open TypeSystem
open Stages.SmallCombined
open Stages
open Linked
open Stages.AstDB
open Id
open DeclIdSet
open ModIdSet
open Env
open EnvTypes
open Imports
open TypeParser
open TypeSignature
open TypeParameter
open TypeParameters
open TypeClasses
open RegionMap
open BuiltIn
open TypeVarSet
open Util
open Error

module Errors = struct
  let export_generic name =
    hilde_raise (H 2018) DeclarationError [
      Text "The function ";
      Code (ident_string name);
      Text " cannot be exported because it is generic over a type.";
      Break;
      Text "An exported function may be generic over regions only: a region has nothing to pass at run time."
    ]

  let export_name name (export: string) (why: string) =
    hilde_raise (H 2050) DeclarationError [
      Text "The function ";
      Code (ident_string name);
      Text " cannot be exported under the name ";
      Code export;
      Text (": " ^ why)
    ]

  let foreign_import_export name =
    internal_raise [
      Text "The function ";
      Code (ident_string name);
      Text " cannot have both the ";
      Code "Foreign_Import";
      Text " and ";
      Code "Foreign_Export";
      Text " pragmas simultaneously."
    ]

  let free_contains_linear ~name ~universe ~parameter =
    hilde_raise (H 4001) LinearityError [
      Code (ident_string name);
      Text " was declared to belong to the ";
      Code "Free";
      Text " universe, but it ";
      Text (if parameter then "has a type parameter" else "contains a type");
      Text " that belongs to the ";
      Code universe;
      Text " universe."
    ]

  let instance_for_non_typeclass name =
    hilde_raise (H 2020) DeclarationError [
      Text "Cannot create an instance for ";
      Code (ident_string name);
      Text " because it is not a typeclass."
    ]

  let typeclass_no_method ~typeclass ~method_name =
    hilde_raise (H 2021) DeclarationError [
      Text "The typeclass ";
      Code (ident_string typeclass);
      Text " has no method named ";
      Code (ident_string method_name)
    ]

  (* The other direction, which Austral does not check: an instance
     that leaves a method out.  Without this check it is caught nowhere
     else either -- it surfaces at monomorphisation, and only if
     something called the missing method, as
     "Internal compiler error: Couldn't find instance method ... This is a
     bug in the compiler."  `instance Printable(Unit)' in
     lib/builtin/Pervasive.hiq was such an instance, and
     `print' on a Span of Unit was that crash. *)
  let instance_missing_methods ~typeclass ~argument ~missing =
    hilde_raise (H 2022) DeclarationError [
      Text "The instance ";
      Code ((ident_string typeclass) ^ "(" ^ argument ^ ")");
      Text " does not implement every method of the typeclass.";
      Break;
      Text "Missing: ";
      Code (String.concat ", " (List.map ident_string missing));
      Text ".";
      Break;
      Text ("An instance has to implement every method the typeclass declares, "
            ^ "even one whose body does nothing: a method that is simply "
            ^ "absent cannot be reported at the call site, only much later "
            ^ "and as an internal error.")
    ]

  let typeclass_param_not_region name =
    hilde_raise (H 2023) DeclarationError [
      Text "The parameter for the typeclass ";
      Code (ident_string name);
      Text " cannot be declared to be in the ";
      Code "Region";
      Text " universe, because regions are distinct from types.";
      Break;
      Text "Consider using one of ";
      Code "Type";
      Text ", ";
      Code "Linear";
      Text ", or ";
      Code "Free";
      Text " instead.";
    ]

  let types_are_not_regions ~name ~declaration =
    hilde_raise (H 2024) DeclarationError [
      Text "The ";
      Text declaration;
      Text " ";
      Code (ident_string name);
      Text " was declared to belong to the ";
      Code "Region";
      Text " universe, but regions are distinct from types.";
      Break;
      Text "Consider using one of ";
      Code "Type";
      Text ", ";
      Code "Linear";
      Text ", or ";
      Code "Free";
      Text " instead.";
    ]

  let unknown_typeclass name =
    hilde_raise (H 2025) DeclarationError [
      Text "Cannot find typeclass with the name ";
      Code (ident_string name)
      ]

  let typaram_not_in_signature (tp: type_parameter) =
    hilde_raise (H 2026) DeclarationError [
        Text "The type parameter ";
        Code (ident_string (typaram_name tp));
        Text " does not appear anywhere in the signature of the function."
      ]
end

(* An export name is the name of a C function: a letter or an
   underscore, then letters, digits and underscores. *)
let is_c_identifier (s: string): bool =
  let first c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_' in
  let rest c = first c || (c >= '0' && c <= '9') in
  String.length s > 0 && first s.[0] && String.for_all rest s

(* The keywords of C17, which no function can be named, and main, which a
   programme's entrypoint defines. *)
let c_reserved_names: string list = [
    "auto"; "break"; "case"; "char"; "const"; "continue"; "default"; "do";
    "double"; "else"; "enum"; "extern"; "float"; "for"; "goto"; "if"; "inline";
    "int"; "long"; "register"; "restrict"; "return"; "short"; "signed";
    "sizeof"; "static"; "struct"; "switch"; "typedef"; "union"; "unsigned";
    "void"; "volatile"; "while"; "_Alignas"; "_Alignof"; "_Atomic"; "_Bool";
    "_Complex"; "_Generic"; "_Imaginary"; "_Noreturn"; "_Static_assert";
    "_Thread_local"; "main"
  ]

let check_slots_are_free (name: identifier) (slots: typed_slot list): unit =
  let check_slot_is_free (slot: typed_slot): unit =
    let (TypedSlot (_, ty)) = slot in
    match type_universe ty with
    | FreeUniverse ->
       ()
    | RegionUniverse ->
       ()
    | LinearUniverse ->
        Errors.free_contains_linear ~name ~universe:"Linear" ~parameter:false
    | TypeUniverse ->
        Errors.free_contains_linear ~name ~universe:"Type" ~parameter:false
  in
  List.iter check_slot_is_free slots

let check_cases_are_free (cases: typed_case list): unit =
  let check_case_is_free (case: typed_case): unit =
    let (TypedCase (name, slots)) = case in
    check_slots_are_free name slots
  in
  List.iter check_case_is_free cases

let check_typarams_are_free (name: identifier) (typarams: typarams): unit =
  let check_universe (u: universe) =
    match u with
    | FreeUniverse ->
       ()
    | RegionUniverse ->
       ()
    | LinearUniverse ->
       Errors.free_contains_linear ~name ~universe:"Linear" ~parameter:true
    | TypeUniverse ->
       Errors.free_contains_linear ~name ~universe:"Type" ~parameter:true
  in
  List.iter (fun tp -> check_universe (typaram_universe tp)) (typarams_as_list typarams)

let check_all_type_parameters_appear_in_signature (typarams: typarams) (params: value_parameter list) (rt: ty): unit =
  (* Get the type variables from the value parameter list. *)
  let param_tyvars: TypeVarSet.t list = List.map (fun (ValueParameter (_, ty)) -> type_variables ty) params in
  let param_tyvars: TypeVarSet.t = List.fold_left TypeVarSet.union TypeVarSet.empty param_tyvars in
  (* Get the type variables from the return type. *)
  let rt_tyvars: TypeVarSet.t = type_variables rt in
  (* Merge them to get the type variables in the signature. *)
  let signature_tyvars: TypeVarSet.t = TypeVarSet.union param_tyvars rt_tyvars in
  (* Go through each of the type parameters, and assert that it is in `singature_tyvars`. *)
  let check_typaram (tp: type_parameter): unit =
    let tv: type_var = typaram_to_tyvar tp in
    if TypeVarSet.mem tv signature_tyvars then
      ()
    else
      Errors.typaram_not_in_signature tp
  in
  List.iter check_typaram (typarams_as_list typarams)

let rec extract_type_signatures (CombinedModule { decls; _ }): type_signature list =
  List.filter_map extract_type_signatures' decls

and extract_type_signatures' (def: combined_definition): type_signature option =
  match def with
  | CConstant _ ->
     None
  | CRecord (_, _, name, typarams, universe, _, _) ->
     Some (TypeSignature (name, typarams, universe))
  | CUnion (_, _, name, typarams, universe, _, _) ->
     Some (TypeSignature (name, typarams, universe))
  | CFunction _ ->
     None
  | CTypeclass _ ->
     None
  | CInstance _ ->
     None

let rec extract (env: env) (cmodule: combined_module) (interface_file: file_id option) (body_file: file_id): (env * linked_module) =
  let (CombinedModule {
           name;
           kind;
           interface_docstring;
           interface_imports;
           body_docstring;
           body_imports;
           decls;
           _
      }) = cmodule in
  (* Find the set of modules we're importing from. *)
  let imports_from: ModIdSet.t =
    let module_names: ModuleNameSet.t =
      ModuleNameSet.union
        (modules_imported_from interface_imports)
        (modules_imported_from body_imports)
    in
    ModIdSet.of_list
      (List.map (fun mn ->
           match get_module_by_name env mn with
           | Some (ModRec { id; _ }) -> id
           | None -> internal_err ("Couldn't find module `" ^ (mod_name_string mn) ^ "`."))
         (List.of_seq (ModuleNameSet.to_seq module_names)))
  in
  (* Add the module to the environment. *)
  let imported_instances: DeclIdSet.t =
    DeclIdSet.union
      (DeclIdSet.of_list (imported_instances interface_imports))
      (DeclIdSet.of_list (imported_instances body_imports))
  in
  let input: mod_input = {
      name;
      interface_file;
      interface_docstring;
      body_file;
      body_docstring;
      kind;
      imported_instances;
      imports_from;
    }
  in
  let (env, mod_id) = add_module env input in
  (* Extract the list of local type signatures. This lets us parse type
     specifiers without reference to the environment. *)
  let sigs: type_signature list = extract_type_signatures cmodule in
  (* Extract all declarations from the module into the environment. *)
  let (env, linked_defs): (env * linked_definition list) = extract_definitions env mod_id name sigs decls in
  (* Construct the linked module *)
  let lmod = LinkedModule {
                 mod_id = mod_id;
                 name = name;
                 kind = kind;
                 interface_docstring = interface_docstring;
                 interface_imports = interface_imports;
                 body_docstring = body_docstring;
                 body_imports = body_imports;
                 decls = linked_defs
               }
  in
  (env, lmod)

(** Given the environment, the ID of the module we're extracting, the list of
    local type signatures, and a list of combined definitions, add all relevant
    decls to the environment, and return all corresponding linked decls. *)
and extract_definitions (env: env) (mod_id: mod_id) (mn: module_name) (local_types: type_signature list) (defs: combined_definition list): (env * (linked_definition list)) =
  let f ((env, comb_def): (env * combined_definition)): (env * linked_definition) =
    extract_definition env mod_id mn local_types comb_def
  in
  map_with_context f env defs

(** Given the environment, the ID of the module we're extracting, the list of
    local type signatures, and a combined definition, add all relevant decls to
    the environment, and return a linked definition. *)
and extract_definition (env: env) (mod_id: mod_id) (mn: module_name) (local_types: type_signature list) (def: combined_definition): (env * linked_definition)  =
  let rm = empty_region_map in
  let parse' = parse_type env local_types in
  let rec parse_slot (typarams: typarams) (Combined.QualifiedSlot (n, ts)): typed_slot =
    TypedSlot (n, parse' rm typarams ts)
  and parse_param (typarams: typarams) (Combined.QualifiedParameter (n, ts)): value_parameter =
    ValueParameter (n, parse' rm typarams ts)
  in
  match def with
  | CConstant (span, vis, name, typespec, def, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         let ty = parse' rm empty_typarams typespec in
         let (env, decl_id) = add_constant env { mod_id; vis; name; ty; docstring } in
         let decl = LConstant (decl_id, vis, name, ty, def, docstring) in
         (env, decl))
  | CRecord (span, vis, name, typarams, universe, slots, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         let slots = List.map (parse_slot typarams) slots in
         (* If the universe is `Free`, check that there are no slots with types in the `Type` or `Linear` universes. *)
         let _ =
           if universe = FreeUniverse then
             check_slots_are_free name slots
           else
             ()
         in
         (* If the universe is `Free`, check that there are no type parameters in
            the `Linear` or `Type` universes. *)
         let _ =
           if universe = FreeUniverse then
             (* Unless it is `Address` or `Pointer` *)
             let qname = make_qident (mn, name, name) in
             if (is_address_type qname) || (is_pointer_type qname) then
               ()
             else
               check_typarams_are_free name typarams
           else
             ()
         in
         (* If the universe is `Region`, fail. *)
         let _ =
           if universe = RegionUniverse then
             Errors.types_are_not_regions ~name ~declaration:"record"
           else
             ()
         in
         let (env, decl_id) = add_record env { mod_id; vis; name; docstring; typarams; universe; slots } in
         let decl = LRecord (decl_id, vis, name, typarams, universe, slots, docstring) in
         (env, decl))
  | CUnion (span, vis, name, typarams, universe, cases, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         (* If the universe is `Free`, check that there are no cases with slots with types in the `Type` or `Linear` universes. *)
         let _ =
           if universe = FreeUniverse then
             let cases = List.map (fun (Combined.QualifiedCase (n, slots)) -> TypedCase (n, List.map (parse_slot typarams) slots)) cases
             in
             check_cases_are_free cases
           else
             ()
         in
         (* If the universe is `Free`, check that there are no type parameters in
            the `Linear` or `Type` universes. *)
         let _ =
           if universe = FreeUniverse then
             check_typarams_are_free name typarams
           else
             ()
         in
         (* If the universe is `Region`, fail. *)
         let _ =
           if universe = RegionUniverse then
             Errors.types_are_not_regions ~name ~declaration:"union"
           else
             ()
         in
         (* Add the union itself to the env *)
         let (env, union_id) = add_union env { mod_id; vis; name; docstring; typarams; universe } in
         (* If the union is public, the cases are public, otherwise they are private. *)
         let case_vis: vis =
           match vis with
           | TypeVisPublic -> VisPublic
           | TypeVisOpaque -> VisPrivate
           | TypeVisPrivate -> VisPrivate
         in
         (* Convert the list of cases into a list of union_case_input records *)
         let case_map (Combined.QualifiedCase (n, slots)): union_case_input =
           let docstring = Docstring "" in (* TODO: Store docstrings in slots and cases *)
           {
             mod_id = mod_id;
             vis = case_vis;
             union_id = union_id;
             name = n;
             slots = List.map (parse_slot typarams) slots;
             docstring = docstring;
           }
         in
         let cases: union_case_input list = List.map case_map cases in
         (* Add the union cases to the environmenmt *)
         let (env, linked_cases) = add_union_cases env cases in
         (* Construct the decl *)
         let decl = LUnion (union_id, vis, name, typarams, universe, linked_cases, docstring) in
         (env, decl))
  | CFunction (span, vis, name, typarams, params, rt, body, docstring, raises, pragmas) ->
     adorn_error_with_span span
       (fun _ ->
         let value_params = List.map (parse_param typarams) params
         and rt = parse' rm typarams rt
         and external_name: string option =
           (match pragmas with
            | [ForeignImportPragma s] ->
               Some s
            | _ ->
               None)
         and export_name: string option =
           (match pragmas with
            | [ForeignExportPragma name] ->
               Some name
            | _ ->
               None)
         in
         let _ =
           (* Check: if we have both an export name and an external name, raise an error. *)
           match (external_name, export_name) with
           | (Some _, Some _) ->
              Errors.foreign_import_export name
           | _ ->
              ()
         in
         let _ =
           (* Check: an exported function may be generic over regions only,
              and its export name is a C identifier that is no keyword of
              C, not main, not a name of the runtime's and no other
              export's. *)
           match export_name with
           | Some export ->
              if List.exists
                   (fun tp -> not (equal_universe (typaram_universe tp) RegionUniverse))
                   (typarams_as_list typarams) then
                Errors.export_generic name
              else if not (is_c_identifier export) then
                Errors.export_name name export
                  "an export name is a C identifier, a letter or an underscore followed by letters, digits and underscores."
              else if List.mem export c_reserved_names then
                Errors.export_name name export "it is a keyword of C or the name of a programme's main function."
              else if String.length export >= 6 && String.sub export 0 6 = "hilde_" then
                Errors.export_name name export "names beginning with hilde_ belong to the runtime."
              else if List.exists (fun (_, n) -> n = export) (get_export_functions env) then
                Errors.export_name name export "another function is exported under it already."
              else
                ()
           | None ->
              ()
         in
         let _ =
           (* Check: all type parameters must appear in the type signature. *)
           check_all_type_parameters_appear_in_signature typarams value_params rt
         in
         let fn_input: function_input = {
             mod_id = mod_id;
             vis = vis;
             name = name;
             docstring = docstring;
             typarams = typarams;
             value_params = value_params;
             rt = rt;
             external_name = external_name;
             raises = raises;
             body = None
           }
         in
         let (env, decl_id) = add_function env fn_input in
         (* The one place a span and a declaration id
            are both in hand.  Everything after this drops the span. *)
         let () = DeclSpans.record_decl decl_id span in
         let env =
           (* If the function has an export name, register it in the environment. *)
           match export_name with
           | Some name ->
              add_exported_function env decl_id name
           | None ->
              env
         in
         let decl = LFunction (decl_id, vis, name, typarams, value_params, rt, body, docstring, raises, pragmas) in
         (env, decl))
  | CTypeclass (span, vis, name, typaram, methods, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         (* Check: the universe is one of {Type, Linear, Free} *)
         let _ =
           match typaram_universe typaram with
           | TypeUniverse -> ()
           | LinearUniverse -> ()
           | FreeUniverse -> ()
           | RegionUniverse ->
              Errors.typeclass_param_not_region name
         in
         (* Add the typeclass itself to the env *)
         let (env, typeclass_id) = add_type_class env { mod_id; vis; name; docstring; param = typaram; } in
         (* Convert the list of methods into a list of type_class_method records *)
         let typarams = typarams_from_list [typaram] in
         let method_map (Combined.CMethodDecl (name, method_typarams, params, rt, docstring, raises)): type_class_method_input =
           let effective_typarams: typarams = merge_typarams typarams method_typarams in
           let value_params = List.map (parse_param effective_typarams) params
           and rt = parse' rm effective_typarams rt in
           {
             mod_id;
             vis;
             typeclass_id;
             name;
             docstring;
             typarams = method_typarams;
             value_params;
             rt;
             raises;
           }
         in
         let methods: type_class_method_input list = List.map method_map methods in
         (* Add the methods to the env *)
         let (env, linked_methods) = add_type_class_methods env methods in
         (* Construct the decl *)
         let decl = LTypeclass (typeclass_id, vis, name, typaram, linked_methods, docstring) in
         (env, decl))
  | CInstance (span, vis, name, typarams, argument, methods, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         let typeclass_name = qident_to_sident name |> sident_name in
         (* First add the instance to the env, then the methods. *)
         let argument = parse' rm typarams argument in
         (* Find typeclass info. *)
         let (typeclass_id, typeclass_mod_id, typeclass_param_name, universe): decl_id * mod_id * identifier * universe =
           match get_decl_by_name env (qident_to_sident name) with
           | Some decl ->
              (match decl with
               | TypeClass { id; mod_id; param; _ } ->
                  (id, mod_id, typaram_name param, typaram_universe param)
               | _ ->
                  Errors.instance_for_non_typeclass typeclass_name)
           | None ->
              Errors.unknown_typeclass typeclass_name
         in
         (* Check the argument has the right universe for the typeclass. *)
         let _ = check_instance_argument_has_right_universe universe argument in
         (* Check the argument has the right shape. *)
         let _ = check_instance_argument_has_right_shape typarams argument in
         (* Check that the non of the type parameters in the generic instance
            collide with the type parameter of the typeclass. *)
         let _ = check_disjoint_typarams typeclass_param_name typarams in
         (* Uniqueness: does this instance collide with an instance of the
            same typeclass anywhere in the PROGRAM?  Not only in this module
            -- see the comment on check_instance_unique_in_program. *)
         let _ =
           let other_instances: decl list =
             List.filter (fun decl ->
                 match decl with
                 | Instance { typeclass_id=typeclass_id'; _ } ->
                    equal_decl_id typeclass_id typeclass_id'
                 | _ -> false)
               (all_instances env)
           in
           check_instance_unique_in_program env mod_id other_instances argument
         in
         (* Global uniqueness: check orphan rules. *)
         let _ = check_instance_orphan_rules env mod_id typeclass_mod_id argument in
         (* Add the instance to the env *)
         let input: instance_input = { mod_id; vis; typeclass_id; docstring; typarams; argument } in
         let (env, instance_id) = add_instance env input in
         (* Convert the list of methods into a list of instance_method_input records *)
         let method_map (CMethodDef (name, method_typarams, params, rt, meth_docstring, body)): (instance_method_input * astmt) =
           let effective_typarams: typarams = merge_typarams typarams method_typarams in
           let value_params = List.map (parse_param effective_typarams) params
           and rt = parse' rm effective_typarams rt
           and method_id: decl_id =
             (match get_method_from_typeclass_id_and_name env typeclass_id name with
              | Some (TypeClassMethod { id; _ }) ->
                 id
              | _ ->
                 Errors.typeclass_no_method
                   ~typeclass:typeclass_name
                   ~method_name:name)
           in
           ({
               instance_id = instance_id;
               method_id = method_id;
               docstring = meth_docstring;
               name = name;
               typarams = method_typarams;
               value_params = value_params;
               rt = rt;
               body = None;
             },
            body)
         in
         let methods: (instance_method_input * astmt) list = List.map method_map methods in
         (* Completeness: every method the typeclass declares has to be here.
            The loop above checks the other direction only -- that each method
            GIVEN exists in the typeclass. *)
         let _ =
           let declared: identifier list =
             List.filter_map
               (fun d -> match d with
                         | TypeClassMethod { name; _ } -> Some name
                         | _ -> None)
               (get_methods_from_typeclass_id env typeclass_id)
           and implemented: identifier list =
             List.map (fun ((input: instance_method_input), _) -> input.name) methods
           in
           let missing =
             List.filter
               (fun n -> not (List.exists (equal_identifier n) implemented))
               declared
           in
           match missing with
           | [] -> ()
           | _ ->
              Errors.instance_missing_methods
                ~typeclass:typeclass_name
                ~argument:(type_string argument)
                ~missing
         in
         (* Add the methods to the env *)
         let (env, linked_methods) = add_instance_methods env methods in
         (* Construct the decl *)
         let decl = LInstance (instance_id, vis, name, typarams, argument, linked_methods, docstring) in
         (env, decl))

(** Utility functions to add lists of things to the environment. *)
and add_union_cases (env: env) (cases: union_case_input list): (env * (linked_case list)) =
  let f ((env, input): (env * union_case_input)): (env * linked_case) =
    let (env, decl_id) = add_union_case env input in
    let { name; slots; _ } = input in
    let case = LCase (decl_id, name, slots) in
    (env, case)
  in
  map_with_context f env cases

and add_type_class_methods (env: env) (cases: type_class_method_input list): (env * (linked_method_decl list)) =
  let f ((env, input): (env * type_class_method_input)): (env * linked_method_decl) =
    let (env, decl_id) = add_type_class_method env input in
    let { name; value_params; rt; docstring; vis; _ } = input in
    (* LOAD-BEARING HACK: need to destructure `vis` because otherwise the
       compiler thinks `input` is supposed to be an instance of
       `instance_method_input` (???). *)
    let _ = vis in
    let { raises; _ } = input in
    let decl = LMethodDecl (decl_id, name, value_params, rt, docstring, raises) in
    (env, decl)
  in
  map_with_context f env cases

and add_instance_methods (env: env) (cases: (instance_method_input * astmt) list): (env * (linked_method_def list)) =
  let f ((env, pair): (env * (instance_method_input * astmt))): (env * linked_method_def) =
    let (input, body) = pair in
    let (env, decl_id) = add_instance_method env input in
    let { name; value_params; rt; docstring; _ } = input in
    let decl = LMethodDef (decl_id, name, value_params, rt, docstring, body) in
    (env, decl)
  in
  map_with_context f env cases
