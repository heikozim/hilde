(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

open Identifier
open Unix
open Error

(* A zig that was found and not taken, with the version it gave. *)
let zig_passed_over: (string * string) option ref = ref None

module Errors = struct
  let c_compiler_error ?(tool: string = "C compiler") ~command ~exit_code ~stdout ~stderr () =
    hilde_raise (H 1014) CliError [
      Text ("Failed to run " ^ tool ^ ".");
      Break;
      Text "Command: ";
      Code command;
      Break;
      Text "Exit code: ";
      Text (string_of_int exit_code);
      Break;
      Text "Standard output:\n";
      Text stdout;
      Break;
      Text "Standard error:\n";
      Text stderr
    ]

  let long_character lit =
    hilde_raise (H 7) ParseError [
      Text "Character literal '";
      Code lit;
      Text " is more than one character."
    ]

  let read_error ~path ~message =
      hilde_raise (H 1034) CliError [
        Text "Failed to read file ";
        Code path;
        Text ": ";
        Break;
        Text message
      ]

  let write_error ~path ~error = match error with
  | Sys_error msg ->
      hilde_raise (H 1015) CliError [
        Text "Failed to write to file ";
        Code path;
        Text ": ";
        Break;
        Text msg
      ]
  | _ ->
      hilde_raise (H 1016) CliError [
        Text "Failed to write to file ";
        Code path
      ]

  let no_wasm_compiler (asked: string option) =
    hilde_raise (H 1038) CliError [
      Text (match asked with
            | Some name -> "The compiler for WebAssembly that HILDE_WASM_CC names, " ^ name ^ ", was not found."
            | None -> "No compiler for WebAssembly was found.");
      Break;
      Text "hilde looks for zig, given as ";
      Code "HILDE_ZIG";
      Text " or on the path, and then for clang on the path with ";
      Code "wasm-ld";
      Text " and the C library of WASI, in ";
      Code "WASI_SYSROOT";
      Text ", /usr/share/wasi-sysroot, /opt/wasi-sdk/share/wasi-sysroot or where Debian's wasi-libc puts it. Install zig, or clang with lld and wasi-libc.";
      Break;
      Text ("A compiler for WebAssembly is needed only for --target=wasm and --target-type=wasm; zig is taken at version "
            ^ BuiltInModules.zig_version ^ " only"
            ^ (match !zig_passed_over with
               | Some (path, version) -> ", and " ^ path ^ " is version " ^ version ^ "."
               | None -> "."))
    ]

  let unknown_wasm_compiler (name: string) =
    hilde_raise (H 1039) CliError [
      Code "HILDE_WASM_CC";
      Text " is ";
      Code name;
      Text ", which is not a compiler hilde knows for WebAssembly.";
      Break;
      Text "It is ";
      Code "zig";
      Text " or ";
      Code "clang";
      Text ", or not set, and then zig is taken when it is there."
    ]

  let no_wasm_runtime () =
    hilde_raise (H 1040) CliError [
      Text "No runtime for WebAssembly was found to run the tests.";
      Break;
      Text "hilde runs a module for wasm32-wasi with wasmtime, given as ";
      Code "HILDE_WASMTIME";
      Text " or on the path."
    ]
end

let string_explode (s: string): char list =
  List.init (String.length s) (String.get s)

(* Through a buffer: String.init with List.nth walked the list from its
   head for every character, which made a string literal of 60000 bytes
   take two seconds to escape. *)
let string_implode (l: char list): string =
  let b = Buffer.create (List.length l) in
  List.iter (Buffer.add_char b) l;
  Buffer.contents b

let read_stream_to_string stream: string =
  let rec read_stream stream =
    try
      let line = input_line stream in
      line :: (read_stream stream)
    with End_of_file ->
      []
  in
  String.trim (String.concat "\n" (read_stream stream))

let read_error (path: string) (message: string): 'a =
  Errors.read_error ~path ~message

(* A file that cannot be opened or read, a missing one or a directory, is
   reported like a write that fails, not left as an exception. *)
let read_file_to_string (path: string): string =
  match open_in path with
  | exception Sys_error message ->
     read_error path message
  | stream ->
     (try
        let contents = read_stream_to_string stream in
        close_in stream;
        contents
      with Sys_error message ->
        close_in_noerr stream;
        read_error path message)

let write_string_to_file (path: string) (contents: string): unit =
  (* Opening the file fails, too, when its directory does not exist; that
     is reported like a write that fails, not left as an exception. *)
  match open_out path with
  | exception error ->
     Errors.write_error ~path ~error
  | stream ->
     (try
        Printf.fprintf stream "%s" contents;
        close_out stream
      with error ->
        close_out_noerr stream;
        Errors.write_error ~path ~error)

let remove_char (s: string) (c: char)  =
  string_implode (List.filter (fun c' -> c <> c') (string_explode s))

let replace_char (s: string) (c: char) (r: string): string =
  let replace char =
    if char = c then
      string_explode r
    else
      [char]
  in
  string_implode (List.concat (List.map replace (string_explode s)))

type replacement = { text: string; search: string; replacement: string }

let search_replace (r: replacement): string =
  let { text: string; search: string; replacement: string } = r in
  let re = Str.regexp_string search in
  Str.global_replace re replacement text

let remove_leading (s: string) (n: int): string =
  String.sub s n ((String.length s) - n)

let parse_hex (s: string): int =
  int_of_string ("0x" ^ s)

let parse_bin (s: string): int =
  int_of_string ("0b" ^ s)

let parse_oct (s: string): int =
  int_of_string ("0o" ^ s)

(* What stands between the apostrophes of a character literal.  Not
   remove_char, which takes out every apostrophe and made the body of the
   literal for an apostrophe a backslash. *)
let char_body (s: string): string =
  String.sub s 1 ((String.length s) - 2)

let parse_ascii_char (s: string): int =
  match s with
  | "\\n" ->
     10
  | "\\r" ->
     13
  | "\\t" ->
     9
  | "\\\\" ->
     92
  | "\\'" ->
     39
  | _ ->
     (match (string_explode s) with
      | [c] ->
         Char.code c
      | _ ->
         Errors.long_character s)

let rec count_leading_whitespace (s: string): int =
  let chars = string_explode s in
  match chars with
  | ' '::rest ->
     1 + (count_leading_whitespace (string_implode rest))
  | _ ->
     0

let min_list (l: int list): int =
  match l with
  | first::rest ->
     List.fold_left min first rest
  | [] ->
     internal_err "empty list passed to min_list"

let trim_common_whitespace (s: string): string =
  let lines = String.split_on_char '\n' s in
  let lines = List.map (fun s -> (count_leading_whitespace s, s)) lines in
  let min_whitespace: int = min_list (List.map (fun (w, _) -> w) lines) in
  let lines: string list = List.map (fun (_, s) -> remove_leading s min_whitespace) lines in
  String.concat "\n" lines

let process_triple_string (s: string): string =
  let lines = String.split_on_char '\n' s in
  match lines with
  | first::rest ->
     let first = if (String.equal (String.trim first) "") then
                   ""
                 else
                   first
     in
     (match (List.rev rest) with
      | last::body ->
         let last = if (String.equal (String.trim last) "") then
                      ""
                    else
                      last
         in
         let s = first ^ (String.concat "\n" (List.rev body)) ^ last in
         trim_common_whitespace s
      | [] ->
         first)
  | [] ->
     internal_err "split_on_char returned empty"

let ident_set_eq a b =
  let sorter a b = compare (ident_string a) (ident_string b) in
  (List.sort sorter a) = (List.sort sorter b)

let get_exit_code = function
  | WEXITED i -> i
  | WSIGNALED i -> i
  | WSTOPPED i -> i

type command_output =
  CommandOutput of { command: string; code: int; stdout: string; stderr: string }

(* Both channels of a child read to their end at the same time, as
   read_stream_to_string gives each.  The descriptors are read directly,
   so the buffers of the channels stay empty. *)
let read_both (a: in_channel) (b: in_channel): string * string =
  let fa = descr_of_in_channel a
  and fb = descr_of_in_channel b in
  let ba = Buffer.create 4096
  and bb = Buffer.create 4096 in
  let chunk = Bytes.create 65536 in
  let rec loop (open_fds: file_descr list): unit =
    if open_fds <> [] then
      let ready =
        try let (r, _, _) = select open_fds [] [] (-1.0) in r
        with Unix_error (EINTR, _, _) -> []
      in
      let still =
        List.filter (fun fd ->
            if List.mem fd ready then
              let got = try read fd chunk 0 (Bytes.length chunk) with Unix_error (EINTR, _, _) -> -1 in
              if got = 0 then false
              else begin
                if got > 0 then Buffer.add_subbytes (if fd = fa then ba else bb) chunk 0 got;
                true
              end
            else true)
          open_fds
      in
      loop still
  in
  loop [fa; fb];
  (String.trim (Buffer.contents ba), String.trim (Buffer.contents bb))

let run_command (argv: string array): command_output =
  let (prog, args): (string * string list) =
    match Array.to_list argv with
    | first::rest ->
       (first, rest)
    | [] ->
       internal_err "Util.run_command called with an empty argument vector."
  in
  (* The program is executed directly. No shell sees these arguments, so a
     path containing a space, a semicolon or any other character a shell acts
     on stays one argument. *)
  (* The child sees PATH and, when they are set, the two variables that tell
     pkg-config where to look, so that the compiler links the libraries the
     test runner links: test-programs/runner.py passes the whole environment.
     zig, which builds a module for wasm32-wasi, needs a cache directory: its
     two variables for one, or HOME, where it keeps its own.  Nothing else of
     the caller's environment is passed on. *)
  let passed =
    List.filter_map
      (fun name -> Option.map (fun value -> name ^ "=" ^ value) (Sys.getenv_opt name))
      [ "PKG_CONFIG_PATH"; "PKG_CONFIG_LIBDIR"; "ZIG_GLOBAL_CACHE_DIR"; "ZIG_LOCAL_CACHE_DIR"; "HOME" ]
  in
  let env = Array.of_list (("PATH=" ^ (getenv "PATH")) :: passed) in
  let (stdout_chan, stdin_chan, stderr_chan) = open_process_args_full prog argv env in
  (* Nothing is written to the child, so it sees the end of its input at
     once.  Both outputs are read as they come: read one after the other,
     a child that fills the pipe of the second (clang with a page of
     warnings on stderr) waits for a reader while the first is read to its
     end, and the compiler with it, for ever. *)
  close_out stdin_chan;
  let (stdout, stderr) = read_both stdout_chan stderr_chan in
  let proc_stat = close_process_full (stdout_chan, stdin_chan, stderr_chan) in
  CommandOutput {
      (* Quoted, and for the error message only: a path with a space has to be
         visible there as one argument. Nothing is ever run from this string. *)
      command = Filename.quote_command prog args;
      code = get_exit_code proc_stat;
      stdout = stdout;
      stderr = stderr
    }

(* The system the compiler runs on, as `uname -s' names it.  The compiler
   links what it compiles on the same machine, so this is the system a
   `pragma Foreign_Library(Name => ..., System => ...)' is held to
.  Asked once.  When
   uname cannot be run the answer is the empty string, which no pragma may
   name: a library for one system is then linked nowhere, and a programme
   that needs it fails at the link, loudly. *)
let host_system: string Lazy.t =
  lazy (
    match run_command [| "uname"; "-s" |] with
    | CommandOutput { code = 0; stdout; _ } -> String.trim stdout
    | CommandOutput _ -> ""
    | exception Unix.Unix_error _ -> "")

(* The systems a programme is built for, by the names `hilde build --target'
   and `pragma Targets' use: four that run a binary, and wasm, a module for
   wasm32-wasi. *)
let target_names: string list = ["linux"; "openbsd"; "freebsd"; "darwin"; "wasm"]

(* The target of the system the compiler runs on, from uname; the empty
   string on a system that is none of the four. *)
let host_target: string Lazy.t =
  lazy (
    match Lazy.force host_system with
    | "Linux" -> "linux"
    | "OpenBSD" -> "openbsd"
    | "FreeBSD" -> "freebsd"
    | "Darwin" -> "darwin"
    | _ -> "")

(* The target of this run of the compiler, set from --target; the empty
   string until then, which is the host's. *)
let build_target: string ref = ref ""

let current_target (): string =
  if !build_target = "" then Lazy.force host_target else !build_target

(* The machines a programme is cross-built for, by the values of --target
   that name a whole machine rather than a system: two systems, each in two
   widths, musl named where the C library is musl.  With one of these the C
   is compiled by `zig cc -target <triple>' when zig is there, and by the
   native cc only when the machine is this one's. *)
let target_triples: string list =
  ["x86_64-openbsd"; "aarch64-openbsd"; "x86_64-linux-musl"; "aarch64-linux-musl"]

(* The system of a machine name, the word between the widths and the C
   library: the name of target_names the modules of pragma Targets are
   held to.  It is total over target_triples. *)
let triple_system (triple: string): string =
  match String.split_on_char '-' triple with
  | _ :: system :: _ -> system
  | _ -> ""

(* Whether a value of --target is shaped as a machine name: <arch>-<system>,
   with the system one of the two the machines build for.  A value shaped
   so, that is none of target_triples, is refused as a machine hilde does
   not build for; one of another shape, as a system it does not build for. *)
let triple_shaped (name: string): bool =
  match String.split_on_char '-' name with
  | _ :: system :: _ -> List.mem system ["openbsd"; "linux"]
  | _ -> false

(* The width of the machine the compiler runs on, as `uname -m' names it,
   with the two names OpenBSD and macOS use brought to the ones of the
   triples; the empty string on a machine of another width. *)
let host_arch: string Lazy.t =
  lazy (
    match run_command [| "uname"; "-m" |] with
    | CommandOutput { code = 0; stdout; _ } ->
       (match String.trim stdout with
        | "amd64" -> "x86_64"
        | "arm64" -> "aarch64"
        | arch -> arch)
    | CommandOutput _ -> ""
    | exception Unix.Unix_error _ -> "")

(* Whether a machine name is the machine the compiler runs on: its system
   is the host's and its width the host's.  The C library of the name is
   left out: the native cc builds for its own, so a name of the host's
   system falls back to it whatever libc the name carries. *)
let triple_is_host (triple: string): bool =
  match String.split_on_char '-' triple with
  | arch :: system :: _ ->
     system = Lazy.force host_target && arch = Lazy.force host_arch
  | _ -> false

(* The machine of --target that this run cross-builds for, set by the
   parser when the value of --target is one of target_triples; the empty
   string when --target names a system, or is not given. *)
let cross_triple: string ref = ref ""


(* The cc flags for one library.  A library pkg-config knows by the name
   the module gave it takes pkg-config's flags: on OpenBSD SQLite comes
   from ports and lives in /usr/local, which the base cc does not search, and
   pkg-config answers `-I/usr/local/include -L/usr/local/lib -lsqlite3'.
   A name pkg-config does not know, or a system without pkg-config, gets
   `-lname' as before.  Debian's sqlite3.pc answers `-lsqlite3', so the line
   there does not change.  test-programs/runner.py applies the same rule to
   the same manifest; the two must not differ.
   When pkg-config does not know the name, it is asked for
   `lib<name>' as well.  A library's file name and its pkg-config name
   differ for PCRE2 (`-lpcre2-8', `libpcre2-8.pc') and for libtls on Debian
   (`-ltls', `libtls.pc'); on OpenBSD `-lpcre2-8' alone does not find
   /usr/local/lib, pkg-config's `libpcre2-8' does. *)
let library_flags (name: string): string list =
  (* pkg-config of the host answers for the host's C library and its
     search paths.  For a machine of --target of another system nothing is
     asked: the flags it gives are wrong there, and the library is linked
     plain, which fails at the link when the target's sysroot does not
     carry it. *)
  if !cross_triple <> "" && not (triple_is_host !cross_triple) then [ "-l" ^ name ]
  else
    let ask (args: string array): command_output option =
      try Some (run_command (Array.append [| "pkg-config" |] args))
      with Unix_error _ -> None
    in
  let plain = [ "-l" ^ name ] in
  let flags_of (known: string): string list option =
    match ask [| "--exists"; known |] with
    | Some (CommandOutput { code = 0; _ }) ->
       (match ask [| "--cflags"; "--libs"; known |] with
        | Some (CommandOutput { code = 0; stdout; _ }) ->
           (match List.filter (fun s -> s <> "")
                    (String.split_on_char ' ' (String.map (fun c -> if c = '\n' || c = '\t' then ' ' else c) stdout)) with
            | [] -> None
            | flags -> Some flags)
        | _ -> None)
    | _ -> None
  in
  match flags_of name with
  | Some flags -> flags
  | None ->
     (match flags_of ("lib" ^ name) with
      | Some flags -> flags
      | None -> plain)

let programme_flags: string list = [ "-O2"; "-fno-strict-aliasing" ]

(* The first file of that name in a directory of PATH, or None. *)
let find_on_path (name: string): string option =
  let path: string = match Sys.getenv_opt "PATH" with Some p -> p | None -> "" in
  List.find_map
    (fun dir ->
      let candidate: string = Filename.concat dir name in
      if dir <> "" && Sys.file_exists candidate && not (Sys.is_directory candidate) then
        Some candidate
      else
        None)
    (String.split_on_char ':' path)

(* zig as the C compiler of a cross build: HILDE_ZIG when it is set and not
   empty, else zig from PATH.  None when there is none.  Its version is not
   asked here: the gate holds it to scripts/zig-version.txt.  Looked up
   each time, so a zig put on PATH after the first build of a run is
   found too. *)
let zig_cc (): string list option =
  let z: string option =
    match Sys.getenv_opt "HILDE_ZIG" with
    | Some z when String.length z > 0 -> Some z
    | _ -> find_on_path "zig"
  in
  match z with
  | Some z -> Some [z; "cc"]
  | None -> None

(* The C compiler of this run as the first words of its command line: zig
   cc -target <machine> when a machine of --target is set and zig is there,
   else the native cc.  A machine of another system without zig is refused
   by the parser before this is called, so what falls through to the native
   cc is the host's own machine. *)
let cc_command (): string list =
  if !cross_triple = "" then ["cc"]
  else
    match zig_cc () with
    | Some zig -> zig @ ["-target"; !cross_triple]
    | None -> ["cc"]

let compile_c_code ?(extra_flags: string list = []) (source_path: string) (output_path: string) (libraries: string list): command_output =
  let libs = Array.of_list (List.concat_map library_flags libraries) in
  let o = run_command (Array.concat [
                           Array.of_list (cc_command () @ [ "-std=c17"; "-Wall"; "-Wextra" ]);
                           Array.of_list extra_flags;
                           [| source_path |];
                           libs;
                           [| "-o"; output_path |] ]) in
  let (CommandOutput { command; code; stdout; stderr }) = o in
  if code <> 0 then
    Errors.c_compiler_error ~command ~exit_code:code ~stdout ~stderr ()
  else
    o

(* A library from one C file, both kinds with -fPIC.
   shared: compiled and linked with -shared and -fvisibility=hidden, so that
   the shared object shows the exported functions and the runtime's three,
   which say default visibility themselves, and hides the rest; the
   libraries are linked into it.
   static: compiled with -c into an object in the temporary directory, from
   which ar(1) makes the archive, after a stale archive of the same name is
   removed (ar would add to it); the object is removed whether or not that
   worked.  An archive cannot carry libraries: they stand in the header,
   and only the -I and -D of pkg-config's answer are passed to the
   compilation. *)
let compile_library ~(shared: bool) (source_path: string) (output_path: string) (libraries: string list): unit =
  let check ?tool (o: command_output): unit =
    let (CommandOutput { command; code; stdout; stderr }) = o in
    if code <> 0 then
      Errors.c_compiler_error ?tool ~command ~exit_code:code ~stdout ~stderr ()
  in
  let flags = List.concat_map library_flags libraries in
  let base = Array.of_list (cc_command () @ [ "-std=c17"; "-Wall"; "-Wextra"; "-fPIC" ]) in
  if shared then
    check (run_command (Array.concat [
                            base;
                            [| "-shared"; "-fvisibility=hidden"; source_path |];
                            Array.of_list flags;
                            [| "-o"; output_path |] ]))
  else
    let compile_flags =
      List.filter (fun f -> String.length f > 2 && (String.sub f 0 2 = "-I" || String.sub f 0 2 = "-D")) flags
    in
    let object_path: string = Filename.temp_file "hilde_" ".o" in
    Fun.protect
      ~finally:(fun () -> if Sys.file_exists object_path then Sys.remove object_path)
      (fun () ->
        check (run_command (Array.concat [
                                base;
                                Array.of_list compile_flags;
                                [| "-c"; source_path; "-o"; object_path |] ]));
        if Sys.file_exists output_path then Sys.remove output_path;
        check ~tool:"the archiver ar" (run_command [| "ar"; "rcs"; output_path; object_path |]))

(* The flags that give clang the C library of WASI: a sysroot from
   WASI_SYSROOT or one of the two places wasi-sdk and its packages use, or
   none at all where Debian's wasi-libc lies in the paths clang searches for
   the target already.  None when there is no C library of WASI. *)
let wasi_sysroot_flags (): string list option =
  let given: string list =
    match Sys.getenv_opt "WASI_SYSROOT" with
    | Some s when s <> "" -> [s]
    | _ -> []
  in
  let candidates: string list = given @ ["/usr/share/wasi-sysroot"; "/opt/wasi-sdk/share/wasi-sysroot"] in
  match List.find_opt (fun d -> Sys.file_exists (Filename.concat d "include")) candidates with
  | Some dir -> Some ["--sysroot=" ^ dir]
  | None ->
     (* Debian's clang searches /usr/include after the headers of WASI, where
        the headers of the host's own C library are: it is kept to the
        headers of WASI and its own. *)
     if Sys.file_exists "/usr/include/wasm32-wasi/stdio.h" then
       Some ["-nostdlibinc"; "-isystem"; "/usr/include/wasm32-wasi"]
     else
       None

(* The compiler for wasm32-wasi, as the first words of its command line.
   zig is HILDE_ZIG when it is set and not empty, else zig from PATH; it
   brings the C library of WASI itself.  clang needs wasm-ld on PATH and the
   C library of WASI.  HILDE_WASM_CC=zig or clang takes that one or fails;
   without it zig is taken when it is there, else clang.  Looked for once. *)
let wasm_compiler: string list Lazy.t =
  lazy (
    (* zig is taken as CMake's find_program with a version takes a tool: it
       is looked for, asked for its version, and passed over when that is
       not the version the gates pin, BuiltInModules.zig_version. *)
    let zig (): string list option =
      let z: string option =
        match Sys.getenv_opt "HILDE_ZIG" with
        | Some z when String.length z > 0 -> Some z
        | _ -> find_on_path "zig"
      in
      match z with
      | None -> None
      | Some z ->
         let o = run_command [| z; "version" |] in
         let (CommandOutput { code; stdout; _ }) = o in
         let found = String.trim stdout in
         if code = 0 && found = BuiltInModules.zig_version then Some [z; "cc"; "-target"; "wasm32-wasi"]
         else begin
           zig_passed_over := Some (z, (if code = 0 then found else "unknown"));
           None
         end
    in
    let clang (): string list option =
      match (find_on_path "clang", find_on_path "wasm-ld", wasi_sysroot_flags ()) with
      | (Some c, Some _, Some flags) -> Some (c :: "--target=wasm32-wasi" :: flags)
      | _ -> None
    in
    match Sys.getenv_opt "HILDE_WASM_CC" with
    | Some "zig" -> (match zig () with Some cc -> cc | None -> Errors.no_wasm_compiler (Some "zig"))
    | Some "clang" -> (match clang () with Some cc -> cc | None -> Errors.no_wasm_compiler (Some "clang"))
    | Some name when name <> "" -> Errors.unknown_wasm_compiler name
    | _ ->
       (match zig () with
        | Some cc -> cc
        | None ->
           (match clang () with
            | Some cc -> cc
            | None -> Errors.no_wasm_compiler None)))

(* A module for wasm32-wasi from one C file.  A reactor is a module without
   main whose host calls its functions and keeps its state between the
   calls: a library, which exports the runtime's three functions and the two
   that give the host memory in the module for what it passes.  A command
   is a programme with main, which wasmtime runs as it runs a binary.  Both
   export the functions named.  The four emulation libraries of WASI's C
   library are linked for mmap, signals, the clocks of the process and
   getpid, which lib/prelude/internal.h asks for under __wasi__.  A C library cannot
   be linked for WebAssembly, and one named fails in the link with the
   linker's message. *)
let compile_wasm_module ~(reactor: bool) (source_path: string) (output_path: string) (exports: string list) (libraries: string list): unit =
  let cc: string list = Lazy.force wasm_compiler in
  let runtime: string list =
    if reactor then
      ["hilde_start"; "hilde_end"; "hilde_set_abort_handler"; "hilde_wasm_alloc"; "hilde_wasm_free"]
    else
      []
  in
  let export_flags = List.map (fun name -> "-Wl,--export=" ^ name) (runtime @ exports) in
  let o = run_command (Array.of_list (List.concat [
                          cc;
                          (if reactor then ["-mexec-model=reactor"] else []);
                          ["-std=c17"; "-Wall"; "-Wextra"; "-O2"; source_path];
                          List.map (fun l -> "-l" ^ l) libraries;
                          ["-lwasi-emulated-mman"; "-lwasi-emulated-signal";
                           "-lwasi-emulated-process-clocks"; "-lwasi-emulated-getpid"];
                          (* The stack of the module, 8 MiB as a thread of a
                             programme has on Linux; the linkers' own sizes
                             differ, and a deep recursion that holds natively
                             trapped with the smaller one. *)
                          ["-Wl,-z,stack-size=8388608"];
                          export_flags;
                          ["-o"; output_path] ])) in
  let (CommandOutput { command; code; stdout; stderr }) = o in
  if code <> 0 then
    Errors.c_compiler_error ~tool:"the compiler for wasm32-wasi" ~command ~exit_code:code ~stdout ~stderr ()

let compile_wasm (source_path: string) (output_path: string) (exports: string list) (libraries: string list): unit =
  compile_wasm_module ~reactor:true source_path output_path exports libraries

(* wasmtime, HILDE_WASMTIME when it is set and not empty, else from PATH.
   Looked for once. *)
let wasm_runtime: string Lazy.t =
  lazy (
    match Sys.getenv_opt "HILDE_WASMTIME" with
    | Some w when String.length w > 0 -> w
    | _ ->
       (match find_on_path "wasmtime" with
        | Some w -> w
        | None -> Errors.no_wasm_runtime ()))

(* The command line that runs a command module in wasmtime with [dir] as its
   working directory, the same directory under its own path, so that a path
   below it written out whole is found, and /tmp beside it, every variable
   of this process's
   environment passed on, and [args] after the module.  WASI gives a module
   no directory and no variable it is not handed. *)
let wasm_run_argv (dir: string) (module_path: string) (args: string list): string list =
  let env: string list =
    List.concat_map (fun binding -> ["--env"; binding]) (Array.to_list (Unix.environment ()))
  in
  [Lazy.force wasm_runtime; "run"; "--dir=" ^ dir ^ "::."; "--dir=" ^ dir; "--dir=/tmp"] @ env @ [module_path] @ args

(* The line wasmtime writes to standard error when a module traps, which
   starts its own report of the trap. *)
let wasm_trap_marker: string = "Error: failed to run main module"

let rec map_with_context (f: ('c * 'a) -> ('c * 'b)) (ctx: 'c) (list: 'a list): ('c * ('b list)) =
  match list with
  | first::rest ->
     let (ctx', b) = f (ctx, first) in
     let (ctx'', rest') = map_with_context f ctx' rest in
     (ctx'', b :: rest')
  | [] ->
     (ctx, [])

let rec iter_with_context (f: ('c -> 'a -> 'c)) (ctx: 'c) (list: 'a list): 'c =
  match list with
  | first::rest ->
     let ctx' = f ctx first in
     iter_with_context f ctx' rest
  | [] ->
     ctx

let last (lst: 'a list): 'a =
  let lst: 'a list = List.rev lst in
  match lst with
  | first::_ ->
     first
  | [] ->
     internal_err "Util.last called with an empty list."

(* The rest of the reversed list is turned back.  Returned reversed, it
   made Fn[A, B, R] a function of a B and an A. *)
let butlast (lst: 'a list): 'a list =
  let lst: 'a list = List.rev lst in
  match lst with
  | _::rest ->
     List.rev rest
  | [] ->
     internal_err "Util.butlast called with an empty list."
