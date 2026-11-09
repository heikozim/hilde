(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* hilde guard: the report of a
   small programme.  Module G is unsafe and binds three C functions: abs
   is called directly, labs only through a function pointer, rand never.
   It has two embeds, one in a generic function the programme uses with
   two types and one in a function it does not.  The report must name each
   of them with the right state, from the entrypoint and without one, and
   the embed of the generic function once, with its count. *)
open OUnit2
open Hilde_core.Identifier
open Hilde_core.Error
open Hilde_core.Compiler
open TestUtil

let interface_code = String.concat "\n" [
    "module G is";
    "    function used(): Int32;";
    "    function unusedHere(): Int32;";
    "    function pointed(): Int64;";
    "    generic [T: Free]";
    "    function viaGeneric(x: T): Int32;";
    "end module.";
    ""
  ]

let body_code = String.concat "\n" [
    "pragma Unsafe_Module;";
    "pragma Foreign_Library(Name => \"c\");";
    "";
    "module body G is";
    "    pragma Foreign_Import(External_Name => \"abs\");";
    "    function cAbs(x: Int32): Int32 is";
    "    end;";
    "";
    "    pragma Foreign_Import(External_Name => \"labs\");";
    "    function cLabs(x: Int64): Int64 is";
    "    end;";
    "";
    "    pragma Foreign_Import(External_Name => \"rand\");";
    "    function cRand(): Int32 is";
    "    end;";
    "";
    "    function used(): Int32 is";
    "        let three: Int32 := -3;";
    "        return cAbs(three);";
    "    end;";
    "";
    "    function unusedHere(): Int32 is";
    "        return @embed(Int32, \"7\");";
    "    end;";
    "";
    "    function viaPointer(x: Int64): Int64 is";
    "        return cLabs(x);";
    "    end;";
    "";
    "    function pointed(): Int64 is";
    "        let f: Fn[Int64, Int64] := viaPointer;";
    "        let five: Int64 := 5;";
    "        return f(five);";
    "    end;";
    "";
    "    generic [T: Free]";
    "    function viaGeneric(x: T): Int32 is";
    "        return @embed(Int32, \"42\");";
    "    end;";
    "end module body.";
    ""
  ]

let main_code = String.concat "\n" [
    "import G (used, pointed, viaGeneric);";
    "";
    "module body M is";
    "    function main(): ExitCode is";
    "        printLn(used());";
    "        printLn(pointed());";
    "        printLn(viaGeneric(true));";
    "        let one: Int32 := 1;";
    "        printLn(viaGeneric(one));";
    "        return ExitSuccess();";
    "    end;";
    "end module body.";
    ""
  ]

let sources: module_source list = [
    TwoFileModuleSource { int_filename = "G.hih"; int_code = interface_code;
                          body_filename = "G.hiq"; body_code = body_code };
    BodyModuleSource { body_filename = "M.hiq"; body_code = main_code };
  ]

let lines (report: string): string list =
  List.filter (fun l -> l <> "") (String.split_on_char '\n' report)

(* The lines of the report that start with one of the given words. *)
let string_list_printer (l: string list): string = String.concat "|" l

let starting (prefix: string) (report: string): string list =
  let n = String.length prefix in
  List.filter (fun l -> String.length l >= n && String.sub l 0 n = prefix) (lines report)

let from_main (): string =
  guard_modules sources (Some (make_mod_name "M", make_ident "main"))

let test_foreign_from_main _ =
  let r = from_main () in
  eq ["foreign functions: 3, reachable: 2"] (starting "foreign functions:" r);
  eq ["  reachable  G.cAbs -> abs";
      "  reachable  G.cLabs -> labs";
      "  unreached  G.cRand -> rand"]
    (starting "  reachable  G." r @ starting "  unreached  G." r
     |> List.filter (fun l -> String.contains l '>'))

let test_embeds_from_main _ =
  let r = from_main () in
  eq ["embeds: 2, reachable: 1"] (starting "embeds:" r);
  eq ["  reachable  G.viaGeneric: 42 (2 times)"; "  unreached  G.unusedHere: 7"]
    (List.filter (fun l -> not (String.contains l '>'))
       (starting "  reachable  G." r @ starting "  unreached  G." r))

let test_unsafe_and_roots _ =
  let r = from_main () in
  eq ["unsafe modules on the command line: 1"] (starting "unsafe modules" r);
  eq ["  G (G.hiq)"] (starting "  G (" r);
  eq ["roots: the entrypoint, the exported functions and the values of the constants"]
    (starting "roots:" r);
  eq 1 (List.length (starting "built into the compiler, not listed:" r))

(* Without an entrypoint every function is a root: both embeds are
   reachable, and rand still is not, since nothing calls it. *)
let test_without_entrypoint _ =
  let r = guard_modules sources None in
  eq ["roots: no entrypoint and no export, so every function"] (starting "roots:" r);
  eq ["foreign functions: 3, reachable: 2"] (starting "foreign functions:" r);
  eq ["embeds: 2, reachable: 2"] (starting "embeds:" r)

(* The vulnerability part,
   against five advisories made for the test, all for version 2.0 of the
   library c the programme binds but where said: 0001 names labs, which the
   programme reaches through a pointer, and is the one reported; 0002 names
   rand, which it never calls; 0003 names abs but starts at 3.0; 0004 is for
   the library m, which the programme does not bind; 0005 names no
   function. *)
let fixture = {|[
  {"id": "HILDE-FIXTURE-0001", "summary": "a fixture, reached through a pointer",
   "affected": [{"package": {"ecosystem": "C", "name": "c"},
                 "ranges": [{"type": "ECOSYSTEM", "events": [{"introduced": "1.0"}, {"fixed": "2.5"}]}],
                 "ecosystem_specific": {"imports": [{"symbols": ["labs"]}]}}]},
  {"id": "HILDE-FIXTURE-0002", "summary": "a fixture, never called",
   "affected": [{"package": {"ecosystem": "C", "name": "c"},
                 "ranges": [{"type": "ECOSYSTEM", "events": [{"introduced": "0"}]}],
                 "ecosystem_specific": {"imports": [{"symbols": ["rand"]}]}}]},
  {"id": "HILDE-FIXTURE-0003", "summary": "a fixture, a later version",
   "affected": [{"package": {"ecosystem": "C", "name": "c"},
                 "ranges": [{"type": "ECOSYSTEM", "events": [{"introduced": "3.0"}]}],
                 "ecosystem_specific": {"imports": [{"symbols": ["abs"]}]}}]},
  {"id": "HILDE-FIXTURE-0004", "summary": "a fixture, another library",
   "affected": [{"package": {"ecosystem": "C", "name": "m"},
                 "ranges": [{"type": "ECOSYSTEM", "events": [{"introduced": "0"}]}],
                 "ecosystem_specific": {"imports": [{"symbols": ["abs"]}]}}]},
  {"id": "HILDE-FIXTURE-0005", "summary": "a fixture, no function named",
   "affected": [{"package": {"ecosystem": "C", "name": "c"},
                 "ranges": [{"type": "ECOSYSTEM", "events": [{"introduced": "2.0"}, {"fixed": "2.0.1"}]}]}]}
]|}

let checked (versions: (string * string) list): string * int =
  let advisories = Hilde_core.Guard.advisories_of_string "the fixture" fixture in
  guard_report sources (Some (make_mod_name "M", make_ident "main"))
    ~vulnerabilities:(Some { Hilde_core.Guard.advisories; source = "the fixture"; versions })

let test_vulnerability_reached _ =
  let (r, reached) = checked [("c", "2.0")] in
  eq 1 reached;
  eq ["vulnerabilities: 5 advisories in the fixture, 4 of them for the libraries linked"]
    (starting "vulnerabilities:" r);
  eq ["  c 2.0: 4 advisories checked"] (starting "  c " r);
  eq ["  reached  HILDE-FIXTURE-0001  c 2.0 (affected: 1.0 to before 2.5) through labs: a fixture, reached through a pointer"]
    (starting "  reached  HILDE-" r);
  eq ["vulnerabilities reached: 1; in the versions given but not reached: 1; naming no function: 1"]
    (starting "vulnerabilities reached:" r)

(* Without the version of c nothing is checked and nothing reported. *)
let test_vulnerability_without_version _ =
  let (r, reached) = checked [] in
  eq 0 reached;
  eq ["  c: no version given, 4 advisories not checked"] (starting "  c" r);
  eq [] (starting "  reached  HILDE-" r)

(* Versions compare number by number; a database that is not JSON, or
   whose version is not numbers, is H1031; no check, no part. *)
let test_vulnerability_database _ =
  let v s = match Hilde_core.Guard.version_parts s with Some v -> v | None -> [] in
  eq 0 (Hilde_core.Guard.compare_versions (v "3.39") (v "3.39.0"));
  eq (-1) (Hilde_core.Guard.compare_versions (v "3.9") (v "3.39"));
  eq None (Hilde_core.Guard.version_parts "3.4b");
  let code_of (text: string): string =
    try let _ = Hilde_core.Guard.advisories_of_string "x" text in "none" with
    | Hilde_error (HildeError { code; _ }) -> code_string code
  in
  eq "H1031" (code_of "not json");
  eq "H1031" (code_of {|{"id": "X", "affected": [{"package": {"name": "c"}, "ranges": [{"events": [{"introduced": "1.x"}]}]}]}|});
  eq [] (starting "vulnerabilities" (guard_modules sources (Some (make_mod_name "M", make_ident "main"))))

let test_same_report_twice _ =
  eq (from_main ()) (from_main ())

let test_missing_entrypoint _ =
  try
    let _ = guard_modules sources (Some (make_mod_name "M", make_ident "start")) in
    assert_failure "an entrypoint that is not there was accepted"
  with Hilde_error e ->
    let (HildeError { code; _ }) = e in
    eq "H1030" (code_string code)

(* The ffi capability: the module G names the library c with pragma
   Foreign_Library, so its package uses ffi; declared or not, the report
   says which.  A manifest that names a table rust uses ffi through the
   table alone. *)
let packages (declared: string list) (rust: bool): Hilde_core.Guard.package_rule list =
  [ { Hilde_core.Guard.prefix = "G"; declared; manifest = "G/hilde.toml"; rust } ]

let test_ffi_undeclared _ =
  let (capability_lines, undeclared) =
    guard_capabilities sources (Some (make_mod_name "M", make_ident "main"))
      ~packages:(packages ["unsafe"] false)
  in
  (* G also calls a foreign function and holds a reached embed, so the
     report names all four capabilities, and ffi among the undeclared. *)
  if undeclared <> 3 then assert_failure ("undeclared is " ^ string_of_int undeclared);
  eq ~printer:string_list_printer
    ["  G (G/hilde.toml): declares unsafe; uses unsafe foreign embed ffi"]
    (List.filter (fun l -> String.length l >= 4 && String.sub l 0 4 = "  G ") capability_lines);
  eq ~printer:string_list_printer
    ["  undeclared: G uses foreign, which G/hilde.toml does not name in [package] capabilities";
     "  undeclared: G uses embed, which G/hilde.toml does not name in [package] capabilities";
     "  undeclared: G uses ffi, which G/hilde.toml does not name in [package] capabilities"]
    (List.filter (fun l -> String.length l >= 13 && String.sub l 0 13 = "  undeclared:") capability_lines)

let test_ffi_declared _ =
  let (capability_lines, undeclared) =
    guard_capabilities sources (Some (make_mod_name "M", make_ident "main"))
      ~packages:(packages ["unsafe"; "foreign"; "embed"; "ffi"] false)
  in
  eq 0 undeclared;
  eq ["  G (G/hilde.toml): declares unsafe foreign embed ffi; uses unsafe foreign embed ffi"]
    (List.filter (fun l -> String.length l >= 4 && String.sub l 0 4 = "  G ") capability_lines)

let test_ffi_from_rust_table _ =
  let (capability_lines, undeclared) =
    guard_capabilities sources (Some (make_mod_name "M", make_ident "main"))
      ~packages:(packages ["ffi"] true)
  in
  (* The table rust alone uses ffi; the module still uses the other three. *)
  eq 3 undeclared;
  eq ["  G (G/hilde.toml): declares ffi; uses unsafe foreign embed ffi"]
    (List.filter (fun l -> String.length l >= 4 && String.sub l 0 4 = "  G ") capability_lines)

(* The parser of the cargo audit output: one vulnerability with the fixed
   version, one yanked crate, and text that is no JSON, which is a finding
   of kind tool. *)
let audit_json =
  {|{"vulnerabilities": {"count": 1, "list": [{"advisory": {"id": "RUSTSEC-FIXTURE-0001", "package": "time", "title": "a fixture", "patched_versions": [">=0.2.23"]}, "versions": {"patched": [">=0.2.23"]}, "package": {"name": "time", "version": "0.1.45"}}]}, "warnings": {"yanked": [{"kind": "yanked", "package": {"name": "memoffset", "version": "0.5.3"}}]}}|}

let kinds (findings: Hilde_core.Guard.rust_finding list): string list =
  List.map (fun f -> f.Hilde_core.Guard.rust_kind) findings

let test_parse_audit _ =
  let findings = Hilde_core.Guard.parse_audit_json audit_json in
  eq ["vulnerability"; "yanked"] (kinds findings);
  (match findings with
   | v :: _ ->
      eq "time" v.Hilde_core.Guard.rust_crate;
      eq "0.1.45" v.Hilde_core.Guard.rust_version;
      eq "0.2.23" v.Hilde_core.Guard.rust_fixed;
      eq "RUSTSEC-FIXTURE-0001: a fixture" v.Hilde_core.Guard.rust_detail
   | _ -> assert_failure "the vulnerability was not read");
  eq ["tool"] (kinds (Hilde_core.Guard.parse_audit_json "not json"))

(* The parser of the cargo deny output: one object per line, a finding for
   each diagnostic of severity error, the kind from fields.checks. *)
let test_parse_deny _ =
  let findings =
    Hilde_core.Guard.parse_deny_output
      {|{"type":"diagnostic","severity":"error","fields":{"checks":["bans"],"message":"crate 'openssl-sys 0.9.100' is banned"}}
{"type":"diagnostic","severity":"error","fields":{"checks":["licenses"],"message":"The 'GPL-3.0-only' license is not allowed"}}
{"type":"diagnostic","severity":"warning","fields":{"checks":["licenses"],"message":"a warning"}}
not json at all|}
  in
  eq ["banned"; "license"; "tool"] (kinds findings);
  (match findings with
   | banned :: _ -> eq "crate 'openssl-sys 0.9.100' is banned" banned.Hilde_core.Guard.rust_detail
   | _ -> assert_failure "the ban was not read")

(* The line of a finding names the crate, its version and the fixed one. *)
let test_finding_line _ =
  let open Hilde_core.Guard in
  eq "  vulnerability: time 0.1.45, fixed in 0.2.23: RUSTSEC-FIXTURE-0001: a fixture"
    (rust_finding_line { rust_kind = "vulnerability"; rust_crate = "time"; rust_version = "0.1.45";
                         rust_fixed = "0.2.23"; rust_detail = "RUSTSEC-FIXTURE-0001: a fixture" });
  eq "  yanked: memoffset 0.5.3: the crate was yanked from crates.io"
    (rust_finding_line { rust_kind = "yanked"; rust_crate = "memoffset"; rust_version = "0.5.3";
                         rust_fixed = ""; rust_detail = "the crate was yanked from crates.io" });
  eq "  tool: cargo-audit ended with exit status 1 and said nothing readable"
    (rust_finding_line { rust_kind = "tool"; rust_crate = ""; rust_version = ""; rust_fixed = "";
                         rust_detail = "cargo-audit ended with exit status 1 and said nothing readable" })

let suite =
  "Guard" >::: [
      "foreign functions from main" >:: test_foreign_from_main;
      "embeds from main" >:: test_embeds_from_main;
      "unsafe modules and roots" >:: test_unsafe_and_roots;
      "without an entrypoint" >:: test_without_entrypoint;
      "the same report twice" >:: test_same_report_twice;
      "a vulnerability reached" >:: test_vulnerability_reached;
      "no version given" >:: test_vulnerability_without_version;
      "the database" >:: test_vulnerability_database;
      "an entrypoint that is not there" >:: test_missing_entrypoint;
      "ffi undeclared" >:: test_ffi_undeclared;
      "ffi declared" >:: test_ffi_declared;
      "ffi from a rust table" >:: test_ffi_from_rust_table;
      "the audit parser" >:: test_parse_audit;
      "the deny parser" >:: test_parse_deny;
      "the line of a finding" >:: test_finding_line
    ]

let _ = run_test_tt_main suite
