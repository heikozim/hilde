(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* `hilde test': which functions of a test file are
   tests, and in which form.  Every case of the name rule has a neighbour on
   the other side of it, so that a rule that took every name, or none, would
   fail here; the forms are read from a compiled module, one accepted form of
   each kind and one refused form of each way a form can be wrong. *)
open OUnit2
open Hilde_core.Identifier
open Hilde_core.Error
open Hilde_core.Compiler

let test_names _ =
  List.iter
    (fun (name, want) ->
      assert_equal ~msg:name want (is_test_name (make_ident name)))
    [ ("testLength", true); ("testA", true); ("test2", true);
      ("test", false); ("testing", false); ("tests", false);
      ("test_length", false); ("lengthTest", false); ("Test", false) ]

let body (code: string list): module_source =
  BodyModuleSource { body_filename = "Example.test.hiq"; body_code = String.concat "\n" code }

let tests_of (code: string list): string =
  let source = body code in
  try
    let c = compile_multiple empty_compiler [source] in
    let (_, tests) = test_functions c source in
    String.concat " "
      (List.map
         (fun (n, form) ->
           ident_string n ^ (match form with TestPlain -> ":plain" | TestWithRoot -> ":root"))
         tests)
  with Hilde_error e ->
    let (HildeError { code; _ }) = e in
    code_string code

let test_forms _ =
  assert_equal ~msg:"both forms, in the order of the file, the helper left out"
    "testPlain:plain testRoot:root"
    (tests_of [
         "module body Example.Test is";
         "    function testPlain(): Unit is";
         "        return nil;";
         "    end;";
         "    function helper(): Nat8 is";
         "        return 1;";
         "    end;";
         "    generic [R: Region]";
         "    function testRoot(root: &![RootCapability, R]): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"a parameter"
    "H2046"
    (tests_of [
         "module body Example.Test is";
         "    function testTakesOne(n: Nat8): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"a result"
    "H2046"
    (tests_of [
         "module body Example.Test is";
         "    function testGivesOne(): Nat8 is";
         "        return 1;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"a read reference to the root capability"
    "H2046"
    (tests_of [
         "module body Example.Test is";
         "    generic [R: Region]";
         "    function testReadsRoot(root: &[RootCapability, R]): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"no test at all"
    "H2047"
    (tests_of [
         "module body Example.Test is";
         "    function helper(): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ])

(* `hilde test --contracts' with --contracts-module: the modules named
   alone are checked, each of them once and in the order the names are
   written; with no name every module with contracts under the paths is
   checked, as before; and a name that is no such module is refused with
   H1054, which names it, so that contract checking can neither be
   switched off nor silently come to nothing. *)

(* One module with contracts, written as the pair of files `hilde test'
   reads. *)
let write_module (dir: string) (file: string) (head: string list) (body: string list): unit =
  Out_channel.with_open_bin (Filename.concat dir (file ^ ".hih"))
    (fun oc -> output_string oc (String.concat "\n" head ^ "\n"));
  Out_channel.with_open_bin (Filename.concat dir (file ^ ".hiq"))
    (fun oc -> output_string oc (String.concat "\n" body ^ "\n"))

(* A module whose one function is a constant with a contract: the driver
   draws no input for it, so the run needs no seed to be reproducible. *)
let write_constant (dir: string) (file: string) (name: string) (value: int): unit =
  write_module dir file
    ["module " ^ name ^ " is";
     "    function theValue(): Int32";
     "        ensures result = " ^ string_of_int value ^ ";";
     "end module."]
    ["module body " ^ name ^ " is";
     "    function theValue(): Int32 is";
     "        return " ^ string_of_int value ^ ";";
     "    end;";
     "end module body."]

(* The standard output of f, with the standard output redirected for the
   length of the call. *)
let capture_output (f: unit -> 'a): ('a * string) =
  let path = Filename.temp_file "hilde-test-output" ".txt" in
  flush stdout;
  let saved = Unix.dup Unix.stdout in
  let fd = Unix.openfile path [Unix.O_WRONLY; Unix.O_TRUNC] 0o600 in
  Unix.dup2 fd Unix.stdout;
  let result =
    Fun.protect
      ~finally:(fun () ->
        flush stdout; Unix.dup2 saved Unix.stdout; Unix.close saved; Unix.close fd)
      f
  in
  let text = In_channel.with_open_bin path In_channel.input_all in
  Sys.remove path;
  (result, text)

(* The result lines of a contracts run over [dir] with the modules named,
   in the order the run prints them. *)
let contract_lines (dir: string) (modules: string list): (int * string) =
  capture_output (fun () ->
    Hilde_core.TestRunner.run
      ~paths:[dir] ~module_dirs:[] ~instrument:NoInstrument ~verbose:false
      ~emit_c:None
      ~contracts:(Some { seed = Some "1"; rounds = 2; modules })
      ~jobs:1 ~test_jobs:1 ~fresh_dirs:false ~doc:false ~json:false
      ~mode:ErrorReportPlain)

let contains (text: string) (part: string): bool =
  let n = String.length part in
  let rec at i = i + n <= String.length text && (String.sub text i n = part || at (i + 1)) in
  n = 0 || at 0

let result_lines (out: string): string list =
  List.filter
    (fun l -> String.starts_with ~prefix:"ok    " l || String.starts_with ~prefix:"FAIL  " l)
    (String.split_on_char '\n' out)

let test_contracts_module ctxt =
  let dir = bracket_tmpdir ctxt in
  write_constant dir "Alpha" "Example.Alpha" 1;
  write_constant dir "Beta" "Example.Beta" 2;
  write_constant dir "Gamma" "Example.Gamma" 3;
  (* No name: every module with contracts under the path is checked, as a
     run without --contracts-module always did. *)
  let (rc, out) = contract_lines dir [] in
  assert_equal ~msg:"no name checks every module" 0 rc;
  assert_equal ~msg:"no name: every module, in the order found"
    ["ok    Example.Alpha (contracts)  1 function";
     "ok    Example.Beta (contracts)  1 function";
     "ok    Example.Gamma (contracts)  1 function"]
    (result_lines out);
  (* A subset, written in an order the files do not have, and one name
     twice: each module once, in the order written. *)
  let (rc, out) = contract_lines dir ["Example.Gamma"; "Example.Alpha"; "Example.Gamma"] in
  assert_equal ~msg:"a subset" 0 rc;
  assert_equal ~msg:"a subset, in the order written, a name twice once"
    ["ok    Example.Gamma (contracts)  1 function";
     "ok    Example.Alpha (contracts)  1 function"]
    (result_lines out);
  assert_bool "the module left out is named nowhere"
    (not (contains out "Example.Beta"));
  (* A name that is no module with a contract under the path: refused with
     H1054, which names it, and nothing is checked. *)
  let refused =
    try
      ignore (contract_lines dir ["Example.Nosuch"]);
      None
    with Hilde_error e ->
      let (HildeError { code; _ }) = e in
      Some (code_string code)
  in
  assert_equal ~msg:"an unknown module" (Some "H1054") refused

(* The work directory of hilde test is removed with what a test left in it:
   a link to a directory outside, whose file must stay, and a link whose
   target was removed before it. *)
let test_remove_tree ctxt =
  let base = bracket_tmpdir ctxt in
  let outside = Filename.concat base "outside" in
  let keep = Filename.concat outside "keep.txt" in
  let work = Filename.concat base "work" in
  let docs = Filename.concat work "docs" in
  Sys.mkdir outside 0o700;
  Out_channel.with_open_bin keep (fun oc -> output_string oc "keep\n");
  Sys.mkdir work 0o700;
  Sys.mkdir docs 0o700;
  Out_channel.with_open_bin (Filename.concat docs "readme.txt") (fun oc -> output_string oc "x\n");
  Unix.symlink outside (Filename.concat work "away");
  Unix.symlink "docs/readme.txt" (Filename.concat work "readme");
  Hilde_core.TestRunner.remove_tree work;
  assert_bool "the work directory is gone" (not (Sys.file_exists work));
  assert_bool "the file behind the link is kept" (Sys.file_exists keep);
  Hilde_core.TestRunner.remove_tree work;
  assert_bool "a missing path is no error" (not (Sys.file_exists work))

let suite =
  "TestRunner" >::: [
      "test names" >:: test_names;
      "test forms" >:: test_forms;
      "contracts module" >:: test_contracts_module;
      "remove tree" >:: test_remove_tree;
    ]

let _ = run_test_tt_main suite
