(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

(** CLI parsing module. *)
open Identifier
open CliUtil

(** Represents a program entrypoint. *)
type entrypoint =
  | Entrypoint of module_name * identifier
[@@deriving eq]

(** Represents the path to a module. *)
type mod_source =
  | ModuleSource of { inter_path: string; body_path: string }
  (** Path to a module's interface and body files. *)
  | ModuleBodySource of { body_path: string }
  (** Path to a module's body file, for public body-only modules. *)
[@@deriving eq]

(** The two kinds of library: an archive of object code, and a
    shared object built with -fPIC. *)
type library_kind =
  | StaticLibrary
  | SharedLibrary
  | WasmModule
[@@deriving eq]

(** The compiler's target output. *)
type target =
  | TypeCheck
  (** Stop at the type checking stage. *)
  | Executable of { bin_path: string; entrypoint: entrypoint; }
  (** Compile to C, generate an executable. *)
  | CStandalone of { output_path: string; entrypoint: entrypoint option; }
  (** Compile to a standalone C file. *)
  | Library of { output_path: string; kind: library_kind; }
  (** Compile to a library without main, and write its header beside it. *)
[@@deriving eq]

type error_reporting_mode =
  | ErrorReportPlain
  | ErrorReportJson
  (** One line of JSON per error, in rustc's form. *)
  | ErrorReportHildeJson
  (** One JSON object per error, in the form of Hilde's own. *)
  | ErrorReportJsonLines

(** What [hilde test] builds its programmes with and runs them under
: nothing, ThreadSanitizer ([--race]), AddressSanitizer and
    UndefinedBehaviorSanitizer ([--memory]), or valgrind ([--valgrind]). *)
type instrument =
  | NoInstrument
  | RaceInstrument
  | MemoryInstrument
  | ValgrindInstrument
[@@deriving eq]

(** [hilde test --contracts]: the public functions of the modules found are
    called with inputs drawn from [seed], [rounds] times each. *)
type contract_run = {
    seed: string option;
    (** [--seed=N], a decimal number from 0 to 2^64 - 1 as written; none
        means a seed from the clock, printed by the run. *)
    rounds: int;
    (** [--rounds=N], from 1 to 100000; 100 when not given. *)
    modules: string list;
    (** [--contracts-module=Name], once per module in the order written;
        when it holds names, the contracts of those modules alone are
        checked, and every name must be a module with a contract under the
        paths of the run. *)
  }
[@@deriving eq]

(** The type of compiler commands. The compiler's CLI arglist is parsed to an
    instance of this type. *)
type cmd =
  | HelpCommand
  (** Print usage. *)
  | VersionCommand
  (** Print the compiler's version. *)
  | CompileHelp
  (** Print usage of the compile command. *)
  | TestHelp
  (** Print usage of the test command. *)
  | WholeProgramCompile of {
      modules: mod_source list;
      (** The list of modules to compile in order. *)
      target: target;
      (** The compiler's target. *)
      target_system: string;
      (** --target=name: the system the programme is built for, one of
          Util.target_names; empty for the system hilde runs on. *)
      error_reporting_mode: error_reporting_mode;
      (** Whether to report errors in plain text or JSON. *)
      forbid_unsafe_modules: bool;
      (** [--forbid-unsafe-modules]: refuse a module named on the command
          line that carries [pragma Unsafe_Module;].  The modules that ship
          with the compiler are exempt by origin. *)
      line_directives: bool;
      (** [--line-directives]: write a [#line] before every
          generated function, pointing at the Hilde declaration
          it came from.  OFF by default. *)
      contract_report: bool;
      (** [--contract-report]: write a line to standard error for every
          contract clause the compiler does not prove. *)
      module_dirs: string list;
      (** [--modules=d:d]: directories whose modules are added where the
          given ones import them. *)
    }
  (** Whole program compilation using the C backend. *)
  | QueryCommand of {
      modules: mod_source list;
      query_module: string;
      (** [--module=Name]: the module to describe. *)
      error_reporting_mode: error_reporting_mode;
    }
  (** [hilde query]: what a module declares, with types and definition
      sites, as JSON on standard output. *)
  | GuardCommand of {
      modules: mod_source list;
      json: bool;
      (** [--json]: the report as one JSON object. *)
      module_dirs: string list;
      (** [--modules=d:d], and inside a package its src, vendor/ and the
          standard library: where the imports of the modules are found. *)
      guard_entry: entrypoint option;
      vulndb: string option;
      rust_db: string option;
      (** [--rust-db=path]: a local RustSec advisory database for cargo
          audit, so the check runs unattended and offline. *)
      library_versions: (string * string) list;
      (** [--entrypoint=Module:name]: the root of the walk; without it the
          exported functions, or every function when there is none. *)
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
  | RunFileCommand of {
      run_file: mod_source;
      (** The module whose main is run: a body ending in .hiq, paired
          with the interface beside it when there is one. *)
      run_dirs: string list;
      (** [--modules=d:d] before the file: where its imports are found;
          the library beside the compiler when it is not given. *)
      run_arguments: string list;
      (** The words after the file, handed to the programme. *)
    }
  (** [hilde run [--modules=d:d] FILE.hiq arguments...]: the module built
      into a programme, its unchanged modules taken from the cache of
      compiled modules, and run. *)
  | LspCommand of {
      module_dirs: string list;
      (** [--modules=d:d]: directories searched for imports before the
          document's own and the standard library beside the compiler. *)
    }
  (** [hilde lsp]: a language server on standard input and output. *)
  | ModulesCommand of {
      module_dirs: string list;
      (** [--modules=d:d]: the directories listed; the standard library
          beside the compiler when none is given. *)
      json: bool;
      (** [--json]: one JSON array instead of text. *)
    }
  (** [hilde modules]: every module with its files and what it exports. *)
  | RenameCommand of {
      paths: string list;
      apply: bool;
      from_plan: string option;
      (** [--from=file]: apply the saved plan, or with --compare hold the
          new file to it. *)
      compare: bool;
      (** [--compare]: the two files are the old and the new one, and the
          token sequences are held to the plan. *)
      module_dirs: string list;
      (** [--modules=d:d]: modules the run reads but does not rename, so an
          import of one of their declarations is renamed with its importer;
          the standard library of a package also. *)
    }
  | FmtCommand of {
      paths: string list;
      (** Files and directories whose Hilde sources are formatted. *)
      check: bool;
      (** [--check]: name the files that are not in the form, write none. *)
      json: bool;
      (** [--json]: one JSON object with the counts. *)
    }
  (** [hilde fmt]: the one form of Hilde sources. *)
  | CheckCommand of {
      modules: mod_source list;
      (** The modules to check; a body whose interface lies beside it is
          checked with it. *)
      target_system: string;
      (** --target=name, as for compile. *)
      module_dirs: string list;
      (** [--modules=d:d]: directories whose modules the given ones may
          import; without it the standard library beside the compiler. *)
      error_reporting_mode: error_reporting_mode;
      forbid_unsafe_modules: bool;
      (** [--forbid-unsafe-modules], as for compile. *)
      fix: bool;
      (** [--fix]: write the one fix of each error that carries one into
          its file, and check again. *)
    }
  (** [hilde check]: the modules parsed, typed, their contracts and
      linearity checked, no C written. *)
  | TestCommand of {
      paths: string list;
      (** Directories searched for test files and modules, and test files
          named by path. *)
      target_system: string;
      (** --target=name, as for compile; with wasm the tests run in wasmtime. *)
      module_dirs: string list;
      (** [--modules=dir:dir]: directories whose modules the test
          programmes may use and whose tests are not run. *)
      instrument: instrument;
      (** [--race], [--memory] or [--valgrind], at most one. *)
      verbose: bool;
      (** [--verbose]: a line per test, and each test's standard output. *)
      emit_c: string option;
      (** [--emit-c=dir]: write each test programme's C into [dir], build
          and run nothing. *)
      contracts: contract_run option;
      (** [--contracts], with [--contracts-module], [--seed] and
          [--rounds]: test the contracts of the modules found besides
          their test files, the modules named by [--contracts-module]
          alone when it is given. *)
      jobs: int;
      (** [--jobs=N]: how many test files are built and run at once,
          1 to 256; 1 without it. *)
      test_jobs: int;
      (** [--test-jobs=M]: how many tests of one file run at once, 1 to
          256; 1 without it. *)
      fresh_dirs: bool;
      (** [--fresh-dirs]: every test starts in an empty working directory
          of its own. *)
      doc: bool;
      (** [--doc], and always inside a package: the example in the docstring
          of each exported function runs as a test. *)
      json: bool;
      (** [--json]: one JSON object with the counts on standard output, the
          lines of the run on standard error. *)
      error_reporting_mode: error_reporting_mode;
    }
  (** [hilde test]: build the programme of every test file and run each of
      its tests in a process of its own. *)
  | SuiteCommand of {
      suite: string;
      (** [--suite=name], one of [known_suites]. *)
      files: string list;
      (** The case files to run; every one of the suite's when empty. *)
      jobs: int option;
      (** [--jobs=N], 1 to 256; without it the script runs as many at
          once as there are processors. *)
      verbose: bool;
      (** [--verbose]: a line per case with the result of every side. *)
    }
  (** [hilde test --suite=name]: a suite of the Hilde tree run by its own
      script from the root of the tree. *)
[@@deriving eq]

(** The suites [hilde test --suite] runs. *)
val known_suites : string list

(** H1050: the script of a suite or python3 is not there. *)
val suite_not_here : string -> string -> 'a

(** The values [--target-type] takes, the default first.  The help text is
    written from this list, and a test holds every name in it to the
    parser, so the help cannot name a target the parser refuses. *)
val target_types : string list

(** The nearest directory from the working directory up that holds a
    hilde.toml, the root of the package; None outside a package. *)
val package_root : unit -> string option

(** The words the compiler hands to hilde-pkg. *)
val package_words : string list

(** H1045: hilde-pkg is not beside the compiler. *)
val package_tool_missing : string -> 'a

(** H1046: hilde-pkg is there and could not be started. *)
val package_tool_failed : string -> string -> 'a

(** H1047: hilde-launcher is not beside the compiler. *)
val run_tool_missing : string -> 'a

(** H1048: hilde-launcher is there and could not be started. *)
val run_tool_failed : string -> string -> 'a

(** Parse an argument list into a compiler command. *)
val parse : arglist -> cmd

(** [parse_run_words words] reads the words of hilde run, the first being
    "run": a body ending in .hiq, after an optional [--modules=d:d], is
    a [RunFileCommand] with the words after it as the programme's
    arguments; anything else is a [RunCommand] for the launcher with the
    words unchanged.
    Requires: the first word is "run"; it is skipped unread, so any other
    first word is taken as if it were "run".
    Ensures: a [RunFileCommand] only when its file ends in .hiq, and its
    arguments are the words after that file, unchanged; a [RunCommand]
    carries [words] unchanged. *)
val parse_run_words : string list -> cmd
