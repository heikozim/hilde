(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
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
  | SuiteCommand { suite; files; jobs; verbose } ->
     exec_suite suite files jobs verbose
  | WholeProgramCompile { modules; target; target_system; error_reporting_mode; forbid_unsafe_modules;
                          line_directives; contract_report; module_dirs } ->
     build_target := target_system;
     (* Set before anything is generated, and only
        here: the code generator asks a flag, it does not take one. *)
     CodeGen.set_line_directives line_directives;
     Contracts.reset_report ();
     (match target with
      | Executable _ | Library { kind = (StaticLibrary | SharedLibrary); _ } when current_target () <> "wasm" ->
         build_rust_crates ()
      | _ -> ());
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
  | RenameCommand { paths; apply; from_plan; compare; module_dirs } ->
     if compare then
       exit (Rename.compare_files from_plan (List.nth paths 0) (List.nth paths 1))
     else begin
       match from_plan with
       | Some plan -> exit (Rename.apply_plan plan)
       | None -> exit (Rename.run paths module_dirs apply)
     end
  | CheckCommand { modules; target_system; module_dirs; error_reporting_mode; forbid_unsafe_modules; fix } ->
     build_target := target_system;
     exec_check modules module_dirs error_reporting_mode forbid_unsafe_modules fix
  | QueryCommand { modules; query_module; error_reporting_mode } ->
     exec_query modules query_module error_reporting_mode
  | GuardCommand { modules; json; module_dirs; guard_entry; vulndb; rust_db; library_versions; error_reporting_mode } ->
     exec_guard modules json module_dirs guard_entry vulndb rust_db library_versions error_reporting_mode
  | PackageCommand { words } ->
     exec_package words
  | RunCommand { words } ->
     exec_run words
  | RunFileCommand { run_file; run_dirs; run_arguments } ->
     exec_run_file run_file run_dirs run_arguments

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

(* Inside a package whose hilde.toml has a table rust, or which has bridge
   modules in rust/bridge, hilde-pkg builds its crates and bridges into one
   static library before the programme is compiled, in the
   root of the package, its output sent to standard error.  pkg-config then
   finds that library, which a module names with pragma Foreign_Library,
   through the directory hilde-pkg writes its file to.  A build that fails
   ends the compilation with the exit status of hilde-pkg. *)
and build_rust_crates (): unit =
  match package_root () with
  | Some root when has_rust_table (Filename.concat root "hilde.toml")
                   || Sys.file_exists (Filename.concat root (Filename.concat "rust" "bridge"))
                   || has_dependency_rust root ->
     let tool = Filename.concat (Filename.dirname Sys.executable_name) "hilde-pkg" in
     if not (Sys.file_exists tool) then package_tool_missing tool;
     let env =
       ("HILDE_COMPILER=" ^ Sys.executable_name)
       :: List.filter
            (fun e -> not (String.length e >= 15 && String.sub e 0 15 = "HILDE_COMPILER="))
            (Array.to_list (Unix.environment ()))
     in
     let here = Sys.getcwd () in
     let status =
       Fun.protect
         ~finally:(fun () -> Sys.chdir here)
         (fun () ->
           Sys.chdir root;
           match Unix.create_process_env tool [| tool; "rust" |] (Array.of_list env) Unix.stdin Unix.stderr Unix.stderr with
           | pid -> snd (Unix.waitpid [] pid)
           | exception Unix.Unix_error (e, _, _) -> package_tool_failed tool (Unix.error_message e))
     in
     (match status with
      | Unix.WEXITED 0 ->
         let dir = Filename.concat root (Filename.concat "target" (Filename.concat "rust" "pkgconfig")) in
         let path = match Sys.getenv_opt "PKG_CONFIG_PATH" with
           | Some old when old <> "" -> dir ^ ":" ^ old
           | _ -> dir
         in
         Unix.putenv "PKG_CONFIG_PATH" path
      | Unix.WEXITED n -> exit n
      | Unix.WSIGNALED _ | Unix.WSTOPPED _ -> exit 1)
  | _ -> ()

(* Whether a hilde.toml has a table rust, by its lines: [rust] as hilde-pkg
   writes it, or a table below it such as [rust.calamine]. *)
and has_rust_table (path: string): bool =
  match open_in path with
  | exception Sys_error _ -> false
  | ic ->
     let found = ref false in
     (try
        while not !found do
          let t = String.trim (input_line ic) in
          if t = "[rust]" || (String.length t > 6 && String.sub t 0 6 = "[rust.") then found := true
        done
      with End_of_file -> ());
     close_in ic;
     !found

(* Whether a package in vendor/ brings Rust: its hilde.toml has a table
   rust, or it holds bridge modules below rust/bridge.  A dependency like
   that joins the one static library, so hilde-pkg rust runs even when
   the package itself names no crate and has no bridge of its own. *)
and has_dependency_rust (root: string): bool =
  let vendor = Filename.concat root "vendor" in
  match Sys.readdir vendor with
  | exception Sys_error _ -> false
  | packages ->
     Array.exists
       (fun package ->
         let dir = Filename.concat vendor package in
         let bridge = Filename.concat dir (Filename.concat "rust" "bridge") in
         has_rust_table (Filename.concat dir "hilde.toml")
         || (Sys.file_exists bridge && Sys.is_directory bridge))
       packages

(* hilde run is a programme of its own, written in Hilde, beside the
   compiler: it starts the ranks of a job.  It replaces this process. *)
and exec_run (words: string list): unit =
  let tool = Filename.concat (Filename.dirname Sys.executable_name) "hilde-launcher" in
  if not (Sys.file_exists tool) then
    run_tool_missing tool
  else
    try Unix.execv tool (Array.of_list (tool :: List.tl words))
    with Unix.Unix_error (e, _, _) -> run_tool_failed tool (Unix.error_message e)

(* A suite is a script of the Hilde tree, run from its root with python3
   in isolated mode and handed this compiler; the process becomes the
   script, so its exit is the command's. *)
and exec_suite (suite: string) (files: string list) (jobs: int option) (verbose: bool): unit =
  let script: string = Filename.concat (Filename.concat "tests" suite) (suite ^ ".py") in
  match find_on_path "python3" with
  | Some python when Sys.file_exists script ->
     let args: string list =
       [python; "-I"; script; "--hilde=" ^ Sys.executable_name]
       @ (match jobs with Some n -> ["--jobs=" ^ string_of_int n] | None -> [])
       @ (if verbose then ["--verbose"] else [])
       @ files
     in
     (try Unix.execv python (Array.of_list args)
      with Unix.Unix_error (e, _, _) -> suite_not_here suite (script ^ " (" ^ Unix.error_message e ^ ")"))
  | _ ->
     suite_not_here suite script

(* hilde run FILE.hiq: the module and what it imports are built into a
   programme in a directory of its own that only this user may enter,
   modules unchanged since an earlier build taken from the cache of
   compiled modules, and the programme is run with the arguments given.
   The entry is the module's main.  What the compiler says goes to
   standard error, so standard output is the programme's alone.  The
   exit status is the programme's; a programme ended by a signal ends
   this process by the same signal.  The directory is removed on every
   way out, an error of the compiler included. *)
and exec_run_file (file: mod_source) (module_dirs: string list) (arguments: string list): unit =
  BuildCache.trace (Printf.sprintf "command line read, %.0f ms of processor time since the start" (Sys.time () *. 1000.0));
  let paired: mod_source = pair_with_interface file in
  let dirs: string list = if module_dirs = [] then library_beside_compiler () else module_dirs in
  let dir: string = Filename.temp_dir ~perms:0o700 "hilde_run_" "" in
  let bin: string = Filename.concat dir "programme" in
  at_exit (fun () ->
      (try if Sys.file_exists bin then Sys.remove bin with Sys_error _ -> ());
      (try if Sys.file_exists dir then Sys.rmdir dir with Sys_error _ -> ()));
  with_output_on_stderr (fun () ->
      let (given, given_map) = read_sources [paired] ErrorReportPlain in
      try
        let (name, _) = module_name_and_imports (List.hd given) in
        let mods: module_source list = TestRunner.modules_for_compile dirs given in
        BuildCache.trace (Printf.sprintf "%d modules found" (List.length mods));
        (try
           exec_compile_to_bin mods bin (Entrypoint (name, Identifier.make_ident "main"))
         with Hilde_error error ->
           report_error error (source_map_of mods) ErrorReportPlain)
      with Hilde_error error ->
        report_error error given_map ErrorReportPlain);
  BuildCache.trace "built";
  if not (Sys.file_exists bin) then begin
    prerr_endline ("hilde run: the programme of " ^ (mod_source_body paired) ^ " was not built");
    exit 1
  end;
  (* Like system(3): an interrupt from the terminal reaches the programme,
     and this process waits for it to end instead of ending first. *)
  let old_int = Sys.signal Sys.sigint Sys.Signal_ignore in
  let old_quit = Sys.signal Sys.sigquit Sys.Signal_ignore in
  let child: int =
    Unix.create_process bin (Array.of_list (bin :: arguments)) Unix.stdin Unix.stdout Unix.stderr
  in
  let rec wait (): Unix.process_status =
    try snd (Unix.waitpid [] child) with Unix.Unix_error (Unix.EINTR, _, _) -> wait ()
  in
  let status: Unix.process_status = wait () in
  Sys.set_signal Sys.sigint old_int;
  Sys.set_signal Sys.sigquit old_quit;
  match status with
  | Unix.WEXITED code -> exit code
  | Unix.WSIGNALED signal | Unix.WSTOPPED signal ->
     (try if Sys.file_exists bin then Sys.remove bin with Sys_error _ -> ());
     (try if Sys.file_exists dir then Sys.rmdir dir with Sys_error _ -> ());
     Sys.set_signal signal Sys.Signal_default;
     Unix.kill (Unix.getpid ()) signal;
     exit 1

and mod_source_body (m: mod_source): string =
  match m with
  | ModuleSource { body_path; _ } | ModuleBodySource { body_path } -> body_path

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
  print_endline "    rename     Variables, parameters and constants to snake_case and";
  print_endline "               functions with an underscore to camelCase; the plan goes";
  print_endline "               out as JSON with the file, line and column of every";
  print_endline "               declaration and use, exit 1 on a collision:";
  print_endline "               hilde rename [--plan] <file or directory...>";
  print_endline "               hilde rename --apply <file or directory...>";
  print_endline "               hilde rename --apply --from=plan.json";
  print_endline "               hilde rename --compare [--from=plan.json] <old> <new>";
  print_endline "               --modules=d:d names modules the run reads but does";
  print_endline "               not rename, such as the standard library, so their";
  print_endline "               constants and functions are renamed with an importer;";
  print_endline "               --from applies a saved plan to its positions, --compare";
  print_endline "               holds the tokens of the new file to the plan of the old";
  print_endline "    check      Parse, type and check modules -- contracts and";
  print_endline "               linearity -- and write no C; exit 0 when they hold:";
  print_endline "               hilde check [--fix] <module...> [--modules=d:d]";
  print_endline "                   [--error-format=plain|json|hilde-json|json-lines]";
  print_endline "               With --fix, write the one fix of each error that";
  print_endline "               carries one into its file and check again, at most";
  print_endline "               20 fixes, then report what is left.";
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
  print_endline "               or build a module and run its main, unchanged";
  print_endline "               modules taken from the cache of compiled modules:";
  print_endline "               hilde run [--modules=d:d] FILE.hiq [arguments...]";
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
  print_endline "    rust       Build the Rust crates of hilde.toml into one static";
  print_endline "               library, offline; build and compile run it first:";
  print_endline "               hilde rust [--vendor] [--target=triple]";
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
  print_endline "    --contracts-module=Name";
  print_endline "                    Check the contracts of the named module alone; repeat";
  print_endline "                    the flag for more than one module.  A name that is not";
  print_endline "                    a module with a contract under the paths is refused.";
  print_endline "    --jobs=N        Build and run N test files at once, 1 to 256; 1 by";
  print_endline "                    default.  The report is the same as with one.";
  print_endline "    --test-jobs=M   Run M tests of a file at once, 1 to 256; 1 by default.";
  print_endline "                    Tests that write the same file need --fresh-dirs.";
  print_endline "    --fresh-dirs    Start every test in an empty directory of its own.";
  print_endline "    --target=wasm   Build every test programme for wasm32-wasi and run";
  print_endline "                    it in wasmtime; no instrument goes with it.";
  print_endline "    --suite=name    Run a suite of the Hilde tree instead, from its";
  print_endline "                    root: coherence builds the cases under";
  print_endline "                    tests/coherence/cases at -O0, at -O2, for wasm and";
  print_endline "                    folded and not, and compares the results.  Paths";
  print_endline "                    name case files; only --jobs, by default one per";
  print_endline "                    processor, and --verbose go with it.";
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
   line with the count.  With --fix the one fix an error carries is written
   into its file and the check runs again, at most most_fixes times. *)
and exec_check (modules: mod_source list) (module_dirs: string list) (error_reporting_mode: error_reporting_mode) (forbid_unsafe_modules: bool) (fix: bool): unit =
  let paired: mod_source list = List.map pair_with_interface modules in
  let dirs: string list = if module_dirs = [] then library_beside_compiler () else module_dirs in
  if fix then check_and_fix paired dirs error_reporting_mode forbid_unsafe_modules 0 0
  else begin
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
          | _ -> ());
         report_unused given error_reporting_mode
       with Hilde_error error ->
         report_error error (source_map_of mods) error_reporting_mode)
    with Hilde_error error ->
      report_error error given_map error_reporting_mode
  end

(* The most fixes one run of --fix writes before it reports what is left: a
   fix may uncover another error, and a pair of fixes that undo one another
   would otherwise run on. *)
and most_fixes: int = 20

(* hilde check --fix: the check, the one fix of its error written into the
   file when the error carries one, and the check again, at most
   most_fixes times.  An error whose fix is not the one marked fix, whose
   span lies outside its file, or whose replacement would write the same
   bytes, ends the run and is reported as hilde check reports it.  The
   files are read again in every round, so a fix written in one round is
   what the next one checks. *)
and check_and_fix (paired: mod_source list) (dirs: string list)
      (error_reporting_mode: error_reporting_mode) (forbid_unsafe_modules: bool)
      (round: int) (applied: int): unit =
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
        | _ -> ());
       print_fixes_applied error_reporting_mode applied;
       report_unused given error_reporting_mode
     with Hilde_error error ->
       (match machine_fix error with
        | Some fix when round < most_fixes && apply_machine_fix fix ->
           check_and_fix paired dirs error_reporting_mode forbid_unsafe_modules (round + 1) (applied + 1)
        | _ ->
           (* The error that is left, or whose fix is not the one marked
              fix: the count first, then the report as hilde check makes
              it. *)
           print_fixes_applied error_reporting_mode applied;
           report_error error (source_map_of mods) error_reporting_mode))
  with Hilde_error error ->
    report_error error given_map error_reporting_mode

(* The warnings of the modules given, after a check without an error: N001,
   a name that breaks the case convention, and N002, a parameter or a
   binding of a free type that its body never reads.  The
   modules a given one imports are checked as well but not reported.  The
   warnings go to standard error, one a line, and leave the exit status as
   it is. *)
and report_unused (given: module_source list) (error_reporting_mode: error_reporting_mode): unit =
  let files: string list =
    List.concat_map (fun (m: module_source) ->
        match m with
        | TwoFileModuleSource { int_filename; body_filename; _ } -> [int_filename; body_filename]
        | BodyModuleSource { body_filename; _ } -> [body_filename]) given
  in
  let found: UnusedCheck.finding list =
    List.filter (fun (f: UnusedCheck.finding) ->
        let (Span.Span { filename; _ }) = f.span in
        List.mem filename files) (UnusedCheck.recorded ())
  in
  List.iter (fun (f: UnusedCheck.finding) ->
      let (Span.Span { filename; startp = Span.Position { line; column }; _ }) = f.span in
      match error_reporting_mode with
      | ErrorReportPlain ->
         Printf.eprintf "%s:%d:%d: warning: %s\n" filename line column (UnusedCheck.message f)
      | _ ->
         Printf.eprintf "%s\n" (Yojson.Basic.to_string (`Assoc [
             ("level", `String "warning");
             ("code", `String f.code);
             ("message", `String (UnusedCheck.message f));
             ("file", `String filename);
             ("line", `Int line);
             ("column", `Int column)
           ]))) found

(* The number of fixes --fix wrote, in plain mode as the count of a check
   is; the JSON formats stay as they are, so that a reader of them gets
   nothing else on the standard output. *)
and print_fixes_applied (error_reporting_mode: error_reporting_mode) (applied: int): unit =
  match error_reporting_mode with
  | ErrorReportPlain ->
     Printf.printf "hilde check --fix: %d fixes applied\n" applied
  | _ -> ()

(* The byte at which each line of a source begins, the first at 0. *)
and line_starts (src: string): int array =
  let starts: int list ref = ref [0] in
  String.iteri (fun i c -> if c = '\n' then starts := (i + 1) :: !starts) src;
  Array.of_list (List.rev !starts)

(* The byte at which a position of a source begins: lines count from 1 and
   columns from 0, as the lexer gives them.  A position past the last line
   is the end of the source. *)
and byte_of_position (starts: int array) (length: int) (Span.Position { line; column }): int =
  if line < 1 || line > Array.length starts then length
  else min length (starts.(line - 1) + column)

(* The bytes of a file as they stand on disk, the last line feed included:
   the check reads a source with its head and tail trimmed, and a fix must
   not write that trim back. *)
and read_file_verbatim (path: string): string =
  In_channel.with_open_bin path In_channel.input_all

(* Where the trimmed source the check reads begins in the file's bytes: the
   trim takes white space off both ends, so the rest stands as one piece. *)
and leading_space (raw: string): int =
  let n = String.length raw in
  let rec walk (i: int): int =
    if i < n && (raw.[i] = ' ' || raw.[i] = '\t' || raw.[i] = '\n' || raw.[i] = '\r') then walk (i + 1)
    else i
  in
  walk 0

(* Writes the replacement over the bytes the span covers in its file, and
   says whether the file changed: false when the file is not there, when
   the span lies outside it, and when the replacement is what stands there
   already, which would leave the next round with the same error.  The
   positions count lines from 1 and columns from 0 over the trimmed source,
   so they are moved by the white space the trim took off the head. *)
and apply_machine_fix ((Span { filename; startp; endp }, replacement): Span.span * string): bool =
  match Sys.file_exists filename with
  | false -> false
  | true ->
     let raw: string = read_file_verbatim filename in
     let src: string = String.trim raw in
     let shift: int = leading_space raw in
     let starts: int array = line_starts src in
     let length: int = String.length src in
     let first: int = byte_of_position starts length startp
     and last: int = byte_of_position starts length endp in
     if first < 0 || last < first || last > length then false
     else begin
       let written: string =
         (String.sub raw 0 (shift + first))
         ^ replacement
         ^ (String.sub raw (shift + last) (String.length raw - shift - last))
       in
       if written = raw then false
       else begin
         write_string_to_file filename written;
         true
       end
     end

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
      (rust_db: string option) (library_versions: (string * string) list) (error_reporting_mode: error_reporting_mode): unit =
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
    (* Inside a package with a table rust, the checks of its crates:
       5 when one of them holds a finding. *)
    let (rust_lines, rust_findings) = rust_checks packages rust_db in
    if json then begin
      let report = List.filter (fun l -> l <> "") (String.split_on_char '\n' text) in
      print_endline (Yojson.Basic.to_string (`Assoc [
          ("command", `String "guard");
          ("report", `List (List.map (fun l -> `String l) report));
          ("capabilities", `List (List.map (fun l -> `String l) lines));
          ("rust", `List (List.map (fun l -> `String l) rust_lines));
          ("vulnerabilities_reached", `Int reached);
          ("capabilities_undeclared", `Int undeclared);
          ("rust_findings", `Int rust_findings);
          ("ok", `Bool (reached = 0 && undeclared = 0 && rust_findings = 0))
        ]))
    end else begin
      print_string text;
      List.iter print_endline lines;
      List.iter print_endline rust_lines
    end;
    (* As govulncheck: 3 when the programme reaches a vulnerability. *)
    if reached > 0 then exit 3;
    if undeclared > 0 then exit 4;
    if rust_findings > 0 then exit 5
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
     let in_package = ref false and name = ref "" and caps = ref [] and rust = ref false in
     List.iter
       (fun l ->
         let t = String.trim l in
         if String.length t > 0 && t.[0] = '[' then begin
           in_package := (t = "[package]");
           if t = "[rust]" then rust := true
         end
         else if !in_package then
           match String.index_opt t '=' with
           | Some i ->
              let key = String.trim (String.sub t 0 i)
              and value = String.sub t (i + 1) (String.length t - i - 1) in
              if key = "name" then name := unquote value
              else if key = "capabilities" then caps := list_of value
           | None -> ())
       (List.rev !lines);
     if !name = "" then None else Some { Guard.prefix = !name; declared = !caps; manifest = path; rust = !rust }

(* The license policy of the cargo deny check, written to target/rust
   beside the wrapper crate: the licenses a crate of the build may carry,
   and the crates banned outright. *)
and deny_config: string =
  "[licenses]\n\
   version = 2\n\
   allow = [\"Apache-2.0\", \"Apache-2.0 WITH LLVM-exception\", \"MIT\", \"BSD-2-Clause\", \"BSD-3-Clause\", \"ISC\", \"Zlib\", \"Unicode-DFS-2016\", \"Unicode-3.0\"]\n\
   \n\
   [bans]\n\
   multiple-versions = \"allow\"\n\
   deny = [{ crate = \"openssl-sys\" }]\n"

(* The checks of the Rust crates inside a package: cargo audit over the
   lock file of every package whose hilde.toml names a table rust, cargo
   deny with the license policy over the wrapper crate hilde rust built.
   A check that cannot run -- the tool is not installed, the lock file is
   missing, no crate was built yet -- says so in a line and does not fail
   the guard; a finding does. *)
and rust_checks (packages: Guard.package_rule list) (rust_db: string option)
    : string list * int =
  let with_rust = List.filter (fun p -> p.Guard.rust) packages in
  match with_rust with
  | [] -> ([], 0)
  | first :: _ ->
     let lines = ref ["rust crates:"] in
     let findings = ref [] in
     List.iter
       (fun p ->
         let dir = Filename.dirname p.Guard.manifest in
         let lock = Filename.concat dir (Filename.concat "rust" "Cargo.lock") in
         if not (Sys.file_exists lock) then
           lines :=
             !lines
             @ [ Printf.sprintf "  %s: no rust/Cargo.lock: the audit did not run" p.Guard.prefix ]
         else begin
           let arguments =
             [ "audit"; "--file"; lock; "--json" ]
             @ (match rust_db with Some db -> [ "--path"; db ] | None -> [])
           in
           let (tool_lines, tool_findings) =
             Guard.rust_check ~variable:"HILDE_CARGO_AUDIT" ~name:"cargo-audit"
               ~arguments ~parse:Guard.parse_audit_json
           in
           lines := !lines @ tool_lines;
           findings := !findings @ tool_findings
         end)
       with_rust;
     let manifest =
       Filename.concat (Filename.dirname first.Guard.manifest)
         (Filename.concat "target" (Filename.concat "rust" "Cargo.toml"))
     in
     if Sys.file_exists manifest then begin
       let dir = Filename.dirname manifest in
       let config = Filename.concat dir "deny.toml" in
       (try
          let oc = open_out config in
          output_string oc deny_config;
          close_out oc
        with Sys_error _ -> ());
       let (tool_lines, tool_findings) =
         Guard.rust_check ~variable:"HILDE_CARGO_DENY" ~name:"cargo-deny"
           ~arguments:
             [ "check"; "licenses"; "bans"; "--offline"; "--format"; "json";
               "--config"; config; "--manifest-path"; manifest ]
           ~parse:Guard.parse_deny_output
       in
       lines := !lines @ tool_lines;
       findings := !findings @ tool_findings
     end
     else
       lines :=
         !lines
         @ [ "  cargo-deny: hilde rust has built no crate in target/rust yet: the check did not run" ];
     (!lines, List.length !findings)

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
  (* The first error, then the errors the typing pass found after it, each
     in the same form, so a reader of one line or one object a line reads
     them all.  The first error ends the run as before. *)
  let further: hilde_error list = further_errors () in
  reset_further_errors ();
  print_error error source_map error_reporting_mode;
  List.iter (fun e -> print_error e source_map error_reporting_mode) further;
  (match error_reporting_mode with
   | ErrorReportPlain | ErrorReportHildeJson -> html_error_dump (try_adding_source_ctx error source_map)
   | ErrorReportJson | ErrorReportJsonLines -> html_error_dump error);
  dump_and_die ()

and print_error (error: hilde_error) (source_map: source_map) (error_reporting_mode: error_reporting_mode): unit =
  match error_reporting_mode with
  | ErrorReportPlain ->
     Printf.eprintf "%s" (render_error_to_plain (try_adding_source_ctx error source_map))
  | ErrorReportJson ->
     Printf.eprintf "%s\n"
       (render_error_to_rustc (fun f -> SourceMap.find_opt f source_map) error)
  | ErrorReportHildeJson ->
     Printf.eprintf "%s" (Yojson.Basic.pretty_to_string (render_error_to_json (try_adding_source_ctx error source_map)))
  | ErrorReportJsonLines ->
     Printf.eprintf "%s\n" (render_error_to_json_line error)

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
  (* Compile everything to C. *)
  let compiler = compile_multiple empty_compiler mods in
  (* Compile the wrapper functions *)
  let compiler = post_compile compiler in
  (* Compile the entrypoint. *)
  let compiler =
    let (Entrypoint (module_name, name)) = entrypoint in
    compile_entrypoint compiler module_name name
  in
  BuildCache.trace "front end done";
  if not (build_in_parts compiler bin_path) then build_from_one_file compiler bin_path

(* The programme built from one object per module, those of unchanged
   modules taken from the cache of compiled modules.  False when the cache
   is off or cannot be opened, the target is wasm, the programme cannot be
   split, or a part of the build failed; nothing is reported then, and the
   programme is built from one file. *)
and build_in_parts (compiler: compiler) (bin_path: string): bool =
  let target = current_target () in
  if target = "wasm" then false
  else
    let identity = BuildCache.compiler_identity () in
    BuildCache.trace "compiler identity read";
    let units = translation_units compiler in
    BuildCache.trace "units split";
    match (identity, units) with
    | (None, _) -> BuildCache.trace "off: the compiler cannot read its own executable"; false
    | (_, None) -> BuildCache.trace "off: a module of this programme is built in one file only"; false
    | (Some identity, Some units) ->
       (match BuildCache.open_default () with
        | Error why -> BuildCache.trace ("off: " ^ why); false
        | Ok cache ->
           let platform = BuildCache.toolchain target in
           BuildCache.trace "cache opened, platform read";
           ModuleBuild.build cache ~compiler:identity ~target:platform
             units ~libraries:(compiler_libraries compiler) bin_path)

and build_from_one_file (compiler: compiler) (bin_path: string): unit =
  (* The C goes to a temporary file, cc builds it at -O2, and the file is
     removed again whether or not cc succeeded.  Without a level cc builds
     at -O0, which made every programme several times slower than it
     needs to be.  -fno-strict-aliasing keeps the optimiser from assuming
     that pointers of different types never meet, which the runtime and
     the generated C do not promise; it costs about one percent. *)
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
        let _ = compile_c_code ~extra_flags:Util.programme_flags cfile bin_path (compiler_libraries compiler) in
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
