(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Type

type err_text = text_elem list

and text_elem =
  | Text of string
  | Code of string
  | Type of ty
  | Break
  | Suggest of suggestion

and suggestion = {
    replacement: string;
    at: Span.span option;
    certain: bool;
  }

let suggestions_of (txt: err_text): suggestion list =
  List.filter_map (fun elem -> match elem with Suggest s -> Some s | _ -> None) txt

let without_suggestions (txt: err_text): err_text =
  List.filter (fun elem -> match elem with Suggest _ -> false | _ -> true) txt

let rec error_text_to_plain (txt: err_text): string =
  String.concat "" (List.map text_elem_to_plain txt)

and text_elem_to_plain (elem: text_elem): string =
  match elem with
  | Text s ->
     s
  | Code c ->
     "`" ^ c ^ "`"
  | Type ty ->
     "`" ^ (type_string ty) ^ "`"
  | Break ->
     "\n\n"
  | Suggest { replacement; _ } ->
     "\n\nSuggested fix: `" ^ replacement ^ "`"

let rec error_text_to_html (txt: err_text): string =
    String.concat "" (List.map text_elem_to_html txt)

and text_elem_to_html (elem: text_elem): string =
  match elem with
  | Text s ->
      s
  | Code c ->
      "<code>" ^ c ^ "</code>"
  | Type ty ->
      "<code>" ^ (type_string ty) ^ "</code>"
  | Break ->
      "<br><br>"
  | Suggest { replacement; _ } ->
      "<br><br>Suggested fix: <code>" ^ replacement ^ "</code>"

let rec error_text_to_json (txt: err_text): Yojson.Basic.t =
  `List (List.map text_elem_to_json txt)

and text_elem_to_json (elem: text_elem): Yojson.Basic.t =
  match elem with
  | Text s ->
     `Assoc [("type", `String "text"); ("content", `String s)]
  | Code c ->
     `Assoc [("type", `String "code"); ("content", `String c)]
  | Type ty ->
     `Assoc [("type", `String "type"); ("content", `String (type_string ty))]
  | Break ->
     `Assoc [("type", `String "break")]
  | Suggest { replacement; certain; _ } ->
     `Assoc [("type", `String "suggestion"); ("content", `String replacement);
             ("applicability", `String (if certain then "MachineApplicable" else "MaybeIncorrect"))]
