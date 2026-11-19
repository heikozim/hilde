(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The compiler's check of literal regex patterns (lib/RegexCheck.ml) must
   answer exactly as Standard.Regex's own `compile' does.

   Standard.Regex's answers are the expected output of suite 043 test 004,
   which the e2e runner compares against the running module in every gate.
   The patterns of that test are scripts/regex/messages.json, in the same
   order.  This test runs every one of them through RegexCheck and compares
   line for line -- so the two parsers are held together by two tests that
   share one file, and a change to either that the other does not follow
   turns one of them red. *)
open OUnit2

let read_file (path: string): string =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

(* The escape test 004 prints its texts with: every byte outside printable
   ASCII, and every `%', as %XX. *)
let escape (s: string): string =
  let b = Buffer.create (String.length s) in
  String.iter (fun c ->
      let code = Char.code c in
      if code < 32 || code > 126 || c = '%' then
        Buffer.add_string b (Printf.sprintf "%%%02X" code)
      else
        Buffer.add_char b c) s;
  Buffer.contents b

(* messages.json holds the patterns %XX-encoded (scripts/regex/cases.py),
   so that a byte which is not UTF-8 can be one of them. *)
let decode (s: string): string =
  let b = Buffer.create (String.length s) in
  let i = ref 0 in
  while !i < String.length s do
    if s.[!i] = '%' then begin
      Buffer.add_char b (Char.chr (int_of_string ("0x" ^ String.sub s (!i + 1) 2)));
      i := !i + 3
    end else begin
      Buffer.add_char b s.[!i];
      incr i
    end
  done;
  Buffer.contents b

let patterns (): string list =
  match Yojson.Safe.from_string (read_file "../scripts/regex/messages.json") with
  | `List items ->
     List.map (function
         | `String s -> decode s
         | _ -> failwith "messages.json: every entry must be a string") items
  | _ -> failwith "messages.json: not a list"

(* Test 004's expected output is pairs of lines, "case N" and the answer. *)
let answers (): string list =
  let lines = String.split_on_char '\n'
                (read_file "../test-programs/suites/043-regex/004-messages/program-stdout.txt") in
  let rec pick = function
    | c :: a :: rest when String.length c > 5 && String.sub c 0 5 = "case " -> a :: pick rest
    | [""] | [] -> []
    | l :: _ -> failwith ("004 output: unexpected line " ^ l)
  in
  pick lines

let answer_of (pattern: string): string =
  match Hilde_core.RegexCheck.check pattern with
  | None -> "ok"
  | Some message -> "error [" ^ (escape message) ^ "]"

let test_every_pattern _ =
  let ps = patterns () and expected = answers () in
  (* Counted, not assumed: an empty file would pass every comparison. *)
  assert_bool "messages.json holds no patterns" (List.length ps > 0);
  assert_equal ~printer:string_of_int (List.length ps) (List.length expected);
  let refused = ref 0 in
  List.iteri (fun i (p, e) ->
      let got = answer_of p in
      if got <> "ok" then incr refused;
      assert_equal ~msg:(Printf.sprintf "case %d, pattern %S" (i + 1) p) ~printer:(fun s -> s) e got)
    (List.combine ps expected);
  (* Both answers occur, so the comparison could have failed both ways. *)
  assert_bool "no pattern was refused" (!refused > 0);
  assert_bool "no pattern was accepted" (!refused < List.length ps)

let suite =
  "RegexCheck" >::: [
      "Every pattern of suite 043 test 004" >:: test_every_pattern
    ]

let _ = run_test_tt_main suite
