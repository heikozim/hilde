(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Id
open Env
open EnvTypes
open Type
open TypeParameters
open MonoTypeBindings
open Error
open CodeGen
open Identifier

(* The boundary between Hilde and C.  Every function
   marked pragma Foreign_Export gets a wrapper under its export name, in
   every target; for a library the same prototypes go into the header.
   What crosses the boundary:

     Bool                  bool
     Nat8 .. Int64         uint8_t .. int64_t
     Index, ByteSize       size_t
     Float32, Float64      float, double
     Address[T]            T*, for T one of the numbers or an Address
     a function pointer    void*
     Unit (result only)    void
     Span[Nat8, R]         const uint8_t* and a size_t length
     SpanMut[Nat8, R]      uint8_t* and a size_t length
     a record or union     a handle: a pointer to a box on the heap
     &[T, R], &![T, R]     const or plain pointer to T's handle

   where R is a region parameter of the exported function and T a record
   or union without type parameters.  A handle passed by value is moved:
   the wrapper takes the value out of its box and frees the box, so the
   caller must not use it again.  A handle returned is the caller's until
   it hands it to an exported function that takes it by value.  Anything
   else is refused with H3001. *)

module Errors = struct
  let disallowed_type ty =
    hilde_raise (H 3001) TypeError [
      Text "The type ";
      Type ty;
      Text " is not allowed in the signature of an exported function."
    ]
end

(* How one parameter or the result crosses. *)
type crossing =
  | Scalar of string * string
  (* The C type the caller sees in the header, and the one the library's C
     file writes for it; they differ only for bool, which the header spells
     with stdbool.h and the library's C, which does not include it, as
     _Bool: the same type. *)
  | Bytes of bool
  (* true: the caller's bytes may be written. *)
  | Handle of string * string
  (* The handle's C name, and the C type of the value in its box. *)
  | HandleRef of string * string * bool
  (* As a handle, not moved; true for a write reference. *)
  | Site
  (* The call site a function with a requires takes: not in the
     header, the wrapper passes one that names the export. *)
  | Nothing

let int_name (s: signedness) (w: integer_width): string =
  match (s, w) with
  | (_, WidthByteSize) | (_, WidthIndex) -> "size_t"
  | (Unsigned, Width8) -> "uint8_t"
  | (Unsigned, Width16) -> "uint16_t"
  | (Unsigned, Width32) -> "uint32_t"
  | (Unsigned, Width64) -> "uint64_t"
  | (Signed, Width8) -> "int8_t"
  | (Signed, Width16) -> "int16_t"
  | (Signed, Width32) -> "int32_t"
  | (Signed, Width64) -> "int64_t"

let rec address_target (ty: ty): string option =
  match ty with
  | Integer (s, w) -> Some (int_name s w)
  | SingleFloat -> Some "float"
  | DoubleFloat -> Some "double"
  | Address t ->
     (match address_target t with
      | Some n -> Some (n ^ "*")
      | None -> None)
  | _ -> None

let scalar (ty: ty): (string * string) option =
  match ty with
  | Boolean -> Some ("bool", "_Bool")
  | Integer (s, w) -> let n = int_name s w in Some (n, n)
  | SingleFloat -> Some ("float", "float")
  | DoubleFloat -> Some ("double", "double")
  | Address t ->
     (match address_target t with
      | Some n -> Some (n ^ "*", n ^ "*")
      | None -> None)
  | FnPtr _ -> Some ("void*", "void*")
  | _ -> None

let is_region_var (ty: ty): bool =
  match ty with
  | TyVar (TypeVariable (_, RegionUniverse, _, _)) -> true
  | _ -> false

(* The C name of a handle: hilde_handle_ and the type's qualified name,
   with every underscore doubled and every dot made one underscore, so that
   two different names never give the same C name. *)
let handle_name (name: qident): string =
  let full: string =
    (mod_name_string (source_module_name name)) ^ "." ^ (ident_string (original_name name))
  in
  let b = Buffer.create (String.length full * 2) in
  String.iter
    (fun c ->
      match c with
      | '_' -> Buffer.add_string b "__"
      | '.' -> Buffer.add_char b '_'
      | c -> Buffer.add_char b c)
    full;
  "hilde_handle_" ^ Buffer.contents b

let handle_of (env: env) (ty: ty): (string * string) option =
  match ty with
  | NamedType (name, [], _) ->
     let mono (id: decl_id) (typarams: typarams): (string * string) option =
       if typarams_size typarams = 0 then
         (match get_type_monomorph env id empty_mono_bindings with
          | Some m -> Some (handle_name name, gen_mono_id m)
          | None -> None)
       else
         None
     in
     (match get_decl_by_name env (qident_to_sident name) with
      | Some (Record { id; typarams; _ }) -> mono id typarams
      | Some (Union { id; typarams; _ }) -> mono id typarams
      | _ -> None)
  | _ ->
     None

let classify_param (env: env) (ty: ty): crossing =
  match scalar ty with
  | Some (h, c) -> Scalar (h, c)
  | None ->
     (match ty with
      | Span (Integer (Unsigned, Width8), r) when is_region_var r ->
         Bytes false
      | SpanMut (Integer (Unsigned, Width8), r) when is_region_var r ->
         Bytes true
      | ReadRef (t, r) when is_region_var r ->
         (match handle_of env t with
          | Some (h, c) -> HandleRef (h, c, false)
          | None -> Errors.disallowed_type ty)
      | WriteRef (t, r) when is_region_var r ->
         (match handle_of env t with
          | Some (h, c) -> HandleRef (h, c, true)
          | None -> Errors.disallowed_type ty)
      | _ ->
         (match handle_of env ty with
          | Some (h, c) -> Handle (h, c)
          | None -> Errors.disallowed_type ty))

let classify_result (env: env) (ty: ty): crossing =
  match ty with
  | Unit -> Nothing
  | Never -> Errors.disallowed_type ty
  | _ ->
     (match scalar ty with
      | Some (h, c) -> Scalar (h, c)
      | None ->
         (match handle_of env ty with
          | Some (h, c) -> Handle (h, c)
          | None -> Errors.disallowed_type ty))

type export = {
    export_name: string;
    mono_name: string;
    params: (string * crossing) list;
    result: crossing;
  }

let get_export (env: env) (id: decl_id) (export_name: string): export =
  match get_decl_by_id env id with
  | Some (Function { id; name; typarams; value_params; rt; _ }) ->
     let mono_name: string =
       match get_function_monomorph env id (Monomorphize.export_bindings typarams) with
       | Some m -> gen_mono_id m
       | None -> internal_err ("No monomorph of exported function `" ^ (ident_string name) ^ "`")
     in
     let params =
       List.map
         (fun (ValueParameter (n, ty)) ->
           if String.equal (ident_string n) Names.contract_site_param then
             (gen_ident n, Site)
           else
             (gen_ident n, classify_param env ty))
         value_params
     in
     { export_name; mono_name; params; result = classify_result env rt }
  | _ ->
     internal_err "Can't find the exported function in the environment."

(* The exports in the order they are declared. *)
let all_exports (env: env): export list =
  List.rev_map (fun (id, name) -> get_export env id name) (get_export_functions env)

let param_decls (header: bool) ((name, c): string * crossing): string list =
  match c with
  | Scalar (h, w) -> [ (if header then h else w) ^ " " ^ name ]
  | Bytes false -> [ "const uint8_t* " ^ name; "size_t " ^ name ^ "_length" ]
  | Bytes true -> [ "uint8_t* " ^ name; "size_t " ^ name ^ "_length" ]
  | Handle (h, _) -> [ h ^ "* " ^ name ]
  | HandleRef (h, _, false) -> [ "const " ^ h ^ "* " ^ name ]
  | HandleRef (h, _, true) -> [ h ^ "* " ^ name ]
  | Site | Nothing -> []

let result_type (header: bool) (c: crossing): string =
  match c with
  | Scalar (h, w) -> if header then h else w
  | Handle (h, _) -> h ^ "*"
  | Nothing -> "void"
  | Bytes _ | HandleRef _ | Site -> internal_err "not a result"

let prototype (header: bool) (e: export): string =
  let params = List.concat_map (param_decls header) e.params in
  (result_type header e.result) ^ " " ^ e.export_name ^ "("
  ^ (match params with [] -> "void" | _ -> String.concat ", " params) ^ ")"

(* The handles an export names, each once, in the order met. *)
let handle_names (exports: export list): string list =
  let of_crossing c =
    match c with
    | Handle (h, _) | HandleRef (h, _, _) -> [h]
    | _ -> []
  in
  let all = List.concat_map (fun e -> List.concat_map (fun (_, c) -> of_crossing c) e.params @ of_crossing e.result) exports in
  List.fold_left (fun acc h -> if List.mem h acc then acc else acc @ [h]) [] all

let handle_typedefs (exports: export list): string =
  String.concat ""
    (List.map (fun h -> "typedef struct " ^ h ^ " " ^ h ^ ";\n") (handle_names exports))

(* A C string literal of an export name, for the runtime's messages.  An
   export name is a C identifier (H2050), so nothing in it needs escaping. *)
let quoted (s: string): string = "\"" ^ s ^ "\""

let wrapper (e: export): string =
  let q: string = quoted e.export_name in
  let before (name, c) =
    match c with
    | Bytes _ ->
       "  hilde_span_t hilde_w_" ^ name ^ " = hilde_library_bytes(" ^ q ^ ", "
       ^ "(const void*) " ^ name ^ ", " ^ name ^ "_length);\n"
    | Handle (_, value) ->
       "  " ^ value ^ " hilde_w_" ^ name ^ ";\n"
       ^ "  hilde_library_take(" ^ q ^ ", (void*) " ^ name ^ ", &hilde_w_" ^ name
       ^ ", sizeof(" ^ value ^ "));\n"
    | HandleRef _ ->
       "  hilde_library_check_handle(" ^ q ^ ", (const void*) " ^ name ^ ");\n"
    | Scalar _ | Site | Nothing -> ""
  in
  (* The call site of a call from C: the export's name, a C identifier
     (H2050), so nothing in it needs escaping. *)
  let site: string = "the caller of the exported function " ^ e.export_name in
  let argument (name, c) =
    match c with
    | Scalar ("bool", _) -> "(hilde_bool_t) " ^ name
    | Scalar _ -> name
    | Bytes _ -> "hilde_w_" ^ name
    | Handle _ -> "hilde_w_" ^ name
    | HandleRef (_, value, _) -> "(" ^ value ^ "*) " ^ name
    | Site ->
       "hilde_make_span_from_string(" ^ (quoted site) ^ ", " ^ (string_of_int (String.length site)) ^ ")"
    | Nothing -> internal_err "not a parameter"
  in
  let call = e.mono_name ^ "(" ^ String.concat ", " (List.map argument e.params) ^ ")" in
  let finish =
    match e.result with
    | Nothing ->
       "  (void) " ^ call ^ ";\n"
       ^ "  hilde_library_leave();\n"
    | Scalar ("bool", _) ->
       "  _Bool hilde_w_result = " ^ call ^ " != 0;\n"
       ^ "  hilde_library_leave();\n"
       ^ "  return hilde_w_result;\n"
    | Scalar (_, w) ->
       "  " ^ w ^ " hilde_w_result = " ^ call ^ ";\n"
       ^ "  hilde_library_leave();\n"
       ^ "  return hilde_w_result;\n"
    | Handle (h, value) ->
       "  " ^ value ^ " hilde_w_result = " ^ call ^ ";\n"
       ^ "  void* hilde_w_box = hilde_library_box(" ^ q ^ ", &hilde_w_result, sizeof(" ^ value ^ "));\n"
       ^ "  hilde_library_leave();\n"
       ^ "  return (" ^ h ^ "*) hilde_w_box;\n"
    | Bytes _ | HandleRef _ | Site -> internal_err "not a result"
  in
  (prototype false e) ^ " {\n"
  ^ "  hilde_library_enter(" ^ q ^ ");\n"
  ^ String.concat "" (List.map before e.params)
  ^ finish
  ^ "}\n"

(* The C of every wrapper: the handles, a prototype of each export with
   default visibility, so that a shared library built with
   -fvisibility=hidden shows these and hides the rest, and the definitions,
   which the compiler holds against the prototypes. *)
let wrappers_code (env: env): string =
  let exports = all_exports env in
  "/* --- BEGIN the wrappers of the exported functions --- */\n"
  ^ handle_typedefs exports
  ^ String.concat ""
      (List.map (fun e -> "__attribute__((visibility(\"default\"))) " ^ (prototype false e) ^ ";\n") exports)
  ^ String.concat "\n" (List.map wrapper exports)
  ^ "/* --- END the wrappers of the exported functions --- */\n"

(* The header of a library: its guard from the file's name, the three
   standard headers the types need, the libraries a programme linking the
   static archive has to link as well, the handles, the runtime's three
   functions, and the prototypes. *)
let export_names (env: env): string list =
  List.map (fun e -> e.export_name) (all_exports env)

let library_header (env: env) (file_name: string) (libraries: string list): string =
  let exports = all_exports env in
  let guard: string =
    "HILDE_LIBRARY_"
    ^ String.map
        (fun c ->
          match c with
          | 'a' .. 'z' -> Char.uppercase_ascii c
          | 'A' .. 'Z' | '0' .. '9' -> c
          | _ -> '_')
        file_name
  in
  "/* " ^ file_name ^ ", written by hilde compile: the functions this library\n"
  ^ "   exports.  Call hilde_start before the first of them and hilde_end\n"
  ^ "   after the last.  A handle passed by value is taken over and must not be\n"
  ^ "   used again; a handle returned belongs to the caller until it is passed\n"
  ^ "   by value.  A static archive needs these libraries as well:\n"
  ^ "   " ^ (match libraries with [] -> "none" | _ -> String.concat " " libraries) ^ " */\n"
  ^ "#ifndef " ^ guard ^ "\n"
  ^ "#define " ^ guard ^ "\n\n"
  ^ "#include <stdbool.h>\n"
  ^ "#include <stddef.h>\n"
  ^ "#include <stdint.h>\n\n"
  ^ "#ifdef __cplusplus\n"
  ^ "extern \"C\" {\n"
  ^ "#endif\n\n"
  ^ handle_typedefs exports
  ^ (match handle_names exports with [] -> "" | _ -> "\n")
  ^ "void hilde_start(void);\n"
  ^ "void hilde_end(void);\n"
  ^ "void hilde_set_abort_handler(void (*handler)(const char* message));\n\n"
  ^ String.concat "" (List.map (fun e -> (prototype true e) ^ ";\n") exports)
  ^ "\n#ifdef __cplusplus\n"
  ^ "}\n"
  ^ "#endif\n\n"
  ^ "#endif\n"
