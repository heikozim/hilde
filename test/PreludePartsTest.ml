(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open OUnit2
open Hilde_core.Compiler

(* Which parts of lib/prelude a programme carries.  The parts, their own
   names and what each needs come from the table concat_builtins.py writes,
   so a case names a part by one of its own names and not by a list of
   names that would go stale. *)

let parts = Hilde_core.BuiltInModules.prelude_parts

let part_names: string list = List.map (fun (p, _, _, _) -> p) parts

let triggers_of (part: string): string list =
  match List.find_opt (fun (p, _, _, _) -> p = part) parts with
  | Some (_, _, t, _) -> t
  | None -> assert_failure ("no prelude part " ^ part)

let needs_of (part: string): string list =
  match List.find_opt (fun (p, _, _, _) -> p = part) parts with
  | Some (_, _, _, n) -> n
  | None -> assert_failure ("no prelude part " ^ part)

(* The part with every part it needs, again and again. *)
let rec closure (seen: string list) (part: string): string list =
  if List.mem part seen then seen
  else List.fold_left closure (part :: seen) (needs_of part)

let show (l: string list): string = "[" ^ String.concat "; " l ^ "]"

let in_order (l: string list): string list = List.filter (fun p -> List.mem p l) part_names

(* A call of name, the way generated C names a function of the runtime. *)
let calling (name: string): string = "    " ^ name ^ "(0);\n"

let test_table_has_the_parts _ =
  List.iter
    (fun p -> assert_bool ("the table lacks " ^ p) (List.mem p part_names))
    ["core"; "library"; "resolve"; "sandbox"; "file"; "socket"; "process"; "task"; "task-none"]

let test_nothing_named _ =
  assert_equal ~printer:show ["core"; "task-none"] (prelude_parts_of ~library:false ~tasks:false "")

let test_hello_world _ =
  (* What hello world's C names of the runtime: the printing of core. *)
  let text = calling "hilde_put_string" ^ calling "hilde_stop" in
  assert_equal ~printer:show ["core"; "task-none"] (prelude_parts_of ~library:false ~tasks:false text)

let test_no_task_without_tasks _ =
  let got = prelude_parts_of ~library:false ~tasks:false (calling "hilde_file_open_read") in
  assert_bool ("task.c linked: " ^ show got) (not (List.mem "task" got));
  assert_bool ("file.c not linked: " ^ show got) (List.mem "file" got)

let test_tasks_bring_task _ =
  let got = prelude_parts_of ~library:false ~tasks:true "" in
  assert_equal ~printer:show (in_order (closure ["task-none"] "task" @ ["core"])) got

let test_library_brings_library _ =
  let got = prelude_parts_of ~library:true ~tasks:false "" in
  assert_equal ~printer:show (in_order (closure ["task-none"] "library" @ ["core"])) got

(* Every part is reached through each of its own names, and with it the
   parts it needs and no other. *)
let test_every_trigger _ =
  List.iter
    (fun part ->
      List.iter
        (fun name ->
          let got = prelude_parts_of ~library:false ~tasks:false (calling name) in
          let want = in_order (closure ["core"; "task-none"] part @ ["core"; "task-none"]) in
          assert_equal ~printer:show ~msg:(part ^ " through " ^ name) want got)
        (triggers_of part))
    (List.filter (fun p -> p <> "core" && p <> "task-none") part_names)

(* A name that only begins like a name of the runtime pulls in nothing:
   the scan takes whole identifiers. *)
let test_whole_identifiers _ =
  let name = List.hd (triggers_of "socket") in
  let got = prelude_parts_of ~library:false ~tasks:false (calling (name ^ "_x") ^ calling ("x" ^ name)) in
  assert_equal ~printer:show ["core"; "task-none"] got

let suite =
  "Prelude parts" >::: [
    "the table has the parts" >:: test_table_has_the_parts;
    "nothing named" >:: test_nothing_named;
    "hello world" >:: test_hello_world;
    "no task.c without tasks" >:: test_no_task_without_tasks;
    "tasks bring task.c" >:: test_tasks_bring_task;
    "a library brings library.c" >:: test_library_brings_library;
    "every own name" >:: test_every_trigger;
    "whole identifiers" >:: test_whole_identifiers;
  ]

let _ = run_test_tt_main suite
