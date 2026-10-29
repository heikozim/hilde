(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open CliParser
open Version
open Compiler
open Util
open Error
open HtmlError
open SourceContext

(* Source map stuff *)

(* Map of filenames to file contents. *)
module SourceMap =
  Map.Make(
      struct
        type t = string
        let compare a b = compare a b
      end
    )

type source_map = string SourceMap.t

(* Parsing file contents *)

let make_module_source (m: mod_source): module_source =
  match m with
  | ModuleSource { inter_path; body_path; } ->
     TwoFileModuleSource {
         int_filename = inter_path;
         int_code = read_file_to_string inter_path;
         body_filename = body_path;
         body_code = read_file_to_string body_path
       }
  | ModuleBodySource { body_path; } ->
     BodyModuleSource {
         body_filename = body_path;
         body_code = read_file_to_string body_path
       }

(* The file names and texts of the modules, for the lines an error shows. *)
let rec source_map_of (contents: module_source list): source_map =
  snd (sources_with_map contents)

and sources_with_map (contents: module_source list): (module_source list * source_map) =
  (* Build source map for error handling *)
  let source_maps =
    List.map (fun source ->
        match source with
        | TwoFileModuleSource { int_filename; int_code; body_filename; body_code; } ->
           let smap = SourceMap.empty in
           let smap = SourceMap.add int_filename int_code smap in
           let smap = SourceMap.add body_filename body_code smap in
           smap
        | BodyModuleSource { body_filename; body_code; } ->
           let smap = SourceMap.empty in
           let smap = SourceMap.add body_filename body_code smap in
           smap)
      contents
  in
  let source_map =
    List.fold_left
      (fun sm sm' -> SourceMap.union (fun _ v _ -> Some v) sm sm')
      (SourceMap.empty)
      source_maps
  in
  (contents, source_map)

let parse_source_files (mods: mod_source list): (module_source list * source_map) =
  sources_with_map (List.map make_module_source mods)

(* Execution *)

let rec exec (cmd: cmd): unit =
  match cmd with
  | HelpCommand ->
     print_usage ()
  | VersionCommand ->
     print_version ()
  | CompileHelp ->
     print_compile_usage ()
  | TestHelp ->
     print_test_usage ()
  | TestCommand { paths; target_system; module_dirs; instrument; verbose; emit_c; contracts; jobs; test_jobs; fresh_dirs; doc; json; error_reporting_mode } ->
     build_target := target_system;
     let doc = doc || package_root () <> None in
     let code: int =
       TestRunner.run ~paths ~module_dirs ~instrument ~verbose ~emit_c ~contracts ~jobs ~test_jobs ~fresh_dirs
         ~doc ~json ~mode:error_reporting_mode
     in
     if code <> 0 then exit code
  | WholeProgramCompile { modules; target; target_system; error_reporting_mode; forbid_unsafe_modules;
                          line_directives; contract_report; module_dirs } ->
     build_target := target_system;
     (* Set before anything is generated, and only
        here: the code generator asks a flag, it does not take one. *)
     CodeGen.set_line_directives line_directives;
     Contracts.reset_report ();
     exec_compile modules target error_reporting_mode forbid_unsafe_modules module_dirs;
     (* Written after the programme compiled: a
        compilation that fails has ended the process before this line. *)
     if contract_report then begin
       let lines = Contracts.report () in
       List.iter (fun line -> prerr_endline ("contract: " ^ line)) lines;
       prerr_endline ("contract report: " ^ (string_of_int (List.length lines))
                      ^ " clauses not proved, checked at run time")
     end
  | ModulesCommand { module_dirs; json } ->
     exec_modules module_dirs json
  | LspCommand { module_dirs } ->
     set_binary_mode_in stdin true;
     set_binary_mode_out stdout true;
     exit (Lsp.serve ~dirs:module_dirs stdin stdout)
  | FmtCommand { paths; check; json } ->
     exec_fmt paths check json
  | CheckCommand { modules; target_system; module_dirs; error_reporting_mode; forbid_unsafe_modules } ->
     build_target := target_system;
     exec_check modules module_dirs error_reporting_mode forbid_unsafe_modules
  | QueryCommand { modules; query_module; error_reporting_mode } ->
     exec_query modules query_module error_reporting_mode
  | GuardCommand { modules; json; module_dirs; guard_entry; vulndb; library_versions; error_reporting_mode } ->
     exec_guard modules json module_dirs guard_entry vulndb library_versions error_reporting_mode
  | PackageCommand { words } ->
     exec_package words
  | RunCommand { words } ->
     exec_run words

(* Runs f with standard output sent to standard error, child processes
   included, and puts standard output back afterwards. *)
and with_output_on_stderr : 'a. (unit -> 'a) -> 'a = fun f ->
  flush stdout;
  let saved = Unix.dup Unix.stdout in
  Unix.dup2 Unix.stderr Unix.stdout;
  Fun.protect
    ~finally:(fun () -> flush stdout; Unix.dup2 saved Unix.stdout; Unix.close saved)
    f

(* The package commands are a programme of their own, written in Hilde,
   which lies beside the compiler.  It replaces this process, so its
   output and its exit status are the command's.  HILDE_COMPILER tells it
   which compiler called it, for the tests it runs and the standard
   library beside that compiler. *)
and exec_package (words: string list): unit =
  let tool = Filename.concat (Filename.dirname Sys.executable_name) "hilde-pkg" in
  if not (Sys.file_exists tool) then
    package_tool_missing tool
  else
    let own = "HILDE_COMPILER=" ^ Sys.executable_name in
    let others =
      List.filter
        (fun e -> not (String.length e >= 15 && String.sub e 0 15 = "HILDE_COMPILER="))
        (Array.to_list (Unix.environment ()))
    in
    try Unix.execve tool (Array.of_list (tool :: words)) (Array.of_list (own :: others))
    with Unix.Unix_error (e, _, _) -> package_tool_failed tool (Unix.error_message e)

(* hilde run is a programme of its own, written in Hilde, beside the
   compiler: it starts the ranks of a job.  It replaces this process. *)
and exec_run (words: string list): unit =
  let tool = Filename.concat (Filename.dirname Sys.executable_name) "hilde-launcher" in
  if not (Sys.file_exists tool) then
    run_tool_missing tool
  else
    try Unix.execv tool (Array.of_list (tool :: List.tl words))
    with Unix.Unix_error (e, _, _) -> run_tool_failed tool (Unix.error_message e)

and print_usage _: unit =
  print_endline ("hilde " ^ version_string);
  print_endline "";
  print_endline "Usage:";
  print_endline "    hilde [options] <command>";
  print_endline "";
  print_endline "Options:";
  print_endline "    --help     Print this text.";
  print_endline "    --version  Print the compiler's version.";
  print_endline "    --dump-calltree";
  print_endline "               On an error, write the compiler's call tree to";
  print_endline "               calltree.html and the error to error.html in the";
  print_endline "               working directory.  Without it no file is written.";
  print_endline "";
  print_endline "Commands:";
  print_endline "    compile    Compile modules.";
  print_endline "    build      Compile modules, as compile does.";
  print_endline "    test       Build and run the tests of test files:";
  print_endline "               hilde test [options] <path...>";
  print_endline "    lsp        A language server on standard input and output:";
  print_endline "               diagnostics, hover with type and contract, and go to";
  print_endline "               definition: hilde lsp [--modules=d:d]";
  print_endline "    modules    Every module with its files and what it exports,";
  print_endline "               or one JSON array with --json:";
  print_endline "               hilde modules [--modules=d:d] [--json]";
  print_endline "    fmt        Write Hilde sources in their one form, or with";
  print_endline "               --check name the files that are not in it (exit 1):";
  print_endline "               hilde fmt [--check] <file or directory...>";
  print_endline "    check      Parse, type and check modules -- contracts and";
  print_endline "               linearity -- and write no C; exit 0 when they hold:";
  print_endline "               hilde check <module...> [--modules=d:d]";
  print_endline "                   [--error-format=plain|json|hilde-json|json-lines]";
  print_endline "    query      What a module declares -- names, kinds, types and";
  print_endline "               definition sites -- as JSON on standard output:";
  print_endline "               hilde query <module...> --module=Name";
  print_endline "    guard      The programme's attack surface -- unsafe modules,";
  print_endline "               C libraries, foreign functions and embeds, and";
  print_endline "               which of them it reaches -- as text:";
  print_endline "               hilde guard <module...> [--entrypoint=Module:name]";
  print_endline "                   [--vulndb=path] [--library-versions=name:version,...]";
  print_endline "    run        Start the ranks of a job over TLS on the listed hosts:";
  print_endline "               hilde run -n N --hosts FILE [--deny-hosts FILE]";
  print_endline "                   [--checkpoint-dir DIR] [--checkpoint-every SECONDS]";
  print_endline "                   [--restart-max K] [--resume JOB] programme [arguments...]";
  print_endline "";
  print_endline "Package commands, carried out by hilde-pkg beside the compiler:";
  print_endline "    new        A new package, or a new module of this one:";
  print_endline "               hilde new <Name> [--bin] [--git] [--packaging]";
  print_endline "    get        Fetch the required packages into vendor/, the only";
  print_endline "               command besides update that uses the network:";
  print_endline "               hilde get [<Prefix>@vX.Y.Z [--git=url]]";
  print_endline "    update     Raise the dependencies within their major version:";
  print_endline "               hilde update [--check]";
  print_endline "    verify     Hold vendor/ against hilde.sum, without the network";
  print_endline "    export     Make the release archive and its signature:";
  print_endline "               hilde export --secret-key=path [--with-c]";
  print_endline "    install    Install into a staging tree for a system package:";
  print_endline "               hilde install --prefix=dir --destdir=dir";
  print_endline "    doc        The documentation of a module or a function, or";
  print_endline "               its manual page: hilde doc <Module[.name]> [--man]";
  print_endline "    api-diff   What changed between two versions of a package:";
  print_endline "               hilde api-diff <old-dir> <new-dir>";
  print_endline "    Each takes --json."

and print_test_usage _: unit =
  print_endline "hilde test";
  print_endline "";
  print_endline "Usage:";
  print_endline "    hilde test [options] <path...>";
  print_endline "";
  print_endline "A path is a directory, searched for test files -- module bodies whose";
  print_endline "file name ends in .test.hiq -- and for the modules they import, or a";
  print_endline "test file named by its path.  Every function of a test file whose name";
  print_endline "is test followed by a capital letter or a digit is a test.  Each test";
  print_endline "runs in a process of its own and passes when it ends with exit 0.";
  print_endline "";
  print_endline "Options:";
  print_endline "    --help          Print this text.";
  print_endline "    --modules=d:d   Directories whose modules the tests may import and";
  print_endline "                    whose tests are not run.";
  print_endline "    --race          Build with ThreadSanitizer.";
  print_endline "    --memory        Build with AddressSanitizer and";
  print_endline "                    UndefinedBehaviorSanitizer.";
  print_endline "    --valgrind      Run every test under valgrind.";
  print_endline "    --verbose       A line for every test, with its standard output.";
  print_endline "    --emit-c=dir    Write the C of every test programme into dir;";
  print_endline "                    build and run nothing.";
  print_endline "    --contracts     Also test the contracts of the modules found: every";
  print_endline "                    public function with a requires or an ensures whose";
  print_endline "                    parameters are all integers, Index or Bool is called";
  print_endline "                    with drawn inputs that satisfy its requires, and its";
  print_endline "                    ensures is checked.";
  print_endline "    --seed=N        The seed of the drawn inputs, 0 to 2^64 - 1; without";
  print_endline "                    it the clock chooses one, and the run prints it.";
  print_endline "    --rounds=N      Inputs per function, 1 to 100000; 100 by default.";
  print_endline "    --jobs=N        Build and run N test files at once, 1 to 256; 1 by";
  print_endline "                    default.  The report is the same as with one.";
  print_endline "    --test-jobs=M   Run M tests of a file at once, 1 to 256; 1 by default.";
  print_endline "                    Tests that write the same file need --fresh-dirs.";
  print_endline "    --fresh-dirs    Start every test in an empty directory of its own.";
  print_endline "    --target=wasm   Build every test programme for wasm32-wasi and run";
  print_endline "                    it in wasmtime; no instrument goes with it.";
  print_endline "";
  print_endline "At most one of --race, --memory and --valgrind.  An instrument this";
  print_endline "system cannot run is refused.  Exit 0 when every test passed, 1 when";
  print_endline "one failed or a test programme did not build."

and print_version _: unit =
  print_endline version_string

and print_compile_usage _: unit =
  print_endline "hilde compile";
  print_endline "";
  print_endline "Usage:";
  print_endline "    hilde compile [options] <module...>";
  print_endline "";
  print_endline "Options:";
  print_endline "    --help          Print this text.";
  print_endline ("    --target-type   One of "
                 ^ (String.concat ", " (List.map (fun t -> "`" ^ t ^ "`") target_types))
                 ^ ". Default is `" ^ (List.hd target_types) ^ "`.");
  print_endline "                    `static` and `shared` build a library, a .a or";
  print_endline "                    a .so, and write its header beside it as .h.";
  print_endline "    --target=name   linux, openbsd, freebsd, darwin or wasm; by default";
  print_endline "                    the system hilde runs on, the only one of the four";
  print_endline "                    it builds for.  wasm builds a module for wasm32-wasi";
  print_endline "                    ending in .wasm, with zig or clang, which hilde finds.";
  print_endline "    --line-directives  Write a #line before every generated function.";
  print_endline "    --contract-report  Write a line to standard error for every";
  print_endline "                    contract clause the compiler does not prove.";
  print_endline "    --output        Path to the output file.";
  print_endline "    --entrypoint    The name of the entrypoint function, in the";
  print_endline "                    format `<module name>:<function name>`.";
  print_endline "    --no-entrypoint  Don't compile an entrypoint. Needs";
  print_endline "                    `--target-type=c`, `static` or `shared`.";
  print_endline "    --modules=d:d   Directories whose modules the given ones may import;";
  print_endline "                    each imported module is found and put in front, as";
  print_endline "                    hilde test finds it.";
  print_endline "    --forbid-unsafe-modules";
  print_endline "                    Refuse any module named below that carries";
  print_endline "                    `pragma Unsafe_Module;`. The modules that ship";
  print_endline "                    with the compiler are exempt.";
  print_endline "    --build-value=name=value";
  print_endline "                    A value the programme reads with";
  print_endline "                    Standard.BuildInfo's value; may be given";
  print_endline "                    more than once, each name once.";
  print_endline "    --no-build-vcs  Do not ask git for the commit and the state";
  print_endline "                    of the work tree; Standard.BuildInfo gives none.";
  print_endline "";
  print_endline "Positional arguments:";
  print_endline "    module    Of the form 'file.hih,file.hiq' for modules with";
  print_endline "              both an interface and body file, or 'file.hiq' for";
  print_endline "              modules with only a body."

and exec_compile (modules: mod_source list) (target: target) (error_reporting_mode: error_reporting_mode) (forbid_unsafe_modules: bool) (module_dirs: string list): unit =
  (* Parse source files *)
  let (given, given_map): (module_source list * source_map) = read_sources modules error_reporting_mode in
  (* Error handling setup *)
  try
    let _ = if forbid_unsafe_modules then refuse_unsafe_modules given else () in
    (* The modules the given
       ones import, from --modules.  --forbid-unsafe-modules holds for the
       modules named on the command line, as before. *)
    let mods: module_source list = TestRunner.modules_for_compile module_dirs given in
    (try
       exec_target mods target
     with Hilde_error error ->
       report_error error (source_map_of mods) error_reporting_mode)
  with Hilde_error error ->
    report_error error given_map error_reporting_mode

(* hilde fmt: every .hih and .hiq file of the paths, directories searched.
   With --check exit 1 when a file is not in the form; a file that would
   change its tokens or does not lex is an error and stays as it is. *)
and exec_fmt (paths: string list) (check: bool) (json: bool): unit =
  try
    (* With --json the names of the files go to standard error, so that
       standard output holds the one object. *)
    let (differing, files, failed) =
      if json then with_output_on_stderr (fun () -> Formatter.run ~check paths)
      else Formatter.run ~check paths
    in
    if json then
      print_endline (Yojson.Basic.to_string (`Assoc [
          ("command", `String "fmt");
          ("check", `Bool check);
          ("files", `Int files);
          ("differing", `Int differing);
          ("unreadable", `Int failed);
          ("ok", `Bool (failed = 0 && (not check || differing = 0)))
        ]))
    else if check then
      Printf.printf "hilde fmt --check: %d of %d files are not in the form, %d could not be read\n" differing files failed
    else
      Printf.printf "hilde fmt: %d of %d files written, %d could not be read\n" differing files failed;
    if failed > 0 then exit 2;
    if check && differing > 0 then exit 1
  with Hilde_error error ->
    report_error error SourceMap.empty ErrorReportPlain

(* hilde check: the given modules, a body completed with the interface
   that lies beside it, with the modules they import from the directories
   of --modules, or from the standard library beside the compiler when
   there are none.  Nothing is written on success but, in plain mode, one
   line with the count. *)
and exec_check (modules: mod_source list) (module_dirs: string list) (error_reporting_mode: error_reporting_mode) (forbid_unsafe_modules: bool): unit =
  let paired: mod_source list = List.map pair_with_interface modules in
  let dirs: string list = if module_dirs = [] then library_beside_compiler () else module_dirs in
  let (given, given_map): (module_source list * source_map) = read_sources paired error_reporting_mode in
  try
    let _ = if forbid_unsafe_modules then refuse_unsafe_modules given else () in
    let mods: module_source list = TestRunner.modules_for_compile dirs given in
    (try
       let _ = check_multiple empty_compiler mods in
       (match error_reporting_mode with
        | ErrorReportPlain ->
           Printf.printf "hilde check: %d modules given, %d checked, no error\n"
             (List.length given) (List.length mods)
        | _ -> ())
     with Hilde_error error ->
       report_error error (source_map_of mods) error_reporting_mode)
  with Hilde_error error ->
    report_error error given_map error_reporting_mode

(* A body given alone, X.hiq, whose interface X.hih lies beside it, is the
   pair. *)
and pair_with_interface (m: mod_source): mod_source =
  match m with
  | ModuleBodySource { body_path } when Filename.check_suffix body_path ".hiq" ->
     let inter = (Filename.chop_suffix body_path ".hiq") ^ ".hih" in
     if Sys.file_exists inter then ModuleSource { inter_path = inter; body_path } else m
  | _ -> m

(* standard/src and bindings/generated in the directory of the compiler's
   binary, those of them that are there. *)
and library_beside_compiler (): string list =
  let base = Filename.dirname Sys.executable_name in
  List.filter
    (fun d -> Sys.file_exists d && Sys.is_directory d)
    [Filename.concat base "standard/src"; Filename.concat base "bindings/generated"]

(* hilde modules: the directories given, or the library beside the
   compiler with lib/builtin; one block per module, or one JSON array. *)
and exec_modules (module_dirs: string list) (json: bool): unit =
  let dirs = match module_dirs with
    | [] ->
       let builtin = Filename.concat (Filename.dirname Sys.executable_name) "lib/builtin" in
       library_beside_compiler () @ (if Sys.file_exists builtin && Sys.is_directory builtin then [builtin] else [])
    | _ -> module_dirs
  in
  match TestRunner.list_modules dirs with
  | exception Hilde_error error ->
     report_error error SourceMap.empty ErrorReportPlain;
     exit 1
  | listed ->
     if json then
       let item (m: TestRunner.module_listing): Yojson.Basic.t =
         `Assoc [
             ("name", `String m.listed_name);
             ("interface", (match m.listed_interface with Some p -> `String p | None -> `Null));
             ("body", `String m.listed_body);
             ("exports", `List (List.map (fun (kind, name) ->
                                   `Assoc [("kind", `String kind); ("name", `String name)])
                                  m.listed_exports))
           ]
       in
       print_endline (Yojson.Basic.pretty_to_string (`List (List.map item listed)))
     else
       List.iter (fun (m: TestRunner.module_listing) ->
           print_endline (m.listed_name ^ "  "
                          ^ (match m.listed_interface with Some p -> p ^ "  " | None -> "")
                          ^ m.listed_body);
           List.iter (fun (kind, name) -> print_endline ("    " ^ kind ^ " " ^ name)) m.listed_exports)
         listed

and exec_query (modules: mod_source list) (name: string) (error_reporting_mode: error_reporting_mode): unit =
  let (mods, source_map): (module_source list * source_map) = read_sources modules error_reporting_mode in
  try
    let json: Yojson.Basic.t = query_modules mods (Identifier.make_mod_name name) in
    print_endline (Yojson.Basic.pretty_to_string json)
  with Hilde_error error ->
    report_error error source_map error_reporting_mode

and exec_guard (modules: mod_source list) (json: bool) (module_dirs: string list) (entry: entrypoint option) (vulndb: string option)
      (library_versions: (string * string) list) (error_reporting_mode: error_reporting_mode): unit =
  let (given, source_map): (module_source list * source_map) = read_sources modules error_reporting_mode in
  try
    let mods: module_source list = TestRunner.modules_for_compile module_dirs given in
    let root = match entry with
      | Some (Entrypoint (mn, name)) -> Some (mn, name)
      | None -> None
    in
    (* The database is read before the programme is compiled, so that a
       database that cannot be read is said before anything else. *)
    let vulnerabilities =
      match vulndb with
      | None -> None
      | Some path ->
         Some { Guard.advisories = Guard.read_database path; source = path; versions = library_versions }
    in
    let (text, reached) = guard_report mods root ~vulnerabilities in
    (* Inside a package, the capabilities of the packages: 4 when one is
       used and not declared. *)
    let packages = package_rules () in
    let (lines, undeclared) =
      if packages = [] then ([], 0) else guard_capabilities mods root ~packages
    in
    if json then begin
      let report = List.filter (fun l -> l <> "") (String.split_on_char '\n' text) in
      print_endline (Yojson.Basic.to_string (`Assoc [
          ("command", `String "guard");
          ("report", `List (List.map (fun l -> `String l) report));
          ("capabilities", `List (List.map (fun l -> `String l) lines));
          ("vulnerabilities_reached", `Int reached);
          ("capabilities_undeclared", `Int undeclared);
          ("ok", `Bool (reached = 0 && undeclared = 0))
        ]))
    end else begin
      print_string text;
      List.iter print_endline lines
    end;
    (* As govulncheck: 3 when the programme reaches a vulnerability. *)
    if reached > 0 then exit 3;
    if undeclared > 0 then exit 4
  with Hilde_error error ->
    report_error error source_map error_reporting_mode

(* The packages of the build when the working directory lies in one: its
   own hilde.toml and that of each tree in vendor/. *)
and package_rules (): Guard.package_rule list =
  match package_root () with
  | None -> []
  | Some root ->
     let vendor = Filename.concat root "vendor" in
     let vendored =
       if Sys.file_exists vendor && Sys.is_directory vendor then
         Sys.readdir vendor |> Array.to_list |> List.sort compare
         |> List.map (fun n -> Filename.concat (Filename.concat vendor n) "hilde.toml")
       else []
     in
     List.filter_map package_rule_of (Filename.concat root "hilde.toml" :: vendored)

(* The name and the capabilities of the table package of a hilde.toml, read
   by its lines in the form hilde-pkg writes; hilde-pkg checks the whole
   file. *)
and package_rule_of (path: string): Guard.package_rule option =
  match open_in path with
  | exception Sys_error _ -> None
  | ic ->
     let lines = ref [] in
     (try while true do lines := input_line ic :: !lines done with End_of_file -> ());
     close_in ic;
     let unquote (v: string): string =
       let v = String.trim v in
       let n = String.length v in
       if n >= 2 && v.[0] = '"' && v.[n - 1] = '"' then String.sub v 1 (n - 2) else v
     in
     let list_of (v: string): string list =
       let v = String.trim v in
       let n = String.length v in
       let inner = if n >= 2 && v.[0] = '[' && v.[n - 1] = ']' then String.sub v 1 (n - 2) else "" in
       List.filter (fun s -> s <> "") (List.map unquote (String.split_on_char ',' inner))
     in
     let in_package = ref false and name = ref "" and caps = ref [] in
     List.iter
       (fun l ->
         let t = String.trim l in
         if String.length t > 0 && t.[0] = '[' then in_package := (t = "[package]")
         else if !in_package then
           match String.index_opt t '=' with
           | Some i ->
              let key = String.trim (String.sub t 0 i)
              and value = String.sub t (i + 1) (String.length t - i - 1) in
              if key = "name" then name := unquote value
              else if key = "capabilities" then caps := list_of value
           | None -> ())
       (List.rev !lines);
     if !name = "" then None else Some { Guard.prefix = !name; declared = !caps; manifest = path }

(* The sources of the modules, read before any of them is parsed.  A file
   that cannot be read is reported in the format asked for, as every later
   error is; report_error ends the programme, so nothing is returned then. *)
and read_sources (modules: mod_source list) (error_reporting_mode: error_reporting_mode): (module_source list * source_map) =
  match parse_source_files modules with
  | exception Hilde_error error ->
     report_error error SourceMap.empty error_reporting_mode;
     ([], SourceMap.empty)
  | sources ->
     sources

and report_error (error: hilde_error) (source_map: source_map) (error_reporting_mode: error_reporting_mode): unit =
  match error_reporting_mode with
  | ErrorReportPlain ->
     let error: hilde_error = try_adding_source_ctx error source_map in
     Printf.eprintf "%s" (render_error_to_plain error);
     html_error_dump error;
     dump_and_die ()
  | ErrorReportJson ->
     Printf.eprintf "%s\n"
       (render_error_to_rustc (fun f -> SourceMap.find_opt f source_map) error);
     html_error_dump error;
     dump_and_die ()
  | ErrorReportHildeJson ->
     let error: hilde_error = try_adding_source_ctx error source_map in
     Printf.eprintf "%s" (Yojson.Basic.pretty_to_string (render_error_to_json error));
     html_error_dump error;
     dump_and_die ()
  | ErrorReportJsonLines ->
     Printf.eprintf "%s\n" (render_error_to_json_line error);
     html_error_dump error;
     dump_and_die ()

and dump_and_die _: unit =
  Reporter.dump ();
  exit (-1)

and try_adding_source_ctx (error: hilde_error) (source_map: source_map): hilde_error =
  let (HildeError { span; source_ctx; _ }) = error in
  match source_ctx with
  | Some _ ->
     (* Already have a context. *)
     error
  | None ->
     (match span with
      | Some span ->
         let (Span { filename; _ }) = span in
         (match (SourceMap.find_opt filename source_map) with
          | Some code ->
             add_source_ctx error (get_source_ctx code span)
          | None ->
             error)
      | None ->
         error)

and exec_target (mods: module_source list) (target: target): unit =
  match target with
  | TypeCheck ->
     (* Compile everything, emit no code. *)
     let _ = compile_multiple empty_compiler mods in
     ()
  | Executable { bin_path; entrypoint; } ->
     exec_compile_to_bin mods bin_path entrypoint
  | CStandalone { output_path; entrypoint; } ->
     exec_compile_to_c mods output_path entrypoint
  | Library { output_path; kind; } ->
     exec_compile_to_library mods output_path kind

(* A library: the C written to a temporary file, built into the
   archive or shared object, the temporary file removed again, and the
   header written beside the library under its name ending in .h.  The
   header is written last, so that a library that did not build leaves no
   header claiming it did. *)
and exec_compile_to_library (mods: module_source list) (output_path: string) (kind: library_kind): unit =
  let compiler = compile_multiple empty_compiler mods in
  let compiler = post_compile compiler in
  let header_path: string = (Filename.remove_extension output_path) ^ ".h" in
  let cfile: string = Filename.temp_file "hilde_" ".c" in
  Fun.protect
    ~finally:(fun () -> if Sys.file_exists cfile then Sys.remove cfile)
    (fun () ->
      write_string_to_file cfile (library_code compiler);
      match kind with
      | WasmModule ->
         compile_wasm cfile output_path (library_export_names compiler) (compiler_libraries compiler)
      | StaticLibrary | SharedLibrary ->
         compile_library ~shared:(equal_library_kind kind SharedLibrary)
           cfile output_path (compiler_libraries compiler));
  write_string_to_file header_path
    (library_header_text compiler (Filename.basename header_path))

and exec_compile_to_bin (mods: module_source list) (bin_path: string) (entrypoint: entrypoint): unit =
  (* Compile everything to a C file. *)
  let compiler = compile_multiple empty_compiler mods in
  (* Compile the wrapper functions *)
  let compiler = post_compile compiler in
  (* Compile the entrypoint. *)
  let compiler =
    let (Entrypoint (module_name, name)) = entrypoint in
    compile_entrypoint compiler module_name name
  in
  (* The C goes to a temporary file, cc builds it at -O2, and the file is
     removed again whether or not cc succeeded.  Without a level cc builds
     at -O0, which made every programme several times slower than it
     needs to be. *)
  let cfile: string = Filename.temp_file "hilde_" ".c" in
  Fun.protect
    ~finally:(fun () -> if Sys.file_exists cfile then Sys.remove cfile)
    (fun () ->
      write_string_to_file cfile (compiler_code compiler);
      if current_target () = "wasm" then
        (* A command module, with the functions marked
           pragma Foreign_Export exported to its host. *)
        compile_wasm_module ~reactor:false cfile bin_path (library_export_names compiler) (compiler_libraries compiler)
      else
        let _ = compile_c_code ~extra_flags:["-O2"] cfile bin_path (compiler_libraries compiler) in
        ())

and exec_compile_to_c (mods: module_source list) (output_path: string) (entrypoint: entrypoint option): unit =
  (* Compile everything to a C file. *)
  let compiler = compile_multiple empty_compiler mods in
  (* Compile the wrapper functions *)
  let compiler = post_compile compiler in
  (* Compile the entrypoint, if needed. *)
  let compiler =
    match entrypoint with
    | Some (Entrypoint (module_name, name)) ->
       (* It's an executable. *)
       compile_entrypoint compiler module_name name
    | None ->
       (* It's a library. *)
       compiler
  in
  (* Write the output to the given file, with the link manifest last
     (Compiler.c_file_text says why).  test-programs/runner.py and anything
     else that compiles the emitted C read the libraries from there rather
     than keeping a list of their own (TEST-012). *)
  write_string_to_file output_path (c_file_text compiler)
