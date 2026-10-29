(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* The error code reaches both renderings.  The
   end-to-end tests read only the JSON one, through --error-format=json;
   this reads the plain one too, from an error raised where the compiler
   raises it. *)
open OUnit2
open Hilde_core.Error
open TestUtil

let raised (f: unit -> unit): hilde_error =
  try
    f ();
    assert_failure "nothing was raised"
  with Hilde_error e -> e

let lines (s: string): string list =
  String.split_on_char '\n' s

let test_code_string _ =
  eq "H0007" (code_string (H 7));
  eq "H3009" (code_string (H 3009))

let test_plain_carries_the_code _ =
  let e = raised (fun () -> Hilde_core.TypeErrors.arithmetic_not_numeric Hilde_core.Type.Unit) in
  let (HildeError { code; _ }) = e in
  eq "H3009" (code_string code);
  (* The line stands directly under the title, and only once. *)
  let l = lines (render_error_to_plain e) in
  eq ["Error:"; "  Title: Type Error"; "  Error code: H3009"]
    (List.filteri (fun i _ -> i < 3) l);
  eq 1 (List.length (List.filter (fun x -> x = "  Error code: H3009") l))

let test_json_carries_the_code _ =
  let e = raised (fun () -> Hilde_core.TypeErrors.arithmetic_not_numeric Hilde_core.Type.Unit) in
  match render_error_to_json e with
  | `Assoc fields ->
     eq (Some (`String "H3009")) (List.assoc_opt "code" fields);
     eq ["module"; "code"; "kind"; "text"; "span"; "context"] (List.map fst fields)
  | _ -> assert_failure "the JSON error is not an object"

let test_internal_error_is_h9999 _ =
  let e = raised (fun () -> internal_err "a test") in
  let (HildeError { code; kind; _ }) = e in
  eq "H9999" (code_string code);
  eq "Internal Error" (error_title kind)

let suite =
  "Error codes" >::: [
      "code_string" >:: test_code_string;
      "plain carries the code" >:: test_plain_carries_the_code;
      "json carries the code" >:: test_json_carries_the_code;
      "internal error is H9999" >:: test_internal_error_is_h9999
    ]

let _ = run_test_tt_main suite
