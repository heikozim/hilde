(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* Contracts proved at compile time:
   a module is compiled to C, and the message of each ensures is counted in
   it.  A proved clause leaves no message at the return where it is proved;
   an unproved one leaves one per return, which is the control that the
   count can find a message at all. *)
open OUnit2
open Hilde_core.Identifier
open Hilde_core.Compiler

let c_of (code: string list): string =
  let source = BodyModuleSource { body_filename = "Proof.hiq"; body_code = String.concat "\n" code } in
  let c = compile_multiple empty_compiler [source] in
  let c = post_compile c in
  let c = compile_entrypoint c (make_mod_name "Example.Proof") (make_ident "main") in
  c_file_text c

(* How often [needle] occurs in [text]. *)
let occurrences (needle: string) (text: string): int =
  let n = String.length needle and m = String.length text in
  let rec go (i: int) (acc: int): int =
    if i + n > m then acc
    else if String.sub text i n = needle then go (i + n) (acc + 1)
    else go (i + 1) acc
  in
  if n = 0 then 0 else go 0 0

let module_code: string list = [
    "module body Example.Proof is";
    "    function keep(x: Nat32): Nat32";
    "        ensures result = x";
    "    is";
    "        return x;";
    "    end;";
    "";
    "    function bound(x: Nat8): Nat8";
    "        requires x < 100";
    "        ensures result < 101";
    "    is";
    "        return x;";
    "    end;";
    "";
    "    function low(a: Int32, b: Int32): Int32";
    "        requires a <= b";
    "        ensures (result <= b) and (a <= result)";
    "    is";
    "        return a;";
    "    end;";
    "";
    "    function pick(a: Nat32, flag: Bool): Nat32";
    "        ensures result <= a";
    "    is";
    "        if flag then";
    "            return a;";
    "        end if;";
    "        return a / 2;";
    "    end;";
    "";
    "    function twice(x: Nat32): Nat32";
    "        ensures result = (x * 2)";
    "    is";
    "        return x + x;";
    "    end;";
    "";
    "    function shadow(x: Nat32): Nat32";
    "        ensures result <= 7";
    "    is";
    "        let y: Nat32 := x;";
    "        return y;";
    "    end;";
    "";
    "    function main(): ExitCode is";
    "        printLn(keep(1));";
    "        printLn(bound(2));";
    "        printLn(low(3, 4));";
    "        printLn(pick(5, true));";
    "        printLn(twice(6));";
    "        printLn(shadow(7));";
    "        return ExitSuccess();";
    "    end;";
    "end module body.";
    "" ]

let message (text: string) (fname: string): string =
  "the ensures " ^ text ^ " of Example.Proof." ^ fname ^ " ("

let test_proofs _ =
  let c = c_of module_code in
  assert_equal ~msg:"result = x at return x: the same expression" ~printer:string_of_int
    0 (occurrences (message "result = x" "keep") c);
  assert_equal ~msg:"result < 101 at return x: the requires narrows x to 0..99" ~printer:string_of_int
    0 (occurrences (message "result < 101" "bound") c);
  assert_equal ~msg:"the requires a <= b as a relation" ~printer:string_of_int
    0 (occurrences (message "(result <= b) and (a <= result)" "low") c);
  assert_equal ~msg:"proved at one return of two" ~printer:string_of_int
    1 (occurrences (message "result <= a" "pick") c);
  assert_equal ~msg:"x + x is not proved to be x * 2" ~printer:string_of_int
    1 (occurrences (message "result = (x * 2)" "twice") c);
  assert_equal ~msg:"a value of the body is not a parameter" ~printer:string_of_int
    1 (occurrences (message "result <= 7" "shadow") c)

(* The report of hilde compile --contract-report:
   a line for each requires and
   for each ensures at each return where it is not proved, none for a clause
   proved.  The module holds two requires and three ensures unproved at one
   return each. *)
let test_report _ =
  Hilde_core.Contracts.reset_report ();
  let _ = c_of module_code in
  let lines = Hilde_core.Contracts.report () in
  let count (part: string): int =
    List.length (List.filter (fun l -> occurrences part l > 0) lines)
  in
  assert_equal ~msg:"five lines" ~printer:string_of_int 5 (List.length lines);
  assert_equal ~msg:"two requires" ~printer:string_of_int 2 (count ": the requires ");
  assert_equal ~msg:"three ensures" ~printer:string_of_int 3 (count ": the ensures ");
  assert_equal ~msg:"pick at one return" ~printer:string_of_int 1 (count "of Example.Proof.pick");
  assert_equal ~msg:"keep proved: no line" ~printer:string_of_int 0 (count "of Example.Proof.keep");
  assert_equal ~msg:"the ensures of bound proved: only its requires" ~printer:string_of_int
    1 (count "of Example.Proof.bound");
  Hilde_core.Contracts.reset_report ();
  assert_equal ~msg:"reset empties it" ~printer:string_of_int 0 (List.length (Hilde_core.Contracts.report ()))

let suite =
  "ContractProof" >::: [
      "proofs" >:: test_proofs;
      "report" >:: test_report;
    ]

let _ = run_test_tt_main suite
