(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open OUnit2
open Hilde_core.Identifier
open Hilde_core.CliUtil
open Hilde_core.CliParser

let parse_cmd (args: string list): cmd =
  parse (parse_args args)

let test_help_cmd _ =
  let cmd: cmd = parse_cmd ["hilde"; "--help"] in
  assert_equal cmd HelpCommand

let test_version_cmd _ =
  let cmd: cmd = parse_cmd ["hilde"; "--version"] in
  assert_equal cmd VersionCommand

let test_compile_help_cmd _ =
  let cmd: cmd = parse_cmd ["hilde"; "compile"; "--help"] in
  assert_equal cmd CompileHelp

let test_compile_default _ =
  let cmd: cmd = parse_cmd ["hilde"; "compile"; "foo.hiq"; "bar.hih,bar.hiq"; "--entrypoint=Foo:main"; "--output=out"]
  and expected: cmd = WholeProgramCompile {
                          modules = [
                            ModuleBodySource { body_path = "foo.hiq" };
                            ModuleSource { inter_path = "bar.hih"; body_path = "bar.hiq" };
                          ];
                          target = Executable {
                                       bin_path = "out";
                                       entrypoint = Entrypoint (make_mod_name "Foo", make_ident "main")
                                     };
                          target_system = "";
                          error_reporting_mode = ErrorReportPlain;
                          forbid_unsafe_modules = false;
                          line_directives = false;
                          contract_report = false;
                          module_dirs = []
                        }
  in
  assert_bool "commands are equal" (equal_cmd cmd expected)

(* --forbid-unsafe-modules, and its negative control: the same command line
   without the flag has to come out false, or the test would pass for a
   parser that always said true. *)
let test_forbid_unsafe_modules _ =
  let base = ["hilde"; "compile"; "foo.hiq"; "--entrypoint=Foo:main"; "--output=out"] in
  let flag_of (cmd: cmd): bool =
    match cmd with
    | WholeProgramCompile { forbid_unsafe_modules; _ } -> forbid_unsafe_modules
    | _ -> assert_failure "not a compile command"
  in
  assert_bool "without the flag" (not (flag_of (parse_cmd base)));
  assert_bool "with the flag"
    (flag_of (parse_cmd (base @ ["--forbid-unsafe-modules"])))

(* --contract-report, and its
   negative control: without the flag it is false. *)
let test_contract_report _ =
  let base = ["hilde"; "compile"; "foo.hiq"; "--entrypoint=Foo:main"; "--output=out"] in
  let flag_of (cmd: cmd): bool =
    match cmd with
    | WholeProgramCompile { contract_report; _ } -> contract_report
    | _ -> assert_failure "not a compile command"
  in
  assert_bool "without the flag" (not (flag_of (parse_cmd base)));
  assert_bool "with the flag" (flag_of (parse_cmd (base @ ["--contract-report"])))

(* --modules for compile:
   the directories in order, empty parts dropped; without the flag none. *)
let test_compile_modules _ =
  let base = ["hilde"; "compile"; "foo.hiq"; "--entrypoint=Foo:main"; "--output=out"] in
  let dirs_of (cmd: cmd): string list =
    match cmd with
    | WholeProgramCompile { module_dirs; _ } -> module_dirs
    | _ -> assert_failure "not a compile command"
  in
  assert_equal [] (dirs_of (parse_cmd base));
  assert_equal ["standard/src"; "bindings/generated"]
    (dirs_of (parse_cmd (base @ ["--modules=standard/src::bindings/generated"])))

(* --error-format=json-lines,
   beside json and the default plain. *)
let test_error_formats _ =
  let base = ["hilde"; "compile"; "foo.hiq"; "--entrypoint=Foo:main"; "--output=out"] in
  let mode_of (cmd: cmd): error_reporting_mode =
    match cmd with
    | WholeProgramCompile { error_reporting_mode; _ } -> error_reporting_mode
    | _ -> assert_failure "not a compile command"
  in
  assert_bool "plain" (mode_of (parse_cmd base) = ErrorReportPlain);
  assert_bool "json" (mode_of (parse_cmd (base @ ["--error-format=json"])) = ErrorReportJson);
  assert_bool "hilde-json"
    (mode_of (parse_cmd (base @ ["--error-format=hilde-json"])) = ErrorReportHildeJson);
  assert_bool "json-lines"
    (mode_of (parse_cmd (base @ ["--error-format=json-lines"])) = ErrorReportJsonLines)

(* hilde check: modules, --modules
   and the error format; without a module it is refused. *)
let test_check_cmd _ =
  let cmd: cmd = parse_cmd ["hilde"; "check"; "foo.hih,foo.hiq"; "bar.hiq"; "--modules=a:b"; "--error-format=json"]
  and expected: cmd = CheckCommand {
                          modules = [ModuleSource { inter_path = "foo.hih"; body_path = "foo.hiq" };
                                     ModuleBodySource { body_path = "bar.hiq" }];
                          target_system = "";
                          module_dirs = ["a"; "b"];
                          error_reporting_mode = ErrorReportJson;
                          forbid_unsafe_modules = false;
                        }
  in
  assert_bool "commands are equal" (equal_cmd cmd expected);
  (try
     let _ = parse_cmd ["hilde"; "check"] in
     assert_failure "a check without a module was accepted"
   with Hilde_core.Error.Hilde_error _ -> ())

(* `hilde query', and its refusal without --module. *)
let test_query_cmd _ =
  let cmd: cmd = parse_cmd ["hilde"; "query"; "foo.hih,foo.hiq"; "--module=Foo"; "--error-format=json"]
  and expected: cmd = QueryCommand {
                          modules = [ModuleSource { inter_path = "foo.hih"; body_path = "foo.hiq" }];
                          query_module = "Foo";
                          error_reporting_mode = ErrorReportJson;
                        }
  in
  assert_bool "commands are equal" (equal_cmd cmd expected)

(* hilde guard: with an
   entrypoint, and without one, where the walk starts from every
   function. *)
let test_guard_cmd _ =
  let modules = [ModuleSource { inter_path = "foo.hih"; body_path = "foo.hiq" }] in
  let with_entry: cmd = parse_cmd ["hilde"; "guard"; "foo.hih,foo.hiq"; "--entrypoint=Foo:main"]
  and without: cmd = parse_cmd ["hilde"; "guard"; "foo.hih,foo.hiq"] in
  assert_bool "with an entrypoint"
    (equal_cmd with_entry
       (GuardCommand { modules; json = false; module_dirs = [];
                       guard_entry = Some (Entrypoint (Hilde_core.Identifier.make_mod_name "Foo",
                                                       Hilde_core.Identifier.make_ident "main"));
                       vulndb = None; library_versions = [];
                       error_reporting_mode = ErrorReportPlain }));
  assert_bool "without one"
    (equal_cmd without (GuardCommand { modules; json = false; module_dirs = []; guard_entry = None; vulndb = None; library_versions = [];
                                       error_reporting_mode = ErrorReportPlain }))

(* hilde modules. *)
let test_modules_cmd _ =
  assert_bool "plain"
    (equal_cmd (parse_cmd ["hilde"; "modules"]) (ModulesCommand { module_dirs = []; json = false }));
  assert_bool "with --json and --modules"
    (equal_cmd (parse_cmd ["hilde"; "modules"; "--json"; "--modules=a:b"])
       (ModulesCommand { module_dirs = ["a"; "b"]; json = true }))

(* An unknown command is H1037, not the usage with exit 0: a tool that
   runs hilde chek must not read the usage as success. *)
let test_unknown_command _ =
  try
    let _ = parse_cmd ["hilde"; "chek"; "foo.hiq"] in
    assert_failure "an unknown command was accepted"
  with Hilde_core.Error.Hilde_error e ->
    let (Hilde_core.Error.HildeError { code; text; _ }) = e in
    assert_equal "H1037" (Hilde_core.Error.code_string code);
    let plain = Hilde_core.ErrorText.error_text_to_plain text in
    let want = "Did you mean `check`?" in
    let n = String.length want and m = String.length plain in
    let rec found i = i + n <= m && (String.sub plain i n = want || found (i + 1)) in
    assert_bool ("names check: " ^ plain) (found 0)

let test_query_needs_module _ =
  try
    let _ = parse_cmd ["hilde"; "query"; "foo.hiq"] in
    assert_failure "a query without --module was accepted"
  with Hilde_core.Error.Hilde_error e ->
    let (Hilde_core.Error.HildeError { code; _ }) = e in
    assert_equal "H1018" (Hilde_core.Error.code_string code)

let code_of (args: string list): string =
  try
    let _ = parse_cmd args in
    "none"
  with Hilde_core.Error.Hilde_error e ->
    let (Hilde_core.Error.HildeError { code; _ }) = e in
    Hilde_core.Error.code_string code

(* The help text names the values of --target-type from target_types.
   Every one of them is taken by the parser, the first is what the parser
   does without the flag, and a name that is not one of them is refused:
   so the help cannot name a target the parser refuses, as it named `bin'
   before. *)
let test_target_types _ =
  let base = ["hilde"; "compile"; "foo.hiq"; "--entrypoint=Foo:main"; "--output=out"] in
  (* tc checks the types and writes nothing, so it takes neither flag; a
     library takes no entrypoint, and its output names its kind. *)
  let args_for (t: string): string list =
    match t with
    | "tc" -> ["hilde"; "compile"; "foo.hiq"]
    | "static" -> ["hilde"; "compile"; "foo.hiq"; "--output=libfoo.a"]
    | "shared" -> ["hilde"; "compile"; "foo.hiq"; "--output=libfoo.so"]
    | "wasm" -> ["hilde"; "compile"; "foo.hiq"; "--output=foo.wasm"]
    | _ -> base
  in
  assert_bool "the list is not empty" (target_types <> []);
  List.iter
    (fun t ->
      assert_equal ~msg:("--target-type=" ^ t) "none" (code_of (args_for t @ ["--target-type=" ^ t])))
    target_types;
  assert_bool "the first is the default"
    (equal_cmd (parse_cmd base) (parse_cmd (base @ ["--target-type=" ^ List.hd target_types])));
  assert_equal ~msg:"--target-type=bin" "H1007" (code_of (base @ ["--target-type=bin"]))

(* The library targets, static, shared and
   wasm: what each makes, and
   the refusals -- an entrypoint, no output, and an output whose suffix is
   the other kind's or only the suffix itself.  --no-entrypoint is taken. *)
let test_library_targets _ =
  let lib (kind: string) (rest: string list): string list =
    ["hilde"; "compile"; "foo.hiq"; "--target-type=" ^ kind] @ rest
  in
  assert_bool "static"
    (match parse_cmd (lib "static" ["--output=libfoo.a"]) with
     | WholeProgramCompile { target = Library { output_path = "libfoo.a"; kind = StaticLibrary }; _ } -> true
     | _ -> false);
  assert_bool "shared, with --no-entrypoint"
    (match parse_cmd (lib "shared" ["--no-entrypoint"; "--output=libfoo.so"]) with
     | WholeProgramCompile { target = Library { output_path = "libfoo.so"; kind = SharedLibrary }; _ } -> true
     | _ -> false);
  assert_equal ~msg:"an entrypoint" "H1026"
    (code_of (lib "static" ["--entrypoint=Foo:main"; "--output=libfoo.a"]));
  assert_equal ~msg:"no output" "H1005" (code_of (lib "shared" []));
  assert_equal ~msg:"the other suffix" "H1027" (code_of (lib "shared" ["--output=libfoo.a"]));
  assert_bool "wasm"
    (match parse_cmd (lib "wasm" ["--output=foo.wasm"]) with
     | WholeProgramCompile { target = Library { output_path = "foo.wasm"; kind = WasmModule }; _ } -> true
     | _ -> false);
  assert_equal ~msg:"wasm, an entrypoint" "H1026"
    (code_of (lib "wasm" ["--entrypoint=Foo:main"; "--output=foo.wasm"]));
  assert_equal ~msg:"wasm, a suffix of a shared object" "H1027" (code_of (lib "wasm" ["--output=libfoo.so"]));
  assert_equal ~msg:"the suffix alone" "H1027" (code_of (lib "static" ["--output=.a"]))

(* --target and hilde build: a programme for wasm is a command module
   ending in .wasm, a library for wasm is built for wasm without the flag,
   and the refusals -- an unknown name, another system than this one, an
   archive or a shared object for wasm, an output without .wasm, an
   instrument of hilde test with wasm. *)
let test_target_system _ =
  let build (rest: string list): string list = ["hilde"; "build"; "foo.hiq"] @ rest in
  let host: string = Lazy.force Hilde_core.Util.host_target in
  let foreign: string =
    List.find (fun n -> n <> "wasm" && n <> host) Hilde_core.Util.target_names
  in
  assert_bool "build, wasm"
    (match parse_cmd (build ["--target=wasm"; "--entrypoint=Foo:main"; "--output=foo.wasm"]) with
     | WholeProgramCompile { target = Executable { bin_path = "foo.wasm"; _ }; target_system = "wasm"; _ } -> true
     | _ -> false);
  assert_bool "build, the host by its name"
    (match parse_cmd (build ["--target=" ^ host; "--entrypoint=Foo:main"; "--output=foo"]) with
     | WholeProgramCompile { target_system; _ } -> target_system = host
     | _ -> false);
  assert_bool "no --target"
    (match parse_cmd (build ["--entrypoint=Foo:main"; "--output=foo"]) with
     | WholeProgramCompile { target_system = ""; _ } -> true
     | _ -> false);
  assert_bool "a library for wasm is built for wasm"
    (match parse_cmd (build ["--target-type=wasm"; "--output=foo.wasm"]) with
     | WholeProgramCompile { target_system = "wasm"; _ } -> true
     | _ -> false);
  assert_equal ~msg:"an unknown name" "H1041" (code_of (build ["--target=wsam"; "--entrypoint=Foo:main"; "--output=foo.wasm"]));
  assert_equal ~msg:"another system" "H1042" (code_of (build ["--target=" ^ foreign; "--entrypoint=Foo:main"; "--output=foo"]));
  assert_equal ~msg:"an archive for wasm" "H1043" (code_of (build ["--target=wasm"; "--target-type=static"; "--output=libfoo.a"]));
  assert_equal ~msg:"no .wasm" "H1044" (code_of (build ["--target=wasm"; "--entrypoint=Foo:main"; "--output=foo"]));
  assert_bool "test, wasm"
    (match parse_cmd ["hilde"; "test"; "src"; "--target=wasm"] with
     | TestCommand { target_system = "wasm"; _ } -> true
     | _ -> false);
  assert_equal ~msg:"test, wasm with valgrind" "H1020" (code_of ["hilde"; "test"; "src"; "--target=wasm"; "--valgrind"])

(* --no-entrypoint without --target-type=c is H1006.  The flag was looked
   up with its two hyphens, which the argument list does not keep, so the
   case fell through to H1003, the missing --entrypoint; the second line is
   the case the flag is for, and the third the plain missing entrypoint. *)
let test_no_entrypoint _ =
  assert_equal ~msg:"--no-entrypoint, default target" "H1006"
    (code_of ["hilde"; "compile"; "foo.hiq"; "--no-entrypoint"; "--output=out"]);
  assert_equal ~msg:"--no-entrypoint, target c" "none"
    (code_of ["hilde"; "compile"; "foo.hiq"; "--no-entrypoint"; "--target-type=c"; "--output=out.c"]);
  assert_equal ~msg:"no entrypoint at all" "H1003"
    (code_of ["hilde"; "compile"; "foo.hiq"; "--output=out"])

(* `hilde test': the defaults, every flag once, and the
   three refusals the command line itself decides -- no path, two
   instruments, --emit-c beside an instrument. *)
let test_test_cmd _ =
  assert_bool "defaults"
    (equal_cmd (parse_cmd ["hilde"; "test"; "src"])
       (TestCommand { paths = ["src"]; target_system = ""; module_dirs = []; instrument = NoInstrument;
                      verbose = false; emit_c = None; contracts = None;
                      jobs = 1; test_jobs = 1; fresh_dirs = false; doc = false; json = false;
                      error_reporting_mode = ErrorReportPlain }));
  assert_bool "every flag"
    (equal_cmd
       (parse_cmd ["hilde"; "test"; "a"; "b.hiq"; "--modules=x:y"; "--race"; "--verbose"])
       (TestCommand { paths = ["a"; "b.hiq"]; target_system = ""; module_dirs = ["x"; "y"]; instrument = RaceInstrument;
                      verbose = true; emit_c = None; contracts = None;
                      jobs = 1; test_jobs = 1; fresh_dirs = false; doc = false; json = false;
                      error_reporting_mode = ErrorReportPlain }));
  assert_bool "--emit-c"
    (equal_cmd (parse_cmd ["hilde"; "test"; "a"; "--emit-c=out"])
       (TestCommand { paths = ["a"]; target_system = ""; module_dirs = []; instrument = NoInstrument;
                      verbose = false; emit_c = Some "out"; contracts = None;
                      jobs = 1; test_jobs = 1; fresh_dirs = false; doc = false; json = false;
                      error_reporting_mode = ErrorReportPlain }));
  assert_bool "--memory" (match parse_cmd ["hilde"; "test"; "a"; "--memory"] with
                          | TestCommand { instrument = MemoryInstrument; _ } -> true | _ -> false);
  assert_bool "--valgrind" (match parse_cmd ["hilde"; "test"; "a"; "--valgrind"] with
                            | TestCommand { instrument = ValgrindInstrument; _ } -> true | _ -> false);
  assert_equal ~msg:"--help" true (equal_cmd (parse_cmd ["hilde"; "test"; "--help"]) TestHelp);
  assert_equal ~msg:"no path" "H1019" (code_of ["hilde"; "test"]);
  assert_equal ~msg:"two instruments" "H1020" (code_of ["hilde"; "test"; "a"; "--race"; "--valgrind"]);
  assert_equal ~msg:"--emit-c and an instrument" "H1020"
    (code_of ["hilde"; "test"; "a"; "--emit-c=out"; "--memory"]);
  assert_bool "--jobs=16" (match parse_cmd ["hilde"; "test"; "a"; "--jobs=16"] with
                           | TestCommand { jobs = 16; _ } -> true | _ -> false);
  assert_bool "--jobs=256" (match parse_cmd ["hilde"; "test"; "a"; "--jobs=256"] with
                            | TestCommand { jobs = 256; _ } -> true | _ -> false);
  assert_equal ~msg:"--jobs=0" "H1028" (code_of ["hilde"; "test"; "a"; "--jobs=0"]);
  assert_equal ~msg:"--jobs=257" "H1028" (code_of ["hilde"; "test"; "a"; "--jobs=257"]);
  assert_equal ~msg:"--jobs=x" "H1028" (code_of ["hilde"; "test"; "a"; "--jobs=x"]);
  assert_bool "--test-jobs=8 --fresh-dirs"
    (match parse_cmd ["hilde"; "test"; "a"; "--test-jobs=8"; "--fresh-dirs"] with
     | TestCommand { test_jobs = 8; fresh_dirs = true; _ } -> true | _ -> false);
  assert_equal ~msg:"--test-jobs=0" "H1028" (code_of ["hilde"; "test"; "a"; "--test-jobs=0"]);
  assert_equal ~msg:"an unknown flag" "H6005" (code_of ["hilde"; "test"; "a"; "--fast"])

(* hilde test --contracts: the
   defaults, a seed and a number of rounds, the largest seed, and the values
   refused -- a seed beyond a Nat64, rounds of 0 and beyond the limit, a
   value that is not a number, and --seed or --rounds without --contracts. *)
let contracts_of (args: string list): contract_run option =
  match parse_cmd args with
  | TestCommand { contracts; _ } -> contracts
  | _ -> None

let test_contracts _ =
  assert_bool "--contracts alone"
    (contracts_of ["hilde"; "test"; "a"; "--contracts"] = Some { seed = None; rounds = 100 });
  assert_bool "--seed and --rounds"
    (contracts_of ["hilde"; "test"; "a"; "--contracts"; "--seed=0042"; "--rounds=7"]
     = Some { seed = Some "42"; rounds = 7 });
  assert_bool "the largest seed"
    (contracts_of ["hilde"; "test"; "a"; "--contracts"; "--seed=18446744073709551615"]
     = Some { seed = Some "18446744073709551615"; rounds = 100 });
  assert_bool "no --contracts" (contracts_of ["hilde"; "test"; "a"] = None);
  assert_equal ~msg:"a seed beyond a Nat64" "H1028"
    (code_of ["hilde"; "test"; "a"; "--contracts"; "--seed=18446744073709551616"]);
  assert_equal ~msg:"a seed that is not a number" "H1028"
    (code_of ["hilde"; "test"; "a"; "--contracts"; "--seed=-1"]);
  assert_equal ~msg:"no rounds" "H1028"
    (code_of ["hilde"; "test"; "a"; "--contracts"; "--rounds=0"]);
  assert_equal ~msg:"too many rounds" "H1028"
    (code_of ["hilde"; "test"; "a"; "--contracts"; "--rounds=100001"]);
  assert_equal ~msg:"--seed without --contracts" "H1029"
    (code_of ["hilde"; "test"; "a"; "--seed=1"]);
  assert_equal ~msg:"--rounds without --contracts" "H1029"
    (code_of ["hilde"; "test"; "a"; "--rounds=5"])

(* The vulnerability database and the versions of the libraries:
   each version kept, in
   the order given; an entry that is not a library, a colon and numbers is
   H1032. *)
let test_guard_vulnerabilities _ =
  let modules = [ModuleSource { inter_path = "foo.hih"; body_path = "foo.hiq" }] in
  let cmd: cmd = parse_cmd ["hilde"; "guard"; "foo.hih,foo.hiq"; "--vulndb=osv";
                            "--library-versions=sqlite3:3.46.1,tls:4.3"] in
  assert_bool "the database and two versions"
    (equal_cmd cmd (GuardCommand { modules; json = false; module_dirs = []; guard_entry = None; vulndb = Some "osv";
                                   library_versions = [("sqlite3", "3.46.1"); ("tls", "4.3")];
                                   error_reporting_mode = ErrorReportPlain }));
  assert_equal ~msg:"no colon" "H1032"
    (code_of ["hilde"; "guard"; "foo.hiq"; "--library-versions=sqlite3"]);
  assert_equal ~msg:"a version with a letter" "H1032"
    (code_of ["hilde"; "guard"; "foo.hiq"; "--library-versions=sqlite3:3.46b"]);
  assert_equal ~msg:"no name" "H1032"
    (code_of ["hilde"; "guard"; "foo.hiq"; "--library-versions=tls:4.3,:3.46.1"])

let suite =
  "CliParser" >::: [
      "test" >:: test_test_cmd;
      "test --contracts" >:: test_contracts;
      "--help" >:: test_help_cmd;
      "--version" >:: test_version_cmd;
      "compile --help" >:: test_compile_help_cmd;
      "compile default" >:: test_compile_default;
      "--forbid-unsafe-modules" >:: test_forbid_unsafe_modules;
      "--contract-report" >:: test_contract_report;
      "compile --modules" >:: test_compile_modules;
      "--error-format values" >:: test_error_formats;
      "check" >:: test_check_cmd;
      "query" >:: test_query_cmd;
      "query without --module" >:: test_query_needs_module;
      "modules" >:: test_modules_cmd;
      "unknown command" >:: test_unknown_command;
      "guard" >:: test_guard_cmd;
      "guard --vulndb" >:: test_guard_vulnerabilities;
      "--target-type values" >:: test_target_types;
      "library targets" >:: test_library_targets;
      "--target and build" >:: test_target_system;
      "--no-entrypoint" >:: test_no_entrypoint;
    ]

let _ = run_test_tt_main suite
