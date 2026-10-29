(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* `hilde query': what a module declares -- names, kinds, types and where
   each is defined -- as JSON, for a program that writes Hilde.

   The types come from the environment after the whole command line has
   been compiled, so they are the compiler's own resolved types and not the
   text as written; the places come from the module's declarations as
   parsed, which is where the spans live -- the typed stages keep no span.
   The two are joined by name.  An instance has no name: it is joined by
   its typeclass and the head of its argument, which instances may not
   share -- two such instances would overlap, and the compiler refuses
   that.  Not by the order of a list: the environment lists a module's
   instances in the reverse of their order in the source (measured by the
   test with two). *)
open Identifier
open Id
open Common
open Span
open Stages.Combined
open EnvTypes
open Env
open Type
open TypeParameter
open TypeParameters

let json_string (s: string): Yojson.Basic.t = `String s

let vis_string (v: vis): string =
  match v with
  | VisPublic -> "public"
  | VisPrivate -> "private"

let type_vis_string (v: type_vis): string =
  match v with
  | TypeVisPublic -> "public"
  | TypeVisOpaque -> "opaque"
  | TypeVisPrivate -> "private"

let docstring_json (Docstring d: docstring): Yojson.Basic.t =
  if String.trim d = "" then `Null else `String (String.trim d)

let typarams_json (tps: typarams): Yojson.Basic.t =
  `List (List.map
           (fun tp ->
             `Assoc [
                 ("name", json_string (ident_string (typaram_name tp)));
                 ("universe", json_string (universe_string (typaram_universe tp)))
               ])
           (typarams_as_list tps))

let params_json (ps: value_parameter list): Yojson.Basic.t =
  `List (List.map
           (fun (ValueParameter (n, t)) ->
             `Assoc [
                 ("name", json_string (ident_string n));
                 ("type", json_string (type_string t))
               ])
           ps)

let slots_json (slots: typed_slot list): Yojson.Basic.t =
  `List (List.map
           (fun (TypedSlot (n, t)) ->
             `Assoc [
                 ("name", json_string (ident_string n));
                 ("type", json_string (type_string t))
               ])
           slots)

(* The head of a type as written, and of a type as resolved: the name of
   its constructor, or the reference or span it is. *)
let written_head (t: Stages.Ast.qtypespec): string =
  match t with
  | Stages.Ast.QTypeSpecifier (q, _) -> ident_string (original_name q)
  | Stages.Ast.QReadRef _ -> "&"
  | Stages.Ast.QWriteRef _ -> "&!"
  | Stages.Ast.QSpan _ -> "Span"
  | Stages.Ast.QSpanWrite _ -> "Span!"

let resolved_head (t: ty): string =
  match t with
  | NamedType (q, _, _) -> ident_string (original_name q)
  | ReadRef _ -> "&"
  | WriteRef _ -> "&!"
  | Span _ -> "Span"
  | SpanMut _ -> "Span!"
  | Address _ -> "Address"
  | Pointer _ -> "Pointer"
  | _ -> type_string t

let entry (name: string) (kind: string) (span: span) (fields: (string * Yojson.Basic.t) list): Yojson.Basic.t =
  `Assoc ([("name", json_string name); ("kind", json_string kind)]
          @ fields
          @ [("span", Error.span_json span)])

(* One declaration of the module, with what the environment knows of it.
   `None' only for a declaration the environment does not have, which
   cannot happen after a successful compile and is reported as an internal
   error rather than left out. *)
let definition (env: env) (mn: module_name) (instances: decl list) (d: combined_definition): Yojson.Basic.t =
  let lookup (name: identifier): decl =
    match get_decl_by_name env (make_sident mn name) with
    | Some decl -> decl
    | None -> Error.internal_err ("query: " ^ (ident_string name) ^ " is not in the environment")
  in
  match d with
  | CConstant (span, _, name, _, _, _) ->
     (match lookup name with
      | Constant { vis; ty; docstring; _ } ->
         entry (ident_string name) "constant" span [
             ("visibility", json_string (vis_string vis));
             ("type", json_string (type_string ty));
             ("docstring", docstring_json docstring)
           ]
      | _ -> Error.internal_err "query: a constant that is not one")
  | CRecord (span, _, name, _, _, _, _) ->
     (match lookup name with
      | Record { vis; typarams; universe; slots; docstring; _ } ->
         entry (ident_string name) "record" span [
             ("visibility", json_string (type_vis_string vis));
             ("universe", json_string (universe_string universe));
             ("type_parameters", typarams_json typarams);
             ("slots", slots_json slots);
             ("docstring", docstring_json docstring)
           ]
      | _ -> Error.internal_err "query: a record that is not one")
  | CUnion (span, _, name, _, _, _, _) ->
     (match lookup name with
      | Union { id; vis; typarams; universe; docstring; _ } ->
         let cases =
           List.map
             (fun c ->
               match c with
               | UnionCase { name; slots; _ } ->
                  `Assoc [
                      ("name", json_string (ident_string name));
                      ("slots", slots_json slots)
                    ]
               | _ -> Error.internal_err "query: a union case that is not one")
             (get_union_cases env id)
         in
         entry (ident_string name) "union" span [
             ("visibility", json_string (type_vis_string vis));
             ("universe", json_string (universe_string universe));
             ("type_parameters", typarams_json typarams);
             ("cases", `List cases);
             ("docstring", docstring_json docstring)
           ]
      | _ -> Error.internal_err "query: a union that is not one")
  | CFunction (span, _, name, _, _, _, _, _, _, _) ->
     (match lookup name with
      | Function { vis; typarams; value_params; rt; external_name; docstring; raises; _ } ->
         entry (ident_string name) "function" span [
             ("visibility", json_string (vis_string vis));
             ("type_parameters", typarams_json typarams);
             ("parameters", params_json value_params);
             ("returns", json_string (type_string rt));
             ("raises", `List (List.map json_string raises));
             ("foreign_name", (match external_name with Some n -> `String n | None -> `Null));
             ("docstring", docstring_json docstring)
           ]
      | _ -> Error.internal_err "query: a function that is not one")
  | CTypeclass (span, _, name, _, _, _) ->
     (match lookup name with
      | TypeClass { id; vis; param; docstring; _ } ->
         let methods =
           List.map
             (fun m ->
               match m with
               | TypeClassMethod { name; typarams; value_params; rt; _ } ->
                  `Assoc [
                      ("name", json_string (ident_string name));
                      ("type_parameters", typarams_json typarams);
                      ("parameters", params_json value_params);
                      ("returns", json_string (type_string rt))
                    ]
               | _ -> Error.internal_err "query: a method that is not one")
             (get_methods_from_typeclass_id env id)
         in
         entry (ident_string name) "typeclass" span [
             ("visibility", json_string (vis_string vis));
             ("parameter", json_string (ident_string (typaram_name param)));
             ("methods", `List methods);
             ("docstring", docstring_json docstring)
           ]
      | _ -> Error.internal_err "query: a typeclass that is not one")
  | CInstance (span, _, qname, _, written, _, _) ->
     let typeclass_of (id: decl_id): (module_name * identifier) =
       match get_decl_by_id env id with
       | Some (TypeClass { name; mod_id; _ }) -> (module_name_from_id env mod_id, name)
       | _ -> Error.internal_err "query: an instance of no typeclass"
     in
     let wanted_class = (source_module_name qname, original_name qname) in
     let matches =
       List.filter
         (fun i ->
           match i with
           | Instance { typeclass_id; argument; _ } ->
              let (cm, cn) = typeclass_of typeclass_id in
              equal_module_name cm (fst wanted_class)
              && equal_identifier cn (snd wanted_class)
              && (resolved_head argument) = (written_head written)
           | _ -> false)
         instances
     in
     (match matches with
      | [Instance { vis; typeclass_id; typarams; argument; docstring; _ }] ->
         let (cm, cn) = typeclass_of typeclass_id in
         entry (ident_string (original_name qname)) "instance" span [
             ("visibility", json_string (vis_string vis));
             ("typeclass", json_string ((mod_name_string cm) ^ "." ^ (ident_string cn)));
             ("type_parameters", typarams_json typarams);
             ("argument", json_string (type_string argument));
             ("docstring", docstring_json docstring)
           ]
      | _ ->
         Error.internal_err (Printf.sprintf "query: %d instances match one declaration" (List.length matches)))

let query_module (env: env) (combined: combined_module): Yojson.Basic.t =
  let (CombinedModule { name; decls; _ }) = combined in
  let instances =
    match get_module_by_name env name with
    | Some (ModRec { id; _ }) -> module_instances env id
    | None -> Error.internal_err "query: the module is not in the environment"
  in
  `Assoc [
      ("version", `Int 1);
      ("module", json_string (mod_name_string name));
      ("declarations", `List (List.map (definition env name instances) decls))
    ]
