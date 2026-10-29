(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open Imports
open Qualifier
open TypeParameter
open TypeParameters
open AbstractionPass
open Cst
open CstUtil
open Stages.Combined
open Env
open ImportResolution
open Reporter
open Error

module Errors = struct
  let declaration_kind_mismatch ~name ~expected =
    hilde_raise (H 2001) DeclarationError [
      Text "The interface requires ";
      Code (ident_string name);
      Text " to be a ";
      Text expected
      ]

  type func_mismatch_msg =
    | DifferentTypeParameters
    | DifferentValueParameters
    | DifferentReturnTypes
    | Else

  let function_mismatch ~name ~msg =
    let message = match msg with
    | DifferentTypeParameters -> "have different type parameters."
    | DifferentValueParameters -> "have different parameters."
    | DifferentReturnTypes -> "have different return types"
    | Else -> "are different."
    in
    hilde_raise (H 2002) DeclarationError [
      Text "The interface declaration for ";
      Code (ident_string name);
      Text " and its implementation ";
      Text message
    ]

  let missing_body_definition ~name ~declaration =
    match declaration with
    | Some declaration ->
       internal_raise [
         Text "The ";
         Text declaration;
         Text " ";
         Code (ident_string name);
         Text " has no corresponding body implementation."
       ]
    | None ->
       hilde_raise (H 2004) DeclarationError [
         Code (ident_string name);
         Text " has no corresponding body implementation."
       ]

  let missing_instance_body_definition ~(name: identifier) ~(ty: typespec) =
    hilde_raise (H 2005) DeclarationError [
        Text "The instance ";
        Code (ident_string name);
        Text " with type ";
        Code (typespec_string ty);
        Text " has no corresponding body implementation."
      ]

  let module_name_mismatch ~interface ~body =
    hilde_raise (H 2006) DeclarationError [
      Text "Module interface and body have different names: ";
      Code (mod_name_string interface);
      Text " and ";
      Code (mod_name_string body)
    ]

  let multiarg_typeclass name =
    internal_raise [
      Text "The typeclass ";
      Code (ident_string name);
      Text " has multiple type parameters, which is unsupported."
    ]

  let type_mismatch name =
    hilde_raise (H 2008) DeclarationError [
      Text "The interface declaration for ";
      Code (ident_string name);
      Text " and its implementation have different types."
    ]

  let universe_mismatch name =
    hilde_raise (H 2009) DeclarationError [
      Text "The interface declaration for ";
      Code (ident_string name);
      Text " and its implementation have different universes."
    ]
end

(* The invariants of the module being combined, for the checks at
   the returns of its public functions. *)
let current_invariants: Contracts.invariant list ref = ref []

let parse_slots (imports: import_map) (slots: concrete_slot list): qslot list =
  List.map
    (fun (ConcreteSlot (n, t)) -> QualifiedSlot (n, qualify_typespec imports t))
    slots

let parse_cases (imports: import_map) (cases: concrete_case list): qcase list =
  List.map
    (fun (ConcreteCase (n, slots)) ->
      QualifiedCase (n,
                     List.map (fun (ConcreteSlot (n, t)) ->
                         QualifiedSlot (n, qualify_typespec imports t))
                       slots))
    cases

let parse_params (imports: import_map) (params: concrete_param list): qparam list =
  List.map
    (fun (ConcreteParam (n, t)) ->
      QualifiedParameter (n, qualify_typespec imports t))
    params

let name_typarams (im: import_map) (params: concrete_type_param list) (name: qident): typarams =
  let lst: type_parameter list =
    List.map (fun (ConcreteTypeParam (n, u, cs)) -> make_typaram (n, u, name, List.map (fun i -> qident_to_sident (qualify_identifier im i)) cs)) params
  in
  typarams_from_list lst

let parse_method_decls (module_name: module_name) (imports: import_map) (methods: concrete_method_decl list): combined_method_decl list =
  List.map (fun (ConcreteMethodDecl (n, typarams, params, rt, method_docstring, contract)) ->
      CMethodDecl (n,
                   name_typarams imports typarams (make_qident (module_name, n, n)),
                   parse_params imports params,
                   qualify_typespec imports rt,
                   method_docstring,
                   Contracts.raises_of_clauses contract))
    methods

let parse_method_defs (module_name: module_name) (imports: import_map) (methods: concrete_method_def list): combined_method_def list =
  List.map (fun (ConcreteMethodDef (n, typarams, params, rt, body, method_docstring, method_clauses)) ->
      (* The clause of a method stands at the typeclass. *)
      (match method_clauses with
       | [] -> ()
       | (ContractClause { span; _ }) :: _ ->
          adorn_error_with_span span (fun _ -> Contracts.Errors.method_def_clause ~name:n));
      CMethodDef (n,
                  name_typarams imports typarams (make_qident (module_name, n, n)),
                  parse_params imports params,
                  qualify_typespec imports rt,
                  method_docstring,
                  abs_stmt imports body))
    methods

let is_slot_pragma (p: Common.pragma): bool =
  match p with
  | Common.SlotPragma -> true
  | _ -> false

(* Whether a function is generic over anything but regions.  A slot may be
   generic over regions: a region has no run-time representation, every
   instantiation is the same C function, and the slot stays one function
   the programme chooses once. *)
let generic_beyond_regions (typarams: concrete_type_param list): bool =
  List.exists (fun (ConcreteTypeParam (_, u, _)) -> u <> Type.RegionUniverse) typarams

(* Records a slot or an implementation in the table of the programme and
   gives back the pragmas the later passes see, without the two of slots,
   and the contract: an implementation without one takes its slot's. *)
let note_slots ~(module_name: module_name) ~(name: identifier) ~(span: Span.span) ~(generic: bool)
      ~(ipragmas: Common.pragma list) ~(contract: contract_clause list) (pragmas: Common.pragma list): Common.pragma list * contract_clause list =
  let misplaced (what: string) = adorn_error_with_span span (fun _ -> Slots.Errors.misplaced ~what) in
  if List.exists is_slot_pragma pragmas then
    misplaced "pragma Slot stands at a function definition.";
  if List.exists (fun p -> match p with Common.ImplementsPragma _ -> true | _ -> false) ipragmas then
    misplaced "pragma Implements stands at a function declaration of an interface.";
  let slot: bool = List.exists is_slot_pragma ipragmas in
  let target: string option =
    List.find_map (fun p -> match p with Common.ImplementsPragma t -> Some t | _ -> None) pragmas
  in
  if (slot || target <> None) && generic then
    misplaced "A function generic over a type cannot be a slot or implement one.";
  if slot && target <> None then
    misplaced "A slot cannot implement another slot.";
  if slot then
    Slots.register_slot { Slots.slot_module = module_name; slot_name = name; slot_span = span; has_default = true; slot_contract = contract };
  let contract: contract_clause list =
    match target with
    | Some t ->
       Slots.register_implementation { Slots.target = t; impl_module = module_name; impl_name = name; impl_span = span };
       (match (contract, Slots.find_slot t) with
        | ([], Some s) -> s.Slots.slot_contract
        | _ -> contract)
    | None ->
       contract
  in
  (List.filter (fun p -> match p with Common.SlotPragma | Common.ImplementsPragma _ -> false | _ -> true) pragmas, contract)

let match_decls (module_name: module_name) (ii: import_map) (bi: import_map) (decl: concrete_decl) (def: concrete_def): combined_definition =
  let make_qname n =
    make_qident (module_name, n, n)
  in
  match decl with
  | ConcreteConstantDecl (span, name, ty, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         match def with
         | ConcreteConstantDef (defspan, name', ty', value, _) ->
            if (name = name') && (ty = ty') then
              CConstant (defspan, VisPublic, name, qualify_typespec ii ty, abs_expr bi value, docstring)
            else
              Errors.type_mismatch name
         | _ ->
            Errors.declaration_kind_mismatch ~name ~expected:"constant")
  | ConcreteOpaqueTypeDecl (span, name, typarams, universe, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         match def with
         | ConcreteRecordDef (ConcreteRecord (defspan, name', typarams', universe', slots, _, _)) ->
            if (name = name') && (typarams = typarams') && (universe = universe') then
              let qname = make_qname name' in
              CRecord (defspan,
                       TypeVisOpaque,
                       name,
                       name_typarams bi typarams qname,
                       universe,
                       parse_slots bi slots,
                       docstring)
            else
              if universe != universe' then
                Errors.universe_mismatch name
              else
                Errors.type_mismatch name
         | ConcreteUnionDef (ConcreteUnion (defspan, name', typarams', universe', cases, _)) ->
            if (name = name') && (typarams = typarams') && (universe = universe') then
              let qname = make_qname name' in
              CUnion (defspan,
                      TypeVisOpaque,
                      name,
                      name_typarams bi typarams qname,
                      universe,
                      parse_cases bi cases,
                      docstring)
            else
              if universe <> universe' then
                Errors.universe_mismatch name
              else
                Errors.type_mismatch name
         | _ ->
            Errors.declaration_kind_mismatch ~name ~expected:"type")
  | ConcreteFunctionDecl (span, name, typarams, params, rt, docstring, contract, ipragmas) ->
     adorn_error_with_span span
       (fun _ ->
         match def with
         | ConcreteFunctionDef (defspan, name', typarams', params', rt', body, _, pragmas, def_contract) ->
            if (name = name') && (typarams = typarams') && (params = params') && (rt = rt') then
              let qname = make_qname name' in
              let (pragmas, contract) =
                note_slots ~module_name ~name ~span:defspan ~generic:(generic_beyond_regions typarams) ~ipragmas ~contract pragmas
              in
              (* The contract of a public function stands in its
                 interface; one in the body is refused and named. *)
              (match def_contract with
               | [] -> ()
               | (ContractClause { span = body_span; _ }) :: _ ->
                  let interface_span =
                    match contract with
                    | (ContractClause { span = s; _ }) :: _ -> s
                    | [] -> span
                  in
                  adorn_error_with_span body_span
                    (fun _ ->
                      Contracts.Errors.repeated_in_body
                        ~name
                        ~interface_span
                        ~has_interface_contract:(contract <> [])));
              let rt_q = qualify_typespec ii rt in
              let (params_q, body_a) =
                Contracts.rewrite_function
                  ~module_name
                  ~name
                  ~def_span:defspan
                  ~cond_imports:ii
                  ~params:(parse_params ii params)
                  ~rt:rt_q
                  ~pragmas
                  ~clauses:contract
                  (abs_stmt bi body)
              in
              let body_a =
                Contracts.add_invariant_checks
                  ~module_name
                  ~name
                  ~def_span:defspan
                  ~invariants:!current_invariants
                  ~params:params_q
                  ~rt:rt_q
                  body_a
              in
              let raises = Contracts.raises_of_clauses contract in
              CFunction (defspan,
                         VisPublic,
                         name,
                         name_typarams bi typarams qname,
                         params_q,
                         rt_q,
                         body_a,
                         docstring,
                         raises,
                         pragmas)
            else
              let msg =
                if typarams <> typarams' then
                  Errors.DifferentTypeParameters
                else if params <> params' then
                  Errors.DifferentValueParameters
                else if rt <> rt' then
                  Errors.DifferentReturnTypes
                else
                  Errors.Else
              in
              Errors.function_mismatch
                ~name
                ~msg:msg
         | _ ->
            Errors.declaration_kind_mismatch ~name ~expected:"function")
  | ConcreteInstanceDecl (span, name, typarams, argument, docstring) ->
     adorn_error_with_span span
       (fun _ ->
         match def with
         | ConcreteInstanceDef (ConcreteInstance (defspan, name', typarams', argument', methods, _)) ->
            if (name = name') && (typarams = typarams') && (argument = argument') then
              (* Instance names might refer to an imported typeclass, so we have to
                 qualify them. Since we're parsing a public declaration, which
                 means the instance (and thus the name of the typeclass) appears in
                 the interface file, we use the interface imports for
                 qualification. *)
              let qname = qualify_identifier ii name in
              CInstance (defspan,
                         VisPublic,
                         qname,
                         name_typarams bi typarams qname,
                         qualify_typespec ii argument,
                         parse_method_defs module_name bi methods,
                         docstring)
            else
              Errors.type_mismatch name
         | _ ->
            Errors.declaration_kind_mismatch ~name ~expected:"instance")
  | _ ->
     internal_err "Invalid decl in this context"

let private_def module_name im def =
  let make_qname n =
    make_qident (module_name, n, n)
  in
  match def with
  | ConcreteConstantDef (span, name, ty, value, docstring) ->
     CConstant (span,
                VisPrivate,
                name,
                qualify_typespec im ty,
                abs_expr im value,
                docstring)
  | ConcreteRecordDef (ConcreteRecord (span, name, typarams, universe, slots, docstring, _)) ->
     let qname = make_qname name in
     CRecord (span,
              TypeVisPrivate,
              name,
              name_typarams im typarams qname,
              universe,
              parse_slots im slots,
              docstring)
  | ConcreteUnionDef (ConcreteUnion (span, name, typarams, universe, cases, docstring)) ->
     let qname = make_qname name in
     CUnion (span,
             TypeVisPrivate,
             name,
             name_typarams im typarams qname,
             universe,
             parse_cases im cases,
             docstring)
  | ConcreteFunctionDef (span, name, typarams, params, rt, body, docstring, pragmas, contract) ->
     let qname = make_qname name in
     let (pragmas, contract) =
       note_slots ~module_name ~name ~span ~generic:(generic_beyond_regions typarams) ~ipragmas:[] ~contract pragmas
     in
     let rt_q = qualify_typespec im rt in
     let (params_q, body_a) =
       Contracts.rewrite_function
         ~module_name
         ~name
         ~def_span:span
         ~cond_imports:im
         ~params:(parse_params im params)
         ~rt:rt_q
         ~pragmas
         ~clauses:contract
         (abs_stmt im body)
     in
     CFunction (span,
                VisPrivate,
                name,
                name_typarams im typarams qname,
                params_q,
                rt_q,
                body_a,
                docstring,
                Contracts.raises_of_clauses contract,
                pragmas)
  | ConcreteTypeClassDef (ConcreteTypeClass (span, name, typaram, methods, docstring)) ->
     let qname = make_qname name in
     CTypeclass (span,
                 VisPrivate,
                 name,
                 (match (typarams_as_list (name_typarams im [typaram] qname)) with
                  | [tp] ->
                     tp
                  | _ ->
                     Errors.multiarg_typeclass name),
                 parse_method_decls module_name im methods,
                 docstring)
  | ConcreteInstanceDef (ConcreteInstance (span, name, typarams, argument, methods, docstring)) ->
     (* Instance names might refer to an imported typeclass, so we have to
        qualify them. Since we're parsing a private declaration, which means the
        instance (and thus the name of the typeclass) appears in the body file,
        we can use the body imports for qualification. *)
     let qname = qualify_identifier im name in
     CInstance (span,
                VisPrivate,
                qname,
                name_typarams im typarams qname,
                qualify_typespec im argument,
                parse_method_defs module_name im methods,
                docstring)

(* While a module is combined, the abstraction pass adds the call
   site to every call of a function with a requires.  local names the
   module's own such functions; another module's are known by their last
   parameter. *)
let with_contract_oracle (env: env) (mn: module_name) (local: string list) (f: unit -> 'a): 'a =
  let oracle (q: qident): bool =
    if equal_module_name (source_module_name q) mn then
      List.mem (ident_string (original_name q)) local
    else
      Contracts.env_function_takes_site env q
  in
  Contracts.begin_module ();
  AbstractionPass.contract_callee := oracle;
  Fun.protect
    ~finally:(fun () -> AbstractionPass.contract_callee := (fun _ -> false))
    f

(* The records of a module body that have invariants, each refused where
   another module could build it or write its slots; and their checking
   functions.  public_records names the records whose slots the interface
   shows; interfaceless says the module has no interface at all. *)
let invariants_of (defs: concrete_def list) (public_records: concrete_record list) (interfaceless: bool): Contracts.invariant list * concrete_def list =
  List.iter
    (fun (ConcreteRecord (span, name, _, _, _, _, clauses)) ->
      if clauses <> [] then
        adorn_error_with_span span
          (fun _ -> Contracts.InvariantErrors.slots_public ~record:name ~why:"its slots stand in the interface"))
    public_records;
  let records =
    List.filter_map
      (fun d ->
        match d with
        | ConcreteRecordDef (ConcreteRecord (_, _, _, _, _, _, (_ :: _)) as r) -> Some r
        | _ -> None)
      defs
  in
  if interfaceless then
    List.iter
      (fun (ConcreteRecord (span, name, _, _, _, _, _)) ->
        adorn_error_with_span span
          (fun _ -> Contracts.InvariantErrors.slots_public ~record:name ~why:"the module has no interface, so every record of it is public"))
      records;
  List.split (List.concat_map Contracts.invariant_checker records)

let rec combine (env: env) (cmi: concrete_module_interface) (cmb: concrete_module_body): combined_module =
  with_frame "Module combining pass: combining .hih and .hiq files"
    (fun _ ->
      let (ConcreteModuleInterface (mn, interface_docstring, interface_imports, decls)) = cmi
      and (ConcreteModuleBody (mn', kind, _, body_docstring, body_imports, defs)) = cmb
      in
      ps ("Module name", (mod_name_string mn));
      if mn <> mn' then
        Errors.module_name_mismatch ~interface:mn ~body:mn'
      else
        let im = resolve mn kind env interface_imports
        and bm = resolve mn kind env body_imports
        in
        let local =
          (List.filter_map
             (fun d ->
               match d with
               | ConcreteFunctionDecl (_, n, _, _, _, _, c, _) when Contracts.has_requires c -> Some (ident_string n)
               | _ -> None)
             decls)
          @ (List.filter_map
               (fun d ->
                 match d with
                 | ConcreteFunctionDef (_, n, _, _, _, _, _, _, c)
                      when (Contracts.has_requires c) && (get_concrete_decl cmi n = None) ->
                    Some (ident_string n)
                 | _ -> None)
               defs)
        in
        let public_records =
          List.filter_map (fun d -> match d with ConcreteRecordDecl r -> Some r | _ -> None) decls
        in
        let (invariants, checkers) = invariants_of defs public_records false in
        current_invariants := invariants;
        with_contract_oracle env mn local
          (fun _ ->
        let public_decls = List.map (parse_decl mn im bm cmb) decls
        and private_decls = parse_defs mn cmi bm (defs @ checkers)
        in
        current_invariants := [];
        CombinedModule {
            name = mn;
            kind = kind;
            interface_docstring = interface_docstring;
            interface_imports = im;
            body_docstring = body_docstring;
            body_imports = bm;
            decls = List.concat [public_decls; private_decls];
    }))

and parse_decl (module_name: module_name) (im: import_map) (bm: import_map) (cmb: concrete_module_body) (decl: concrete_decl): combined_definition =
  let make_qname n =
    make_qident (module_name, n, n)
  in
  match concrete_decl_name decl with
  | (Some name) ->
     (match decl with
      (* Some declarations don't need to have a matching body *)
      | ConcreteRecordDecl (ConcreteRecord (span, name, typarams, universe, slots, docstring, _)) ->
         let qname = make_qname name in
         CRecord (span,
                  TypeVisPublic,
                  name,
                  name_typarams im typarams qname,
                  universe,
                  parse_slots im slots,
                  docstring)
      | ConcreteUnionDecl (ConcreteUnion (span, name, typarams, universe, cases, docstring)) ->
         let qname = make_qname name in
         CUnion (span,
                 TypeVisPublic,
                 name,
                 name_typarams im typarams qname,
                 universe,
                 parse_cases im cases,
                 docstring)
      | ConcreteTypeClassDecl (ConcreteTypeClass (span, name, typaram, methods, docstring)) ->
         let qname = make_qname name in
         CTypeclass (span,
                     VisPublic,
                     name,
                 (match (typarams_as_list (name_typarams im [typaram] qname)) with
                  | [tp] ->
                     tp
                  | _ ->
                     Errors.multiarg_typeclass name),
                     parse_method_decls module_name im methods,
                     docstring)
      | _ ->
         (* Other declarations need to match a body *)
         (match get_concrete_def cmb name with
          | (Some def) ->
             match_decls module_name im bm decl def
          | None ->
             (match decl with
              | ConcreteFunctionDecl (span, fname, tps, params, rt, _, _, ipragmas)
                   when List.exists is_slot_pragma ipragmas ->
                 (* A slot without a default: a body that is never written, since
                    the check of the programme asks for an implementation. *)
                 let body = CDiscarding (span, CFuncall (span, make_ident "abort",
                                ConcretePositionalArgs [CStringConstant (span, "slot without implementation")])) in
                 let def = ConcreteFunctionDef (span, fname, tps, params, rt, body, Docstring "", [], []) in
                 let combined = match_decls module_name im bm decl def in
                 (match Slots.find_slot (Slots.full_name module_name fname) with
                  | Some s -> Slots.register_slot { s with Slots.has_default = false }
                  | None -> ());
                 combined
              | _ ->
                 Errors.missing_body_definition ~name ~declaration:None)))
  | None ->
     (match decl with
      | ConcreteInstanceDecl (_, name, typarams, argument, _) ->
         (* It's an instance declaration. Find the corresponding instance in the body. *)
         (match get_instance_def cmb name typarams argument with
          | (Some def) ->
             match_decls module_name im bm decl (ConcreteInstanceDef def)
          | None ->
             Errors.missing_instance_body_definition ~name ~ty:argument)
      | _ ->
         internal_err "Couldn't parse declaration declaration")

and parse_defs (mn: module_name) (cmi: concrete_module_interface) (im: import_map) (defs: concrete_def list): combined_definition list =
  List.filter_map (parse_def mn cmi im) defs

and parse_def (module_name: module_name) (cmi: concrete_module_interface) (im: import_map) (def: concrete_def): combined_definition option =
  match def_name def with
  | (Some name) ->
     (* If this def exists in the interface, skip it *)
     (match get_concrete_decl cmi name with
      | (Some _) ->
         None
      | None ->
         Some (private_def module_name im def))
  | None ->
     (match def with
      | ConcreteInstanceDef (ConcreteInstance (_, name, typarams, argument, _, _)) ->
      (* It's an instance declaration. If the interface file declares it, ignore
         it: it's already been processed. Otherwise, process it as a private
         instance declaration. *)
         if has_instance_decl cmi name typarams argument then
           None
         else
           Some (private_def module_name im def)
      | _ ->
         internal_err "Couldn't parse definition")

let as_public (def: combined_definition): combined_definition =
  match def with
  | CConstant (span, _, name, ty, value, docstring) ->
     CConstant (span, VisPublic, name, ty, value, docstring)
  | CRecord (span, _, name, typarams, universe, slots, docstring) ->
     CRecord (span, TypeVisPublic, name, typarams, universe, slots, docstring)
  | CUnion (span, _, name, typarams, universe, cases, docstring) ->
     CUnion (span, TypeVisPublic, name, typarams, universe, cases, docstring)
  | CFunction (span, _, name, typarams, params, rt, body, docstring, raises, pragmas) ->
     CFunction (span, VisPublic, name, typarams, params, rt, body, docstring, raises, pragmas)
  | CTypeclass (span, _, name, typaram, methods, docstring) ->
     CTypeclass (span, VisPublic, name, typaram, methods, docstring)
  | CInstance (span, _, name, typarams, argument, methods, docstring) ->
     CInstance (span, VisPublic, name, typarams, argument, methods, docstring)

let body_as_combined (env: env) (body: concrete_module_body): combined_module =
  with_frame "Module combining pass: module body without interface"
    (fun _ ->
      let (ConcreteModuleBody (mn, kind, _, body_docstring, body_imports, defs)) = body in
      ps ("Module name", (mod_name_string mn));
      (* We fake an empty module interface. *)
      let cmi: concrete_module_interface = ConcreteModuleInterface (mn, Docstring "", [], []) in
      let imports = resolve mn kind env body_imports in
      let local =
        List.filter_map
          (fun d ->
            match d with
            | ConcreteFunctionDef (_, n, _, _, _, _, _, _, c) when Contracts.has_requires c -> Some (ident_string n)
            | _ -> None)
          defs
      in
      let _ = invariants_of defs [] true in
      let decls = with_contract_oracle env mn local (fun _ -> parse_defs mn cmi imports defs) in
      (* Go through the declarations and make them public. *)
      let decls = List.map as_public decls in
      CombinedModule {
          name = mn;
          kind = kind;
          interface_docstring = Docstring "";
          interface_imports = empty_map mn;
          body_docstring = body_docstring;
          body_imports = imports;
          decls = decls;
    })
