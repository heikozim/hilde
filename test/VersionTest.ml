(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open OUnit2

(* The version this compiler reports, and the version the tree declares.
   The declaration in dune-project, the one dune generates hilde.opam from
   and the one the package commands carry must name the version of
   lib/Version.ml, so that a release cut from this tree cannot report a
   version older than the one already published.  The files are read from
   the tree the tests run in. *)

let read_file (path: string): string =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

let starts_with (prefix: string) (s: string): bool =
  String.length s >= String.length prefix && String.sub s 0 (String.length prefix) = prefix

(* The first line of the file that starts with the prefix, or a failure. *)
let line_starting_with (file: string) (prefix: string): string =
  match List.find_opt (starts_with prefix) (String.split_on_char '\n' (read_file file)) with
  | Some l -> l
  | None -> assert_failure (file ^ " has no line starting with " ^ prefix)

(* The line after the first one that starts with the prefix, or a failure. *)
let line_after (file: string) (prefix: string): string =
  let rec go = function
    | a :: (b :: _) when starts_with prefix a -> b
    | _ :: rest -> go rest
    | [] -> assert_failure (file ^ " has no line starting with " ^ prefix)
  in
  go (String.split_on_char '\n' (read_file file))

let reported (): string = Hilde_core.Version.version_string

(* The version the compiler reports is the one of the published release, not
   an older one: a tree that reports 1.1.0 after 1.1.1 was released cannot be
   told apart from it by a user reading the version, and its build cache key
   collides with the one of 1.1.0. *)
let test_reports_the_published_release _ =
  assert_equal ~msg:"the version the compiler reports" "1.1.1" (reported ())

(* dune-project is the source dune generates hilde.opam from. *)
let test_dune_project_names_the_same_version _ =
  assert_equal ~msg:"dune-project" ("(version " ^ reported () ^ ")")
    (line_starting_with "../dune-project" "(version ")

(* The generated opam file, which is committed and read without dune. *)
let test_hilde_opam_names_the_same_version _ =
  assert_equal ~msg:"hilde.opam" ("version: \"" ^ reported () ^ "\"")
    (line_starting_with "../hilde.opam" "version: ")

(* The package commands report the version of the compiler they come with. *)
let test_package_commands_name_the_same_version _ =
  assert_equal ~msg:"pkg/src/Main.hiq toolVersion" ("        return \"" ^ reported () ^ "\";")
    (line_after "../pkg/src/Main.hiq" "    function toolVersion(): Span[Nat8, Static] is")

(* Whether the text holds the word, byte for byte. *)
let contains (word: string) (text: string): bool =
  let n = String.length word and m = String.length text in
  let rec at i = i + n <= m && (String.sub text i n = word || at (i + 1)) in
  n = 0 || at 0

(* The headings of the CHANGELOG, in the order the file has them: every
   line that starts a release, "hilde (X) stable; urgency=...", without the
   blank lines and the notes below it. *)
let release_headings (): string list =
  List.filter (starts_with "hilde (") (String.split_on_char '\n' (read_file "../CHANGELOG"))

(* The lines of one release, from its heading up to the heading of the
   release below it. *)
let release_lines (heading: string): string list =
  let rec drop = function
    | [] -> assert_failure ("CHANGELOG has no heading " ^ heading)
    | l :: rest when l = heading -> l :: rest
    | _ :: rest -> drop rest
  in
  let rec take = function
    | [] -> []
    | l :: _ when starts_with "hilde (" l -> []
    | l :: rest -> l :: take rest
  in
  match drop (String.split_on_char '\n' (read_file "../CHANGELOG")) with
  | [] -> []
  | h :: rest -> h :: take rest

(* The CHANGELOG tells the releases in the order they were published, with
   the notes each one carries: the top entry is the version the compiler
   reports, then 1.1.0 with the split of the runtime prelude, then 1.0.0,
   and no entry is left as UNRELEASED once a later release stands above
   it. *)
let test_changelog_lists_the_published_releases _ =
  let headings = release_headings () in
  let top = reported () in
  assert_equal ~msg:"the CHANGELOG names no unreleased entry"
    false (List.exists (contains "UNRELEASED") headings);
  (match headings with
   | first :: second :: third :: _ ->
     assert_equal ~msg:"the top CHANGELOG entry starts with the reported version" true
       (starts_with ("hilde (" ^ top ^ ") stable;") first);
     assert_equal ~msg:"the second CHANGELOG entry" "hilde (1.1.0) stable; urgency=low" second;
     assert_equal ~msg:"the third CHANGELOG entry" "hilde (1.0.0) stable; urgency=low" third
   | _ -> assert_failure "the CHANGELOG names fewer than three releases");
  let notes = String.concat "\n" (release_lines "hilde (1.1.0) stable; urgency=low") in
  assert_equal ~msg:"the 1.1.0 notes name the split of the prelude" true
    (contains "Runtime prelude split into parts." notes)

let suite =
  "Version" >::: [
      "reports the published release" >:: test_reports_the_published_release;
      "dune-project names the same version" >:: test_dune_project_names_the_same_version;
      "hilde.opam names the same version" >:: test_hilde_opam_names_the_same_version;
      "the package commands name the same version" >:: test_package_commands_name_the_same_version;
      "the CHANGELOG lists the published releases" >:: test_changelog_lists_the_published_releases;
    ]

let _ = run_test_tt_main suite
