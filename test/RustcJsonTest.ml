(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* --error-format=json writes an error as rustc writes a diagnostic:
   this holds the fields a tool reads --
   the code, the level, the place in bytes and in columns counted from 1, the
   note after the first paragraph break, and a suggested fix as a child of
   level help that carries its replacement. *)
open OUnit2
open Hilde_core.Error
open Hilde_core.ErrorText
open Hilde_core.Span
open TestUtil

let source: string = "ab\ncdefgh\n"

let place (line: int) (c0: int) (c1: int): span =
  Span { filename = "f.hiq"; startp = Position { line; column = c0 }; endp = Position { line; column = c1 } }

let error (text: err_text): hilde_error =
  HildeError {
      module_name = None;
      code = H 9;
      kind = ParseError;
      text;
      span = Some (place 2 4 5);
      source_ctx = None;
    }

let field (name: string) (j: Yojson.Basic.t): Yojson.Basic.t =
  match j with
  | `Assoc fields ->
     (match List.assoc_opt name fields with
      | Some v -> v
      | None -> assert_failure ("no field " ^ name))
  | _ -> assert_failure ("not an object at " ^ name)

let items (j: Yojson.Basic.t): Yojson.Basic.t list =
  match j with
  | `List l -> l
  | _ -> assert_failure "not a list"

let rendered (source_of: string -> string option) (e: hilde_error): Yojson.Basic.t =
  let line = render_error_to_rustc source_of e in
  eq false (String.contains line '\n');
  Yojson.Basic.from_string line

let known (f: string): string option =
  if f = "f.hiq" then Some source else None

let test_fields _ =
  let j = rendered known (error [Text "one"; Break; Text "two"]) in
  eq (`String "diagnostic") (field "$message_type" j);
  eq (`String "one") (field "message" j);
  eq (`String "error") (field "level" j);
  eq (`String "H0009") (field "code" (field "code" j));
  let span = List.hd (items (field "spans" j)) in
  eq (`Int 7) (field "byte_start" span);
  eq (`Int 8) (field "byte_end" span);
  eq (`Int 2) (field "line_start" span);
  eq (`Int 5) (field "column_start" span);
  eq (`Int 6) (field "column_end" span);
  eq (`String "cdefgh") (field "text" (List.hd (items (field "text" span))));
  match items (field "children" j) with
  | [note] ->
     eq (`String "note") (field "level" note);
     eq (`String "two") (field "message" note)
  | _ -> assert_failure "not one child"

let test_suggestion _ =
  let fix = Suggest { replacement = "(1 + 2)"; at = Some (place 2 1 3); certain = false } in
  let j = rendered known (error [Text "one"; fix]) in
  eq (`String "one") (field "message" j);
  match items (field "children" j) with
  | [help] ->
     eq (`String "help") (field "level" help);
     let span = List.hd (items (field "spans" help)) in
     eq (`String "(1 + 2)") (field "suggested_replacement" span);
     eq (`String "MaybeIncorrect") (field "suggestion_applicability" span);
     eq (`Int 4) (field "byte_start" span);
     eq (`Int 6) (field "byte_end" span)
  | _ -> assert_failure "not one child"

let test_certain_fix _ =
  let fix = Suggest { replacement = "since"; at = None; certain = true } in
  let j = rendered known (error [Text "one"; fix]) in
  let help = List.hd (items (field "children" j)) in
  let span = List.hd (items (field "spans" help)) in
  eq (`String "MachineApplicable") (field "suggestion_applicability" span);
  eq (`Int 7) (field "byte_start" span)

let test_unknown_source _ =
  let j = rendered (fun _ -> None) (error [Text "one"]) in
  let span = List.hd (items (field "spans" j)) in
  eq (`Int 0) (field "byte_start" span);
  eq (`List []) (field "text" span)

let test_plain_shows_the_fix _ =
  let fix = Suggest { replacement = "since"; at = None; certain = false } in
  let plain = render_error_to_plain (error [Text "one"; fix]) in
  let has (s: string) (part: string): bool =
    let n = String.length part in
    let rec at i = (i + n <= String.length s) && ((String.sub s i n = part) || at (i + 1)) in
    at 0
  in
  eq true (has plain "Suggested fix: `since`")

let suite =
  "rustc JSON" >::: [
      "fields" >:: test_fields;
      "suggestion" >:: test_suggestion;
      "certain fix" >:: test_certain_fix;
      "unknown source" >:: test_unknown_source;
      "plain shows the fix" >:: test_plain_shows_the_fix
    ]

let _ = run_test_tt_main suite
