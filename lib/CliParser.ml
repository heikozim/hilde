(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open CliUtil
open Error
open Util

module Errors = struct
  (* A word where a command belongs that is none.  A usage text with exit 0
     would let a tool that runs a command this compiler lacks take the
     silence for success. *)
  let package_tool_missing (path: string) =
    hilde_raise (H 1045) CliError [
      Text "The package commands are carried out by ";
      Code path;
      Text ", which is not there.";
      Break;
      Text "Build it beside the compiler with ";
      Code "make hilde-pkg";
      Text ", or install both with ";
      Code "make install";
      Text "."
    ]

  let package_tool_failed (path: string) (why: string) =
    hilde_raise (H 1046) CliError [
      Code path;
      Text " could not be started: ";
      Text why;
      Text ".";
      Break;
      Text "Check that it may be run, or build it again with ";
      Code "make hilde-pkg";
      Text "."
    ]

  let run_tool_missing (path: string) =
    hilde_raise (H 1047) CliError [
      Text "The command run is carried out by ";
      Code path;
      Text ", which is not there.";
      Break;
      Text "Build it beside the compiler with ";
      Code "make hilde-launcher";
      Text ", or install both with ";
      Code "make install";
      Text "."
    ]

  let run_tool_failed (path: string) (why: string) =
    hilde_raise (H 1048) CliError [
      Code path;
      Text " could not be started: ";
      Text why;
      Text ".";
      Break;
      Text "Check that it may be run, or build it again with ";
      Code "make hilde-launcher";
      Text "."
    ]

  let unknown_command (word: string) (known: string list) =
    let open ErrorText in
    let hint = match Suggest.closest word known with
      | Some near -> [Text " Did you mean "; Code near; Text "?"]
      | None -> []
    in
    hilde_raise (H 1037) CliError ([
      Text "Unknown command ";
      Code word;
      Text ". The commands are ";
      Text (String.concat ", " known);
      Text "."
    ] @ hint)

  let invalid_entrypoint entry =
    hilde_raise (H 1001) CliError [
      Text "Invalid entrypoint format ";
      Code entry;
      Break;
      Text "The entrypoint must be supplied in the form ";
      Code "Module:name"
    ]

  let invalid_module_source source =
    hilde_raise (H 1002) CliError [
      Text "Invalid module source format ";
      Code source;
      Break;
      Text "Sources must be supplied as either";
      Code "interface.hih,body.hiq";
      Text " or ";
      Code "body.hiq"
    ]

  let missing_entrypoint () =
    hilde_raise (H 1003) CliError [
      Code "--entrypoint";
      Text " argument not provided."
    ]

  let missing_module () =
    hilde_raise (H 1004) CliError [
      Text "The ";
      Code "compile";
      Text " command must specify at least one module."
    ]

  let missing_output () =
    hilde_raise (H 1005) CliError [
      Code "--output";
      Text " argument not provided."
    ]

  let no_entrypoint_wrong_target () =
    hilde_raise (H 1006) CliError [
      Code "--no-entrypoint";
      Text " requires ";
      Code "--target-type=c";
      Text ", ";
      Code "static";
      Text ", ";
      Code "shared";
      Text " or ";
      Code "wasm";
      Text ", because otherwise the compiler will try to build an executable, and will fail because there is no entrypoint function."
    ]

  let unknown_target target =
    hilde_raise (H 1007) CliError [
      Text "Unknown target type ";
      Code target
    ]

  let library_entrypoint (target: string) =
    hilde_raise (H 1026) CliError [
      Code ("--target-type=" ^ target);
      Text " builds a library, and a library has no entrypoint: ";
      Code "--entrypoint";
      Text " cannot be given with it.";
      Break;
      Text "The functions a library offers are the ones marked ";
      Code "pragma Foreign_Export";
      Text ", called from C after ";
      Code "hilde_start";
      Text "."
    ]

  let library_suffix (target: string) (suffix: string) (path: string) =
    hilde_raise (H 1027) CliError [
      Text "The output of ";
      Code ("--target-type=" ^ target);
      Text " must end in ";
      Code suffix;
      Text ", and ";
      Code path;
      Text " does not.";
      Break;
      Text "The header is written beside the library under the same name ending in ";
      Code ".h";
      Text "."
    ]

  let unknown_target_system (name: string) =
    let open ErrorText in
    let hint = match Suggest.closest name target_names with
      | Some near -> [Break; Text "Did you mean "; Code near; Text "?"; Suggest { replacement = "--target=" ^ near; at = None; certain = false }]
      | None -> []
    in
    hilde_raise (H 1041) CliError ([
      Code ("--target=" ^ name);
      Text " names no target hilde builds for.";
      Break;
      Text "The targets are ";
      Code (String.concat ", " target_names);
      Text "."
    ] @ hint)

  let foreign_target_system (name: string) (host: string) =
    hilde_raise (H 1042) CliError [
      Code ("--target=" ^ name);
      Text " asks for a binary of another system, and hilde builds a binary only for the system it runs on";
      Text (if host = "" then "." else ", " ^ host ^ ".");
      Break;
      Text "Build on a machine of ";
      Code name;
      Text ", or build a module for WebAssembly with ";
      Code "--target=wasm";
      Text "."
    ]

  let wasm_target_type (target: string) =
    hilde_raise (H 1043) CliError [
      Code "--target=wasm";
      Text " cannot build ";
      Code ("--target-type=" ^ target);
      Text ": there is no archive and no shared object for WebAssembly.";
      Break;
      Text "A programme with an entrypoint becomes a command module, ";
      Code "--target-type=wasm";
      Text " a library module, a reactor."
    ]

  let wasm_output_suffix (path: string) =
    hilde_raise (H 1044) CliError [
      Text "The output of ";
      Code "--target=wasm";
      Text " is a module for wasm32-wasi and must end in ";
      Code ".wasm";
      Text ", and ";
      Code path;
      Text " does not."
    ]

  let no_test_path () =
    hilde_raise (H 1019) CliError [
      Code "hilde test";
      Text " names no path: give the directories to search for test files, or test files by name."
    ]

  let exclusive_flags (first: string) (second: string) =
    hilde_raise (H 1020) CliError [
      Text "The flags ";
      Code first;
      Text " and ";
      Code second;
      Text " of ";
      Code "hilde test";
      Text " exclude one another.";
      Break;
      Text "A run takes at most one of ";
      Code "--race";
      Text ", ";
      Code "--memory";
      Text " and ";
      Code "--valgrind";
      Text ", and ";
      Code "--emit-c";
      Text " builds and runs nothing, so it takes none of them."
    ]

  let bad_number (flag: string) (value: string) (low: string) (high: string) =
    hilde_raise (H 1028) CliError [
      Text "The value of ";
      Code flag;
      Text " is ";
      Code value;
      Text ", which is not a decimal number from ";
      Text low;
      Text " to ";
      Text high;
      Text "."
    ]

  let without_contracts (flag: string) =
    hilde_raise (H 1029) CliError [
      Code flag;
      Text " is read only by ";
      Code "hilde test --contracts";
      Text ", and this run has no ";
      Code "--contracts";
      Text ".";
      Break;
      Text "Add ";
      Code "--contracts";
      Text ", or leave the flag out."
    ]

  let unknown_error_reporting_mode (mode: string) =
    hilde_raise (H 1008) CliError [
      Text "Unknown error reporting mode: ";
      Code mode;
      Text ". Valid values are ";
      Code "plain";
      Text ", ";
      Code "json";
      Text ", ";
      Code "hilde-json";
      Text " and ";
      Code "json-lines";
      Text "."
    ]
end

type entrypoint =
  | Entrypoint of module_name * identifier
[@@deriving eq]

type mod_source =
  | ModuleSource of { inter_path: string; body_path: string }
  | ModuleBodySource of { body_path: string }
[@@deriving eq]

type library_kind =
  | StaticLibrary
  | SharedLibrary
  | WasmModule
[@@deriving eq]

type target =
  | TypeCheck
  | Executable of { bin_path: string; entrypoint: entrypoint; }
  | CStandalone of { output_path: string; entrypoint: entrypoint option; }
  | Library of { output_path: string; kind: library_kind; }
[@@deriving eq]

type error_reporting_mode =
  | ErrorReportPlain
  | ErrorReportJson
  | ErrorReportHildeJson
  | ErrorReportJsonLines
[@@deriving eq]

type instrument =
  | NoInstrument
  | RaceInstrument
  | MemoryInstrument
  | ValgrindInstrument
[@@deriving eq]

type contract_run = {
    seed: string option;
    rounds: int;
  }
[@@deriving eq]

type cmd =
  | HelpCommand
  | VersionCommand
  | CompileHelp
  | TestHelp
  | WholeProgramCompile of {
      modules: mod_source list;
      target: target;
      target_system: string;
      (** --target=name: the system the programme is built for, one of
          Util.target_names; empty for the system hilde runs on. *)
      error_reporting_mode: error_reporting_mode;
      forbid_unsafe_modules: bool;
      (** --forbid-unsafe-modules: refuse a module on the command line that
          carries `pragma Unsafe_Module;'.  The modules that ship with the
          compiler are exempt by origin. *)
      line_directives: bool;
      (** --line-directives: write a `#line' before every generated function,
          pointing at the Hilde declaration it came from.  OFF by default. *)
      contract_report: bool;
      (** --contract-report: write a line to standard error for every
          contract clause the compiler does not prove. *)
      module_dirs: string list;
      (** --modules=d:d: directories whose modules are added where the
          given ones import them. *)
    }
  | QueryCommand of {
      modules: mod_source list;
      query_module: string;
      (** --module=Name: the module to describe. *)
      error_reporting_mode: error_reporting_mode;
    }
  (** `hilde query': what a module declares, with types and definition
      sites, as JSON on standard output. *)
  | GuardCommand of {
      modules: mod_source list;
      json: bool;
      module_dirs: string list;
      (** [--modules=d:d], and inside a package its src, vendor/ and the
          standard library: where the imports of the modules are found. *)
      guard_entry: entrypoint option;
      (** [--entrypoint=Module:name]: the root of the walk; without it the
          exported functions, or every function when there is none. *)
      vulndb: string option;
      (** [--vulndb=path]: a file or a directory of advisories in the OSV
          format. *)
      library_versions: (string * string) list;
      (** [--library-versions=name:version,...]: the version of each library. *)
      error_reporting_mode: error_reporting_mode;
    }
  (** [hilde guard]: the programme's attack surface as text on standard
      output. *)
  | PackageCommand of {
      words: string list;
      (** The command line after the programme name, as it was given. *)
    }
  (** [hilde get], [update], [verify], [export], [new], [install], [doc]
      and [api-diff]: handed to hilde-pkg beside the compiler. *)
  | RunCommand of {
      words: string list;
      (** The command line after the programme name, as it was given. *)
    }
  (** [hilde run -n N --hosts FILE programme...]: handed to hilde-launcher beside
      the compiler. *)
  | LspCommand of {
      module_dirs: string list;
    }
  | ModulesCommand of {
      module_dirs: string list;
      json: bool;
    }
  | FmtCommand of {
      paths: string list;
      check: bool;
      json: bool;
    }
  | CheckCommand of {
      modules: mod_source list;
      target_system: string;
      (** --target=name, as for compile. *)
      module_dirs: string list;
      error_reporting_mode: error_reporting_mode;
      forbid_unsafe_modules: bool;
    }
  | TestCommand of {
      paths: string list;
      target_system: string;
      (** --target=name, as for compile; with wasm the tests run in wasmtime. *)
      module_dirs: string list;
      instrument: instrument;
      verbose: bool;
      emit_c: string option;
      contracts: contract_run option;
      jobs: int;
      test_jobs: int;
      fresh_dirs: bool;
      doc: bool;
      json: bool;
      error_reporting_mode: error_reporting_mode;
    }
  (** `hilde test': build and run the tests of test files. *)
[@@deriving eq]

let check_leftovers (arglist: arglist): unit =
  if (arglist_size arglist) > 0 then
    err (H 6005) "There are leftover arguments."
  else
    ()

let parse_mod_source (s: string): mod_source =
  let ss = String.split_on_char ',' s in
  match ss with
  | [path] ->
     ModuleBodySource { body_path = path }
  | [inter_path; body_path] ->
     ModuleSource { inter_path = inter_path; body_path = body_path }
  | _ ->
     Errors.invalid_module_source s

let parse_entrypoint (s: string): entrypoint =
  let ss = String.split_on_char ':' s in
  match ss with
  | [mn; i] ->
     Entrypoint (make_mod_name mn, make_ident i)
  | _ ->
     Errors.invalid_entrypoint s

let parse_executable_target (arglist: arglist): (arglist * target) =
  (* Get the --entrypoint *)
  match pop_value_flag arglist "entrypoint" with
  | Some (arglist, entrypoint) ->
     (match pop_value_flag arglist "output" with
      | Some (arglist, bin_path) ->
         (arglist, Executable { bin_path = bin_path; entrypoint = parse_entrypoint entrypoint })
      | None ->
         Errors.missing_output ())
  | None ->
     (match pop_bool_flag arglist "no-entrypoint" with
      | Some _ ->
         Errors.no_entrypoint_wrong_target ()
      | None ->
         Errors.missing_entrypoint ())

let get_output (arglist: arglist): (arglist * string) =
  match pop_value_flag arglist "output" with
  | Some (arglist, output_path) ->
     (arglist, output_path)
  | None ->
     Errors.missing_output ()

let parse_c_target (arglist: arglist): (arglist * target) =
  (* Get the --entrypoint *)
  match pop_value_flag arglist "entrypoint" with
  | Some (arglist, entrypoint) ->
     (* An entrypoint was passed in. *)
     let (arglist, output_path) = get_output arglist in
     (arglist, CStandalone { output_path = output_path; entrypoint = Some (parse_entrypoint entrypoint) })
  | None ->
     (* No --entrypoint. Did we get the --no-entrypoint flag? *)
     (match pop_bool_flag arglist "no-entrypoint" with
      | Some arglist ->
         let (arglist, output_path) = get_output arglist in
         (arglist, CStandalone { output_path = output_path; entrypoint = None })
      | None ->
         Errors.missing_entrypoint ())

(* A static or a shared library: no entrypoint, and an output whose suffix
   says what it is, so that the header can be written beside it under the
   same name ending in .h.  --no-entrypoint says what is true of every
   library and is taken without effect. *)
let parse_library_target (arglist: arglist) (target: string) (kind: library_kind): (arglist * target) =
  match pop_value_flag arglist "entrypoint" with
  | Some _ ->
     Errors.library_entrypoint target
  | None ->
     let arglist =
       match pop_bool_flag arglist "no-entrypoint" with
       | Some arglist -> arglist
       | None -> arglist
     in
     let (arglist, output_path) = get_output arglist in
     let suffix: string =
       match kind with
       | StaticLibrary -> ".a"
       | SharedLibrary -> ".so"
       | WasmModule -> ".wasm"
     in
     if Filename.check_suffix output_path suffix
        && String.length output_path > String.length suffix then
       (arglist, Library { output_path = output_path; kind = kind })
     else
       Errors.library_suffix target suffix output_path

let target_types: string list = ["exe"; "tc"; "c"; "static"; "shared"; "wasm"]

let parse_target_type (arglist: arglist): (arglist * target) =
  match pop_value_flag arglist "target-type" with
  | Some (arglist, target_value) ->
     (* An explicit target type was passed. *)
     (match target_value with
      | "exe" ->
         (* Build an executable binary. *)
         parse_executable_target arglist
      | "c" ->
         (* Build a standaloine C file. *)
         parse_c_target arglist
      | "tc" ->
         (* Typecheck. *)
         (arglist, TypeCheck)
      | "static" ->
         parse_library_target arglist target_value StaticLibrary
      | "shared" ->
         parse_library_target arglist target_value SharedLibrary
      | "wasm" ->
         (* A library for wasm32-wasi, built by zig cc. *)
         parse_library_target arglist target_value WasmModule
      | _ ->
         Errors.unknown_target target_value)
  | None ->
     (* The default target is to build an executable binary. This means we need
        an entrypoint. *)
     parse_executable_target arglist

(* --target=name: one of Util.target_names.  wasm, and the name of the system
   hilde runs on, are built; another system is refused, since its binary is
   built only on a machine of it.  Without the flag the empty name, the
   system hilde runs on. *)
let parse_target_system (arglist: arglist): (arglist * string) =
  match pop_value_flag arglist "target" with
  | None -> (arglist, "")
  | Some (arglist, name) ->
     if not (List.mem name target_names) then
       Errors.unknown_target_system name
     else if name = "wasm" || name = Lazy.force host_target then
       (arglist, name)
     else
       Errors.foreign_target_system name (Lazy.force host_target)

let parse_error_reporting_mode (arglist: arglist): (arglist * error_reporting_mode) =
  match pop_value_flag arglist "error-format" with
  | Some (arglist, value) ->
     (* An explicit error reporting mode was passed. *)
     (match value with
      | "plain" ->
         (* Report errors in plain text. *)
         (arglist, ErrorReportPlain)
      | "json" ->
         (* Report errors in JSON as rustc does. *)
         (arglist, ErrorReportJson)
      | "hilde-json" ->
         (* Report errors in the JSON form of Hilde's own. *)
         (arglist, ErrorReportHildeJson)
      | "json-lines" ->
         (* One line of JSON per error. *)
         (arglist, ErrorReportJsonLines)
      | _ ->
         Errors.unknown_error_reporting_mode value)
  | None ->
     (* The default target is plain text errors. *)
     (arglist, ErrorReportPlain)

let parse_forbid_unsafe_modules (arglist: arglist): (arglist * bool) =
  match pop_bool_flag arglist "forbid-unsafe-modules" with
  | Some arglist -> (arglist, true)
  | None -> (arglist, false)

let parse_line_directives (arglist: arglist): (arglist * bool) =
  match pop_bool_flag arglist "line-directives" with
  | Some arglist -> (arglist, true)
  | None -> (arglist, false)

let parse_contract_report (arglist: arglist): (arglist * bool) =
  match pop_bool_flag arglist "contract-report" with
  | Some arglist -> (arglist, true)
  | None -> (arglist, false)

(* --modules=d:d, the directories of hilde test and hilde compile; empty
   parts are dropped. *)
(* The root of the package the working directory lies in: the nearest
   directory, going up, that holds a hilde.toml; None outside a package. *)
let package_root (): string option =
  let rec up (dir: string): string option =
    if Sys.file_exists (Filename.concat dir "hilde.toml") then Some dir
    else
      let parent = Filename.dirname dir in
      if parent = dir then None else up parent
  in
  match Sys.getcwd () with
  | dir -> up dir
  | exception Sys_error _ -> None

let is_directory (path: string): bool =
  Sys.file_exists path && Sys.is_directory path

(* Inside a package, the directories its modules come from: its own src,
   the src of each tree in vendor/ in the order of their names, and the
   standard library beside the compiler.  Nothing is fetched: what is not
   in vendor/ is not found.  Outside a package, nothing. *)
let package_module_dirs (): string list =
  match package_root () with
  | None -> []
  | Some root ->
     let own = Filename.concat root "src" in
     let vendor = Filename.concat root "vendor" in
     let vendored =
       if is_directory vendor then
         Sys.readdir vendor
         |> Array.to_list
         |> List.sort compare
         |> List.map (fun name -> Filename.concat (Filename.concat vendor name) "src")
         |> List.filter is_directory
       else []
     in
     let base = Filename.dirname Sys.executable_name in
     let library =
       List.filter is_directory
         [Filename.concat base "standard/src"; Filename.concat base "bindings/generated"]
     in
     (if is_directory own then [own] else []) @ vendored @ library

let parse_module_dirs (arglist: arglist): (arglist * string list) =
  let given (arglist: arglist): (arglist * string list) =
    match pop_value_flag arglist "modules" with
    | Some (arglist, value) ->
       (arglist, List.filter (fun s -> s <> "") (String.split_on_char ':' value))
    | None ->
       (arglist, [])
  in
  let (arglist, dirs) = given arglist in
  let added = List.filter (fun d -> not (List.mem d dirs)) (package_module_dirs ()) in
  (arglist, dirs @ added)

(* Every --build-value, handed to BuildInfo in the order given, and
   --no-build-vcs; the values reach the C of a programme that imports
   Standard.BuildInfo. *)
let parse_build_values (arglist: arglist): arglist =
  let (arglist, values) = pop_value_flags arglist "build-value" in
  List.iter BuildInfo.add_value values;
  arglist

let parse_build_vcs (arglist: arglist): arglist =
  match pop_bool_flag arglist "no-build-vcs" with
  | Some arglist -> BuildInfo.set_vcs false; arglist
  | None -> arglist

let parse_compile_command' (arglist: arglist): (arglist * cmd) =
  let arglist = parse_build_values arglist in
  let arglist = parse_build_vcs arglist in
  BuildInfo.check_source_date ();
  (* Parse module list *)
  let (arglist, modules): (arglist * string list) = pop_positional arglist in
  let modules: mod_source list = List.map parse_mod_source modules in
  let (arglist, error_reporting_mode) = parse_error_reporting_mode arglist in
  let (arglist, forbid_unsafe_modules) = parse_forbid_unsafe_modules arglist in
  let (arglist, line_directives) = parse_line_directives arglist in
  let (arglist, contract_report) = parse_contract_report arglist in
  let (arglist, module_dirs) = parse_module_dirs arglist in
  (* There must be at least one module. *)
  if ((List.length modules) < 1) then
    Errors.missing_module ()
  else
    (* Parse the target type. *)
    let (arglist, target): (arglist * target) = parse_target_type arglist in
    let (arglist, target_system) = parse_target_system arglist in
    (* A library for wasm is built for wasm, whatever --target says; a
       programme for wasm is a command module ending in .wasm. *)
    let target_system: string =
      match (target, target_system) with
      | (Library { kind = WasmModule; _ }, _) -> "wasm"
      | (Library { kind = (StaticLibrary | SharedLibrary); _ }, "wasm") ->
         Errors.wasm_target_type (match target with Library { kind = StaticLibrary; _ } -> "static" | _ -> "shared")
      | (Executable { bin_path; _ }, "wasm") ->
         if Filename.check_suffix bin_path ".wasm" && String.length bin_path > 5 then "wasm"
         else Errors.wasm_output_suffix bin_path
      | (_, s) -> s
    in
    (arglist, WholeProgramCompile { modules = modules; target = target; target_system = target_system; error_reporting_mode = error_reporting_mode; forbid_unsafe_modules = forbid_unsafe_modules; line_directives = line_directives; contract_report = contract_report; module_dirs = module_dirs; })

let parse_compile_command (arglist: arglist): (arglist * cmd) =
  match pop_bool_flag arglist "help" with
  | Some arglist ->
     (arglist, CompileHelp)
  | None ->
     parse_compile_command' arglist

let parse_lsp_command (arglist: arglist): (arglist * cmd) =
  let (arglist, module_dirs) = parse_module_dirs arglist in
  (arglist, LspCommand { module_dirs })

let parse_modules_command (arglist: arglist): (arglist * cmd) =
  let (arglist, module_dirs) = parse_module_dirs arglist in
  let (arglist, json) =
    match pop_bool_flag arglist "json" with
    | Some arglist -> (arglist, true)
    | None -> (arglist, false)
  in
  (arglist, ModulesCommand { module_dirs; json })

let parse_fmt_command (arglist: arglist): (arglist * cmd) =
  let (arglist, paths): (arglist * string list) = pop_positional arglist in
  let (arglist, check) =
    match pop_bool_flag arglist "check" with
    | Some arglist -> (arglist, true)
    | None -> (arglist, false)
  in
  if paths = [] then
    Errors.missing_module ()
  else
    let (arglist, json) = (match pop_bool_flag arglist "json" with Some a -> (a, true) | None -> (arglist, false)) in
    (arglist, FmtCommand { paths; check; json })

let parse_check_command (arglist: arglist): (arglist * cmd) =
  let (arglist, modules): (arglist * string list) = pop_positional arglist in
  let modules: mod_source list = List.map parse_mod_source modules in
  let (arglist, error_reporting_mode) = parse_error_reporting_mode arglist in
  let (arglist, module_dirs) = parse_module_dirs arglist in
  let (arglist, forbid_unsafe_modules) = parse_forbid_unsafe_modules arglist in
  let (arglist, target_system) = parse_target_system arglist in
  if ((List.length modules) < 1) then
    Errors.missing_module ()
  else
    (arglist, CheckCommand { modules; target_system; module_dirs; error_reporting_mode; forbid_unsafe_modules })

let parse_query_command (arglist: arglist): (arglist * cmd) =
  let (arglist, modules): (arglist * string list) = pop_positional arglist in
  let modules: mod_source list = List.map parse_mod_source modules in
  let (arglist, error_reporting_mode) = parse_error_reporting_mode arglist in
  if ((List.length modules) < 1) then
    Errors.missing_module ()
  else
    match pop_value_flag arglist "module" with
    | Some (arglist, name) ->
       (arglist, QueryCommand { modules = modules; query_module = name; error_reporting_mode = error_reporting_mode; })
    | None ->
       hilde_raise (H 1018) CliError [
           Code "hilde query";
           Text " needs ";
           Code "--module=Name";
           Text ": the module to describe."
         ]

(* One entry of --library-versions=name:version,...: a library as it is
   linked and its version as numbers separated by dots. *)
let parse_library_version (s: string): string * string =
  let bad () =
    hilde_raise (H 1032) CliError [
        Code s;
        Text " in --library-versions is not a library, a colon and a version of numbers separated by dots, such as ";
        Code "--library-versions=sqlite3:3.46.1,tls:4.3.0";
        Text "."
      ]
  in
  match String.index_opt s ':' with
  | None -> bad ()
  | Some i ->
     let name = String.sub s 0 i and version = String.sub s (i + 1) (String.length s - i - 1) in
     if name = "" || Guard.version_parts version = None then bad () else (name, version)

(* hilde guard: the modules, an
   entrypoint when one is given, and the vulnerability database with the
   libraries' versions when they are given. *)
let parse_guard_command (arglist: arglist): (arglist * cmd) =
  let (arglist, modules): (arglist * string list) = pop_positional arglist in
  let modules: mod_source list = List.map parse_mod_source modules in
  let (arglist, error_reporting_mode) = parse_error_reporting_mode arglist in
  if ((List.length modules) < 1) then
    Errors.missing_module ()
  else
    let (arglist, guard_entry) =
      match pop_value_flag arglist "entrypoint" with
      | Some (arglist, entry) -> (arglist, Some (parse_entrypoint entry))
      | None -> (arglist, None)
    in
    let (arglist, vulndb) =
      match pop_value_flag arglist "vulndb" with
      | Some (arglist, path) -> (arglist, Some path)
      | None -> (arglist, None)
    in
    let (arglist, library_versions) =
      match pop_value_flag arglist "library-versions" with
      | Some (arglist, v) -> (arglist, List.map parse_library_version (String.split_on_char ',' v))
      | None -> (arglist, [])
    in
    let (arglist, json) = (match pop_bool_flag arglist "json" with Some a -> (a, true) | None -> (arglist, false)) in
    let (arglist, module_dirs) = parse_module_dirs arglist in
    (arglist, GuardCommand { modules; json; module_dirs; guard_entry; vulndb; library_versions; error_reporting_mode })

let pop_flag (arglist: arglist) (name: string): (arglist * bool) =
  match pop_bool_flag arglist name with
  | Some arglist -> (arglist, true)
  | None -> (arglist, false)

(* The digits of a decimal number, without leading zeros; None when the text
   is empty or holds anything but digits. *)
let decimal_digits (text: string): string option =
  if text = "" || not (String.for_all (fun c -> c >= '0' && c <= '9') text) then
    None
  else
    let n: int = String.length text in
    let rec first (i: int): int =
      if i < n - 1 && text.[i] = '0' then first (i + 1) else i
    in
    let start: int = first 0 in
    Some (String.sub text start (n - start))

(* A seed is a Nat64: at most twenty digits, and twenty only up to the
   largest one.  Comparing the digit strings is comparing the numbers, since
   they have the same length. *)
let largest_nat64: string = "18446744073709551615"

let parse_seed (text: string): string =
  match decimal_digits text with
  | Some d when String.length d < 20 || (String.length d = 20 && d <= largest_nat64) -> d
  | _ -> Errors.bad_number "--seed" text "0" largest_nat64

let most_rounds: int = 100000

let parse_rounds (text: string): int =
  match decimal_digits text with
  | Some d when String.length d <= 6 ->
     let n: int = int_of_string d in
     if n >= 1 && n <= most_rounds then n else Errors.bad_number "--rounds" text "1" (string_of_int most_rounds)
  | _ -> Errors.bad_number "--rounds" text "1" (string_of_int most_rounds)

(* --contracts, --seed and --rounds.  The two values are read only with
   --contracts; given without it they would change nothing, so they are
   refused rather than ignored. *)
(* --jobs=N: how many test files are built and run at once, 1 to
   most_jobs; 1 without it. *)
let most_jobs: int = 256

let parse_jobs_of (flag: string) (text: string): int =
  match decimal_digits text with
  | Some d when String.length d <= 3 ->
     let n: int = int_of_string d in
     if n >= 1 && n <= most_jobs then n else Errors.bad_number flag text "1" (string_of_int most_jobs)
  | _ -> Errors.bad_number flag text "1" (string_of_int most_jobs)

let parse_jobs (text: string): int = parse_jobs_of "--jobs" text

let parse_contract_run (arglist: arglist): (arglist * contract_run option) =
  let (arglist, given) = pop_flag arglist "contracts" in
  let (arglist, seed): (arglist * string option) =
    match pop_value_flag arglist "seed" with
    | Some (arglist, value) -> (arglist, Some value)
    | None -> (arglist, None)
  in
  let (arglist, rounds): (arglist * string option) =
    match pop_value_flag arglist "rounds" with
    | Some (arglist, value) -> (arglist, Some value)
    | None -> (arglist, None)
  in
  if given then
    (arglist, Some { seed = Option.map parse_seed seed;
                     rounds = (match rounds with Some r -> parse_rounds r | None -> 100) })
  else begin
    (match seed with Some _ -> Errors.without_contracts "--seed" | None -> ());
    (match rounds with Some _ -> Errors.without_contracts "--rounds" | None -> ());
    (arglist, None)
  end

(* `hilde test'.  The instruments exclude one another:
   ThreadSanitizer and AddressSanitizer cannot be linked into one programme,
   and valgrind runs a programme built without either.  --emit-c writes C
   and builds nothing, so an instrument beside it would be a flag that does
   nothing; it is refused rather than ignored. *)
let parse_test_command' (arglist: arglist): (arglist * cmd) =
  let (arglist, paths): (arglist * string list) = pop_positional arglist in
  let (arglist, error_reporting_mode) = parse_error_reporting_mode arglist in
  let (arglist, module_dirs): (arglist * string list) = parse_module_dirs arglist in
  let (arglist, race) = pop_flag arglist "race" in
  let (arglist, memory) = pop_flag arglist "memory" in
  let (arglist, valgrind) = pop_flag arglist "valgrind" in
  let (arglist, verbose) = pop_flag arglist "verbose" in
  let (arglist, emit_c): (arglist * string option) =
    match pop_value_flag arglist "emit-c" with
    | Some (arglist, dir) -> (arglist, Some dir)
    | None -> (arglist, None)
  in
  let (arglist, contracts): (arglist * contract_run option) = parse_contract_run arglist in
  let (arglist, jobs): (arglist * int) =
    match pop_value_flag arglist "jobs" with
    | Some (arglist, value) -> (arglist, parse_jobs value)
    | None -> (arglist, 1)
  in
  let (arglist, test_jobs): (arglist * int) =
    match pop_value_flag arglist "test-jobs" with
    | Some (arglist, value) -> (arglist, parse_jobs_of "--test-jobs" value)
    | None -> (arglist, 1)
  in
  let (arglist, fresh_dirs) = pop_flag arglist "fresh-dirs" in
  let (arglist, doc) = pop_flag arglist "doc" in
  let (arglist, json) = pop_flag arglist "json" in
  let chosen: (string * instrument) list =
    List.filter_map
      (fun (given, flag, instrument) -> if given then Some (flag, instrument) else None)
      [(race, "--race", RaceInstrument);
       (memory, "--memory", MemoryInstrument);
       (valgrind, "--valgrind", ValgrindInstrument)]
  in
  let instrument: instrument =
    match chosen with
    | [] -> NoInstrument
    | [(_, i)] -> i
    | (a, _) :: (b, _) :: _ -> Errors.exclusive_flags a b
  in
  (match (emit_c, chosen) with
   | (Some _, (a, _) :: _) -> Errors.exclusive_flags "--emit-c" a
   | _ -> ());
  let (arglist, target_system) = parse_target_system arglist in
  (* wasmtime runs a module without the instruments of a binary. *)
  (match (target_system, chosen) with
   | ("wasm", (a, _) :: _) -> Errors.exclusive_flags "--target=wasm" a
   | _ -> ());
  match paths with
  | [] ->
     Errors.no_test_path ()
  | _ ->
     (arglist, TestCommand { paths; target_system; module_dirs; instrument; verbose; emit_c; contracts; jobs; test_jobs; fresh_dirs; doc; json; error_reporting_mode })

let parse_test_command (arglist: arglist): (arglist * cmd) =
  match pop_bool_flag arglist "help" with
  | Some arglist ->
     (arglist, TestHelp)
  | None ->
     parse_test_command' arglist

(* The two refusals of hilde-pkg, raised where it is started. *)
let package_tool_missing (path: string) = Errors.package_tool_missing path
let package_tool_failed (path: string) (why: string) = Errors.package_tool_failed path why
let run_tool_missing (path: string) = Errors.run_tool_missing path
let run_tool_failed (path: string) (why: string) = Errors.run_tool_failed path why

(* The words of the package commands, which hilde-pkg carries out. *)
let package_words: string list =
  ["get"; "update"; "verify"; "export"; "new"; "install"; "doc"; "api-diff"]

let parse (arglist: arglist): cmd =
  let args: arg list = arglist_to_list arglist in
  match args with
  | [BoolFlag "help"] ->
     HelpCommand
  | [BoolFlag "version"] ->
     VersionCommand
  | (PositionalArg ("compile" | "build"))::rest ->
     (* Try parsing the `compile` command. *)
     let (arglist, cmd) = parse_compile_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "test")::rest ->
     let (arglist, cmd) = parse_test_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "lsp")::rest ->
     let (arglist, cmd) = parse_lsp_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "modules")::rest ->
     let (arglist, cmd) = parse_modules_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "fmt")::rest ->
     let (arglist, cmd) = parse_fmt_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "check")::rest ->
     let (arglist, cmd) = parse_check_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "query")::rest ->
     let (arglist, cmd) = parse_query_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "guard")::rest ->
     let (arglist, cmd) = parse_guard_command (arglist_from_list rest) in
     let _ = check_leftovers arglist in
     cmd
  | (PositionalArg "run")::_ ->
     RunCommand { words = List.tl (Array.to_list Sys.argv) }
  | (PositionalArg word)::_ when List.mem word package_words ->
     PackageCommand { words = List.tl (Array.to_list Sys.argv) }
  | (PositionalArg word)::_ ->
     Errors.unknown_command word
       (["build"; "compile"; "test"; "lsp"; "modules"; "fmt"; "check"; "query"; "guard"; "run"] @ package_words)
  | _ ->
     HelpCommand
