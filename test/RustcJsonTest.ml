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

(* --fix writes only the suggestion the raise site marked as the one fix.
   The hint of an error is a suggestion like the others, and is left to the
   reader: this holds the two sides of that mark, and the span a certain
   suggestion takes when it names none, which is the error's own. *)
let test_machine_fix_none_for_a_hint _ =
  let hint = Suggest { replacement = "(1 + 2)"; at = Some (place 2 1 3); certain = false } in
  eq None (machine_fix (error [Text "one"; hint]))

let test_machine_fix_of_a_certain_suggestion _ =
  let fix = Suggest { replacement = "(1 + 2)"; at = Some (place 2 1 3); certain = true } in
  eq (Some (place 2 1 3, "(1 + 2)")) (machine_fix (error [Text "one"; fix]))

let test_machine_fix_takes_the_errors_span _ =
  let fix = Suggest { replacement = "since"; at = None; certain = true } in
  eq (Some (place 2 4 5, "since")) (machine_fix (error [Text "one"; fix]))

(* H0008, a reserved word as a name: its free name is the one fix when the
   word stands once in the source and the free name nowhere; a use of the
   word elsewhere, or the free name already taken, leaves it a hint. *)
let reserved_fix (code: string): string option =
  try
    ignore (Hilde_core.ParserInterface.parse_module_body code "T.hiq");
    Some "parsed"
  with Hilde_error e ->
    (match machine_fix e with
     | Some (_, replacement) -> Some replacement
     | None -> None)

let test_reserved_word_once _ =
  eq (Some "since") (reserved_fix
    "module body T is\n    function f(from: Index): Index is\n        return 1;\n    end;\nend module body.\n")

let test_reserved_word_used _ =
  eq None (reserved_fix
    "module body T is\n    function f(from: Index): Index is\n        return from;\n    end;\nend module body.\n")

let test_reserved_word_free_name_taken _ =
  eq None (reserved_fix
    "module body T is\n    function f(from: Index, since: Index): Index is\n        return 1;\n    end;\nend module body.\n")

(* H0009, an operator after an operation: the parentheses around the
   operation before it are the one fix when that operation binds tighter by
   the usual convention, or as tightly and is arithmetic; else a hint. *)
let grouping_fix (expression: string): string option =
  reserved_fix
    ("module body T is\n    function f(a: Index, b: Index, c: Index): Index is\n        return "
     ^ expression ^ ";\n    end;\nend module body.\n")

let test_grouping_tighter_before _ =
  eq (Some "(a * b)") (grouping_fix "a * b + c")

let test_grouping_left_to_right _ =
  eq (Some "(a - b)") (grouping_fix "a - b + c")

let test_grouping_comparison_before_and _ =
  eq (Some "(a = b)") (grouping_fix "a = b and c")

let test_grouping_looser_before _ =
  eq None (grouping_fix "a + b * c")

let test_grouping_two_comparisons _ =
  eq None (grouping_fix "a < b < c")

let test_grouping_or_before_and _ =
  eq None (grouping_fix "a or b and c")

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
      "no machine fix for a hint" >:: test_machine_fix_none_for_a_hint;
      "machine fix of a certain suggestion" >:: test_machine_fix_of_a_certain_suggestion;
      "machine fix takes the error's span" >:: test_machine_fix_takes_the_errors_span;
      "a reserved word once: its free name is the one fix" >:: test_reserved_word_once;
      "a reserved word used again: a hint" >:: test_reserved_word_used;
      "a reserved word whose free name is taken: a hint" >:: test_reserved_word_free_name_taken;
      "a * b + c: the parentheses are the one fix" >:: test_grouping_tighter_before;
      "a - b + c: the parentheses are the one fix" >:: test_grouping_left_to_right;
      "a = b and c: the parentheses are the one fix" >:: test_grouping_comparison_before_and;
      "a + b * c: a hint" >:: test_grouping_looser_before;
      "a < b < c: a hint" >:: test_grouping_two_comparisons;
      "a or b and c: a hint" >:: test_grouping_or_before_and;
      "unknown source" >:: test_unknown_source;
      "plain shows the fix" >:: test_plain_shows_the_fix
    ]

let _ = run_test_tt_main suite
