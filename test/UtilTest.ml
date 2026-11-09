(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)
open OUnit2
open Hilde_core.Util
open TestUtil

let test_run_command _ =
  let (CommandOutput { command; code; stdout; stderr }) = run_command [|"echo"; "derp"|] in
  eq "'echo' 'derp'" command;
  eq 0 code;
  eq "derp" stdout;
  eq "" stderr

(* The compiler runs `cc` with paths its caller controls, so an argument a
   shell would split or act on has to arrive whole. The input carries the
   case on purpose: a semicolon and a space. Against the previous version,
   which passed a string to a shell, stdout would read "a b" and the file
   below would exist. *)
let test_run_command_passes_arguments_whole _ =
  let marker = "hilde-shell-marker.txt" in
  if Sys.file_exists marker then Sys.remove marker;
  let (CommandOutput { code; stdout; _ }) = run_command [|"echo"; "a b; touch " ^ marker|] in
  eq 0 code;
  eq ("a b; touch " ^ marker) stdout;
  assert_bool "a shell ran: the marker file was created" (not (Sys.file_exists marker))

let test_search_replace _ =
  let out = search_replace {
                text = "The quick brown fox.";
                search = "quick";
                replacement = "slow"
              }
  in
  assert_equal out "The slow brown fox."

let test_map_with_context _ =
  let lst = ["a"; "b"; "c"; "d"]
  and ctx = 0
  and f ((c, a): (int * string)): (int * string) =
    (c + 1, String.uppercase_ascii a)
  in
  let (ctx', results) = map_with_context f ctx lst in
  assert_equal ctx' 4;
  assert_equal results ["A"; "B"; "C"; "D"]

(* Every executable programme is built at -O2 and without strict aliasing,
   from one file or in parts. *)
let test_programme_flags _ =
  assert_bool "-O2" (List.mem "-O2" programme_flags);
  assert_bool "-fno-strict-aliasing" (List.mem "-fno-strict-aliasing" programme_flags)

(* A zig on PATH is taken for a machine of --target and called as
   `zig cc -target <machine>' with the flags of the native cc after it; a
   machine of the host's system and width without zig falls back to the
   native cc; and without --target nothing changes.  The zig of the test is
   a stub that writes its arguments into a file and exits 0, so the test
   sees the command line the compiler builds and no compiler of another
   machine is needed.  The environment is put back, and HILDE_ZIG is only
   named where it stands already, since an unset variable cannot be taken
   out again. *)
let contains (sub: string) (s: string): bool =
  let n = String.length s and m = String.length sub in
  let rec go (i: int): bool =
    i + m > n || (String.sub s i m = sub || go (i + 1))
  in
  m = 0 || go 0

let remove_tree (d: string): unit =
  List.iter
    (fun e ->
      let p: string = Filename.concat d e in
      if Sys.is_directory p then begin
        Array.iter (fun f -> Unix.unlink (Filename.concat p f)) (Sys.readdir p);
        Unix.rmdir p
      end else
        Unix.unlink p)
    (Array.to_list (Sys.readdir d));
  Unix.rmdir d

let test_cc_command _ =
  let saved_triple: string = !cross_triple in
  let saved_path: string = Sys.getenv "PATH" in
  let saved_zig: string option = Sys.getenv_opt "HILDE_ZIG" in
  let restore (): unit =
    cross_triple := saved_triple;
    Unix.putenv "PATH" saved_path;
    (match saved_zig with Some z when String.length z > 0 -> Unix.putenv "HILDE_ZIG" z | _ -> ())
  in
  Fun.protect ~finally:restore
    (fun () ->
      (match saved_zig with Some z when String.length z > 0 -> Unix.putenv "HILDE_ZIG" "" | _ -> ());
      let dir: string = Filename.temp_dir "hilde-util-test-" "" in
      Fun.protect
        ~finally:(fun () -> if Sys.file_exists dir then remove_tree dir)
        (fun () ->
          let work: string = Filename.concat dir "work" in
          Unix.mkdir work 0o755;
          let stubs: string = Filename.concat dir "stubs" in
          Unix.mkdir stubs 0o755;
          let log: string = Filename.concat dir "zig-argv.log" in
          let stub: string = Filename.concat stubs "zig" in
          let oc = Out_channel.open_text stub in
          output_string oc
            ("#!/bin/sh\nprintf '%s\\n' \"$*\" >> '" ^ log ^ "'\nexit 0\n");
          Out_channel.close oc;
          Unix.chmod stub 0o755;
          let source: string = Filename.concat work "probe.c" in
          write_string_to_file source "int main(void) { return 0; }\n";
          let binary: string = Filename.concat work "probe" in
          let foreign: string = List.find (fun t -> not (triple_is_host t)) target_triples in
          (* A machine of another system with zig: the stub is called with
             -target and the machine's name, and the flags of cc after
             them.  The stub's own name is not in what it sees. *)
          cross_triple := foreign;
          Unix.putenv "PATH" (stubs ^ ":" ^ saved_path);
          ignore (compile_c_code source binary []);
          let (CommandOutput { stdout; _ }) = run_command [| "cat"; log |] in
          let words: string list =
            List.filter (fun w -> w <> "") (String.split_on_char ' ' (String.trim stdout))
          in
          (match words with
           | "cc" :: "-target" :: machine :: _ ->
              assert_equal ~msg:"the machine of --target" foreign machine
           | _ -> assert_failure ("the stub saw: " ^ String.trim stdout));
          assert_bool "-std=c17 after the machine" (contains "-std=c17" (String.concat " " words));
          (* The machine of this system without zig: the native cc. *)
          cross_triple := (match List.find_opt triple_is_host target_triples with Some t -> t | None -> "");
          Unix.putenv "PATH" "";
          if !cross_triple <> "" then
            assert_equal ["cc"] (cc_command ());
          (* Without --target: the native cc, and the compiler of the host
             is called and makes a programme that runs. *)
          cross_triple := "";
          Unix.putenv "PATH" saved_path;
          assert_equal ["cc"] (cc_command ());
          ignore (compile_c_code source binary []);
          let (CommandOutput { code; _ }) = run_command [| binary |] in
          assert_bool "the programme of the native cc runs" (code = 0)))

let suite =
  "Utilities" >::: [
      "run_command" >:: test_run_command;
      "run_command passes arguments whole" >:: test_run_command_passes_arguments_whole;
      "search_replace" >:: test_search_replace;
      "map_with_context" >:: test_map_with_context;
      "programme_flags" >:: test_programme_flags;
      "cc_command and the cross build" >:: test_cc_command
    ]

let _ = run_test_tt_main suite
