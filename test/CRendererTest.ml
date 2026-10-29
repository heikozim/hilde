(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open OUnit2
open Hilde_core.CRenderer
open Hilde_core.Escape
open Hilde_core.CRepr

let r_e = render_expr
let test_render_bool _ =
  assert_equal (r_e (CBool true)) "true";
  assert_equal (r_e (CBool false)) "false"

let test_render_string _ =
  assert_equal (r_e (CString  (escape_string "abcd"))) "\"abcd\"";
  assert_equal (r_e (CString (escape_string "\""))) "\"\\\"\"";
  assert_equal (r_e (CString (escape_string "\"\"\""))) "\"\\\"\\\"\\\"\""

(* After a continuation the string is read on -- a second
   continuation and an escape after the first one included. *)
let test_continuation _ =
  assert_equal (escaped_to_string (escape_string "AB\\\n    \\CD")) "ABCD";
  assert_equal (escaped_to_string (escape_string "AB\\\n    \\CD\\\n    \\EF")) "ABCDEF";
  assert_equal (escaped_to_string (escape_string "AB\\\n    \\C\\tD")) "ABC\tD"

(* What the C17 standard asks without extensions: a function without
   parameters says void, a struct has a member, and an initializer is not
   empty. *)
let lines ls = String.concat "\n" (List.map render_line ls)

let test_no_parameters _ =
  let d = CFunctionDeclaration (Desc "d", "f", [], CNamedType "int", LinkageInternal) in
  assert_equal ~printer:Fun.id "/*\n  d\n*/\nint f(void);" (lines (render_decl zero_indent d));
  let p = CFunctionDeclaration (Desc "d", "g", [CValueParam ("x", CNamedType "int")], CNamedType "int", LinkageInternal) in
  assert_equal ~printer:Fun.id "/*\n  d\n*/\nint g(int x);" (lines (render_decl zero_indent p));
  assert_equal ~printer:Fun.id "((int(*)(void))(h))()" (r_e (CFptrCall (CVar "h", CNamedType "int", [], [])))

let test_empty_struct _ =
  assert_equal ~printer:Fun.id "struct  {char hilde_empty;}" (render_type (CStructType (CStruct (None, []))));
  assert_equal ~printer:Fun.id "union { char hilde_empty;}" (render_type (CUnionType []));
  assert_equal ~printer:Fun.id "struct  {int a;}" (render_type (CStructType (CStruct (None, [CSlot ("a", CNamedType "int")]))));
  assert_equal ~printer:Fun.id "{ 0 }" (r_e (CStructInitializer []));
  assert_equal ~printer:Fun.id "{ .a = 1 }" (r_e (CStructInitializer [("a", CInt "1")]))

let test_byte_array _ =
  let d = CByteArrayDefinition (Desc "t", "x", "\000A\255") in
  assert_equal ~printer:Fun.id "/*\n  t\n*/\nstatic const unsigned char x[3] = {\n    0, 65, 255\n};" (lines (render_decl zero_indent d));
  let long = CByteArrayDefinition (Desc "t", "y", String.make 17 'a') in
  assert_equal ~printer:Fun.id "/*\n  t\n*/\nstatic const unsigned char y[17] = {\n    97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97,\n    97\n};" (lines (render_decl zero_indent long))

  let suite =
    "CliUtil" >::: [
        "render_bool" >:: test_render_bool;
        "render_string" >:: test_render_string;
        "continuation" >:: test_continuation;
        "no_parameters" >:: test_no_parameters;
        "empty_struct" >:: test_empty_struct;
        "byte_array" >:: test_byte_array
      ]

  let _ = run_test_tt_main suite
