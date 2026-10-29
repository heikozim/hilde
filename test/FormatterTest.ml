(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* hilde fmt: the form of a few
   sources written badly, that the form of the form is the form, that
   comments and docstrings stay, and that a source the formatter would have
   to change in its tokens is refused. *)
open OUnit2
open Hilde_core
open TestUtil

let fmt (s: string): string = Formatter.format "t.hiq" s

let bad: string = String.concat "\n" [
    "-- head";
    "module body T is";
    "  function f(a:Int32,b : Int32):Int32 is";
    "        let x: Int32 := a+b + 1;";
    "    if x>0 then";
    "  return -x;   -- negative";
    "      else";
    "return (x : Int32);";
    "        end if;";
    "  end;";
    "";
    "";
    "";
    "    function g(o: Option[Int32]): Int32 is";
    "        case o of";
    "        when Some(value as v: Int32) do";
    "        return v;";
    "        when None do";
    "        return 0;";
    "        end case;";
    "    end;";
    "end module body.";
    ""
  ]

let good: string = String.concat "\n" [
    "-- head";
    "module body T is";
    "    function f(a: Int32, b: Int32): Int32 is";
    "        let x: Int32 := a + b + 1;";
    "        if x > 0 then";
    "            return -x; -- negative";
    "        else";
    "            return (x: Int32);";
    "        end if;";
    "    end;";
    "";
    "    function g(o: Option[Int32]): Int32 is";
    "        case o of";
    "            when Some(value as v: Int32) do";
    "                return v;";
    "            when None do";
    "                return 0;";
    "        end case;";
    "    end;";
    "end module body.";
    ""
  ]

let test_form _ = eq good (fmt bad)

let test_idempotent _ = eq (fmt bad) (fmt (fmt bad))

let test_form_is_kept _ = eq good (fmt good)

let continued: string = String.concat "\n" [
    "import Standard.String (";
    "  String";
    ");";
    "";
    "module Example is";
    "    \"\"\"";
    "    A docstring.";
    "    \"\"\"";
    "    generic [R: Region]";
    "    function size(text: Span[Nat8, R],";
    "                  limit: Index): Index";
    "      requires limit > 0;";
    "end module.";
    ""
  ]

let continued_form: string = String.concat "\n" [
    "import Standard.String (";
    "    String";
    ");";
    "";
    "module Example is";
    "    \"\"\"";
    "    A docstring.";
    "    \"\"\"";
    "    generic [R: Region]";
    "    function size(text: Span[Nat8, R],";
    "        limit: Index): Index";
    "        requires limit > 0;";
    "end module.";
    ""
  ]

let test_brackets_and_contracts _ = eq continued_form (fmt continued)

(* A sign before a number stays apart from it: glued, the two would be a
   literal of their own and the parser would read another expression. *)
let test_sign_before_number _ =
  let s = "module body T is\n    function f(): Int32 is\n        return - 1;\n    end;\nend module body.\n" in
  eq s (fmt s)

let test_refuses_a_change_of_tokens _ =
  (* An unclosed string cannot be cut into lines; the formatter refuses it
     and does not guess. *)
  try
    let _ = fmt "module body T is\n    let s := \"open\nend module body.\n" in
    assert_failure "an unclosed string was formatted"
  with Error.Hilde_error _ -> ()

let suite =
  "hilde fmt" >::: [
      "form" >:: test_form;
      "idempotent" >:: test_idempotent;
      "form is kept" >:: test_form_is_kept;
      "brackets and contracts" >:: test_brackets_and_contracts;
      "sign before number" >:: test_sign_before_number;
      "refuses a change of tokens" >:: test_refuses_a_change_of_tokens
    ]

let _ = run_test_tt_main suite
