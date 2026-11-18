(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* Every declaration of a module is typed: the first error is raised, each
   one after it is kept, so that a check reports them all. *)
open OUnit2
open Hilde_core
open TestUtil

(* The codes of the raised error and of those kept after it. *)
let codes (src: string): string list =
  let source = Compiler.BodyModuleSource { body_filename = "T.hiq"; body_code = src } in
  try
    ignore (Compiler.check_multiple Compiler.empty_compiler [source]);
    []
  with Error.Hilde_error (Error.HildeError { code; _ }) ->
    Error.code_string code
    :: List.map (fun (Error.HildeError { code; _ }) -> Error.code_string code) (Error.further_errors ())

(* Two functions that each return a Bool as an Int32, and a good one between
   them: two errors, the second one kept. *)
let test_two _ =
  let src = String.concat "\n" [
      "module body T is";
      "    function f(): Int32 is";
      "        return true;";
      "    end;";
      "    function g(): Int32 is";
      "        return 1;";
      "    end;";
      "    function h(): Int32 is";
      "        return false;";
      "    end;";
      "end module body."
    ] in
  let found = codes src in
  eq 2 (List.length found);
  eq true (List.hd found = List.nth found 1)

(* The control: one error is one, and a clean module none. *)
let test_one _ =
  let src = String.concat "\n" [
      "module body T is";
      "    function f(): Int32 is";
      "        return true;";
      "    end;";
      "end module body."
    ] in
  eq 1 (List.length (codes src));
  eq 0 (List.length (codes "module body T is\n    function f(): Int32 is\n        return 1;\n    end;\nend module body."))

(* A method that names the parameter of its class nowhere is refused with
   H3111; the call of it in main, typed after it, ends in an internal error
   that is a consequence of the refusal and is not reported beside it. *)
let test_consequence _ =
  let src = String.concat "\n" [
      "module body T is";
      "    typeclass Sized(T: Free) is";
      "        method size(): Index;";
      "    end;";
      "    instance Sized(Int32) is";
      "        method size(): Index is";
      "            return 4;";
      "        end;";
      "    end;";
      "    function main(): ExitCode is";
      "        printLn(size());";
      "        return ExitSuccess();";
      "    end;";
      "end module body."
    ] in
  eq ["H3111"] (codes src)

let suite =
  "AllErrors" >::: [
      "two errors in one module" >:: test_two;
      "one error, and none" >:: test_one;
      "an internal error after the first is left out" >:: test_consequence
    ]

let _ = run_test_tt_main suite
