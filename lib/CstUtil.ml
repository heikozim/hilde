(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open Common
open Cst
open Error
open ErrorText

module Errors = struct
  let pragma_argument_error ~pragma_name ~argument =
    let text = Text ("Invalid " ^ pragma_name ^ " pragma.") :: match argument with
    | Some argument -> [Break; Text "This pragma takes exactly one argument, "; Code argument]
    | None -> [Break; Text "This pragma takes no arguments."]
    in
    hilde_raise (H 2011) DeclarationError text

  let unknown_pragma name =
    hilde_raise (H 2012) DeclarationError [
      Text "Unknown pragma ";
      Code name
    ]

  (* The module name is put into the text because this error is raised while
     the module head is still being built, before the name is in the dynamic
     context the renderer reads -- the rendered error says
     "Module: [unknown]".  Naming it here is the difference between a message
     that can be acted on and one that says a library is wrong somewhere. *)
  let foreign_library_in_safe_module module_name name =
    hilde_raise (H 2013) DeclarationError [
      Text "Module ";
      Code (mod_name_string module_name);
      Text " is safe and can't name the C library ";
      Code name;
      Text ".";
      Break;
      Text "A safe module has no C to link against: it can hold neither a ";
      Code "pragma Foreign_Import";
      Text " nor an ";
      Code "@embed";
      Text ". Write ";
      Code "pragma Unsafe_Module;";
      Text " above ";
      Code "module body";
      Text ", or take the library declaration out."
    ]

  let foreign_library_empty_name () =
    hilde_raise (H 2014) DeclarationError [
      Text "The name in a ";
      Code "pragma Foreign_Library";
      Text " must not be empty.";
      Break;
      Text "It is a library name, the ";
      Code "z";
      Text " of ";
      Code "-lz";
      Text ", not a linker switch."
    ]

  (* The names `uname -s' prints on the systems a programme can
     be compiled on; the gates run two of them.  A name outside the list is
     refused rather than compared: a misspelt system would never match, and
     its library would silently never be linked. *)
  let known_systems: string list = ["Linux"; "OpenBSD"; "FreeBSD"; "NetBSD"; "Darwin"]

  let foreign_library_unknown_system name =
    hilde_raise (H 2048) DeclarationError [
      Text "The system ";
      Code name;
      Text " in a ";
      Code "pragma Foreign_Library";
      Text " is not one this compiler knows.";
      Break;
      Text "It is compared with what ";
      Code "uname -s";
      Text " prints on the machine that compiles the programme, and must be one of ";
      Code (String.concat ", " known_systems);
      Text ", written as it prints them."
    ]

  let targets_arguments (detail: string) =
    hilde_raise (H 2068) DeclarationError [
      Text "Invalid ";
      Code "pragma Targets";
      Text (": " ^ detail ^ ".");
      Break;
      Text "It takes ";
      Code "Names";
      Text ", the targets separated by one space each, out of ";
      Code (String.concat ", " Util.target_names);
      Text ", and after it, where another module does the work on the other targets, ";
      Code "Instead";
      Text ": ";
      Code "pragma Targets(Names => \"linux openbsd freebsd darwin\", Instead => \"Standard.Regex\");"
    ]

  let interface_pragma (name: string) =
    hilde_raise (H 2069) DeclarationError [
      Code ("pragma " ^ name);
      Text " cannot stand before a module interface.";
      Break;
      Text "Only ";
      Code "pragma Targets";
      Text " stands there, once."
    ]

  let foreign_library_arguments () =
    hilde_raise (H 2049) DeclarationError [
      Text "Invalid ";
      Code "pragma Foreign_Library";
      Text ".";
      Break;
      Text "It takes the argument ";
      Code "Name";
      Text ", and after it, for a library linked on one system only, ";
      Code "System";
      Text ": ";
      Code "pragma Foreign_Library(Name => \"crypt\", System => \"Linux\");"
    ]

  (* A header is C as much as a library is, and for the same
     reason a safe module cannot name one. *)
  let foreign_header_in_safe_module module_name name =
    hilde_raise (H 2042) DeclarationError [
      Text "Module ";
      Code (mod_name_string module_name);
      Text " is safe and can't name the C header ";
      Code name;
      Text ".";
      Break;
      Text "A header gives C's own constants to an ";
      Code "@embed";
      Text ", and a safe module can hold none. Write ";
      Code "pragma Unsafe_Module;";
      Text " above ";
      Code "module body";
      Text ", or take the header declaration out."
    ]

  let foreign_header_bad_name name =
    hilde_raise (H 2043) DeclarationError [
      Text "The name in a ";
      Code "pragma Foreign_Header";
      Text " is not a header name: ";
      Code name;
      Break;
      Text "It is what stands between the angle brackets of an ";
      Code "#include";
      Text ", such as ";
      Code "openssl/evp.h";
      Text ": letters, digits and ";
      Code "_ . / + -";
      Text ", not empty, not starting with a slash, and without a ";
      Code "..";
      Text " part."
    ]
end

(* The name goes between the angle brackets of an #include in the
   emitted C, so it is held to the characters a header name is made of.  A
   quote, a space or a `>' would let the text of a module reach the C
   preprocessor as something other than a header name. *)
let is_header_name (name: string): bool =
  let allowed c =
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
    || c = '_' || c = '.' || c = '/' || c = '+' || c = '-'
  in
  let parts = String.split_on_char '/' name in
  name <> ""
  && name.[0] <> '/'
  && String.for_all allowed name
  && not (List.mem ".." parts)
  && not (List.mem "" parts)

(* A module interface: the pragmas before it may only be one pragma Targets,
   whose targets are kept for the module by name in ModuleTargets. *)
let make_module_int (name: module_name) (doc: docstring) (pragmas: pragma list) (imports: concrete_import_list list) (decls: concrete_decl list): concrete_module_interface =
  let targets: (string list * string option) list =
    List.map
      (fun p ->
        match p with
        | TargetsPragma (names, instead) -> (names, instead)
        | ForeignImportPragma _ -> Errors.interface_pragma "Foreign_Import"
        | ForeignExportPragma _ -> Errors.interface_pragma "Foreign_Export"
        | ForeignLibraryPragma _ -> Errors.interface_pragma "Foreign_Library"
        | ForeignHeaderPragma _ -> Errors.interface_pragma "Foreign_Header"
        | UnsafeModulePragma -> Errors.interface_pragma "Unsafe_Module"
        | SlotPragma -> Errors.interface_pragma "Slot"
        | ImplementsPragma _ -> Errors.interface_pragma "Implements")
      pragmas
  in
  (match targets with
   | [] -> ()
   | [(names, instead)] -> ModuleTargets.register (mod_name_string name) { ModuleTargets.names; instead }
   | _ -> Errors.interface_pragma "Targets");
  ConcreteModuleInterface (name, doc, imports, decls)

let make_module_body (name: module_name) (imports: concrete_import_list list) (pragmas: pragma list) (defs: concrete_def list) (docstring: docstring) =
  let is_unsafe_module p =
    match p with
    | UnsafeModulePragma -> true
    | _ -> false
  in
  let kind_from_pragmas pragmas =
    if (List.exists is_unsafe_module pragmas) then
      UnsafeModule
    else
      SafeModule
  in
  let kind = kind_from_pragmas pragmas in
  (* The C libraries this module needs, in the order they are written.  A
     safe module cannot name one: it can hold neither a foreign import nor an
     `@embed', so it has no C to link against, and a library named there
     would silently enlarge the link line of every program that imports it
     (Errors.foreign_library_in_safe_module). *)
  let named_libraries =
    List.filter_map
      (fun p -> match p with ForeignLibraryPragma (l, s) -> Some (l, s) | _ -> None)
      pragmas
  in
  let _ =
    match kind, named_libraries with
    | SafeModule, (l, _) :: _ -> Errors.foreign_library_in_safe_module name l
    | _ -> ()
  in
  (* A library named for one system is linked on that system only
; the check above
     holds for it on every system. *)
  let libraries =
    List.filter_map
      (fun (l, s) ->
        match s with
        | None -> Some l
        | Some system -> if system = Lazy.force Util.host_system then Some l else None)
      named_libraries
  in
  (* The C headers, in the order written. *)
  let headers =
    List.filter_map
      (fun p -> match p with ForeignHeaderPragma h -> Some h | _ -> None)
      pragmas
  in
  let _ =
    match kind, headers with
    | SafeModule, h :: _ -> Errors.foreign_header_in_safe_module name h
    | _ -> ()
  in
  ConcreteModuleBody (name, kind, { c_libraries = libraries; c_headers = headers }, docstring, imports, defs)

(* The text of the file being parsed.  ParserInterface sets it before each
   parse; the parser takes the text of a contract's condition from it. *)
let parse_source: string ref = ref ""

(* The bytes of the file being parsed between two positions.  A run of
   white space that holds a line end becomes one space, so that a condition
   written over several lines prints as one; any other run stays as it is,
   and with it the inside of a string literal. *)
let source_text (start_pos: Lexing.position) (end_pos: Lexing.position): string =
  let s = !parse_source
  and a = start_pos.Lexing.pos_cnum
  and b = end_pos.Lexing.pos_cnum in
  if (a < 0) || (b > String.length s) || (a > b) then
    ""
  else
    let raw = String.sub s a (b - a) in
    let buf = Buffer.create (String.length raw) in
    let run = Buffer.create 8 in
    let run_has_line_end = ref false in
    let flush_run () =
      if !run_has_line_end then
        Buffer.add_char buf ' '
      else
        Buffer.add_buffer buf run;
      Buffer.clear run;
      run_has_line_end := false
    in
    String.iter
      (fun c ->
        match c with
        | ' ' | '\t' ->
           Buffer.add_char run c
        | '\n' | '\r' ->
           Buffer.add_char run c;
           run_has_line_end := true
        | _ ->
           flush_run ();
           Buffer.add_char buf c)
      raw;
    Buffer.contents buf

(* A contract clause: its span runs from the keyword to the end of the
   condition, its text is the condition's alone. *)
let make_contract_clause (kind: contract_kind) (clause_start: Lexing.position) (cond_start: Lexing.position) (cond_end: Lexing.position) (condition: cexpr): contract_clause =
  ContractClause {
      kind;
      span = Span.from_loc (clause_start, cond_end);
      condition;
      text = source_text cond_start cond_end;
    }

(* The raises clause of a signature: the kinds joined with ", "
   are its text and its condition.  The condition is unused by every pass
   that reads the clause -- the kinds are read out of the text, which is
   what the signature says -- and it is kept as a list of the names made
   into unit constants, so that a future pass that wants structured kinds
   does not re-parse the text. *)
let make_raises_clause (clause_start: Lexing.position) (clause_end: Lexing.position) (kinds: identifier list): contract_clause =
  let names = List.map ident_string kinds in
  ContractClause {
      kind = RaisesClause;
      span = Span.from_loc (clause_start, clause_end);
      condition = CNilConstant Span.empty_span;
      text = String.concat ", " names;
    }

let concrete_decl_name = function
  | ConcreteConstantDecl (_, n, _, _) -> Some n
  | ConcreteOpaqueTypeDecl (_, n, _, _, _) -> Some n
  | ConcreteRecordDecl (ConcreteRecord (_, n, _, _, _, _, _)) -> Some n
  | ConcreteUnionDecl (ConcreteUnion (_, n, _, _, _, _)) -> Some n
  | ConcreteFunctionDecl (_, n, _, _, _, _, _, _) -> Some n
  | ConcreteTypeClassDecl (ConcreteTypeClass (_, n, _, _, _)) -> Some n
  | ConcreteInstanceDecl _ -> None

let def_name = function
  | ConcreteConstantDef (_, n, _, _, _) -> Some n
  | ConcreteRecordDef (ConcreteRecord (_, n, _, _, _, _, _)) -> Some n
  | ConcreteUnionDef (ConcreteUnion (_, n, _, _, _, _)) -> Some n
  | ConcreteFunctionDef (_, n, _, _, _, _, _, _, _) -> Some n
  | ConcreteTypeClassDef (ConcreteTypeClass (_, n, _, _, _)) -> Some n
  | ConcreteInstanceDef _ -> None

let get_concrete_decl (ConcreteModuleInterface (_, _, _, decls)) name =
  let pred decl =
    match concrete_decl_name decl with
    | (Some name') ->
       name = name'
    | None ->
       false
  in
  List.find_opt pred decls

let get_concrete_def (ConcreteModuleBody (_, _, _, _, _, defs)) name =
  let pred def =
    match def_name def with
    | (Some name') ->
       name = name'
    | None ->
       false
  in
  List.find_opt pred defs

let has_instance_decl (ConcreteModuleInterface (_, _, _, decls)) (name: identifier) (typarams: concrete_type_param list) (ty: typespec): bool =
  let pred = function
    | ConcreteInstanceDecl (_, name', typarams', ty', _) ->
       (name = name') && (typarams = typarams') && (ty = ty')
    | _ ->
       false
  in
  List.exists pred decls

let get_instance_def (ConcreteModuleBody (_, _, _, _, _, defs)) (name: identifier) (typarams: concrete_type_param list) (ty: typespec): concrete_instance option =
  let filter = function
    | ConcreteInstanceDef ci -> Some ci
    | _ -> None
  and pred (ConcreteInstance (_, name', typarams', ty', _, _)) =
    (name = name') && (typarams = typarams') && (ty = ty')
  in
  List.find_opt pred (List.filter_map filter defs)

let make_pragma name args =
  let s = ident_string name in
  if s = "Foreign_Import" then
    let raise_err () =
      Errors.pragma_argument_error
        ~pragma_name:"Foreign_Import"
        ~argument:(Some "External_Name")
    in
    match args with
    | ConcreteNamedArgs [(a, CStringConstant (_, f))] ->
       if equal_identifier a (make_ident "External_Name") then
         ForeignImportPragma f
       else
         raise_err ()
    | _ ->
       raise_err ()
  else
    if s = "Foreign_Export" then
      let raise_err () =
        Errors.pragma_argument_error
          ~pragma_name:"Foreign_Export"
          ~argument:(Some "External_Name")
      in
      match args with
      | ConcreteNamedArgs [(a, CStringConstant (_, f))] ->
         if equal_identifier a (make_ident "External_Name") then
           ForeignExportPragma f
         else
           raise_err ()
      | _ ->
         raise_err ()
    else
    if s = "Foreign_Library" then
      let named (f: string): string =
        if f = "" then Errors.foreign_library_empty_name () else f
      in
      match args with
      | ConcreteNamedArgs [(a, CStringConstant (_, f))]
           when equal_identifier a (make_ident "Name") ->
         ForeignLibraryPragma (named f, None)
      | ConcreteNamedArgs [(a, CStringConstant (_, f)); (b, CStringConstant (_, system))]
           when equal_identifier a (make_ident "Name") && equal_identifier b (make_ident "System") ->
         let f: string = named f in
         if List.mem system Errors.known_systems then
           ForeignLibraryPragma (f, Some system)
         else
           Errors.foreign_library_unknown_system system
      | _ ->
         Errors.foreign_library_arguments ()
    else
    if s = "Foreign_Header" then
      let raise_err () =
        Errors.pragma_argument_error
          ~pragma_name:"Foreign_Header"
          ~argument:(Some "Name")
      in
      match args with
      | ConcreteNamedArgs [(a, CStringConstant (_, f))] ->
         if equal_identifier a (make_ident "Name") then
           if is_header_name f then
             ForeignHeaderPragma f
           else
             Errors.foreign_header_bad_name f
         else
           raise_err ()
      | _ ->
         raise_err ()
    else
      if s = "Slot" then
        (match args with
         | ConcretePositionalArgs [] ->
            SlotPragma
         | _ ->
            Errors.pragma_argument_error ~pragma_name:"Slot" ~argument:None)
      else
      if s = "Implements" then
        (match args with
         | ConcreteNamedArgs [(a, CStringConstant (_, f))]
              when equal_identifier a (make_ident "Name") && String.contains f '.' ->
            ImplementsPragma f
         | _ ->
            Errors.pragma_argument_error ~pragma_name:"Implements" ~argument:(Some "Name"))
      else
      if s = "Targets" then
        let names_of (text: string): string list =
          let names: string list = String.split_on_char ' ' text in
          if names = [] || List.mem "" names then
            Errors.targets_arguments "the names are separated by one space each, and there is at least one"
          else
            (match List.find_opt (fun n -> not (List.mem n Util.target_names)) names with
             | Some unknown -> Errors.targets_arguments (unknown ^ " is no target")
             | None ->
                if List.length (List.sort_uniq compare names) <> List.length names then
                  Errors.targets_arguments "a target is named twice"
                else
                  names)
        in
        (match args with
         | ConcreteNamedArgs [(a, CStringConstant (_, names))]
              when equal_identifier a (make_ident "Names") ->
            TargetsPragma (names_of names, None)
         | ConcreteNamedArgs [(a, CStringConstant (_, names)); (b, CStringConstant (_, instead))]
              when equal_identifier a (make_ident "Names") && equal_identifier b (make_ident "Instead") ->
            let names: string list = names_of names in
            if not (String.contains instead '.') then
              Errors.targets_arguments "Instead names a module by its full name"
            else if List.length names = List.length Util.target_names then
              Errors.targets_arguments "Instead has no target to stand for when every target is named"
            else
              TargetsPragma (names, Some instead)
         | _ ->
            Errors.targets_arguments "the arguments are Names, and Instead after it")
      else
      if s = "Unsafe_Module" then
        let raise_err () =
          Errors.pragma_argument_error
            ~pragma_name:"Unsafe_Module"
            ~argument:None
        in
        match args with
        | ConcretePositionalArgs [] ->
           UnsafeModulePragma
        | _ ->
           raise_err ()
      else
        Errors.unknown_pragma s

let mod_int_name (inter: concrete_module_interface): module_name =
  let (ConcreteModuleInterface (name, _, _, _)) = inter in
  name

let mod_body_name (body: concrete_module_body): module_name =
  let (ConcreteModuleBody (name, _, _, _, _, _)) = body in
  name

let rec typespec_string (ts: typespec): string =
  match ts with
  | TypeSpecifier (name, args) ->
     (match args with
      | [] -> (ident_string name)
      | args -> (ident_string name) ^ "[" ^ (String.concat ", " (List.map typespec_string args)) ^ "]")
  | ConcreteReadRef (ty, reg) ->
     "&[" ^ (typespec_string ty) ^ ", " ^ (typespec_string reg) ^ "]"
  | ConcreteWriteRef (ty, reg) ->
     "&![" ^ (typespec_string ty) ^ ", " ^ (typespec_string reg) ^ "]"
  | ConcreteSpan (ty, reg) ->
     "Span[" ^ (typespec_string ty) ^ ", " ^ (typespec_string reg) ^ "]"
  | ConcreteSpanWrite (ty, reg) ->
     "Span![" ^ (typespec_string ty) ^ ", " ^ (typespec_string reg) ^ "]"

let decl_replace_docstring_and_pragmas (decl: concrete_decl) (docstring: docstring) (pragmas: pragma list): concrete_decl =
  match decl with
  | ConcreteConstantDecl (span, name, ty, _) ->
     ConcreteConstantDecl (span, name, ty, docstring)
  | ConcreteOpaqueTypeDecl (span, name, typarams, universe, _) ->
     ConcreteOpaqueTypeDecl (span, name, typarams, universe, docstring)
  | ConcreteRecordDecl (ConcreteRecord (span, name, typarams, universe, slots, _, invariants)) ->
     ConcreteRecordDecl (ConcreteRecord (span, name, typarams, universe, slots, docstring, invariants))
  | ConcreteUnionDecl (ConcreteUnion (span, name, typarams, universe, cases, _)) ->
     ConcreteUnionDecl (ConcreteUnion (span, name, typarams, universe, cases, docstring))
  | ConcreteFunctionDecl (span, name, typarams, params, rt, _, contract, _) ->
     ConcreteFunctionDecl (span, name, typarams, params, rt, docstring, contract, pragmas)
  | ConcreteTypeClassDecl (ConcreteTypeClass (span, name, typarams, methods, _)) ->
     ConcreteTypeClassDecl (ConcreteTypeClass (span, name, typarams, methods, docstring))
  | ConcreteInstanceDecl (span, name, methods, ty, _) ->
     ConcreteInstanceDecl (span, name, methods, ty, docstring)

let def_replace_docstring_and_pragmas (decl: concrete_def) (docstring: docstring) (pragmas: pragma list): concrete_def =
  match decl with
  | ConcreteConstantDef (span, name, ty, expr, _) ->
     ConcreteConstantDef (span, name, ty, expr, docstring)
  | ConcreteRecordDef (ConcreteRecord (span, name, typarams, universe, slots, _, invariants)) ->
     ConcreteRecordDef (ConcreteRecord (span, name, typarams, universe, slots, docstring, invariants))
  | ConcreteUnionDef (ConcreteUnion (span, name, typarams, universe, cases, _)) ->
     ConcreteUnionDef (ConcreteUnion (span, name, typarams, universe, cases, docstring))
  | ConcreteFunctionDef (span, name, typarams, params, ty, body, _, _, contract) ->
     ConcreteFunctionDef (span, name, typarams, params, ty, body, docstring, pragmas, contract)
  | ConcreteTypeClassDef (ConcreteTypeClass (span, name, typarams, methods, _)) ->
     ConcreteTypeClassDef (ConcreteTypeClass (span, name, typarams, methods, docstring))
  | ConcreteInstanceDef (ConcreteInstance (span, name, typarams, ty, methods, _)) ->
     ConcreteInstanceDef (ConcreteInstance (span, name, typarams, ty, methods, docstring))
