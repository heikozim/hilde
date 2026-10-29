(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* Slots: a function of an interface that one function anywhere in the
   programme may implement, chosen when the whole programme is compiled.

   A slot is declared with pragma Slot at its declaration in the interface
   and may have a body, its default.  A function with pragma Implements
   names the slot it implements by its full name, Module.function.  When the
   last module is compiled, every slot has at most one implementation, the
   implementation has the slot's signature, and a slot without a default has
   one.  The C of every slot is then one function that calls the chosen
   function directly: the implementation, or the default, which is written
   under a name of its own.  No function pointer is involved. *)

open Identifier
open Error
open Span
open CRepr

type slot = {
    slot_module: module_name;
    slot_name: identifier;
    slot_span: span;
    has_default: bool;
    slot_contract: Cst.contract_clause list;
  }

type implementation = {
    target: string;
    impl_module: module_name;
    impl_name: identifier;
    impl_span: span;
  }

(* What the code generator wrote for a slot or an implementation: the C name
   and, for a slot, its parameters and result. *)
type emitted = {
    c_name: string;
    c_params: c_param list;
    c_rt: c_ty;
    never: bool;
  }

let slots: (string, slot) Hashtbl.t = Hashtbl.create 16
let implementations: implementation list ref = ref []
let emitted_slots: (string, emitted) Hashtbl.t = Hashtbl.create 16
let emitted_impls: (string, string) Hashtbl.t = Hashtbl.create 16

let full_name (m: module_name) (n: identifier): string =
  (mod_name_string m) ^ "." ^ (ident_string n)

module Errors = struct
  let no_implementation ~name =
    hilde_raise (H 2063) DeclarationError [
      Text "The slot ";
      Code name;
      Text " has no default body and no function of the programme implements it.";
      Break;
      Text "Give the declaration a body in the module, or mark one function with pragma Implements(Name => \"";
      Text name;
      Text "\")."
    ]

  let two_implementations ~name ~first ~second =
    hilde_raise (H 2064) DeclarationError [
      Text "The slot ";
      Code name;
      Text " is implemented twice: by ";
      Code first;
      Text " and by ";
      Code second;
      Text ".";
      Break;
      Text "A slot has one implementation in a programme; remove the pragma Implements from one of them."
    ]

  let signature_differs ~name ~impl ~why =
    hilde_raise (H 2065) DeclarationError [
      Text "The function ";
      Code impl;
      Text " implements the slot ";
      Code name;
      Text " but its signature differs: ";
      Text why;
      Text ".";
      Break;
      Text "An implementation has the parameters of the slot, with their names and types, and its result type."
    ]

  let no_such_slot ~name ~impl =
    hilde_raise (H 2066) DeclarationError [
      Text "The function ";
      Code impl;
      Text " implements ";
      Code name;
      Text ", which is not a slot of a module compiled before it.";
      Break;
      Text "The name is Module.function of a declaration with pragma Slot, and the implementing module imports that module."
    ]

  let misplaced ~what =
    hilde_raise (H 2067) DeclarationError [
      Text what;
      Break;
      Text "pragma Slot stands at a function declaration in an interface, and pragma Implements at a function definition that is not a slot; neither at a function generic over anything but regions."
    ]
end

(* A new programme starts with an empty table: one process may compile
   several, as hilde test does. *)
let reset (): unit =
  Hashtbl.reset slots;
  implementations := [];
  Hashtbl.reset emitted_slots;
  Hashtbl.reset emitted_impls

(* The table after the built-in modules, which every programme of the
   process starts from. *)
let base: (slot list * (string * emitted) list) ref = ref ([], [])

let save_base (): unit =
  base := (Hashtbl.fold (fun _ s acc -> s :: acc) slots [],
           Hashtbl.fold (fun k e acc -> (k, e) :: acc) emitted_slots [])

let restore_base (): unit =
  reset ();
  let (ss, es) = !base in
  List.iter (fun s -> Hashtbl.replace slots (full_name s.slot_module s.slot_name) s) ss;
  List.iter (fun (k, e) -> Hashtbl.replace emitted_slots k e) es

let register_slot (s: slot): unit =
  Hashtbl.replace slots (full_name s.slot_module s.slot_name) s

let find_slot (name: string): slot option =
  Hashtbl.find_opt slots name

let is_slot (m: module_name) (n: identifier): bool =
  Hashtbl.mem slots (full_name m n)

let register_implementation (i: implementation): unit =
  (match find_slot i.target with
   | None ->
      adorn_error_with_span i.impl_span
        (fun _ -> Errors.no_such_slot ~name:i.target ~impl:(full_name i.impl_module i.impl_name))
   | Some _ ->
      ());
  (match List.find_opt (fun j -> j.target = i.target) !implementations with
   | Some j ->
      adorn_error_with_span i.impl_span
        (fun _ -> Errors.two_implementations ~name:i.target
                    ~first:(full_name j.impl_module j.impl_name)
                    ~second:(full_name i.impl_module i.impl_name))
   | None ->
      ());
  implementations := !implementations @ [i]

let implementation_of (name: string): implementation option =
  List.find_opt (fun i -> i.target = name) !implementations

(* The name of the C function that carries the default body of a slot. *)
let default_c_name (c_name: string): string = c_name ^ "_slot_default"

let note_slot_emitted (name: string) (e: emitted): unit =
  Hashtbl.replace emitted_slots name e

let note_impl_emitted (name: string) (c_name: string): unit =
  Hashtbl.replace emitted_impls name c_name

(* The slot a function of this module and name implements, if it does. *)
let slot_implemented_by (m: module_name) (n: identifier): slot option =
  match List.find_opt (fun i -> equal_module_name i.impl_module m && equal_identifier i.impl_name n) !implementations with
  | Some i -> find_slot i.target
  | None -> None

(* Whether a function of this module and name implements a slot. *)
let implements (m: module_name) (n: identifier): bool =
  List.exists (fun i -> equal_module_name i.impl_module m && equal_identifier i.impl_name n) !implementations

(* The signature of a function of the environment: its type parameters, its
   parameters, with names and types, and its result. *)
let signature (env: Env.env) (m: module_name) (n: identifier): (TypeParameters.typarams * Type.value_parameter list * Type.ty) option =
  match Env.get_decl_by_name env (make_sident m n) with
  | Some (EnvTypes.Function { typarams; value_params; rt; _ }) -> Some (typarams, value_params, rt)
  | _ -> None

(* The parameters and result of the implementation with its type
   parameters renamed, by position, to the slot's: both are generic over
   regions only, and each names its own. *)
let renamed (slot_typarams: TypeParameters.typarams) (impl_typarams: TypeParameters.typarams) (ip, irt) =
  let st = TypeParameters.typarams_as_list slot_typarams
  and it = TypeParameters.typarams_as_list impl_typarams in
  if List.length st <> List.length it then
    (ip, irt)
  else
    let bindings =
      TypeBindings.bindings_from_list
        (List.map2 (fun i s -> (i, Type.TyVar (TypeParameter.typaram_to_tyvar s))) it st)
    in
    let r = TypeBindings.replace_variables bindings in
    (List.map (fun (Type.ValueParameter (n, t)) -> Type.ValueParameter (n, r t)) ip, r irt)

let differences (st, sp, srt) (it, ip, irt): string option =
  let n_slot = List.length (TypeParameters.typarams_as_list st)
  and n_impl = List.length (TypeParameters.typarams_as_list it) in
  if n_slot <> n_impl then
    Some (Printf.sprintf "the slot has %d region parameters and the implementation %d" n_slot n_impl)
  else
  let (ip, irt) = renamed st it (ip, irt) in
  if List.length sp <> List.length ip then
    Some (Printf.sprintf "the slot has %d parameters and the implementation %d" (List.length sp) (List.length ip))
  else
    match List.find_opt (fun (Type.ValueParameter (a, at), Type.ValueParameter (b, bt)) ->
              not (equal_identifier a b) || not (Type.equal_ty at bt)) (List.combine sp ip) with
    | Some (Type.ValueParameter (a, at), Type.ValueParameter (b, bt)) ->
       Some (Printf.sprintf "the parameter %s: %s of the slot is %s: %s in the implementation"
               (ident_string a) (Type.type_string at) (ident_string b) (Type.type_string bt))
    | None ->
       if Type.equal_ty srt irt then None
       else Some (Printf.sprintf "the slot returns %s and the implementation %s" (Type.type_string srt) (Type.type_string irt))

(* The checks of the whole programme, after the last module: a slot without
   a default has an implementation, and an implementation has the slot's
   signature. *)
let check (env: Env.env): unit =
  Hashtbl.iter
    (fun name s ->
      match implementation_of name with
      | None ->
         if not s.has_default then
           adorn_error_with_span s.slot_span (fun _ -> Errors.no_implementation ~name)
      | Some i ->
         (match (signature env s.slot_module s.slot_name, signature env i.impl_module i.impl_name) with
          | (Some a, Some b) ->
             (match differences a b with
              | Some why ->
                 adorn_error_with_span i.impl_span
                   (fun _ -> Errors.signature_differs ~name ~impl:(full_name i.impl_module i.impl_name) ~why)
              | None -> ())
          | _ -> internal_err ("A slot or its implementation is not in the environment: " ^ name)))
    slots

(* The C function of every slot that was written: it calls the
   implementation or the default directly.  A slot whose result is Never
   says so, and ends in an unreachable after the call. *)
let forwarders (): c_decl list =
  Hashtbl.fold
    (fun name e acc ->
      let target: string =
        match implementation_of name with
        | Some i ->
           (match Hashtbl.find_opt emitted_impls (full_name i.impl_module i.impl_name) with
            | Some c -> c
            | None -> internal_err ("The implementation of the slot " ^ name ^ " was not written."))
        | None ->
           default_c_name e.c_name
      in
      let args: c_expr list = List.map (fun (CValueParam (n, _)) -> CVar n) e.c_params in
      let call: c_expr = CFuncall (target, args) in
      let body: c_stmt =
        if e.never then
          CBlock [CDiscarding call; CDiscarding (CFuncall ("__builtin_unreachable", []))]
        else
          CBlock [CReturn call]
      in
      (* The default is used even when an implementation replaces it, so
         that the C compiler does not warn of a function nothing calls. *)
      let keep_default: c_stmt = CDiscarding (CCast (CVar (default_c_name e.c_name), CNamedType "void")) in
      CFunctionDefinition (Desc ("Slot " ^ name), e.c_name, e.c_params, e.c_rt, CBlock [keep_default; body])
      :: acc)
    emitted_slots []
