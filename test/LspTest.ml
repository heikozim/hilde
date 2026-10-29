(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* The parts of hilde lsp that need no compiler run:
   the name under a position, a
   path and its URI there and back, and a message written and read again
   through a file.  scripts/check-lsp.py holds a whole session. *)
open OUnit2
open Hilde_core
open TestUtil

let test_word_at _ =
  let text = "    let line: String := redirectHeader(\"/done\");\n\n" in
  eq (Some "redirectHeader") (Lsp.word_at text 0 30);
  eq (Some "redirectHeader") (Lsp.word_at text 0 27);
  eq (Some "line") (Lsp.word_at text 0 8);
  eq None (Lsp.word_at text 1 0);
  eq None (Lsp.word_at text 5 0)

let test_uri _ =
  let path = "/work/a dir/Doc.hiq" in
  let uri = Lsp.uri_of_path path in
  eq "file:///work/a%20dir/Doc.hiq" uri;
  eq path (Lsp.path_of_uri uri)

let test_message_round_trip _ =
  let file = Filename.temp_file "lsp" ".msg" in
  let oc = open_out_bin file in
  let msg = `Assoc [("jsonrpc", `String "2.0"); ("id", `Int 7); ("method", `String "shutdown")] in
  Lsp.write_message oc msg;
  Lsp.write_message oc (`Assoc [("x", `List [`Int 1; `Int 2])]);
  close_out oc;
  let ic = open_in_bin file in
  let first = Lsp.read_message ic in
  let second = Lsp.read_message ic in
  let third = Lsp.read_message ic in
  close_in ic;
  Sys.remove file;
  eq (Some msg) first;
  eq (Some (`Assoc [("x", `List [`Int 1; `Int 2])])) second;
  eq None third

let suite =
  "hilde lsp" >::: [
      "word at" >:: test_word_at;
      "uri" >:: test_uri;
      "message round trip" >:: test_message_round_trip
    ]

let _ = run_test_tt_main suite
