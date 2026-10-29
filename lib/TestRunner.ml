(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* `hilde test': the tests of test files, built into one
   programme per file and run one process per test.  This comment says
   how the parts fit.

   1. Find.  Every path on the command line is a directory, searched for
      test files (a name ending in .test.hiq) and for modules, or a test
      file named by its path.  The paths of --modules are searched for
      modules only.  A module is a .hiq file with or without a .hih of the
      same stem beside it; an interface without its body is refused.  A
      directory whose name begins with a point or an underscore is not
      entered.
   2. Resolve.  A test file needs the modules it imports, and the modules
      those import, found by name among what step 1 found.  A name two
      files declare is refused only when a programme needs it.  A name that
      is not found is left to the compiler, which reports it in its own
      words.
   3. Build.  The modules and the test file are compiled, the file's tests
      are read with their forms (Compiler.test_functions), and a driver
      module is compiled after them: its main runs the one test whose name
      is its argument.  The C is compiled with the instrument's flags.
   4. Run.  The programme runs once per test, in a process of its own, so
      that a test that aborts ends only itself.  Its standard output and
      error go to files; a test still running after test_time_limit
      seconds is killed.  A test passes when its process ends with exit 0.
   5. Report.  A FAIL line with the test's output for every test that
      failed, one line per test file, and a count; exit 1 when anything
      failed. *)
open Identifier
open Error
open Util
open CliParser
open Compiler

module Errors = struct
  let not_a_path (path: string) =
    hilde_raise (H 1022) CliError [
      Code path;
      Text " is neither a directory nor a file ending in .hiq."
    ]

  let no_test_files (paths: string list) =
    hilde_raise (H 1023) CliError [
      Text "There is no test file under ";
      Code (String.concat " " paths);
      Text ".";
      Break;
      Text ("A test file is a module body whose file name ends in .test.hiq, "
            ^ "or a .hiq file named on the command line.")
    ]

  let module_twice (name: module_name) (first: string) (second: string) =
    hilde_raise (H 1024) CliError [
      Text "The module ";
      Code (mod_name_string name);
      Text " is declared by two files, ";
      Code first;
      Text " and ";
      Code second;
      Text ", and a test programme imports it, so there is no telling which one it means."
    ]

  let interface_without_body (path: string) (body: string) =
    hilde_raise (H 1025) CliError [
      Text "The interface ";
      Code path;
      Text " has no body ";
      Code body;
      Text " beside it, so its module cannot be compiled."
    ]

  let instrument_unavailable (flag: string) (what: string) (answer: string) =
    hilde_raise (H 1021) CliError [
      Code ("hilde test " ^ flag);
      Text " cannot run on this system: ";
      Text what;
      Break;
      Text "The answer was: ";
      Code answer
    ]
end

(* A test still running after this many seconds is killed and fails.  Go's
   test command has ten minutes.  Most tests of the standard library take
   well under a second.  valgrind runs the programme, which is built without
   optimisation, some hundreds of times slower than it runs alone: the tests
   that go over every code point of Unicode take minutes under it, and one
   of them took longer than ten on the FreeBSD guest
.  So a test under valgrind has three
   times the limit. *)
let test_time_limit (i: instrument): float =
  match i with
  | ValgrindInstrument -> 1800.0
  | NoInstrument | RaceInstrument | MemoryInstrument -> 600.0

(* The name of the module that holds the generated main. *)
let driver_name: string = "Hilde.Test.Driver"

(* Every file this run read, for the source context of a message. *)
let sources_read: (string, string) Hashtbl.t = Hashtbl.create 64

let read_source (path: string): string =
  match Hashtbl.find_opt sources_read path with
  | Some text -> text
  | None ->
     let text = read_file_to_string path in
     Hashtbl.replace sources_read path text;
     text

(* 1. Find. *)

let is_test_file (path: string): bool =
  Filename.check_suffix path ".test.hiq"

let entered (name: string): bool =
  not (String.length name > 0 && (name.[0] = '.' || name.[0] = '_'))

let is_directory (path: string): bool =
  Sys.file_exists path && Sys.is_directory path

(* The files of a directory tree, in the order of their names, each as a
   path under the directory as it was given. *)
let rec files_under (dir: string): string list =
  let names: string array = Sys.readdir dir in
  Array.sort compare names;
  List.concat_map
    (fun name ->
      let path: string = Filename.concat dir name in
      if is_directory path then
        (if entered name then files_under path else [])
      else
        [path])
    (Array.to_list names)

(* A .hiq file of a --modules path named on its own brings its interface. *)
let with_interface (body: string): string list =
  let interface: string = (Filename.chop_suffix body ".hiq") ^ ".hih" in
  if Sys.file_exists interface then [body; interface] else [body]

let module_files_of (path: string): string list =
  if is_directory path then
    files_under path
  else if Sys.file_exists path && Filename.check_suffix path ".hiq" then
    with_interface path
  else
    Errors.not_a_path path

let test_files_of (path: string): string list =
  if is_directory path then
    List.filter is_test_file (files_under path)
  else if Sys.file_exists path && Filename.check_suffix path ".hiq" then
    [path]
  else
    Errors.not_a_path path

(* Keep the first of every file, however it is spelt: src/A.hiq and the
   absolute path of the same file are one file, by the path the system
   resolves them to.  A path that does not resolve is its own key. *)
let unique (paths: string list): string list =
  let seen: (string, unit) Hashtbl.t = Hashtbl.create 64 in
  let key (p: string): string = try Unix.realpath p with Unix.Unix_error _ -> p in
  List.filter
    (fun p ->
      let k = key p in
      if Hashtbl.mem seen k then false else (Hashtbl.replace seen k (); true))
    paths

(* The modules among the files: every .hiq that is not a test file, with the
   .hih of the same stem where there is one. *)
let module_sources (files: string list): module_source list =
  let bodies: string list =
    List.filter (fun f -> Filename.check_suffix f ".hiq" && not (is_test_file f)) files
  and interfaces: string list =
    List.filter (fun f -> Filename.check_suffix f ".hih") files
  in
  List.iter
    (fun i ->
      let body: string = (Filename.chop_suffix i ".hih") ^ ".hiq" in
      if not (List.mem body bodies) then Errors.interface_without_body i body)
    interfaces;
  List.map
    (fun b ->
      let interface: string = (Filename.chop_suffix b ".hiq") ^ ".hih" in
      if List.mem interface interfaces then
        TwoFileModuleSource {
            int_filename = interface;
            int_code = read_source interface;
            body_filename = b;
            body_code = read_source b
          }
      else
        BodyModuleSource { body_filename = b; body_code = read_source b })
    bodies

let body_path (source: module_source): string =
  match source with
  | TwoFileModuleSource { body_filename; _ } -> body_filename
  | BodyModuleSource { body_filename; _ } -> body_filename

(* 2. Resolve. *)

type found_module = {
    source: module_source;
    imports: module_name list;
  }

let index_modules (sources: module_source list): (string, module_name * found_module) Hashtbl.t =
  let index = Hashtbl.create 64 in
  List.iter
    (fun source ->
      let (name, imports) = module_name_and_imports source in
      Hashtbl.add index (mod_name_string name) (name, { source; imports }))
    sources;
  index

(* The modules every programme has without a file: the compiler builds them
   from sources inside itself.  A search of lib/builtin finds their files,
   and they are never compiled a second time. *)
let built_in: string list = ["Hilde.Pervasive"; "Hilde.Memory"; "Hilde.Array"]

(* The modules a test file needs, in no particular order: the compiler puts
   them in the order of their imports. *)
let needed_modules ?(given: string list = []) (index: (string, module_name * found_module) Hashtbl.t) (imports: module_name list): module_source list =
  let taken: (string, unit) Hashtbl.t = Hashtbl.create 64 in
  List.iter (fun n -> Hashtbl.replace taken n ()) (built_in @ given);
  let rec visit (acc: module_source list) (names: module_name list): module_source list =
    match names with
    | [] -> acc
    | name :: rest ->
       let key: string = mod_name_string name in
       if Hashtbl.mem taken key then
         visit acc rest
       else begin
         Hashtbl.replace taken key ();
         match Hashtbl.find_all index key with
         | [] ->
            visit acc rest
         | [(_, found)] ->
            visit (found.source :: acc) (found.imports @ rest)
         | (_, a) :: (_, b) :: _ ->
            (* find_all returns the latest binding first. *)
            Errors.module_twice name (body_path b.source) (body_path a.source)
       end
  in
  visit [] imports

(* hilde compile --modules: the modules the given ones import, found under
   module_dirs by the rule hilde test uses, in front of the given ones.  A
   module given on the command line is not looked up again, and test files
   under the directories are left out. *)
type module_listing = {
    listed_name: string;
    listed_interface: string option;
    listed_body: string;
    listed_exports: (string * string) list;
  }

let declared (d: Cst.concrete_decl): string * string =
  match d with
  | Cst.ConcreteConstantDecl (_, n, _, _) -> ("constant", ident_string n)
  | Cst.ConcreteOpaqueTypeDecl (_, n, _, _, _) -> ("type", ident_string n)
  | Cst.ConcreteRecordDecl (Cst.ConcreteRecord (_, n, _, _, _, _, _)) -> ("record", ident_string n)
  | Cst.ConcreteUnionDecl (Cst.ConcreteUnion (_, n, _, _, _, _)) -> ("union", ident_string n)
  | Cst.ConcreteFunctionDecl (_, n, _, _, _, _, _, _) -> ("function", ident_string n)
  | Cst.ConcreteTypeClassDecl (Cst.ConcreteTypeClass (_, n, _, _, _)) -> ("typeclass", ident_string n)
  | Cst.ConcreteInstanceDecl (_, n, _, _, _) -> ("instance", ident_string n)

let defined (d: Cst.concrete_def): string * string =
  match d with
  | Cst.ConcreteConstantDef (_, n, _, _, _) -> ("constant", ident_string n)
  | Cst.ConcreteRecordDef (Cst.ConcreteRecord (_, n, _, _, _, _, _)) -> ("record", ident_string n)
  | Cst.ConcreteUnionDef (Cst.ConcreteUnion (_, n, _, _, _, _)) -> ("union", ident_string n)
  | Cst.ConcreteFunctionDef (_, n, _, _, _, _, _, _, _) -> ("function", ident_string n)
  | Cst.ConcreteTypeClassDef (Cst.ConcreteTypeClass (_, n, _, _, _)) -> ("typeclass", ident_string n)
  | Cst.ConcreteInstanceDef (Cst.ConcreteInstance (_, n, _, _, _, _)) -> ("instance", ident_string n)

(* hilde modules: every module under dirs, read from its own files.  The
   exports of a module with an interface are the declarations there; a
   module of one body file exports what it defines. *)
let list_modules (dirs: string list): module_listing list =
  let files: string list = unique (List.concat_map module_files_of dirs) in
  let listing (source: module_source): module_listing =
    match source with
    | TwoFileModuleSource { int_filename; int_code; body_filename; _ } ->
       let (Cst.ConcreteModuleInterface (name, _, _, decls)) = ParserInterface.parse_module_int int_code int_filename in
       { listed_name = mod_name_string name; listed_interface = Some int_filename;
         listed_body = body_filename; listed_exports = List.map declared decls }
    | BodyModuleSource { body_filename; body_code } ->
       let (Cst.ConcreteModuleBody (name, _, _, _, _, defs)) = ParserInterface.parse_module_body body_code body_filename in
       { listed_name = mod_name_string name; listed_interface = None;
         listed_body = body_filename; listed_exports = List.map defined defs }
  in
  let all = List.map listing (module_sources files) in
  List.sort (fun a b -> compare a.listed_name b.listed_name) all

let modules_for_compile (module_dirs: string list) (given: module_source list): module_source list =
  match module_dirs with
  | [] -> given
  | _ ->
     let files: string list = unique (List.concat_map module_files_of module_dirs) in
     let index = index_modules (module_sources files) in
     let named = List.map module_name_and_imports given in
     let given_names: string list = List.map (fun (n, _) -> mod_name_string n) named in
     let imports: module_name list = List.concat_map snd named in
     (needed_modules ~given:given_names index imports) @ given

(* 3. Build. *)

let instrument_flag (i: instrument): string =
  match i with
  | NoInstrument -> ""
  | RaceInstrument -> "--race"
  | MemoryInstrument -> "--memory"
  | ValgrindInstrument -> "--valgrind"

(* The include flag for valgrind's header, which programmes under valgrind
   name as <valgrind/valgrind.h>.  A cc finds it in /usr/include, where
   Debian puts it; ports install valgrind under /usr/local, which the cc of
   FreeBSD does not search.  run_command gives a programme it starts the
   PATH and nothing else, so no include variable of the caller's reaches the
   cc.  pkg-config's own Cflags for valgrind name the directory valgrind/
   itself and so do not help, but its prefix does: the include directory of
   the prefix is passed when pkg-config knows valgrind and the prefix is not
   /usr.  Asked once, and nothing where pkg-config is missing or does not
   know valgrind. *)
let valgrind_include_flags: string list Lazy.t =
  lazy
    (match run_command [| "pkg-config"; "--variable=prefix"; "valgrind" |] with
     | exception Unix.Unix_error _ -> []
     | CommandOutput { code = 0; stdout; _ } ->
        let prefix: string = String.trim stdout in
        if prefix = "" || prefix = "/usr" then [] else ["-I" ^ Filename.concat prefix "include"]
     | _ -> [])

(* The flags the C compiler gets for an instrument, after its own
   -std=c17 -Wall -Wextra.  The sanitizers want -O1 and the frame pointer
   for their stacks, and stop at the first report, so that a report is a
   failed test and not a line in a passed one.  Under valgrind the runtime
   registers every task stack with valgrind, which HILDE_VALGRIND switches
   on. *)
let cc_flags (i: instrument): string list =
  match i with
  | NoInstrument -> []
  | RaceInstrument -> ["-fsanitize=thread"; "-g"; "-O1"]
  | MemoryInstrument ->
     ["-fsanitize=address,undefined"; "-fno-sanitize-recover=all";
      "-fno-omit-frame-pointer"; "-g"; "-O1"]
  | ValgrindInstrument -> ["-g"; "-DHILDE_VALGRIND"] @ Lazy.force valgrind_include_flags

let valgrind_command: string list =
  ["valgrind"; "--quiet"; "--error-exitcode=66"; "--leak-check=full";
   "--errors-for-leak-kinds=definite"; "--show-leak-kinds=definite"]

let first_line (s: string): string =
  match String.split_on_char '\n' (String.trim s) with
  | line :: _ when line <> "" -> line
  | _ -> "(nothing)"

(* Whether this system can run the instrument, asked before anything is
   built: a programme that does nothing is compiled with the instrument's
   flags and run, and valgrind is asked for its version and a programme
   that reads valgrind's header is compiled.  OpenBSD's cc, for one,
   refuses every sanitizer, and it has no valgrind. *)
let check_instrument (work: string) (i: instrument): unit =
  let flag: string = instrument_flag i in
  match i with
  | NoInstrument -> ()
  | RaceInstrument | MemoryInstrument ->
     let c: string = Filename.concat work "probe.c"
     and bin: string = Filename.concat work "probe" in
     write_string_to_file c "int main(void) { return 0; }\n";
     let (CommandOutput { code; stderr; _ }) =
       run_command (Array.of_list (["cc"; "-std=c17"] @ cc_flags i @ [c; "-o"; bin]))
     in
     if code <> 0 then
       Errors.instrument_unavailable flag
         ("the C compiler does not build a programme with " ^ (String.concat " " (cc_flags i)) ^ ".")
         (first_line stderr)
     else
       let (CommandOutput { code; stderr; _ }) = run_command [| bin |] in
       if code <> 0 then
         Errors.instrument_unavailable flag
           "a programme built with its flags does not run."
           (first_line stderr)
  | ValgrindInstrument ->
     (match run_command [| "valgrind"; "--version" |] with
      | exception Unix.Unix_error (e, _, _) ->
         Errors.instrument_unavailable flag "valgrind cannot be started." (Unix.error_message e)
      | CommandOutput { code = 0; _ } ->
         let c: string = Filename.concat work "probe.c"
         and bin: string = Filename.concat work "probe" in
         write_string_to_file c
           "#include <valgrind/valgrind.h>\nint main(void) { return RUNNING_ON_VALGRIND; }\n";
         let (CommandOutput { code; stderr; _ }) =
           run_command (Array.of_list (["cc"; "-std=c17"] @ cc_flags i @ [c; "-o"; bin]))
         in
         if code <> 0 then
           Errors.instrument_unavailable flag
             "the C compiler does not find valgrind's header valgrind/valgrind.h."
             (first_line stderr)
      | CommandOutput { stderr; _ } ->
         Errors.instrument_unavailable flag "valgrind --version fails." (first_line stderr))

let driver_source (test_module: module_name) (tests: (identifier * test_form) list): string =
  let names: string list = List.map (fun (n, _) -> ident_string n) tests in
  let call (name, form) =
    let n: string = ident_string name in
    let args: string =
      match form with
      | TestPlain -> "()"
      | TestWithRoot -> "(&!capability)"
    in
    "            if nameIs(given, \"" ^ n ^ "\") then\n"
    ^ "                " ^ n ^ args ^ ";\n"
    ^ "                ran := true;\n"
    ^ "            end if;\n"
  in
  "import " ^ (mod_name_string test_module) ^ " (" ^ (String.concat ", " names) ^ ");\n"
  ^ "\n"
  ^ "module body " ^ driver_name ^ " is\n"
  ^ "    function nameIs(given: Span[Nat8, Static], name: Span[Nat8, Static]): Bool is\n"
  ^ "        let length: Index := spanLength(name);\n"
  ^ "        if spanLength(given) /= length then\n"
  ^ "            return false;\n"
  ^ "        end if;\n"
  ^ "        var i: Index := 0;\n"
  ^ "        while i < length do\n"
  ^ "            if given[i] /= name[i] then\n"
  ^ "                return false;\n"
  ^ "            end if;\n"
  ^ "            i := i + 1;\n"
  ^ "        end while;\n"
  ^ "        return true;\n"
  ^ "    end;\n"
  ^ "\n"
  ^ "    function main(root: RootCapability): ExitCode is\n"
  ^ "        var capability: RootCapability := root;\n"
  ^ "        var ran: Bool := false;\n"
  ^ "        if argumentCount() = 2 then\n"
  ^ "            let given: Span[Nat8, Static] := nthArgument(1);\n"
  ^ String.concat "" (List.map call tests)
  ^ "        end if;\n"
  ^ "        surrenderRoot(capability);\n"
  ^ "        if ran then\n"
  ^ "            return ExitSuccess();\n"
  ^ "        end if;\n"
  ^ "        return ExitFailure();\n"
  ^ "    end;\n"
  ^ "end module body.\n"

(* The programme of one test file, compiled to C: its module name, its
   tests, the C file's text and the libraries it links. *)
let build_c (index: (string, module_name * found_module) Hashtbl.t) (path: string): module_name * (identifier * test_form) list * string * string list =
  let test_source: module_source = BodyModuleSource { body_filename = path; body_code = read_source path } in
  let (_, imports) = module_name_and_imports test_source in
  let needed: module_source list = needed_modules index imports in
  let c: compiler = compile_multiple empty_compiler (needed @ [test_source]) in
  let (name, tests) = test_functions c test_source in
  let driver: module_source =
    BodyModuleSource { body_filename = "(the test driver of " ^ path ^ ")";
                       body_code = driver_source name tests }
  in
  let c: compiler = compile_mod c driver in
  let c: compiler = post_compile c in
  let c: compiler = compile_entrypoint c (make_mod_name driver_name) (make_ident "main") in
  (name, tests, c_file_text c, compiler_libraries c)

(* 4. Run. *)

let signal_name (s: int): string =
  let known = [
      (Sys.sigabrt, "SIGABRT"); (Sys.sigsegv, "SIGSEGV"); (Sys.sigbus, "SIGBUS");
      (Sys.sigfpe, "SIGFPE"); (Sys.sigill, "SIGILL"); (Sys.sigkill, "SIGKILL");
      (Sys.sigterm, "SIGTERM"); (Sys.sigtrap, "SIGTRAP")
    ] in
  match List.assoc_opt s known with
  | Some name -> name
  | None -> "signal " ^ (string_of_int s)

let rec wait_pid_blocking (pid: int): unit =
  match Unix.waitpid [] pid with
  | exception Unix.Unix_error (Unix.EINTR, _, _) -> wait_pid_blocking pid
  | _ -> ()

(* How many tests of one file run at once (--test-jobs), and whether each
   runs in an empty working directory of its own (--fresh-dirs).  run sets
   them before the first file. *)
let tests_at_once: int ref = ref 1
let each_test_fresh: bool ref = ref false

(* Start one test: standard input from /dev/null, its output and error into
   the two files.  Returns the process. *)
let start_one (argv: string array) (out_path: string) (err_path: string): int =
  let flags = [Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC; Unix.O_CLOEXEC] in
  let out_fd = Unix.openfile out_path flags 0o600 in
  let err_fd = Unix.openfile err_path flags 0o600 in
  let null_fd = Unix.openfile "/dev/null" [Unix.O_RDONLY; Unix.O_CLOEXEC] 0 in
  Fun.protect
    ~finally:(fun () -> Unix.close out_fd; Unix.close err_fd; Unix.close null_fd)
    (fun () -> Unix.create_process_env argv.(0) argv (Unix.environment ()) null_fd out_fd err_fd)

(* How a test ended: None when it passed, the reason when it did not; no
   status means it was killed after limit seconds. *)
let verdict (limit: float) (status: Unix.process_status option): string option =
  match status with
  | Some (Unix.WEXITED 0) -> None
  | Some (Unix.WEXITED n) -> Some ("exit " ^ (string_of_int n))
  | Some (Unix.WSIGNALED s) -> Some ("ended by " ^ (signal_name s))
  | Some (Unix.WSTOPPED s) -> Some ("stopped by " ^ (signal_name s))
  | None -> Some (Printf.sprintf "still running after %.0f seconds, killed" limit)

(* Run the tests, each given as its command and its two files, at most jobs
   at once, each killed after limit seconds; the verdicts come back in the
   order of the tests, whatever order they ended in. *)
let run_many (limit: float) (jobs: int) (items: (string array * string * string) array): string option array =
  let n: int = Array.length items in
  let results: string option array = Array.make n None in
  let running: (int * int * float) list ref = ref []
  and next: int ref = ref 0 in
  while !next < n || !running <> [] do
    while List.length !running < jobs && !next < n do
      let (argv, out, err) = items.(!next) in
      running := (!next, start_one argv out err, Unix.gettimeofday () +. limit) :: !running;
      incr next
    done;
    let still =
      List.filter
        (fun (k, pid, deadline) ->
          match Unix.waitpid [Unix.WNOHANG] pid with
          | exception Unix.Unix_error (Unix.EINTR, _, _) -> true
          | (0, _) ->
             if Unix.gettimeofday () > deadline then begin
               Unix.kill pid Sys.sigkill;
               wait_pid_blocking pid;
               results.(k) <- verdict limit None;
               false
             end else true
          | (_, status) ->
             results.(k) <- verdict limit (Some status);
             false)
        !running
    in
    if List.length still = List.length !running then Unix.sleepf 0.01;
    running := still
  done;
  results

let print_indented (text: string): unit =
  match String.trim text with
  | "" -> ()
  | trimmed ->
     List.iter
       (fun line -> if line = "" then print_endline "" else print_endline ("        " ^ line))
       (String.split_on_char '\n' trimmed)

let count (n: int) (noun: string): string =
  (string_of_int n) ^ " " ^ noun ^ (if n = 1 then "" else "s")

(* 5. Report, and the whole run. *)

type tally = {
    mutable files: int;
    mutable tests: int;
    mutable failed: int;
    mutable not_built: int;
  }

let render_with_context (mode: error_reporting_mode) (error: hilde_error): string =
  let (HildeError { span; source_ctx; _ }) = error in
  let error =
    match (source_ctx, span) with
    | (None, Some span) ->
       let (Span.Span { filename; _ }) = span in
       (match Hashtbl.find_opt sources_read filename with
        | Some code -> add_source_ctx error (SourceContext.get_source_ctx code span)
        | None -> error)
    | _ -> error
  in
  match mode with
  | ErrorReportPlain -> render_error_to_plain error
  | ErrorReportJson ->
     (render_error_to_rustc (fun f -> Hashtbl.find_opt sources_read f) error) ^ "\n"
  | ErrorReportHildeJson -> (Yojson.Basic.pretty_to_string (render_error_to_json error)) ^ "\n"
  | ErrorReportJsonLines -> (render_error_to_json_line error) ^ "\n"

let rec remove_tree (path: string): unit =
  if is_directory path then begin
    Array.iter (fun n -> remove_tree (Filename.concat path n)) (Sys.readdir path);
    Sys.rmdir path
  end else if Sys.file_exists path then
    Sys.remove path

(* The part of a run after the C exists: write it for --emit-c, or build it
   and run each test in a process of its own.  [label] names the programme
   in the result lines, [file] is the name of its C file under --emit-c,
   and [noun] is what a test is called in them. *)
(* What a test programme wrote to standard error: under wasmtime, the
   report wasmtime adds when the module traps is cut off, and a line says
   that it trapped. *)
let programme_stderr (text: string): string =
  let lines: string list = String.split_on_char '\n' text in
  let rec before (acc: string list) (rest: string list): string list * bool =
    match rest with
    | [] -> (List.rev acc, false)
    | l :: more ->
       if String.starts_with ~prefix:wasm_trap_marker l then (List.rev acc, true)
       else before (l :: acc) more
  in
  match before [] lines with
  | (_, false) -> text
  | (kept, true) -> String.concat "\n" (kept @ ["(the module trapped; the report of wasmtime is left out)"])

let run_built (tally: tally) (work: string) (number: string) (instrument: instrument)
      (verbose: bool) (emit_c: string option) (mode: error_reporting_mode)
      ~(label: string) ~(file: string) ~(noun: string)
      (tests: identifier list) (text: string) (libraries: string list): unit =
  match emit_c with
  | Some dir ->
     let out: string = Filename.concat dir (file ^ ".c") in
     write_string_to_file out text;
     print_endline ("emitted  " ^ out ^ "  " ^ (count (List.length tests) noun))
  | None ->
     let dir: string = Filename.concat work number in
     Sys.mkdir dir 0o700;
     let c: string = Filename.concat dir "test.c"
     and bin: string = Filename.concat dir "test" in
     write_string_to_file c text;
     (* For wasm the test programme is a command module beside the C, run
        by wasmtime. *)
     let wasm: bool = current_target () = "wasm" in
     let built: string = if wasm then bin ^ ".wasm" else bin in
     let build (): unit =
       if wasm then
         compile_wasm_module ~reactor:false c built [] libraries
       else
         ignore (compile_c_code ~extra_flags:(cc_flags instrument) c bin libraries)
     in
     (match build () with
      | exception Hilde_error error ->
         prerr_string (render_with_context mode error);
         flush stderr;
         print_endline ("FAIL  " ^ label ^ "  the test programme did not build");
         tally.not_built <- tally.not_built + 1
      | _ ->
         let failed: int ref = ref 0 in
         let out_of (k: int): string = Filename.concat dir (Printf.sprintf "out-%d.txt" k)
         and err_of (k: int): string = Filename.concat dir (Printf.sprintf "err-%d.txt" k) in
         (* With --fresh-dirs a test starts in an empty directory of its own,
            through sh, which changes into it and then runs the test. *)
         let items =
           Array.of_list
             (List.mapi
                (fun k test ->
                  let t: string = ident_string test in
                  let home: string option =
                    if !each_test_fresh then begin
                      let home: string = Filename.concat dir (Printf.sprintf "dir-%d" k) in
                      Sys.mkdir home 0o700;
                      Some home
                    end else None
                  in
                  let argv: string list =
                    if wasm then
                      (* wasmtime hands the module its working directory
                         itself. *)
                      wasm_run_argv (match home with Some h -> h | None -> Sys.getcwd ()) built [t]
                    else
                      let argv: string list =
                        match instrument with
                        | ValgrindInstrument -> valgrind_command @ [bin; t]
                        | _ -> [bin; t]
                      in
                      match home with
                      | Some h -> ["/bin/sh"; "-c"; "cd \"$0\" || exit 127; exec \"$@\""; h] @ argv
                      | None -> argv
                  in
                  (Array.of_list argv, out_of k, err_of k))
                tests)
         in
         let results: string option array =
           run_many (test_time_limit instrument) !tests_at_once items
         in
         List.iteri
           (fun k test ->
             let t: string = ident_string test in
             let out: string = out_of k
             and err: string = err_of k in
             let result: string option = results.(k) in
             tally.tests <- tally.tests + 1;
             match result with
             | None ->
                if verbose then begin
                  print_endline ("    ok    " ^ t);
                  print_indented (read_file_to_string out)
                end
             | Some reason ->
                incr failed;
                tally.failed <- tally.failed + 1;
                print_endline ("    FAIL  " ^ t ^ " (" ^ reason ^ ")");
                print_indented (read_file_to_string out);
                print_indented (programme_stderr (read_file_to_string err)))
           tests;
         let n: int = List.length tests in
         if !failed = 0 then
           print_endline (Printf.sprintf "ok    %s  %s" label (count n noun))
         else
           print_endline (Printf.sprintf "FAIL  %s  %d of %s failed" label !failed (count n noun)))

let run_file (tally: tally) (index: (string, module_name * found_module) Hashtbl.t) (work: string)
      (number: int) (instrument: instrument) (verbose: bool) (emit_c: string option)
      (mode: error_reporting_mode) (path: string): unit =
  tally.files <- tally.files + 1;
  match build_c index path with
  | exception Hilde_error error ->
     prerr_string (render_with_context mode error);
     flush stderr;
     print_endline ("FAIL  " ^ path ^ "  the test programme did not build");
     tally.not_built <- tally.not_built + 1
  | (name, tests, text, libraries) ->
     run_built tally work (string_of_int number) instrument verbose emit_c mode
       ~label:(mod_name_string name) ~file:(mod_name_string name) ~noun:"test"
       (List.map fst tests) text libraries

(* 3b. Contracts.  With --contracts every module found under the paths --
   not under --modules -- whose interface declares a public function with a
   requires or an ensures gets a programme of its own.  Its driver calls
   each such function with inputs drawn from the seed, keeps only the inputs
   its requires accepts by evaluating the clause's own text, and lets the
   function check its ensures as it always does: a broken ensures stops the
   process, which fails that function's test.  Before every call the driver
   prints a line with the seed, the round and the inputs, so that a failure
   names what to repeat. *)

(* A parameter type the driver can draw: its name, the values tried first,
   written as Hilde expressions, and the driver's function that makes a
   value of the type from a drawn Nat64. *)
type drawable = {
    type_name: string;
    boundaries: string list;
    maker: string;
  }

let drawables: drawable list = [
    { type_name = "Bool"; boundaries = ["false"; "true"]; maker = "contractBoolOf" };
    { type_name = "Nat8"; boundaries = ["0"; "1"; "255"]; maker = "contractNat8Of" };
    { type_name = "Nat16"; boundaries = ["0"; "1"; "65535"]; maker = "contractNat16Of" };
    { type_name = "Nat32"; boundaries = ["0"; "1"; "4294967295"]; maker = "contractNat32Of" };
    { type_name = "Nat64"; boundaries = ["0"; "1"; "18446744073709551615"]; maker = "contractNat64Of" };
    { type_name = "Index"; boundaries = ["0"; "1"]; maker = "contractIndexOf" };
    { type_name = "Int8"; boundaries = ["0"; "1"; "-1"; "(-127) - 1"; "127"]; maker = "contractInt8Of" };
    { type_name = "Int16"; boundaries = ["0"; "1"; "-1"; "(-32767) - 1"; "32767"]; maker = "contractInt16Of" };
    { type_name = "Int32"; boundaries = ["0"; "1"; "-1"; "(-2147483647) - 1"; "2147483647"]; maker = "contractInt32Of" };
    { type_name = "Int64"; boundaries = ["0"; "1"; "-1"; "(-9223372036854775807) - 1"; "9223372036854775807"];
      maker = "contractInt64Of" };
  ]

let drawable_of (spec: Cst.typespec): drawable option =
  match spec with
  | Cst.TypeSpecifier (name, []) ->
     List.find_opt (fun d -> d.type_name = ident_string name) drawables
  | _ -> None

(* The maker of each drawable type, as Hilde text.  A narrower type takes the
   remainder of the draw by its number of values; a signed one is shifted
   down by half of them.  A conversion that cannot fail is still checked,
   since Option says it could.  The number of values is bound to a Nat64
   before rem is called: rem takes two values of one type, and a literal
   given to it beside a Nat64 is typed Int32, which the type checker
   refuses with H3003. *)
let maker_source (d: drawable): string =
  let narrow (fn: string) (convert: string) (ty: string) (width: string) =
    "    function " ^ fn ^ "(draw: Nat64): " ^ ty ^ " is\n"
    ^ "        let width: Nat64 := " ^ width ^ ";\n"
    ^ "        case " ^ convert ^ "(rem(draw, width)) of\n"
    ^ "            when Some(value as v: " ^ ty ^ ") do\n"
    ^ "                return v;\n"
    ^ "            when None do\n"
    ^ "                abort(\"hilde test: a drawn value did not fit its type\");\n"
    ^ "                return 0;\n"
    ^ "        end case;\n"
    ^ "    end;\n"
  and signed (fn: string) (convert: string) (ty: string) (width: string) (half: string) =
    "    function " ^ fn ^ "(draw: Nat64): " ^ ty ^ " is\n"
    ^ "        let width: Nat64 := " ^ width ^ ";\n"
    ^ "        case toInt64(rem(draw, width)) of\n"
    ^ "            when Some(value as wide: Int64) do\n"
    ^ "                case " ^ convert ^ "(wide - " ^ half ^ ") of\n"
    ^ "                    when Some(value as v: " ^ ty ^ ") do\n"
    ^ "                        return v;\n"
    ^ "                    when None do\n"
    ^ "                        abort(\"hilde test: a drawn value did not fit its type\");\n"
    ^ "                        return 0;\n"
    ^ "                end case;\n"
    ^ "            when None do\n"
    ^ "                abort(\"hilde test: a drawn value did not fit its type\");\n"
    ^ "                return 0;\n"
    ^ "        end case;\n"
    ^ "    end;\n"
  in
  match d.type_name with
  | "Bool" ->
     "    function contractBoolOf(draw: Nat64): Bool is\n"
     ^ "        let two: Nat64 := 2;\n"
     ^ "        return rem(draw, two) = 1;\n"
     ^ "    end;\n"
  | "Nat64" ->
     "    function contractNat64Of(draw: Nat64): Nat64 is\n"
     ^ "        return draw;\n"
     ^ "    end;\n"
  | "Index" ->
     "    function contractIndexOf(draw: Nat64): Index is\n"
     ^ "        case toIndex(draw) of\n"
     ^ "            when Some(value as v: Index) do\n"
     ^ "                return v;\n"
     ^ "            when None do\n"
     ^ "                abort(\"hilde test: a drawn value did not fit its type\");\n"
     ^ "                return 0;\n"
     ^ "        end case;\n"
     ^ "    end;\n"
  | "Nat8" -> narrow d.maker "toNat8" "Nat8" "256"
  | "Nat16" -> narrow d.maker "toNat16" "Nat16" "65536"
  | "Nat32" -> narrow d.maker "toNat32" "Nat32" "4294967296"
  | "Int8" -> signed d.maker "toInt8" "Int8" "256" "128"
  | "Int16" -> signed d.maker "toInt16" "Int16" "65536" "32768"
  | "Int32" -> signed d.maker "toInt32" "Int32" "4294967296" "2147483648"
  | _ ->
     (* Int64: the upper half of the draws is the non-negative values, the
        lower half the negative ones. *)
     "    function contractInt64Of(draw: Nat64): Int64 is\n"
     ^ "        if draw >= 9223372036854775808 then\n"
     ^ "            case toInt64(draw - 9223372036854775808) of\n"
     ^ "                when Some(value as v: Int64) do\n"
     ^ "                    return v;\n"
     ^ "                when None do\n"
     ^ "                    abort(\"hilde test: a drawn value did not fit its type\");\n"
     ^ "                    return 0;\n"
     ^ "            end case;\n"
     ^ "        end if;\n"
     ^ "        case toInt64(draw) of\n"
     ^ "            when Some(value as v: Int64) do\n"
     ^ "                return (v - 9223372036854775807) - 1;\n"
     ^ "            when None do\n"
     ^ "                abort(\"hilde test: a drawn value did not fit its type\");\n"
     ^ "                return 0;\n"
     ^ "        end case;\n"
     ^ "    end;\n"

(* A public function whose contract the driver can test. *)
type contract_function = {
    fname: string;
    params: (string * drawable) list;
    result: string option;
    (** None for Unit, else the name of a drawable type. *)
    requires: string list;
    (** The texts of its requires clauses. *)
    names: string list;
    (** The names its requires clauses use, parameters left out. *)
  }

type verdict =
  | Tested of contract_function
  | Skipped of string * string

type result_kind =
  | UnitResult
  | DrawnResult of string
  | OtherResult

(* The names an expression uses as variables or as functions it calls.  A
   form this does not look into adds none; a name it misses is left to the
   compiler, which reports it in its own words. *)
let rec expression_names (e: Cst.cexpr): string list =
  match e with
  | Cst.CVariable (_, n) -> [ident_string n]
  | Cst.CFuncall (_, n, args) ->
     (ident_string n)
     :: (match args with
         | Cst.ConcretePositionalArgs es -> List.concat_map expression_names es
         | Cst.ConcreteNamedArgs pairs -> List.concat_map (fun (_, e) -> expression_names e) pairs)
  | Cst.CArith (_, _, a, b) | Cst.CComparison (_, _, a, b)
  | Cst.CConjunction (_, a, b) | Cst.CDisjunction (_, a, b) ->
     (expression_names a) @ (expression_names b)
  | Cst.CNegation (_, a) | Cst.CArithNegation (_, a) -> expression_names a
  | Cst.CIfExpression (_, a, b, c) ->
     (expression_names a) @ (expression_names b) @ (expression_names c)
  | _ -> []

let has_contract (clauses: Cst.contract_clause list): bool =
  List.exists
    (fun (Cst.ContractClause { kind; _ }) -> kind = Cst.Requires || kind = Cst.Ensures)
    clauses

let verdict_of (decl: Cst.concrete_decl): verdict option =
  match decl with
  | Cst.ConcreteFunctionDecl (_, name, typarams, params, result, _, clauses, _) when has_contract clauses ->
     let n: string = ident_string name in
     let drawn: (string * drawable option) list =
       List.map (fun (Cst.ConcreteParam (p, spec)) -> (ident_string p, drawable_of spec)) params
     in
     let result_kind: result_kind =
       match result with
       | Cst.TypeSpecifier (u, []) when ident_string u = "Unit" -> UnitResult
       | spec ->
          (match drawable_of spec with
           | Some d -> DrawnResult d.type_name
           | None -> OtherResult)
     in
     (match (typarams, List.find_opt (fun (_, d) -> d = None) drawn, result_kind) with
      | (_ :: _, _, _) -> Some (Skipped (n, "it has type parameters"))
      | (_, Some (p, _), _) ->
         Some (Skipped (n, "its parameter " ^ p ^ " is not an integer, Index or Bool"))
      | (_, _, OtherResult) -> Some (Skipped (n, "its result is not an integer, Index, Bool or Unit"))
      | ([], None, (UnitResult | DrawnResult _)) ->
         let result: string option =
           match result_kind with DrawnResult t -> Some t | _ -> None
         in
         let names: string list = List.map fst drawn in
         let requires: Cst.contract_clause list =
           List.filter (fun (Cst.ContractClause { kind; _ }) -> kind = Cst.Requires) clauses
         in
         let used: string list =
           List.concat_map (fun (Cst.ContractClause { condition; _ }) -> expression_names condition) requires
         in
         Some (Tested {
                   fname = n;
                   params = List.map (fun (p, d) -> (p, Option.get d)) drawn;
                   result;
                   requires = List.map (fun (Cst.ContractClause { text; _ }) -> text) requires;
                   names = List.sort_uniq compare (List.filter (fun u -> not (List.mem u names)) used);
                 }))
  | _ -> None

(* The splitmix64 step: the golden-ratio increment is added to the state
   before each draw, and this mixes the state into the drawn number.  The
   shifts are divisions, since the language has no shift. *)
let mix_source: string =
  "    function contractMix(state: Nat64): Nat64 is\n"
  ^ "        let c1: Nat64 := 13787848793156543929;\n"
  ^ "        let c2: Nat64 := 10723151780598845931;\n"
  ^ "        let z1: Nat64 := modularMultiply(bitwiseXor(state, state / 1073741824), c1);\n"
  ^ "        let z2: Nat64 := modularMultiply(bitwiseXor(z1, z1 / 134217728), c2);\n"
  ^ "        return bitwiseXor(z2, z2 / 2147483648);\n"
  ^ "    end;\n"

(* The driver's function that tries one input: it evaluates the requires
   with the inputs bound to the parameters' own names, and only when it
   holds prints the input line and calls the function. *)
let try_source (m: module_name) (seed: string) (k: int) (f: contract_function): string =
  let params: string =
    String.concat ", "
      (("contractRound: Nat64") :: (List.map (fun (p, d) -> p ^ ": " ^ d.type_name) f.params))
  in
  let condition: string =
    match f.requires with
    | [] -> "true"
    | first :: rest ->
       List.fold_left (fun acc t -> "(" ^ acc ^ ") and (" ^ t ^ ")") first rest
  in
  let args: string = String.concat ", " (List.map fst f.params) in
  let prints: string =
    String.concat ""
      (List.map
         (fun (p, _) -> "            print(\" " ^ p ^ "=\");\n            print(" ^ p ^ ");\n")
         f.params)
  in
  let call: string =
    match f.result with
    | None ->
       "            " ^ f.fname ^ "(" ^ args ^ ");\n"
       ^ "            printLn(\"contract-returned\");\n"
    | Some ty ->
       "            let contractResult: " ^ ty ^ " := " ^ f.fname ^ "(" ^ args ^ ");\n"
       ^ "            print(\"contract-returned \");\n"
       ^ "            printLn(contractResult);\n"
  in
  "    function contractTry" ^ (string_of_int k) ^ "(" ^ params ^ "): Bool is\n"
  ^ "        if " ^ condition ^ " then\n"
  ^ "            print(\"contract-input seed=" ^ seed ^ " function=" ^ (mod_name_string m) ^ "." ^ f.fname
  ^ " round=\");\n"
  ^ "            print(contractRound);\n"
  ^ prints
  ^ "            printLn(\"\");\n"
  ^ call
  ^ "            return true;\n"
  ^ "        end if;\n"
  ^ "        return false;\n"
  ^ "    end;\n"

(* The test of one function: the boundary rounds first, each parameter
   taking its boundary values in turn, then drawn rounds up to [rounds].  A
   function no input of which its requires accepted fails, since then
   nothing of it was tested. *)
let test_source (m: module_name) (seed: string) (rounds: int) (k: int) (f: contract_function): string =
  let widths: int list = List.map (fun (_, d) -> List.length d.boundaries) f.params in
  let boundary_rounds: int = min rounds (List.fold_left max 1 widths) in
  let try_name: string = "contractTry" ^ (string_of_int k) in
  let boundary (i: int): string =
    let values: string list =
      List.mapi (fun j (_, d) -> List.nth d.boundaries ((i + j) mod (List.length d.boundaries))) f.params
    in
    "        if " ^ try_name ^ "(" ^ (String.concat ", " ((string_of_int i) :: values)) ^ ") then\n"
    ^ "            accepted := accepted + 1;\n"
    ^ "        end if;\n"
  in
  let draws: string =
    String.concat ""
      (List.mapi
         (fun j (_, d) ->
           "            state := modularAdd(state, golden);\n"
           ^ "            let draw" ^ (string_of_int j) ^ ": " ^ d.type_name ^ " := "
           ^ d.maker ^ "(contractMix(state));\n")
         f.params)
  in
  let drawn_args: string =
    String.concat ", " ("round" :: (List.mapi (fun j _ -> "draw" ^ (string_of_int j)) f.params))
  in
  "    function contractTest" ^ (string_of_int k) ^ "(): Unit is\n"
  ^ "        var accepted: Nat64 := 0;\n"
  ^ String.concat "" (List.init boundary_rounds boundary)
  ^ "        let golden: Nat64 := 11400714819323198485;\n"
  ^ "        var state: Nat64 := " ^ seed ^ ";\n"
  ^ "        var round: Nat64 := " ^ (string_of_int boundary_rounds) ^ ";\n"
  ^ "        while round < " ^ (string_of_int rounds) ^ " do\n"
  ^ draws
  ^ "            if " ^ try_name ^ "(" ^ drawn_args ^ ") then\n"
  ^ "                accepted := accepted + 1;\n"
  ^ "            end if;\n"
  ^ "            round := round + 1;\n"
  ^ "        end while;\n"
  ^ "        print(\"contract-accepted function=" ^ (mod_name_string m) ^ "." ^ f.fname ^ " rounds="
  ^ (string_of_int rounds) ^ " accepted=\");\n"
  ^ "        printLn(accepted);\n"
  ^ "        if accepted = 0 then\n"
  ^ "            abort(\"hilde test: no input satisfied the requires of " ^ f.fname ^ "\");\n"
  ^ "        end if;\n"
  ^ "        return nil;\n"
  ^ "    end;\n"

let import_line (m: string) (items: string list): string =
  match items with
  | [] -> ""
  | _ -> "import " ^ m ^ " (" ^ (String.concat ", " items) ^ ");\n"

(* The driver of a module's contracts.  It imports the functions under test
   and the module's own names their requires use; a name a requires takes
   from another module is imported as the interface imports it. *)
let contract_driver (m: module_name) (declared: string list) (imports: Cst.concrete_import_list list)
      (seed: string) (rounds: int) (fs: contract_function list): string =
  let used: string list = List.sort_uniq compare (List.concat_map (fun f -> f.names) fs) in
  let own: string list =
    List.sort_uniq compare
      ((List.map (fun f -> f.fname) fs) @ (List.filter (fun n -> List.mem n declared) used))
  in
  let foreign: string =
    String.concat ""
      (List.map
         (fun (Cst.ConcreteImportList (mn, items)) ->
           let wanted: string list =
             List.filter_map
               (fun (Cst.ConcreteImport (name, nick)) ->
                 let local: string =
                   match nick with Some n -> ident_string n | None -> ident_string name
                 in
                 if List.mem local used && not (List.mem local own) then
                   Some (match nick with
                         | Some n -> (ident_string name) ^ " as " ^ (ident_string n)
                         | None -> ident_string name)
                 else None)
               items
           in
           import_line (mod_name_string mn) wanted)
         imports)
  in
  let makers: string list =
    List.sort_uniq compare
      (List.concat_map (fun f -> List.map (fun (_, d) -> maker_source d) f.params) fs)
  in
  let dispatch (k: int) (f: contract_function): string =
    "            if nameIs(given, \"" ^ f.fname ^ "\") then\n"
    ^ "                contractTest" ^ (string_of_int k) ^ "();\n"
    ^ "                ran := true;\n"
    ^ "            end if;\n"
  in
  import_line (mod_name_string m) own
  ^ foreign
  ^ "\n"
  ^ "module body " ^ driver_name ^ " is\n"
  ^ "    function nameIs(given: Span[Nat8, Static], name: Span[Nat8, Static]): Bool is\n"
  ^ "        let length: Index := spanLength(name);\n"
  ^ "        if spanLength(given) /= length then\n"
  ^ "            return false;\n"
  ^ "        end if;\n"
  ^ "        var i: Index := 0;\n"
  ^ "        while i < length do\n"
  ^ "            if given[i] /= name[i] then\n"
  ^ "                return false;\n"
  ^ "            end if;\n"
  ^ "            i := i + 1;\n"
  ^ "        end while;\n"
  ^ "        return true;\n"
  ^ "    end;\n"
  ^ "\n"
  ^ mix_source
  ^ String.concat "" makers
  ^ String.concat "" (List.mapi (try_source m seed) fs)
  ^ String.concat "" (List.mapi (test_source m seed rounds) fs)
  ^ "\n"
  ^ "    function main(root: RootCapability): ExitCode is\n"
  ^ "        var capability: RootCapability := root;\n"
  ^ "        var ran: Bool := false;\n"
  ^ "        if argumentCount() = 2 then\n"
  ^ "            let given: Span[Nat8, Static] := nthArgument(1);\n"
  ^ String.concat "" (List.mapi dispatch fs)
  ^ "        end if;\n"
  ^ "        surrenderRoot(capability);\n"
  ^ "        if ran then\n"
  ^ "            return ExitSuccess();\n"
  ^ "        end if;\n"
  ^ "        return ExitFailure();\n"
  ^ "    end;\n"
  ^ "end module body.\n"

(* The modules under the paths whose interface declares a function with a
   contract, each with the verdict on every such function, in the order of
   their files. *)
let contract_modules (sources: module_source list): (module_source * module_name * string list * Cst.concrete_import_list list * verdict list) list =
  List.filter_map
    (fun source ->
      match source with
      | TwoFileModuleSource { int_filename; int_code; _ } ->
         let (Cst.ConcreteModuleInterface (name, _, imports, decls)) =
           ParserInterface.parse_module_int int_code int_filename
         in
         let declared: string list =
           List.filter_map
             (fun d ->
               match d with
               | Cst.ConcreteFunctionDecl (_, n, _, _, _, _, _, _) -> Some (ident_string n)
               | Cst.ConcreteConstantDecl (_, n, _, _) -> Some (ident_string n)
               | _ -> None)
             decls
         in
         (match List.filter_map verdict_of decls with
          | [] -> None
          | verdicts -> Some (source, name, declared, imports, verdicts))
      | BodyModuleSource _ -> None)
    sources

(* A seed from the clock: the microseconds since the epoch, which is what a
   run that names none is given, and prints. *)
let clock_seed (): string =
  Printf.sprintf "%Lu" (Int64.of_float (Unix.gettimeofday () *. 1e6))

let run_contracts (tally: tally) (index: (string, module_name * found_module) Hashtbl.t) (work: string)
      (instrument: instrument) (verbose: bool) (emit_c: string option) (mode: error_reporting_mode)
      (seed: string) (rounds: int) (number: int)
      ((source, name, declared, imports, verdicts): module_source * module_name * string list * Cst.concrete_import_list list * verdict list): unit =
  let label: string = (mod_name_string name) ^ " (contracts)" in
  List.iter
    (fun v ->
      match v with
      | Skipped (f, why) -> print_endline ("    skip  " ^ (mod_name_string name) ^ "." ^ f ^ " (" ^ why ^ ")")
      | Tested _ -> ())
    verdicts;
  let tested: contract_function list =
    List.filter_map (fun v -> match v with Tested f -> Some f | Skipped _ -> None) verdicts
  in
  match tested with
  | [] -> ()
  | _ ->
     tally.files <- tally.files + 1;
     let module_imports: module_name list =
       name :: (List.map (fun (Cst.ConcreteImportList (mn, _)) -> mn) imports)
     in
     (match
        (let needed: module_source list = needed_modules index module_imports in
         let needed: module_source list =
           if List.memq source needed then needed else needed @ [source]
         in
         let c: compiler = compile_multiple empty_compiler needed in
         let driver: module_source =
           BodyModuleSource { body_filename = "(the contract driver of " ^ (body_path source) ^ ")";
                              body_code = contract_driver name declared imports seed rounds tested }
         in
         let c: compiler = compile_mod c driver in
         let c: compiler = post_compile c in
         let c: compiler = compile_entrypoint c (make_mod_name driver_name) (make_ident "main") in
         (c_file_text c, compiler_libraries c))
      with
      | exception Hilde_error error ->
         prerr_string (render_with_context mode error);
         flush stderr;
         print_endline ("FAIL  " ^ label ^ "  the test programme did not build");
         tally.not_built <- tally.not_built + 1
      | (text, libraries) ->
         run_built tally work ("contracts-" ^ (string_of_int number)) instrument verbose emit_c mode
           ~label ~file:((mod_name_string name) ^ ".contracts") ~noun:"function"
           (List.map (fun f -> make_ident f.fname) tested) text libraries)

(* Every test file is built and run by a child process of its own, at
   most jobs at once.  A child writes what it would print
   into two files of its own and its counts into a third; the parent prints
   them in the order of the files and adds the counts, so the report is the
   one a single process gives.  A child that leaves no counts behind counts
   as a file whose programme was not built. *)
let rec wait_any (): int =
  match Unix.wait () with
  | (pid, _) -> pid
  | exception Unix.Unix_error (Unix.EINTR, _, _) -> wait_any ()

let run_files_in_children (jobs: int) (tally: tally) (work: string) (files: string list)
      (step: tally -> int -> string -> unit): unit =
  let paths: string array = Array.of_list files in
  let total: int = Array.length paths in
  let part (k: int) (suffix: string): string =
    Filename.concat work (Printf.sprintf "file-%d.%s" k suffix)
  in
  let start (k: int): int =
    flush stdout;
    flush stderr;
    match Unix.fork () with
    | 0 ->
       let code: int =
         try
           let flags = [Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC] in
           let out = Unix.openfile (part k "out") flags 0o600 in
           let err = Unix.openfile (part k "err") flags 0o600 in
           Unix.dup2 out Unix.stdout;
           Unix.dup2 err Unix.stderr;
           Unix.close out;
           Unix.close err;
           let mine: tally = { files = 0; tests = 0; failed = 0; not_built = 0 } in
           step mine k paths.(k);
           flush stdout;
           flush stderr;
           write_string_to_file (part k "tally")
             (Printf.sprintf "%d %d %d %d" mine.files mine.tests mine.failed mine.not_built);
           0
         with _ -> 2
       in
       Unix._exit code
    | pid -> pid
  in
  let running: int ref = ref 0
  and next: int ref = ref 0 in
  while !next < total || !running > 0 do
    while !running < jobs && !next < total do
      ignore (start !next);
      incr next;
      incr running
    done;
    ignore (wait_any ());
    decr running
  done;
  Array.iteri
    (fun k path ->
      (* The bytes as the child wrote them: read_file_to_string trims. *)
      let read (suffix: string): string =
        if Sys.file_exists (part k suffix) then
          In_channel.with_open_bin (part k suffix) In_channel.input_all
        else ""
      in
      print_string (read "out");
      prerr_string (read "err");
      match String.split_on_char ' ' (String.trim (read "tally")) with
      | [f; t; x; n] ->
         tally.files <- tally.files + int_of_string f;
         tally.tests <- tally.tests + int_of_string t;
         tally.failed <- tally.failed + int_of_string x;
         tally.not_built <- tally.not_built + int_of_string n
      | _ ->
         print_endline ("FAIL  " ^ path ^ "  the process that ran it left no counts");
         tally.files <- tally.files + 1;
         tally.not_built <- tally.not_built + 1)
    paths;
  flush stdout;
  flush stderr

(* --- Doc tests ------------------------------------------------------------ *)

(* The lines of a file, or none when it cannot be read. *)
let file_lines (path: string): string list =
  match open_in path with
  | exception Sys_error _ -> []
  | ic ->
     let lines = ref [] in
     (try while true do lines := input_line ic :: !lines done with End_of_file -> ());
     close_in ic;
     List.rev !lines

let leading_blanks (s: string): int =
  let n = String.length s in
  let rec go i = if i < n && s.[i] = ' ' then go (i + 1) else i in
  go 0

let starts_with (s: string) (prefix: string): bool =
  String.length s >= String.length prefix && String.sub s 0 (String.length prefix) = prefix

(* The name after "function " up to the parenthesis, or None. *)
let function_name (line: string): string option =
  let t = String.trim line in
  if starts_with t "function " then
    let rest = String.sub t 9 (String.length t - 9) in
    match String.index_opt rest '(' with
    | Some i -> Some (String.trim (String.sub rest 0 i))
    | None -> None
  else None

(* The module of an interface, and every exported function with the
   example of its docstring: the lines set off by four blanks more than the
   docstring, the four blanks and the docstring's own indent taken off. *)
let doc_examples (path: string): (string * string list * (string * string list) list) option =
  let lines = Array.of_list (file_lines path) in
  let n = Array.length lines in
  let module_name = ref None and names = ref [] and found = ref [] in
  let i = ref 0 in
  while !i < n do
    let t = String.trim lines.(!i) in
    if !module_name = None && starts_with t "module " && String.length t > 10
       && String.sub t (String.length t - 3) 3 = " is" then begin
      module_name := Some (String.trim (String.sub t 7 (String.length t - 10)));
      incr i
    end else if t = "\"\"\"" && !module_name <> None then begin
      let indent = leading_blanks lines.(!i) in
      let j = ref (!i + 1) and example = ref [] in
      while !j < n && String.trim lines.(!j) <> "\"\"\"" do
        let l = lines.(!j) in
        if leading_blanks l >= indent + 4 && String.trim l <> "" then
          example := String.sub l (indent + 4) (String.length l - indent - 4) :: !example;
        incr j
      done;
      (* The declaration after the docstring, past a generic line. *)
      let k = ref (!j + 1) in
      while !k < n && (String.trim lines.(!k) = "" || starts_with (String.trim lines.(!k)) "generic") do incr k done;
      (if !k < n then
         match function_name lines.(!k) with
         | Some name when !example <> [] -> found := (name, List.rev !example) :: !found
         | _ -> ());
      i := !j + 1
    end else begin
      (match function_name lines.(!i) with
       | Some name when !module_name <> None -> names := name :: !names
       | _ -> ());
      incr i
    end
  done;
  match !module_name with
  | Some m when !found <> [] -> Some (m, List.rev !names, List.rev !found)
  | _ -> None

(* Whether the text calls the name: the name and a parenthesis, and no
   letter, digit or underscore before it. *)
let mentions (text: string) (name: string): bool =
  let n = String.length text and k = String.length name in
  let word c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_' in
  let rec go i =
    if i + k >= n then false
    else if String.sub text i k = name && text.[i + k] = '(' && (i = 0 || not (word text.[i - 1])) then true
    else go (i + 1)
  in
  k > 0 && go 0

(* Writes the doc tests of one interface into dir as a test file and gives
   its path: one test per example, the lines of an example that begin with
   import put at the head of the file, and the functions the examples call
   imported from the module. *)
let write_doc_test (dir: string) (k: int) (m: string) (names: string list) (examples: (string * string list) list): string =
  let all = String.concat "\n" (List.concat_map snd examples) in
  let used = List.filter (mentions all) (List.sort_uniq compare names) in
  let imports = List.concat_map (fun (_, lines) -> List.filter (fun l -> starts_with (String.trim l) "import ") lines) examples in
  let b = Buffer.create 1024 in
  List.iter (fun l -> Buffer.add_string b (String.trim l); Buffer.add_char b '\n') imports;
  if used <> [] then begin
    Buffer.add_string b ("import " ^ m ^ " (\n");
    Buffer.add_string b (String.concat ",\n" (List.map (fun u -> "    " ^ u) used));
    Buffer.add_string b "\n);\n"
  end;
  Buffer.add_string b ("\nmodule body " ^ m ^ ".DocTest is\n");
  List.iteri
    (fun t (name, lines) ->
      Buffer.add_string b (Printf.sprintf "    function testDoc%d(): Unit is\n" (t + 1));
      Buffer.add_string b (Printf.sprintf "        -- The example of %s.%s.\n" m name);
      List.iter
        (fun l -> if not (starts_with (String.trim l) "import ") then Buffer.add_string b ("        " ^ l ^ "\n"))
        lines;
      Buffer.add_string b "        return nil;\n    end;\n")
    examples;
  Buffer.add_string b "end module body.\n";
  let path = Filename.concat dir (Printf.sprintf "doc%d.test.hiq" k) in
  let oc = open_out path in
  output_string oc (Buffer.contents b);
  close_out oc;
  path

(* The doc test files of the interfaces under the paths, written into dir. *)
let doc_tests (dir: string) (paths: string list): string list =
  let interfaces =
    List.filter (fun f -> Filename.check_suffix f ".hih")
      (List.concat_map (fun p -> if is_directory p then files_under p else []) paths)
  in
  List.concat
    (List.mapi
       (fun k f ->
         match doc_examples f with
         | Some (m, names, examples) -> [write_doc_test dir k m names examples]
         | None -> [])
       interfaces)

(* Standard output sent to standard error while f runs, child processes
   included; for --json, whose object is then the only output. *)
let output_on_stderr (f: unit -> int): int =
  flush stdout;
  let saved = Unix.dup Unix.stdout in
  Unix.dup2 Unix.stderr Unix.stdout;
  Fun.protect
    ~finally:(fun () -> flush stdout; Unix.dup2 saved Unix.stdout; Unix.close saved)
    f

let rec run ~(paths: string list) ~(module_dirs: string list) ~(instrument: instrument)
      ~(verbose: bool) ~(emit_c: string option) ~(contracts: contract_run option)
      ~(jobs: int) ~(test_jobs: int) ~(fresh_dirs: bool) ~(doc: bool) ~(json: bool)
      ~(mode: error_reporting_mode): int =
  let doc_dir: string option = if doc then Some (Filename.temp_dir "hilde-doc-" "") else None in
  let last: (int * int * int * int) ref = ref (0, 0, 0, 0) in
  let body () =
    run_counted ~paths ~module_dirs ~instrument ~verbose ~emit_c ~contracts ~jobs ~test_jobs ~fresh_dirs
      ~doc_dir ~last ~mode
  in
  Fun.protect
    ~finally:(fun () -> match doc_dir with Some d -> remove_tree d | None -> ())
    (fun () ->
      if json then begin
        let code = output_on_stderr body in
        let (files, tests, failed, not_built) = !last in
        print_endline (Yojson.Basic.to_string (`Assoc [
            ("command", `String "test");
            ("files", `Int files);
            ("tests", `Int tests);
            ("failed", `Int failed);
            ("not_built", `Int not_built);
            ("doc_tests", `Bool doc);
            ("ok", `Bool (code = 0))
          ]));
        code
      end else body ())

and run_counted ~(paths: string list) ~(module_dirs: string list) ~(instrument: instrument)
      ~(verbose: bool) ~(emit_c: string option) ~(contracts: contract_run option)
      ~(jobs: int) ~(test_jobs: int) ~(fresh_dirs: bool) ~(doc_dir: string option)
      ~(last: (int * int * int * int) ref) ~(mode: error_reporting_mode): int =
  (* The test files first: a path that is neither a directory nor a .hiq
     file is refused before anything else is read.  The doc tests of the
     interfaces under the paths join them. *)
  let docs: string list = match doc_dir with Some d -> doc_tests d paths | None -> [] in
  let test_files: string list = unique (List.concat_map test_files_of paths) @ docs in
  let dir_files (p: string): string list = if is_directory p then files_under p else [] in
  let module_files: string list =
    unique ((List.concat_map dir_files paths) @ (List.concat_map module_files_of module_dirs))
  in
  let sources: module_source list = module_sources module_files in
  let index = index_modules sources in
  (* The modules whose contracts are tested are those under the paths; the
     modules of --modules are there to be imported, as their tests are. *)
  let tested_sources: module_source list =
    match contracts with
    | None -> []
    | Some _ ->
       let under: string list = unique (List.concat_map dir_files paths) in
       List.filter (fun s -> List.mem (body_path s) under) sources
  in
  let with_contracts = contract_modules tested_sources in
  (match (test_files, with_contracts) with
   | ([], []) -> Errors.no_test_files paths
   | _ -> ());
  tests_at_once := test_jobs;
  each_test_fresh := fresh_dirs;
  let work: string = Filename.temp_dir "hilde-test-" "" in
  Fun.protect
    ~finally:(fun () -> remove_tree work)
    (fun () ->
      check_instrument work instrument;
      let tally: tally = { files = 0; tests = 0; failed = 0; not_built = 0 } in
      let step (t: tally) (k: int) (path: string): unit =
        run_file t index work k instrument verbose emit_c mode path
      in
      (* Every file in a child of its own, with one job too: the compiler
         numbers its names in counters of the process, and a file built
         after others would get other names than built alone, so the C of
         a file would depend on the files before it and on the jobs. *)
      run_files_in_children (max 1 jobs) tally work test_files step;
      (match contracts with
       | None -> ()
       | Some { seed; rounds } ->
          let seed: string = match seed with Some s -> s | None -> clock_seed () in
          print_endline (Printf.sprintf "hilde test --contracts: seed=%s rounds=%d, %s"
                           seed rounds (count (List.length with_contracts) "module with contracts"));
          List.iteri
            (fun k m -> run_contracts tally index work instrument verbose emit_c mode seed rounds k m)
            with_contracts);
      (match emit_c with
       | Some _ ->
          print_endline (Printf.sprintf "hilde test: %s, %d emitted, %d not built"
                           (count tally.files "test file") (tally.files - tally.not_built) tally.not_built)
       | None ->
          print_endline (Printf.sprintf "hilde test: %s, %s, %d failed, %d not built"
                           (count tally.files "test file") (count tally.tests "test")
                           tally.failed tally.not_built));
      last := (tally.files, tally.tests, tally.failed, tally.not_built);
      if tally.failed = 0 && tally.not_built = 0 then 0 else 1)
