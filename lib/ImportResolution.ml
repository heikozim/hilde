(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open Common
open Imports
open Cst
open BuiltIn
open Error
open Id
open Env
open EnvTypes
open EnvUtils

(* A second name for the example of a message: otherQuestion for question,
   OtherRoute for Route. *)
let other_name (n: string): string =
  if (String.length n > 0) && (Char.uppercase_ascii n.[0] = n.[0]) then "Other" ^ n
  else "other" ^ (String.capitalize_ascii n)

module Errors = struct
  let double_import name =
    hilde_raise (H 2027) DeclarationError [
      Text "Colliding imports: a declaration with name ";
      Code (ident_string name);
      Text " has already been imported.";
      Break;
      Text "Consider giving it a different nickname using ";
      Code "as";
      Text ", as in ";
      Code ("import M (" ^ (ident_string name) ^ " as " ^ (other_name (ident_string name)) ^ ");");
      Text "."
    ]

  let import_memory_in_safe_module () =
    hilde_raise (H 2028) DeclarationError [
      Text "Cannot import from the ";
      Code "Hilde.Memory";
      Text " module in a safe module.";
      Break;
      Text "Consider using a safe wrapper or adding ";
      Code "pragma Unsafe_Module;"
    ]

  let privacy_error name =
    hilde_raise (H 2029) DeclarationError [
      Code (ident_string name);
      Text " is private and cannot be imported."
    ]

  let unresolved ~name ~module_name =
    hilde_raise (H 2030) DeclarationError [
      Text "No declaration with the name ";
      Code (ident_string name);
      Text " in the module ";
      Code (mod_name_string module_name)
    ]

  let import_binding ~importing ~binding =
    hilde_raise (H 2045) DeclarationError [
      Code (mod_name_string importing);
      Text " imports from ";
      Code (mod_name_string binding);
      Text ", a module that binds C.";
      Break;
      Text "Only the standard library imports a module whose name begins with ";
      Code "Bindings.";
      Text "; a program imports the safe module built on it, whose name begins with ";
      Code "Standard.";
      Text "."
    ]

  let targets_outside_library ~importing =
    hilde_raise (H 2070) DeclarationError [
      Code (mod_name_string importing);
      Text " names its targets with ";
      Code "pragma Targets";
      Text ", and only a module of the standard library does.";
      Break;
      Text "A programme is there for the targets of the modules it imports: what differs between the targets is in the standard library, and a programme holds no code for one target only."
    ]

  let targets_missing ~importing =
    hilde_raise (H 2071) DeclarationError [
      Text "The module ";
      Code (mod_name_string importing);
      Text " of the standard library names no targets.";
      Break;
      Text "Its interface says before its imports which targets it is there for: ";
      Code "pragma Targets(Names => \"linux openbsd freebsd darwin wasm\");"
    ]

  let targets_wider_than_import ~importing ~imported ~target =
    hilde_raise (H 2072) DeclarationError [
      Code (mod_name_string importing);
      Text " names the target ";
      Code target;
      Text ", but imports ";
      Code (mod_name_string imported);
      Text ", which is not there for it.";
      Break;
      Text "A module is there only for targets all its imports are there for: take ";
      Code target;
      Text " out of its pragma Targets, or make the import there for it."
    ]

  let not_for_target ~importing ~imported ~target ~instead =
    let open ErrorText in
    let tail: err_text =
      match instead with
      | Some other ->
         [Text " Take "; Code other; Text " instead.";
          Suggest { replacement = other; at = None; certain = false }]
      | None ->
         [Text " The standard library has no module that does its work there."]
    in
    hilde_raise (H 2073) DeclarationError ([
      Code (mod_name_string imported);
      Text " is not there for the target ";
      Code target;
      Text ", and ";
      Code (mod_name_string importing);
      Text " imports it.";
      Break;
      Text ("It is there for " ^ String.concat ", " (match ModuleTargets.find (mod_name_string imported) with Some t -> t.ModuleTargets.names | None -> []) ^ ".")
    ] @ tail)
end

(* A Bindings module holds the work with addresses and C, and some
   of what makes it safe to call is checked only at the safe module in front
   of it -- Standard.Task.spawn's argument (H3002), the mode of a
   Standard.Sqlite connection.  So only a module of the standard library,
   Standard.* or Bindings.*, may import from one.  The rule goes by name:
   a module that calls itself Standard.* takes on what the standard library
   promises. *)
let has_prefix (prefix: string) (name: module_name): bool =
  let s: string = mod_name_string name in
  let n: int = String.length prefix in
  String.length s >= n && String.sub s 0 n = prefix

let check_binding_imports (importing: module_name) (list: concrete_import_list list): unit =
  if (has_prefix "Standard." importing) || (has_prefix "Bindings." importing) then
    ()
  else
    List.iter
      (fun (ConcreteImportList (mn, _)) ->
        if has_prefix "Bindings." mn then
          Errors.import_binding ~importing ~binding:mn)
      list

(** Represents a Hilde import declaration, that is, in some code like:

    {import Foo.Bar (A as D, B, C);}

    The first symbol would correspond to this {ImportDecl}:

    {ImportDecl ("Foo.Bar", "A", "D")}
 *)
type import_decl = ImportDecl of module_name * identifier * identifier

(** Return the nickname if non-{None}, otherwise return the name. *)
let nickname_or_real_name (name: identifier) (nickname: identifier option): identifier =
  match nickname with
  | (Some nick) -> nick
  | None -> name

(** Take a list of import lists, and flatten it to a list of import decls *)
let flatten_imports (list: concrete_import_list list): import_decl list =
  let ll = List.map
             (fun (ConcreteImportList (mn, imports)) ->
               List.map (fun (ConcreteImport (name, nickname)) ->
                   ImportDecl (mn, name, nickname_or_real_name name nickname))
                 imports)
             list in
  List.concat ll

let resolve_import (env: env) (kind: module_kind) (imports: import_map) (idecl: import_decl): import_map =
  let (ImportDecl (module_name, name, nickname)) = idecl in
  let sname = make_sident module_name name in
  match get_decl_by_name env sname with
  | Some decl ->
     if is_importable decl then
       match get_symbol imports nickname with
       | Some _ -> Errors.double_import name
       | None ->
          if (equal_module_name module_name memory_module_name) && (kind = SafeModule) then
            Errors.import_memory_in_safe_module ()
          else
            add_symbol imports (make_qident (module_name, name, nickname))
     else
       Errors.privacy_error name
  | None ->
     Errors.unresolved ~name ~module_name

let rec resolve' (env: env) (kind: module_kind) (imports: import_map) (list: import_decl list): import_map =
  match list with
  | (first::rest) ->
     resolve' env kind (resolve_import env kind imports first) rest
  | [] ->
     imports

let rec add_instances (im: import_map) (is: decl_id list): import_map =
  match is with
  | first::rest ->
     add_instance_to_imports (add_instances im rest) first
  | [] ->
     im

let module_names (cil: concrete_import_list list): module_name list =
  List.map (fun (ConcreteImportList (mn, _)) -> mn) cil

let module_defined_instances (env: env) (mn: module_name): decl_id list =
  match (get_module_by_name env mn) with
  | Some mod_rec ->
     let ModRec { id; _ } = mod_rec in
     let decls: decl list = module_public_instances env id in
     List.map decl_id decls
  | None ->
     []

let import_instances (env: env) (list: concrete_import_list list): decl_id list =
  let mns = module_names list in
  let instances = List.map (module_defined_instances env) mns in
  List.flatten instances

(* The targets of the imports.  A module of the standard library, by its
   name Standard.*, names its targets, and only it does.  It names only
   targets all its imports are there for, whatever is being built.  A
   module that names no targets, the programme's own, imports only modules
   that are there for the target being built; a module of the standard
   library that is not there for that target is not checked against it, as
   the module that imports it is. *)
(* A module of the standard library with an interface names its targets
   there. *)
let check_library_targets (name: module_name): unit =
  if has_prefix "Standard." name && ModuleTargets.find (mod_name_string name) = None then
    Errors.targets_missing ~importing:name

let check_target_imports (importing: module_name) (list: concrete_import_list list): unit =
  let own: ModuleTargets.targets option = ModuleTargets.find (mod_name_string importing) in
  let library: bool = has_prefix "Standard." importing || has_prefix "Bindings." importing in
  (match (own, library) with
   | (Some _, false) -> Errors.targets_outside_library ~importing
   | _ -> ());
  let target: string = Util.current_target () in
  List.iter
    (fun (ConcreteImportList (imported, _)) ->
      match ModuleTargets.find (mod_name_string imported) with
      | None -> ()
      | Some theirs ->
         (match own with
          | Some mine ->
             (match List.find_opt (fun t -> not (List.mem t theirs.ModuleTargets.names)) mine.ModuleTargets.names with
              | Some t -> Errors.targets_wider_than_import ~importing ~imported ~target:t
              | None -> ())
          | None ->
             if target <> "" && not (List.mem target theirs.ModuleTargets.names) then
               Errors.not_for_target ~importing ~imported ~target ~instead:theirs.ModuleTargets.instead))
    list

let resolve (importing_module: module_name) (kind: module_kind) (env: env) (list: concrete_import_list list): import_map =
  check_binding_imports importing_module list;
  check_target_imports importing_module list;
  let im: import_map = resolve' env kind (empty_map importing_module) (flatten_imports list) in
  let ins: decl_id list = import_instances env list in
  add_instances im ins
