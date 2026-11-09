(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The warning N002: which names of a checked module are never read, and
   which are left alone. *)
open OUnit2
open Hilde_core
open TestUtil

(* The findings hilde check records for one body, as their messages. *)
let found (src: string): string list =
  let source =
    Compiler.BodyModuleSource { body_filename = "T.hiq"; body_code = src }
  in
  ignore (Compiler.check_multiple Compiler.empty_compiler [source]);
  List.map UnusedCheck.message (UnusedCheck.recorded ())

let source: string = String.concat "\n" [
    "module body T is";
    "    function f(used: Int32, unread: Int32): Int32 is";
    "        let kept: Int32 := used + 1;";
    "        let dropped: Int32 := 2;";
    "        return kept;";
    "    end;";
    "end module body."
  ]

(* The parameter and the binding the body never reads, and nothing else. *)
let test_unread _ =
  eq ["N002: the parameter unread of f is never read";
      "N002: the binding dropped in f is never read"] (found source)

(* The control: the same function with every name read gives nothing, so a
   check that reported every name would fail here. *)
let test_all_read _ =
  let src = String.concat "\n" [
      "module body T is";
      "    function f(used: Int32, read: Int32): Int32 is";
      "        let kept: Int32 := used + read;";
      "        return kept;";
      "    end;";
      "end module body."
    ] in
  eq [] (found src)

(* A name read only in a borrow, a loop bound or a condition is read. *)
let test_read_in_statements _ =
  let src = String.concat "\n" [
      "module body T is";
      "    function g(limit: Index, flag: Bool): Index is";
      "        var total: Index := 0;";
      "        if flag then";
      "            for i from 0 to limit do";
      "                total := total + i;";
      "            end for;";
      "        end if;";
      "        return total;";
      "    end;";
      "end module body."
    ] in
  eq [] (found src)

(* N001: a parameter, a variable and a function that break the convention,
   each read, so only N001 is reported. *)
let test_naming _ =
  let src = String.concat "\n" [
      "module body T is";
      "    function do_work(someArg: Int32): Int32 is";
      "        let localName: Int32 := someArg + 1;";
      "        return localName;";
      "    end;";
      "end module body."
    ] in
  eq ["N001: the function do_work is not camelCase";
      "N001: the parameter someArg of do_work is not snake_case";
      "N001: the variable localName in do_work is not snake_case"] (found src)

(* The forms the convention allows: a digit after an underscore of a
   function, snake_case names. *)
let test_naming_clean _ =
  let src = String.concat "\n" [
      "module body T is";
      "    function sha3_256(some_arg: Int32): Int32 is";
      "        let local_name: Int32 := some_arg + 1;";
      "        return local_name;";
      "    end;";
      "end module body."
    ] in
  eq [] (found src);
  eq true (NamingCheck.is_camel "hmacSha3_512");
  eq false (NamingCheck.is_camel "find_all");
  eq false (NamingCheck.is_snake "maxSize")

let suite =
  "UnusedCheck" >::: [
      "names against the convention" >:: test_naming;
      "names the convention allows" >:: test_naming_clean;
      "an unread parameter and binding" >:: test_unread;
      "every name read" >:: test_all_read;
      "read in statements" >:: test_read_in_statements
    ]

let _ = run_test_tt_main suite
