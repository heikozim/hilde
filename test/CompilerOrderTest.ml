(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open OUnit2
open Hilde_core.Compiler

(* The module order the compiler computes from the imports.  Every
   case below names the order it puts in and the order it wants out; a case
   that put in the order it wants out would pass whatever the function did. *)

let body (name: string) (code: string): module_source =
  BodyModuleSource { body_filename = name ^ ".hiq"; body_code = code }

let plain (name: string): module_source =
  body name
    ("module body " ^ name ^ " is\n"
     ^ "    function f(): Unit is\n"
     ^ "        return nil;\n"
     ^ "    end;\n"
     ^ "end module body.\n")

let importing (name: string) (imported: string list): module_source =
  let imports =
    String.concat ""
      (List.map (fun m -> "import " ^ m ^ " (f);\n") imported)
  in
  body name
    (imports
     ^ "module body " ^ name ^ " is\n"
     ^ "    function f(): Unit is\n"
     ^ "        return nil;\n"
     ^ "    end;\n"
     ^ "end module body.\n")

let names (mods: module_source list): string list =
  List.map
    (fun m ->
      match m with
      | BodyModuleSource { body_filename; _ } ->
         Filename.remove_extension body_filename
      | TwoFileModuleSource { body_filename; _ } ->
         Filename.remove_extension body_filename)
    mods

let eq_names (want: string list) (got: module_source list) =
  assert_equal ~printer:(String.concat ",") want (names got)

(* The case the point is about: the importer is named first, and has to come
   out last. *)
let test_reverse_order_is_corrected _ =
  eq_names ["B"; "A"]
    (sort_modules [importing "A" ["B"]; plain "B"])

(* The negative control of that case: an order that is already right must
   come out unchanged, or the test above would pass for a function that
   simply reverses its input. *)
let test_right_order_is_kept _ =
  eq_names ["B"; "A"]
    (sort_modules [plain "B"; importing "A" ["B"]])

(* Stability: modules that do not depend on each other keep the given order,
   so a command line that worked before builds the same thing. *)
let test_independent_modules_keep_their_order _ =
  eq_names ["C"; "A"; "B"]
    (sort_modules [plain "C"; plain "A"; plain "B"])

let test_chain _ =
  eq_names ["C"; "B"; "A"]
    (sort_modules [importing "A" ["B"]; importing "B" ["C"]; plain "C"])

let test_diamond _ =
  eq_names ["D"; "B"; "C"; "A"]
    (sort_modules [importing "A" ["B"; "C"];
                   importing "B" ["D"];
                   importing "C" ["D"];
                   plain "D"])

(* An import of a module that is not on the command line orders nothing --
   Hilde.Pervasive is imported by every module and is not in the list. *)
let test_unknown_import_is_ignored _ =
  eq_names ["A"; "B"]
    (sort_modules [importing "A" ["Not_Given_Here"]; plain "B"])

(* A cycle cannot be ordered.  The list comes back as it was given, and the
   compilation reports the cycle in its own words rather than here. *)
let test_cycle_leaves_the_order_alone _ =
  eq_names ["A"; "B"]
    (sort_modules [importing "A" ["B"]; importing "B" ["A"]])

(* A head that does not parse raises its own parse error.  Left in the
   order given, the module before it that imports it was reported as
   importing an unknown module (H2017) instead. *)
let test_unparsable_head_raises_its_parse_error _ =
  try
    let _ = sort_modules [importing "A" ["B"]; body "B" "this is not a module at all"] in
    assert_failure "an unparsable head was ordered"
  with Hilde_core.Error.Hilde_error e ->
    let (Hilde_core.Error.HildeError { code; _ }) = e in
    let c = Hilde_core.Error.code_string code in
    assert_bool ("a parse error, not " ^ c) (String.length c = 5 && String.sub c 0 2 = "H0")

let test_empty_and_single _ =
  eq_names [] (sort_modules []);
  eq_names ["A"] (sort_modules [plain "A"])

let suite =
  "CompilerOrder" >::: [
      "reverse order is corrected" >:: test_reverse_order_is_corrected;
      "right order is kept" >:: test_right_order_is_kept;
      "independent modules keep their order" >:: test_independent_modules_keep_their_order;
      "chain" >:: test_chain;
      "diamond" >:: test_diamond;
      "unknown import is ignored" >:: test_unknown_import_is_ignored;
      "cycle leaves the order alone" >:: test_cycle_leaves_the_order_alone;
      "unparsable head raises its parse error" >:: test_unparsable_head_raises_its_parse_error;
      "empty and single" >:: test_empty_and_single;
    ]

let _ = run_test_tt_main suite
