(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open OUnit2
open Hilde_core
open Compiler

(* The translation units of a programme built in parts: the prelude first
   and the tail last, one unit per module between them; a changed module
   changes its own unit and leaves the units before it as they were, which
   is what lets the cache take them; and a unit holds the bodies of its own
   module only. *)

let helper (body: string): module_source =
  TwoFileModuleSource {
      int_filename = "Helper.hih";
      int_code = "module Helper is\n    function seven(): Int32;\nend module.\n";
      body_filename = "Helper.hiq";
      body_code = "module body Helper is\n    function seven(): Int32 is\n        return " ^ body ^ ";\n    end;\nend module body.\n";
    }

let main (word: string): module_source =
  BodyModuleSource {
      body_filename = "Main.hiq";
      body_code = "import Helper (seven);\n\nmodule body Main is\n    function main(): ExitCode is\n        printLn(\"" ^ word
                  ^ "\");\n        printLn(seven());\n        return ExitSuccess();\n    end;\nend module body.\n";
    }

(* The units of the programme, compiled in a child process: the numbers of
   declarations count on from one compilation to the next in a process,
   and hilde compiles one programme per process. *)
let units_of (modules: module_source list): translation_unit list =
  let (r, w) = Unix.pipe ~cloexec:true () in
  match Unix.fork () with
  | 0 ->
     Unix.close r;
     let units =
       try
         let c = compile_multiple empty_compiler modules in
         let c = post_compile c in
         let c = compile_entrypoint c (Identifier.make_mod_name "Main") (Identifier.make_ident "main") in
         translation_units c
       with _ -> None
     in
     let oc = Unix.out_channel_of_descr w in
     Marshal.to_channel oc (units: translation_unit list option) [];
     close_out oc;
     Unix._exit 0
  | pid ->
     Unix.close w;
     let ic = Unix.in_channel_of_descr r in
     let units: translation_unit list option = Marshal.from_channel ic in
     close_in ic;
     ignore (Unix.waitpid [] pid);
     (match units with
      | Some units -> units
      | None -> assert_failure "the programme did not compile or was not split")

let text_of (units: translation_unit list) (name: string): string =
  match List.find_opt (fun u -> u.unit_name = name) units with
  | Some u -> u.unit_text
  | None -> assert_failure ("no unit " ^ name)

let contains (text: string) (part: string): bool =
  let n = String.length part in
  let rec at i = i + n <= String.length text && (String.sub text i n = part || at (i + 1)) in
  at 0

let test_order _ =
  let units = units_of [main "one"; helper "7"] in
  assert_equal ~printer:(String.concat " ")
    ["Hilde.Prelude"; "Hilde.Pervasive"; "Hilde.Memory"; "Hilde.Array"; "Helper"; "Main"; "Hilde.Programme"]
    (List.map (fun u -> u.unit_name) units);
  assert_bool "the prelude's unit begins with internal.h"
    (String.starts_with ~prefix:BuiltInModules.prelude_internal_shared (text_of units "Hilde.Prelude"));
  let helper_unit = List.find (fun u -> u.unit_name = "Helper") units in
  assert_equal ~msg:"the files of the module" ["Helper.hih"; "Helper.hiq"] (List.map fst helper_unit.unit_sources);
  List.iter (fun u ->
      if u.unit_name <> "Hilde.Prelude" then
        assert_bool (u.unit_name ^ " starts with the declarations of the prelude")
          (String.starts_with ~prefix:BuiltInModules.prelude_internal_declarations u.unit_text))
    units

let test_changed_module_changes_its_unit_only _ =
  let before = units_of [main "one"; helper "7"] in
  let after = units_of [main "one"; helper "8"] in
  List.iter (fun name ->
      assert_equal ~msg:(name ^ " stays") ~printer:(fun _ -> name) (text_of before name) (text_of after name))
    ["Hilde.Prelude"; "Hilde.Pervasive"; "Hilde.Memory"; "Hilde.Array"];
  assert_bool "Helper changes" (text_of before "Helper" <> text_of after "Helper");
  let changed_main = units_of [main "two"; helper "7"] in
  List.iter (fun name ->
      assert_equal ~msg:(name ^ " stays when Main changes") ~printer:(fun _ -> name)
        (text_of before name) (text_of changed_main name))
    ["Hilde.Prelude"; "Hilde.Pervasive"; "Hilde.Memory"; "Hilde.Array"; "Helper"];
  assert_bool "Main changes" (text_of before "Main" <> text_of changed_main "Main")

(* Every part of lib/prelude, the way a programme with tasks carries them. *)
let all_parts: string list = List.map (fun (part, _, _, _) -> part) BuiltInModules.prelude_parts

let test_bodies_stay_in_their_unit _ =
  let (prelude_shared, prelude_declarations) = split_prelude all_parts in
  let units = units_of [main "unique-word-of-main"; helper "7"] in
  assert_bool "the body of main is in Main" (contains (text_of units "Main") "unique-word-of-main");
  assert_bool "and not in the tail" (not (contains (text_of units "Hilde.Programme") "unique-word-of-main"));
  assert_bool "the prelude has no body of a function that is not static"
    (not (contains prelude_declarations "hilde_make_span(void* data, size_t size) {"));
  assert_bool "the whole prelude has it" (contains prelude_shared "hilde_make_span(void* data, size_t size) {")

(* The names of the writable data an object defines, from nm: types b, d,
   B and D. *)
let writable_data (obj: string): string list =
  let ic = Unix.open_process_args_in "nm" [| "nm"; obj |] in
  let lines = In_channel.input_lines ic in
  (match Unix.close_process_in ic with
   | Unix.WEXITED 0 -> ()
   | _ -> assert_failure "nm failed");
  List.filter_map (fun line ->
      match String.split_on_char ' ' line with
      | [_; ("b" | "d" | "B" | "D"); name] -> Some name
      | _ -> None)
    lines

(* Every unit of a module holds the declarations of the prelude.  A static
   variable in them would give each unit a copy of its own, and the state
   of the runtime would split; the declarations compiled alone define no
   writable data, while the prelude's own unit defines that data once. *)
let test_prelude_state_is_shared ctxt =
  let dir = bracket_tmpdir ctxt in
  let (prelude_shared, prelude_declarations) = split_prelude all_parts in
  let compile (name: string) (text: string): string =
    let source = Filename.concat dir (name ^ ".c") and obj = Filename.concat dir (name ^ ".o") in
    Out_channel.with_open_bin source (fun oc -> output_string oc text);
    (match Unix.system (Filename.quote_command "cc" [ "-std=c17"; "-O0"; "-c"; source; "-o"; obj ]) with
     | Unix.WEXITED 0 -> ()
     | _ -> assert_failure ("cc failed on " ^ name));
    obj
  in
  let shared = writable_data (compile "shared" prelude_shared) in
  assert_bool "the prelude's unit defines the task state" (List.mem "hilde_task_preempt_pending" shared);
  assert_equal ~printer:(String.concat " ") [] (writable_data (compile "declarations" prelude_declarations))

(* split_prelude takes only names of parts, and both of its texts begin
   with internal.h. *)
let test_split_prelude_contract _ =
  assert_raises (Invalid_argument "Compiler.split_prelude: no part nowhere") (fun () -> split_prelude ["nowhere"]);
  let (shared, declarations) = split_prelude ["core"] in
  assert_bool "the shared text begins with internal.h" (String.starts_with ~prefix:BuiltInModules.prelude_internal_shared shared);
  assert_bool "the declarations begin with internal.h"
    (String.starts_with ~prefix:BuiltInModules.prelude_internal_declarations declarations);
  assert_bool "a variable of internal.h is extern in the declarations"
    (contains declarations "extern int hilde_library_calls");
  assert_bool "and shared, not static, in the prelude's unit"
    (not (contains shared "static int hilde_library_calls"))

let suite =
  "ModuleUnits" >::: [
      "split prelude contract" >:: test_split_prelude_contract;
      "prelude state is shared" >:: test_prelude_state_is_shared;
      "order" >:: test_order;
      "changed module changes its unit only" >:: test_changed_module_changes_its_unit_only;
      "bodies stay in their unit" >:: test_bodies_stay_in_their_unit;
    ]

let _ = run_test_tt_main suite
