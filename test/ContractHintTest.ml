(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* hilde check --missing-contracts:
   a module with one function for each derivation, each of which must draw
   exactly its hint and clause, and functions that must draw none -- the
   clause already stated, the parameter tested in the body, the words No
   contract in the docstring.  The same module with the switch off draws
   nothing, which is the control that the hints come from the switch. *)
open OUnit2
open Hilde_core.Compiler
open Hilde_core.Error
open Hilde_core.ErrorText

let interface: string list = [
    "module Example.Hint is";
    "    function share(total: Nat32, count: Nat32): Nat32";
    "        ensures result <= total;";
    "    function left(total: Nat32, count: Nat32): Nat32";
    "        ensures result <= total;";
    "    function leftOp(total: Nat32, count: Nat32): Nat32";
    "        ensures result <= total;";
    "    generic [R: Region]";
    "    function byteAt(text: Span[Nat8, R], index: Index): Nat8";
    "        ensures result <= 255;";
    "    function more(a: Nat32, b: Nat32): Nat32";
    "        ensures result <= a;";
    "    function low(a: Nat32): Nat32";
    "        ensures result <= a;";
    "    function width(): Int64;";
    "    function checkedShare(total: Nat32, count: Nat32): Nat32";
    "        requires count > 0;";
    "    function half(total: Nat32, parts: Nat32): Nat32";
    "        ensures result <= total;";
    "    \"\"\"";
    "    No contract: nothing to state.";
    "    \"\"\"";
    "    function waived(total: Nat32, count: Nat32): Nat32;";
    "    function safeShare(total: Nat32, count: Nat32): Nat32";
    "        ensures result <= total;";
    "end module.";
    "" ]

let body: string list = [
    "module body Example.Hint is";
    "    function share(total: Nat32, count: Nat32): Nat32 is";
    "        return total / count;";
    "    end;";
    "    function left(total: Nat32, count: Nat32): Nat32 is";
    "        return rem(total, count);";
    "    end;";
    "    function leftOp(total: Nat32, count: Nat32): Nat32 is";
    "        return total % count;";
    "    end;";
    "    generic [R: Region]";
    "    function byteAt(text: Span[Nat8, R], index: Index): Nat8 is";
    "        return text[index];";
    "    end;";
    "    function more(a: Nat32, b: Nat32): Nat32 is";
    "        return a - b;";
    "    end;";
    "    function low(a: Nat32): Nat32 is";
    "        let x: Nat32 := a - 1;";
    "        return a - 8;";
    "    end;";
    "    function width(): Int64 is";
    "        return 32;";
    "    end;";
    "    function checkedShare(total: Nat32, count: Nat32): Nat32 is";
    "        return total / count;";
    "    end;";
    "    function half(total: Nat32, parts: Nat32): Nat32 is";
    "        return checkedShare(total, parts);";
    "    end;";
    "    function waived(total: Nat32, count: Nat32): Nat32 is";
    "        return total / count;";
    "    end;";
    "    function safeShare(total: Nat32, count: Nat32): Nat32 is";
    "        if count = 0 then";
    "            return 0;";
    "        end if;";
    "        return total / count;";
    "    end;";
    "end module body.";
    "" ]

let source: module_source =
  TwoFileModuleSource {
      int_filename = "Hint.hih"; int_code = String.concat "\n" interface;
      body_filename = "Hint.hiq"; body_code = String.concat "\n" body
    }

(* Each hint as its code and the clause it suggests, or "-" for none. *)
let hints_of (enabled: bool): string list =
  Hilde_core.ContractHints.reset ();
  Hilde_core.ContractHints.enabled := enabled;
  let _ = check_multiple empty_compiler [source] in
  Hilde_core.ContractHints.enabled := false;
  let source_of f =
    if f = "Hint.hih" then Some (String.concat "\n" interface)
    else if f = "Hint.hiq" then Some (String.concat "\n" body) else None
  in
  List.map
    (fun (HildeError { code; text; kind; _ }) ->
      assert_bool "the kind is a hint" (kind = ContractHint);
      let clause = match suggestions_of text with s :: _ -> s.replacement | [] -> "-" in
      (code_string code) ^ " " ^ clause)
    (Hilde_core.ContractHints.hints ~source_of ~files:["Hint.hih"; "Hint.hiq"])

let test_hints _ =
  let want = [
      "H2201 requires count /= 0";
      "H2202 requires count /= 0";
      "H2202 requires count /= 0";
      "H2203 requires index < spanLength(text)";
      "H2204 requires a >= b";
      "H2204 requires a >= 8";
      "H2205 ensures result = 32";
      "H2207 -";
      "H2206 requires parts > 0";
    ] in
  assert_equal ~msg:"the hints, in the order of the module" ~printer:(String.concat "; ") want (hints_of true)

let test_switch_off _ =
  assert_equal ~msg:"no hint without the switch" ~printer:(String.concat "; ") [] (hints_of false)

let suite =
  "ContractHint" >::: [
      "hints" >:: test_hints;
      "switch off" >:: test_switch_off;
    ]

let _ = run_test_tt_main suite
