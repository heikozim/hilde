(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)
open Identifier
open Id
open Common
open Env
open BuiltIn
open BuiltInModules
open ParserInterface
open CombiningPass
open ExtractionPass
open TypingPass
open BodyExtractionPass
open CodeGen
open CRenderer
open CRepr
open Cst
open CstUtil
open Stages.Tast
open Error
open Stages
open Linked
open Mtast
open Monomorphize
open LinearityCheck
open Reporter
open Entrypoint
open ExportInstantiation
open HtmlError

module Errors = struct
  let unsafe_module_forbidden ~name ~path =
    hilde_raise (H 2010) DeclarationError [
      Text "The module ";
      Code (mod_name_string name);
      Text " is unsafe, and this compilation was run with ";
      Code "--forbid-unsafe-modules";
      Text ".";
      Break;
      Text "It is ";
      Code path;
      Text ", and it carries ";
      Code "pragma Unsafe_Module;";
      Text ", which is what lets a module hold a foreign function, an ";
      Code "@embed";
      Text ", or an import from ";
      Code "Hilde.Memory";
      Text ".";
      Break;
      Text ("The modules that ship with the compiler are exempt; this "
            ^ "applies to the modules named on the command line.")
    ]

  let wrong_test_form (name: identifier) =
    hilde_raise (H 2046) DeclarationError [
      Text "The function ";
      Code (ident_string name);
      Text " has the name of a test, and a test has one of two forms:";
      Break;
      Code "function testName(): Unit";
      Text ", or, for a test that needs the root capability, ";
      Code "generic [R: Region] function testName(root: &![RootCapability, R]): Unit";
      Text ".";
      Break;
      Text ("In a test file every function whose name is test followed by "
            ^ "a capital letter or a digit is a test.")
    ]

  let test_with_requires (name: identifier) =
    hilde_raise (H 2056) DeclarationError [
      Text "The test ";
      Code (ident_string name);
      Text " has a requires.";
      Break;
      Text "A violated requires names the call that broke it, and a test is called by hilde test, not by a call in the programme.  Check the condition in the test's body instead."
    ]

  let no_tests (path: string) =
    hilde_raise (H 2047) DeclarationError [
      Text "The test file ";
      Code path;
      Text " holds no test.";
      Break;
      Text "A test is a function whose name is test followed by a capital letter or a digit, such as ";
      Code "testLength";
      Text "."
    ]
end

let append_import_to_interface (ci: concrete_module_interface) (import: concrete_import_list): concrete_module_interface =
  let (ConcreteModuleInterface (mn, docstring, imports, decls)) = ci in
  if equal_module_name mn pervasive_module_name then
    ci
  else
    ConcreteModuleInterface (mn, docstring, import :: imports, decls)

let append_import_to_body (cb: concrete_module_body) (import: concrete_import_list): concrete_module_body =
  let (ConcreteModuleBody (mn, kind, libraries, docstring, imports, decls)) = cb in
  if equal_module_name mn pervasive_module_name then
    cb
  else
    ConcreteModuleBody (mn, kind, libraries, docstring, import :: imports, decls)

(* `libraries' is the C libraries the modules compiled so far have named with
   `pragma Foreign_Library', in the order the modules were reached and
   deduplicated by name keeping the FIRST occurrence.  Keeping the first
   rather than the last is what makes the rule useful for a static archive: a
   library a module needs early stays early.

   `headers' is the same for `pragma Foreign_Header', and `foreign_names'
   the C names of every function imported with `pragma Foreign_Import', both
   collected so that the header block after the prelude can be written once
   the whole program is known.  `code' is the C of the modules; the
   prelude and the header block are put in front of it by `compiler_code'.
   `monos' is the monomorphic code of every module compiled so far, the last
   first, which hilde guard reads.  `parts' is the C of every module again,
   one part each, the last first, for a programme built in parts; `tail'
   the C that follows the modules in `code': the wrappers, the slots and
   the entry point. *)
type compiler = Compiler of {
    env: env;
    code: string;
    libraries: string list;
    headers: string list;
    foreign_names: string list;
    monos: mono_module list;
    parts: part list;
    tail: string;
  }

(* The C of one module: the unit itself, the unit as the declarations the
   modules after it read, and the headers, foreign names and libraries of
   the modules compiled up to it, with the files of its source. *)
and part = Part of {
    part_name: string;
    part_code: string;
    part_declarations: string;
    part_headers: string list;
    part_foreign_names: string list;
    part_libraries: string list;
    part_sources: (string * string) list;
  }

type translation_unit = {
    unit_name: string;
    unit_text: string;
    unit_sources: (string * string) list;
    unit_libraries: string list;
  }

(** Extract the env from the compiler. *)
let cenv (Compiler { env; _ }): env = env

let compiler_libraries (Compiler { libraries; _ }): string list = libraries

(* Append the names that are not there yet, keeping the order of both lists. *)
let add_libraries (have: string list) (fresh: string list): string list =
  List.fold_left
    (fun acc l -> if List.mem l acc then acc else acc @ [l])
    have fresh

(* The headers modules name, included right after the prelude and
   before any module's C.  While they are read, every function the program
   imports through `pragma Foreign_Import', and every name the prelude
   declares itself, is renamed by a #define, so that a header's declaration
   of it is a declaration of another name: this file declares those names
   itself, with its own types, and next to the header's declaration that is
   a conflicting-types ERROR (the reason lib/prelude/internal.h gives for not
   including <stdio.h>).  What the header leaves behind that matters -- its
   macros -- is untouched.  A program that names no header gets nothing
   here, and its C is the same byte for byte as before. *)
(* The names lib/prelude declares itself, inside the functions that use
   them -- `putchar', `calloc', OpenBSD's `__stdout' as a `char[]' --
   which a header's own declarations meet exactly as they meet a foreign
   function's (gcc 14.2.0: "conflicting types for 'stdout'", once
   <openssl/evp.h> brings <stdio.h>).  Read from the
   prelude's text and not listed: every line that starts with a blank and
   then `extern', and the identifier before the first `(', `[' or `;' on it.
   A declaration added to the prelude cannot be missed here that way
   (TEST-012).  glibc's stdin, stdout and stderr are no longer among them:
   <stdio.h> follows their declarations with `#define stdout stdout', which
   undid their renaming, so the prelude reaches them under names of its own
   at file scope. *)
let prelude_declared_names: string list Lazy.t =
  lazy (
    let ident_char c =
      (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_'
    in
    let name_of (line: string): string option =
      let starts_blank = String.length line > 0 && (line.[0] = ' ' || line.[0] = '\t') in
      let t = String.trim line in
      if starts_blank && String.length t > 7 && String.sub t 0 7 = "extern " then
        let stop =
          List.fold_left
            (fun acc c -> match String.index_opt t c with
                          | Some i -> (match acc with Some j -> Some (min i j) | None -> Some i)
                          | None -> acc)
            None ['('; '['; ';']
        in
        match stop with
        | None -> None
        | Some i ->
           let before = String.trim (String.sub t 0 i) in
           let n = String.length before in
           let rec back k = if k > 0 && ident_char before.[k - 1] then back (k - 1) else k in
           let k = back n in
           if k < n then Some (String.sub before k (n - k)) else None
      else
        None
    in
    let whole = prelude_internal_h ^ String.concat "" (List.map (fun (_, text, _, _) -> text) prelude_parts) in
    add_libraries [] (List.filter_map name_of (String.split_on_char '\n' whole)))

let header_block (headers: string list) (foreign: string list): string =
  match headers with
  | [] -> ""
  | _ ->
     let names = add_libraries (Lazy.force prelude_declared_names) foreign in
     let hidden n = "hilde_foreign_header_" ^ n in
     "\n/* pragma Foreign_Header: the headers are read for their\n"
     ^ "   macros; every name the prelude declares itself and every function\n"
     ^ "   imported through pragma Foreign_Import is renamed while they are\n"
     ^ "   read, so that a declaration there cannot meet the one this file\n"
     ^ "   makes with its own types. */\n"
     ^ String.concat "" (List.map (fun n -> "#define " ^ n ^ " " ^ hidden n ^ "\n") names)
     ^ String.concat "" (List.map (fun h -> "#include <" ^ h ^ ">\n") headers)
     ^ String.concat "" (List.map (fun n -> "#undef " ^ n ^ "\n") names)

(* Every identifier of text that begins with hilde_, each once. *)
let hilde_names (text: string): (string, unit) Hashtbl.t =
  let names = Hashtbl.create 256 in
  let n = String.length text in
  let ident_char c =
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_'
  in
  let rec scan i =
    if i < n then
      if ident_char text.[i] then begin
        let j = ref i in
        while !j < n && ident_char text.[!j] do incr j done;
        if !j - i > 6 && String.sub text i 6 = "hilde_" then
          Hashtbl.replace names (String.sub text i (!j - i)) ();
        scan !j
      end else
        scan (i + 1)
  in
  scan 0;
  names

(* The parts of the runtime prelude in lib/prelude that a programme
   carries, in the order of BuiltInModules.prelude_parts.  core.c and
   task-none.c always; library.c in a library; task.c when the programme
   compiles Bindings.Task, so that Standard.Task always meets the real
   runtime; every part one of whose own names the programme's C names, the
   way a binding or an @embed calls into the runtime; and, again and again,
   every part one of those needs.  text is the C that follows the prelude. *)
let prelude_parts_of ~(library: bool) ~(tasks: bool) (text: string): string list =
  let named = hilde_names text in
  let wanted = Hashtbl.create 16 in
  List.iter (fun p -> Hashtbl.replace wanted p ()) ["core"; "task-none"];
  if library then Hashtbl.replace wanted "library" ();
  if tasks then Hashtbl.replace wanted "task" ();
  List.iter
    (fun (part, _, triggers, _) ->
      if List.exists (fun t -> Hashtbl.mem named t) triggers then Hashtbl.replace wanted part ())
    prelude_parts;
  let rec close () =
    let before = Hashtbl.length wanted in
    List.iter
      (fun (part, _, _, needs) ->
        if Hashtbl.mem wanted part then List.iter (fun q -> Hashtbl.replace wanted q ()) needs)
      prelude_parts;
    if Hashtbl.length wanted > before then close ()
  in
  close ();
  List.filter_map (fun (part, _, _, _) -> if Hashtbl.mem wanted part then Some part else None) prelude_parts

(* The prelude made of the named parts: internal.h, then each part after a
   line that names it. *)
let prelude_text (parts: string list): string =
  prelude_internal_h
  ^ String.concat ""
      (List.filter_map
         (fun (part, text, _, _) ->
           if List.mem part parts then Some ("\n/* hilde prelude part: " ^ part ^ " */\n" ^ text) else None)
         prelude_parts)

let rec compiler_code ?(library = false) (c: compiler): string =
  let (parts, rest) = prelude_parts_and_rest ~library c in
  prelude_text parts ^ rest

(* The parts of the prelude a programme carries, and the C that follows
   the prelude in its one file. *)
and prelude_parts_and_rest ~(library: bool) (Compiler { env; code; headers; foreign_names; _ }): string list * string =
  (* Only a programme that compiles Bindings.BuildInfo reads the macros,
     so only then does git run. *)
  let build = match get_module_by_name env (make_mod_name "Bindings.BuildInfo") with
    | Some _ -> BuildInfo.c_block ()
    | None -> ""
  in
  (* ML-DSA is close to a megabyte of C; only a programme that compiles
     its binding gets it. *)
  let mldsa = match get_module_by_name env (make_mod_name "Bindings.MlDsa") with
    | Some _ -> "\n" ^ BuiltInModules.mldsa_c
    | None -> ""
  in
  let rest = (header_block headers foreign_names) ^ build ^ mldsa ^ code in
  let tasks = Option.is_some (get_module_by_name env (make_mod_name "Bindings.Task")) in
  (prelude_parts_of ~library ~tasks rest, rest)

(* The prelude of a programme built in parts, made of the parts it
   carries: the text of the prelude's own unit, where the static variables
   that can change are shared, and the declarations the other units read,
   where they are extern. *)
let split_prelude (parts: string list): string * string =
  List.iter
    (fun part ->
      if not (List.exists (fun (known, _, _) -> known = part) prelude_split) then
        invalid_arg ("Compiler.split_prelude: no part " ^ part))
    parts;
  let pick (f: string * string * string -> string): string =
    String.concat ""
      (List.filter_map
         (fun ((part, _, _) as p) ->
           if List.mem part parts then Some ("\n/* hilde prelude part: " ^ part ^ " */\n" ^ f p) else None)
         prelude_split)
  in
  (prelude_internal_shared ^ pick (fun (_, shared, _) -> shared),
   prelude_internal_declarations ^ pick (fun (_, _, declarations) -> declarations))

(* The libraries the C prelude needs whatever the programme imports, first in
   every link manifest.  `pthread': the task runtime runs on N threads
, and on OpenBSD a programme calling pthread_create does not link
   without it ("undefined symbol: pthread_create");
   glibc 2.34 and newer carry the functions in libc and take -lpthread all
   the same. *)
let prelude_libraries: string list = [ "pthread" ]

(* The translation units of a programme built in parts, in the order of
   the link: the whole prelude, its changeable variables shared with the
   other units, one unit for every module, and the tail.
   The unit of a module is the prelude's declarations, the header block of
   the modules up to it, the declarations of the modules before it and its
   own C; the tail sees the declarations of every module.  None for a
   programme of Bindings.BuildInfo or Bindings.MlDsa, whose C stands
   between the header block and the modules, as one file only. *)
let translation_units (c: compiler): translation_unit list option =
  let (Compiler { env; parts; tail; headers; foreign_names; libraries; _ }) = c in
  let present (name: string): bool =
    Option.is_some (get_module_by_name env (make_mod_name name))
  in
  if present "Bindings.BuildInfo" || present "Bindings.MlDsa" then None
  else
    let (prelude_shared, prelude_declarations) = split_prelude (fst (prelude_parts_and_rest ~library:false c)) in
    let prelude = { unit_name = "Hilde.Prelude"; unit_text = prelude_shared; unit_sources = []; unit_libraries = prelude_libraries } in
    let (units, seen) =
      List.fold_left
        (fun (acc, seen) (Part p) ->
          let text = prelude_declarations
                     ^ header_block p.part_headers p.part_foreign_names
                     ^ seen ^ "\n" ^ p.part_code in
          let u = { unit_name = p.part_name; unit_text = text; unit_sources = p.part_sources; unit_libraries = p.part_libraries } in
          (u :: acc, seen ^ "\n" ^ p.part_declarations))
        ([], "") (List.rev parts)
    in
    let last = {
        unit_name = "Hilde.Programme";
        unit_text = prelude_declarations ^ header_block headers foreign_names ^ seen ^ "\n" ^ tail;
        unit_sources = [];
        unit_libraries = libraries;
      }
    in
    Some ((prelude :: List.rev units) @ [last])

(* The head of the link manifest every C file the compiler writes ends with.
   It is a constant because two readers have to agree on it: this file
   writes it, test-programs/runner.py greps for it.  The form is

       /* hilde link libraries: m z */

   with one space before each name, so that a program needing none reads
   `/* hilde link libraries: */' and not a line with two spaces in it.
   Whoever compiles the emitted C is not the compiler and cannot be told the
   libraries any other way; the line is that answer, in one place, in a form
   a caller can read with one `grep'.  It is a comment, so it changes nothing
   about the program, and it is deterministic, so it does not disturb the
   byte-for-byte comparison between platforms.  `hilde compile
   --target-type=c' and `hilde test --emit-c' write it through this one
   function. *)
let link_manifest_prefix: string = "/* hilde link libraries:"

let c_file_text (c: compiler): string =
  let manifest: string =
    link_manifest_prefix
    ^ (List.fold_left (fun acc l -> acc ^ " " ^ l) "" (compiler_libraries c))
    ^ " */\n"
  in
  (compiler_code c) ^ "\n" ^ manifest

(* The C of a library: the programme's C with HILDE_LIBRARY
   defined before the runtime, which switches it to its library behaviour
   -- hilde_start and hilde_end, a check at every wrapper, and a stop that
   calls the host's handler and abort(3) instead of ending the process with
   _Exit. *)
let library_code (c: compiler): string =
  "#define HILDE_LIBRARY 1\n" ^ (compiler_code ~library:true c)

(* The C names a library exports, in the order of its header. *)
let library_export_names (c: compiler): string list =
  ExportInstantiation.export_names (cenv c)

(* The header of a library, named file_name, beside it. *)
let library_header_text (c: compiler) (file_name: string): string =
  library_header (cenv c) file_name (compiler_libraries c)

(* The C names of the foreign functions of a monomorphized module, in the
   order they are declared. *)
let foreign_function_names (MonoModule (_, decls)): string list =
  List.filter_map
    (fun d -> match d with MForeignFunction (_, _, _, _, underlying) -> Some underlying | _ -> None)
    decls

let body_foreign_c (cb: concrete_module_body): foreign_c =
  let (ConcreteModuleBody (_, _, foreign, _, _, _)) = cb in
  foreign

type module_source =
  | TwoFileModuleSource of {
      int_filename: string;
      int_code: string;
      body_filename: string;
      body_code: string
    }
  | BodyModuleSource of {
      body_filename: string;
      body_code: string
    }

let parse_and_combine (env: env) (source: module_source): (env * module_name * Combined.combined_module * file_id option * file_id * foreign_c) =
  match source with
  | TwoFileModuleSource { int_filename; int_code; body_filename; body_code } ->
     let (env, int_file_id) = add_file env { path = int_filename; contents = int_code } in
     let (env, body_file_id) = add_file env { path = body_filename; contents = body_code } in
     let ci: concrete_module_interface = parse_module_int int_code int_filename in
     let name: module_name = mod_int_name ci in
     adorn_error_with_module_name name
       (fun _ ->
         ImportResolution.check_library_targets name;
         let cb: concrete_module_body = parse_module_body body_code body_filename in
         let ci: concrete_module_interface = append_import_to_interface ci pervasive_imports
         and cb: concrete_module_body = append_import_to_body cb pervasive_imports in
         let combined: Combined.combined_module = combine env ci cb in
         (env, name, combined, Some int_file_id, body_file_id, body_foreign_c cb))
  | BodyModuleSource { body_filename; body_code } ->
     let (env, body_file_id) = add_file env { path = body_filename; contents = body_code } in
     let cb: concrete_module_body = parse_module_body body_code body_filename in
     let name: module_name = mod_body_name cb in
     adorn_error_with_module_name name
       (fun _ ->
         let cb: concrete_module_body = append_import_to_body cb pervasive_imports in
         let combined: Combined.combined_module = body_as_combined env cb in
         (env, name, combined, None, body_file_id, body_foreign_c cb))

(* emit false is hilde check: the module is parsed, typed, its contracts
   and its linearity checked, its bodies put into the environment and
   monomorphised, and nothing is written as C.  The monomorphiser makes
   checks of its own on the instantiated types, the argument of a task
   among them, so a module check passes is one compile takes. *)
let rec compile_mod ?(emit: bool = true) (c: compiler) (source: module_source): compiler =
  with_frame "Compile module"
    (fun _ ->
      let env: env = cenv c in
      let (env, name, combined, int_file_id, body_file_id, foreign) = parse_and_combine env source in
      adorn_error_with_module_name name
        (fun _ ->
          let combined: SmallCombined.combined_module = DesugaringPass.desugar combined in
          let (env, linked): (env * linked_module) = extract env combined int_file_id body_file_id in
          let typed: typed_module = augment_module env linked in
          (* Every function ends, and Never stands only where it may. *)
          let _ = NeverCheck.check_module typed in
          (* A condition only reads.  Checked before the linearity
             check, whose message about a consumed value would name the
             statement the contract was made into rather than the contract;
             with this module's bodies in the environment, since a condition
             may call a function of its own module. *)
          let _ = Contracts.check_module (extract_bodies env typed) typed in
          let _ = check_module_linearity typed in
          (* hilde check gathers the names a body never reads and the names
             that break the case convention. *)
          if not emit then
            UnusedCheck.record (UnusedCheck.findings typed @ NamingCheck.findings typed);
          let env: env = extract_bodies env typed in
          if not emit then
            let (env, _): (env * mono_module) = monomorphize env typed in
            let (Compiler prev) = c in
            let libraries = add_libraries prev.libraries foreign.c_libraries in
            refuse_both_sqlites name libraries;
            Compiler { prev with env; libraries; headers = add_libraries prev.headers foreign.c_headers }
          else
          let (env, mono): (env * mono_module) = monomorphize env typed in
          let unit: c_unit = gen_module env mono in
          let unit_code: string = render_unit unit in
          let (Compiler prev) = c in
          let libraries = add_libraries prev.libraries foreign.c_libraries in
          refuse_both_sqlites name libraries;
          let headers = add_libraries prev.headers foreign.c_headers in
          let foreign_names = add_libraries prev.foreign_names (foreign_function_names mono) in
          let part = Part {
              part_name = mod_name_string name;
              part_code = unit_code;
              part_declarations = render_unit_declarations unit;
              part_headers = headers;
              part_foreign_names = foreign_names;
              part_libraries = libraries;
              part_sources = source_files source;
            }
          in
          Compiler {
              env;
              code = prev.code ^ "\n" ^ unit_code;
              libraries;
              headers;
              foreign_names;
              monos = mono :: prev.monos;
              parts = part :: prev.parts;
              tail = prev.tail;
            }))

(* The names and texts of the files of a module. *)
and source_files (source: module_source): (string * string) list =
  match source with
  | TwoFileModuleSource { int_filename; int_code; body_filename; body_code } ->
     [(int_filename, int_code); (body_filename, body_code)]
  | BodyModuleSource { body_filename; body_code } ->
     [(body_filename, body_code)]

(* SQLite and SQLCipher export the same sqlite3_* symbols, so a link against
   both takes each function from whichever comes first.  The import chooses;
   importing both is refused where every module's libraries meet, the module
   that brought the second one named. *)
and refuse_both_sqlites (name: module_name) (libraries: string list): unit =
  if List.mem "sqlite3" libraries && List.mem "sqlcipher" libraries then
    hilde_raise (H 2044) DeclarationError [
        Text "This programme links both ";
        Code "sqlite3";
        Text " and ";
        Code "sqlcipher";
        Text ", which export the same functions.";
        Break;
        Text "Import ";
        Code "Standard.Sqlite";
        Text " or ";
        Code "Standard.SqlCipher";
        Text ", not both.  The module that brought the second one is ";
        Code (mod_name_string name);
        Text "."
      ]

(* --- The order the modules are compiled in ---------------------------------

   A module has to be compiled after every module it imports from, and until
   now that order was the caller's to get right: the command line was folded
   over in the order it was written, and a wrong order failed to compile with
   an error about a name the compiler had not seen yet.  Nothing anywhere
   said so -- not the help text, not a message.

   The order is now computed from the imports.  Two properties of the
   computation are deliberate:

   * It is STABLE.  Among modules that do not depend on each other the given
     order is kept, so every command line that worked before builds the same
     thing in the same sequence, and the emitted C does not move.
   * It never fails.  A module head that does not parse, a cycle, an import
     of a module that is not on the command line -- each of those leaves the
     order as it was given, and the real compilation below reports it in its
     own words.  Ordering is not the place to invent a second set of error
     messages for the same defects (TEST-012).

   The heads are read with the ordinary parser rather than with a second,
   smaller reader of imports: two readers of one syntax drift apart, and the
   one used less is the one that is wrong. *)

type module_head = {
    head_name: module_name;
    head_kind: module_kind;
    head_imports: module_name list;
    head_libraries: string list;
  }

let import_names (imports: concrete_import_list list): module_name list =
  List.map (fun (ConcreteImportList (mn, _)) -> mn) imports

let read_module_head_raising (source: module_source): module_head =
  match source with
  | TwoFileModuleSource { int_filename; int_code; body_filename; body_code } ->
     let ci = parse_module_int int_code int_filename in
     let cb = parse_module_body body_code body_filename in
     let (ConcreteModuleInterface (_, _, int_imports, _)) = ci in
     let (ConcreteModuleBody (_, kind, { c_libraries; _ }, _, body_imports, _)) = cb in
     { head_name = mod_int_name ci;
       head_kind = kind;
       head_imports = (import_names int_imports) @ (import_names body_imports);
       head_libraries = c_libraries }
  | BodyModuleSource { body_filename; body_code } ->
     let cb = parse_module_body body_code body_filename in
     let (ConcreteModuleBody (_, kind, { c_libraries; _ }, _, body_imports, _)) = cb in
     { head_name = mod_body_name cb;
       head_kind = kind;
       head_imports = import_names body_imports;
       head_libraries = c_libraries }

let read_module_head (source: module_source): module_head option =
  try Some (read_module_head_raising source) with _ -> None

(* `hilde test' finds the modules a test file needs by
   their names before it compiles anything, so it reads every head it is
   given; a head that does not parse is reported as the compilation would
   report it. *)
let rec module_name_and_imports (source: module_source): module_name * module_name list =
  match quick_head source with
  | Some head -> head
  | None ->
     let head = read_module_head_raising source in
     (head.head_name, head.head_imports)

(* The name and imports of a module from its tokens up to the module line,
   without parsing the rest: a search of a directory reads every module's
   head, and parsing every module whole took most of the time of a check.
   None when the tokens are not of the expected form; the caller then
   parses the module and reports what is wrong as the compilation would. *)
and quick_head (source: module_source): (module_name * module_name list) option =
  let read (code: string) (filename: string): (module_name * module_name list) option =
    let lexbuf = Lexing.from_string code in
    Lexing.set_filename lexbuf filename;
    let next () = Lexer.token lexbuf in
    let rec dotted (acc: string list) (t: Parser.token): (string list * Parser.token) option =
      match t with
      | Parser.IDENTIFIER s ->
         (match next () with
          | Parser.PERIOD -> dotted (s :: acc) (next ())
          | t' -> Some (List.rev (s :: acc), t'))
      | _ -> None
    in
    let rec skip_to_semi (t: Parser.token): bool =
      match t with
      | Parser.SEMI -> true
      | Parser.EOF -> false
      | _ -> skip_to_semi (next ())
    in
    let rec walk (imports: module_name list) (t: Parser.token): (module_name * module_name list) option =
      match t with
      | Parser.IMPORT ->
         (match dotted [] (next ()) with
          | Some (parts, t') ->
             if skip_to_semi t' then walk (make_mod_name (String.concat "." parts) :: imports) (next ())
             else None
          | None -> None)
      | Parser.MODULE ->
         let t' = next () in
         let t'' = (match t' with Parser.BODY -> next () | _ -> t') in
         (match dotted [] t'' with
          | Some (parts, Parser.IS) -> Some (make_mod_name (String.concat "." parts), List.rev imports)
          | _ -> None)
      | Parser.EOF -> None
      | _ -> walk imports (next ())
    in
    try walk [] (next ()) with _ -> None
  in
  match source with
  | TwoFileModuleSource { int_filename; int_code; body_filename; body_code } ->
     (match (read int_code int_filename, read body_code body_filename) with
      | (Some (name, int_imports), Some (body_name, body_imports)) when equal_module_name name body_name ->
         Some (name, int_imports @ body_imports)
      | _ -> None)
  | BodyModuleSource { body_filename; body_code } ->
     read body_code body_filename

(* Kahn's algorithm, taking at every step the ready module that stood
   earliest in the given list.  `ready' is recomputed rather than kept in a
   queue: the lists here are a command line long. *)
let sort_module_heads (heads: module_head array): int list option =
  let n = Array.length heads in
  let index_of (mn: module_name): int option =
    let found = ref None in
    Array.iteri (fun i h ->
        if !found = None && equal_module_name h.head_name mn then found := Some i)
      heads;
    !found
  in
  let needs = Array.map (fun h -> List.filter_map index_of h.head_imports) heads in
  let done_ = Array.make n false in
  let order = ref [] in
  let placed = ref 0 in
  let progress = ref true in
  while !progress && !placed < n do
    progress := false;
    let i = ref 0 in
    let picked = ref false in
    while not !picked && !i < n do
      if (not done_.(!i))
         && List.for_all (fun d -> d = !i || done_.(d)) needs.(!i) then begin
          done_.(!i) <- true;
          order := !i :: !order;
          incr placed;
          picked := true;
          progress := true
        end;
      incr i
    done
  done;
  if !placed = n then Some (List.rev !order) else None

let sort_modules (modules: module_source list): module_source list =
  let sources = Array.of_list modules in
  let heads = Array.map read_module_head sources in
  if Array.exists (fun h -> h = None) heads then begin
    (* One head could not be read.  Its own parse error is the answer: in
       the order given, a module before it that imports a module after it
       would otherwise be reported as importing an unknown module. *)
    Array.iter (fun s -> ignore (read_module_head_raising s)) sources;
    modules
  end
  else
    let heads = Array.map Option.get heads in
    match sort_module_heads heads with
    | Some order ->
       List.map (fun i -> sources.(i)) order
    | None ->
       (* A cycle among the modules given.  Leave the order alone. *)
       modules

(* --- `--forbid-unsafe-modules' ---------------------------------------------

   An application that wants to say "no unsafe modules" cannot simply refuse
   every module carrying `pragma Unsafe_Module;': Hilde.Pervasive and
   Hilde.Memory carry it themselves, and every module imports
   Hilde.Pervasive implicitly, so such a flag would refuse every program ever
   written.  They are exempted.

   The exemption is by ORIGIN and costs no list of names: the modules that
   ship with the compiler are compiled by `empty_compiler' from sources
   embedded in the binary, and the ones this function is given are the ones
   the caller named.  A built-in never passes through here, so it is never
   refused, and nothing has to be kept in step with a list. *)
let refuse_unsafe_modules (modules: module_source list): unit =
  let check (source: module_source): unit =
    match read_module_head source with
    | Some { head_name; head_kind = UnsafeModule; _ } ->
       let path =
         match source with
         | TwoFileModuleSource { body_filename; _ } -> body_filename
         | BodyModuleSource { body_filename; _ } -> body_filename
       in
       Errors.unsafe_module_forbidden ~name:head_name ~path
    | _ ->
       (* Safe, or a head that does not parse.  An unreadable head is the
          compilation's to report, in its own words, not this check's. *)
       ()
  in
  List.iter check modules

let rec compile_in_order ?(emit: bool = true) c modules =
  match modules with
  | m::rest -> compile_in_order ~emit (compile_mod ~emit c m) rest
  | [] -> c

let compile_multiple c modules =
  Slots.restore_base ();
  Error.reset_further_errors ();
  compile_in_order c (sort_modules modules)

let check_multiple c modules =
  Slots.restore_base ();
  UnusedCheck.reset ();
  Error.reset_further_errors ();
  let c = compile_in_order ~emit:false c (sort_modules modules) in
  Slots.check (cenv c);
  c

let compile_entrypoint c mn i =
  let qi = make_qident (mn, i, i) in
  let (Compiler prev) = c in
  let entry_code: string = entrypoint_code prev.env qi in
  Compiler { prev with code = prev.code ^ "\n" ^ entry_code; tail = prev.tail ^ "\n" ^ entry_code }

let fake_mod_source (is: string) (bs: string): module_source =
  TwoFileModuleSource { int_filename = ""; int_code = is; body_filename = ""; body_code = bs }

let dump_and_die _: 'a =
  Reporter.dump ();
  exit (-1)

let post_compile (compiler: compiler): compiler =
  let env: env = cenv compiler in
  (* The slots of the whole programme, checked and forwarded. *)
  Slots.check env;
  let slot_code: string =
    render_unit (CUnit ("Hilde.Slots", Slots.forwarders ()))
  in
  let (env, decls): env * mdecl list = monomorphize_wrappers env in
  let unit: c_unit = gen_module env (MonoModule (make_mod_name "Hilde.Wrappers", decls)) in
  let unit_code: string = render_unit unit in
  let wrapper_code: string = wrappers_code env in
  let (Compiler prev) = compiler in
  Compiler {
      prev with
      env;
      code = prev.code ^ "\n" ^ unit_code ^ "\n" ^ wrapper_code ^ "\n" ^ slot_code;
      tail = prev.tail ^ "\n" ^ unit_code ^ "\n" ^ wrapper_code ^ "\n" ^ slot_code;
      foreign_names = add_libraries prev.foreign_names
                        (foreign_function_names (MonoModule (make_mod_name "Hilde.Wrappers", decls)));
    }


let () =
  if Sys.getenv_opt "HILDE_PROFILE_TMP" = Some "1" then begin
    let counts : (string, int) Hashtbl.t = Hashtbl.create 1000 in
    let incl : (string, int) Hashtbl.t = Hashtbl.create 1000 in
    let total = ref 0 in
    Sys.set_signal Sys.sigprof (Sys.Signal_handle (fun _ ->
      incr total;
      let cs = Printexc.raw_backtrace_to_string (Printexc.get_callstack 60) in
      let lines = String.split_on_char '\n' cs |> List.filter (fun l -> l <> "") in
      let name l = match String.index_opt l '"' with Some i -> (let j = String.index_from l (i+1) '"' in let f = String.sub l (i+1) (j-i-1) in
        (match String.index_opt l ',' with Some k -> f ^ String.sub l k (min 14 (String.length l - k)) | None -> f)) | None -> l in
      (match lines with _ :: top :: _ -> let n = name top in Hashtbl.replace counts n (1 + Option.value ~default:0 (Hashtbl.find_opt counts n)) | _ -> ());
      let seen = Hashtbl.create 64 in
      List.iter (fun l -> let n = name l in
        if not (Hashtbl.mem seen n) then (Hashtbl.replace seen n (); Hashtbl.replace incl n (1 + Option.value ~default:0 (Hashtbl.find_opt incl n)))) lines));
    ignore (Unix.setitimer Unix.ITIMER_PROF { Unix.it_interval = 0.001; it_value = 0.001 });
    at_exit (fun () ->
      let dump tbl title = 
        let l = Hashtbl.fold (fun k v acc -> (v, k) :: acc) tbl [] |> List.sort compare |> List.rev in
        Printf.eprintf "== %s (samples %d)\n" title !total;
        List.iteri (fun i (v, k) -> if i < 40 then Printf.eprintf "%5d %s\n" v k) l in
      dump counts "self"; dump incl "inclusive by file")
  end

let empty_compiler: compiler =
  with_frame "Compile built-in modules"
    (fun _ ->
      (* We have to compile the Hilde.Pervasive module, followed by
         Hilde.Memory, since the latter uses declarations from the former. *)
      let env: env = empty_env in
      Slots.reset ();
      (* The C prelude is put in front by `compiler_code', with the header
         block after it. *)
      let c = Compiler { env; code = ""; libraries = prelude_libraries; headers = []; foreign_names = []; monos = []; parts = []; tail = "" } in
      let c =
        (* Handle errors during the compilation of the Hilde.Pervasive
           module. Otherwise, a typo in the source code of this module will cause a
           fatal error due to an exception stack overflow (unsure why this
           happens). *)
        try
          compile_mod c (fake_mod_source pervasive_interface_source pervasive_body_source)
        with Hilde_error error ->
          Printf.eprintf "%s" (render_error_to_plain error);
          html_error_dump error;
          dump_and_die ()
      in
      let c =
        try
          compile_mod c (fake_mod_source memory_interface_source memory_body_source)
        with Hilde_error error ->
          Printf.eprintf "%s" (render_error_to_plain error);
          html_error_dump error;
          dump_and_die ()
      in
      (* Hilde.Array, the heap array Standard.Buffer and
         Standard.Box are built on.  After Hilde.Memory, which it uses. *)
      let c =
        try
          compile_mod c (fake_mod_source array_interface_source array_body_source)
        with Hilde_error error ->
          Printf.eprintf "%s" (render_error_to_plain error);
          html_error_dump error;
          dump_and_die ()
      in
      (* The slots of the built-in modules are where every programme starts. *)
      Slots.save_base ();
      c)

(* `hilde query': compile the whole command line as
   `--target-type=tc' does, then describe one module of it -- its
   declarations as parsed, for the places, and the environment as compiled,
   for the types. *)
let query_modules (modules: module_source list) (target: module_name): Yojson.Basic.t =
  let c: compiler = compile_multiple empty_compiler modules in
  let env: env = cenv c in
  let rec find (sources: module_source list): Stages.Combined.combined_module option =
    match sources with
    | [] -> None
    | source :: rest ->
       let (_, name, combined, _, _, _) = parse_and_combine env source in
       if equal_module_name name target then Some combined else find rest
  in
  match find modules with
  | Some combined -> Query.query_module env combined
  | None ->
     hilde_raise (H 1017) CliError [
         Text "The module ";
         Code (mod_name_string target);
         Text " is not on the command line, so there is nothing to query."
       ]

(* hilde guard: compile the whole
   command line as --target-type=tc does, then report the programme's
   attack surface from the monomorphic code of every module, the modules
   built into the compiler included.  The entrypoint, when one is named,
   must be a function of a module on the command line. *)
(* The report and the number of vulnerabilities the programme reaches
; guard_modules is the
   report alone, without a vulnerability check. *)
let rec guard_modules (modules: module_source list) (entry: (module_name * identifier) option): string =
  fst (guard_report modules entry ~vulnerabilities:None)

and guard_report (modules: module_source list) (entry: (module_name * identifier) option)
      ~(vulnerabilities: Guard.vulnerability_check option): string * int =
  let c: compiler = compile_multiple empty_compiler modules in
  let (Compiler { env; monos; libraries; headers; _ }) = c in
  let entry_id: Id.decl_id option =
    match entry with
    | None -> None
    | Some (mn, name) ->
       (match get_decl_by_name env (make_sident mn name) with
        | Some decl -> Some (EnvUtils.decl_id decl)
        | None ->
           hilde_raise (H 1030) CliError [
               Text "The entrypoint ";
               Code (mod_name_string mn ^ ":" ^ ident_string name);
               Text " is not a function of a module on the command line."
             ])
  in
  let path_of (source: module_source): string =
    match source with
    | TwoFileModuleSource { body_filename; _ } -> body_filename
    | BodyModuleSource { body_filename; _ } -> body_filename
  in
  let unsafe: (module_name * string) list =
    List.filter_map
      (fun source ->
        match read_module_head source with
        | Some { head_name; head_kind = UnsafeModule; _ } -> Some (head_name, path_of source)
        | _ -> None)
      modules
  in
  Guard.report env (List.rev monos) ~entry:entry_id ~unsafe ~libraries ~headers ~vulnerabilities

(* hilde guard inside a package: what the modules of each package do that
   it must declare, held against what its hilde.toml declares; the lines
   and the number used undeclared. *)
and guard_capabilities (modules: module_source list) (entry: (module_name * identifier) option)
      ~(packages: Guard.package_rule list): string list * int =
  let c: compiler = compile_multiple empty_compiler modules in
  let (Compiler { env; monos; _ }) = c in
  let entry_id: Id.decl_id option =
    match entry with
    | None -> None
    | Some (mn, name) ->
       (match get_decl_by_name env (make_sident mn name) with
        | Some decl -> Some (EnvUtils.decl_id decl)
        | None -> None)
  in
  (* What the modules on the command line declare: the unsafe ones, and
     those that name a C library with pragma Foreign_Library, each of
     which brings a foreign library into the binary, so its package has
     to declare the ffi capability. *)
  let heads: (module_name * string * string list) list =
    List.filter_map
      (fun source ->
        match read_module_head source with
        | Some { head_name; head_kind; head_libraries; _ } ->
           (match head_kind with
            | UnsafeModule -> Some (head_name, "unsafe", head_libraries)
            | _ -> if head_libraries <> [] then Some (head_name, "", head_libraries) else None)
        | None -> None)
      modules
  in
  let unsafe: (module_name * string) list =
    List.filter_map (fun (m, kind, _) -> if kind = "unsafe" then Some (m, "") else None) heads
  in
  let libraries: (module_name * string list) list =
    List.filter_map (fun (m, _, libs) -> if libs <> [] then Some (m, libs) else None) heads
  in
  Guard.capability_lines env (List.rev monos) ~entry:entry_id ~unsafe ~packages ~libraries

(* `hilde test'.  A function of a test file whose name
   is `test' followed by a capital letter or a digit is a test, and a test
   has one of two forms: no parameter, or the root capability lent to it.
   A function with a test's name in any other form is refused rather than
   skipped: a test that is silently not run looks exactly like one that
   passed. *)
type test_form =
  | TestPlain
  | TestWithRoot

let is_test_name (name: identifier): bool =
  let s: string = ident_string name in
  String.length s > 4
  && String.sub s 0 4 = "test"
  && (match s.[4] with 'A' .. 'Z' | '0' .. '9' -> true | _ -> false)

let test_form_of (decl: EnvTypes.decl): test_form option =
  match decl with
  | EnvTypes.Function { typarams; value_params; rt; _ } ->
     (match (TypeParameters.typarams_as_list typarams, value_params, rt) with
      | ([], [], Type.Unit) ->
         Some TestPlain
      | ([tp],
         [Type.ValueParameter (_, Type.WriteRef (Type.NamedType (q, [], _),
                                                 Type.TyVar (Type.TypeVariable (r, _, _, _))))],
         Type.Unit)
           when Type.equal_universe (TypeParameter.typaram_universe tp) Type.RegionUniverse
                && equal_identifier (TypeParameter.typaram_name tp) r
                && ident_string (original_name q) = "RootCapability"
                && equal_module_name (source_module_name q) pervasive_module_name ->
         Some TestWithRoot
      | _ ->
         None)
  | _ ->
     None

(* The tests of a test file, in the order the file declares them.  The
   compiler must already have compiled the file: the forms are read from the
   environment, which has every type resolved, and the places from the file
   as parsed, which is where the spans live. *)
let test_functions (c: compiler) (source: module_source): module_name * (identifier * test_form) list =
  let env: env = cenv c in
  let (_, name, combined, _, _, _) = parse_and_combine env source in
  let (Combined.CombinedModule { decls; _ }) = combined in
  let path: string =
    match source with
    | TwoFileModuleSource { body_filename; _ } -> body_filename
    | BodyModuleSource { body_filename; _ } -> body_filename
  in
  adorn_error_with_module_name name
    (fun _ ->
      let tests =
        List.filter_map
          (fun d ->
            match d with
            | Combined.CFunction (span, _, fname, _, _, _, _, _, _, _) when is_test_name fname ->
               let form =
                 match get_decl_by_name env (make_sident name fname) with
                 | Some (EnvTypes.Function { value_params; _ } as decl) ->
                    (* The call site a requires adds as the last
                       parameter; no test form has it. *)
                    (match List.rev value_params with
                     | (Type.ValueParameter (n, _)) :: _
                          when String.equal (ident_string n) Names.contract_site_param ->
                        adorn_error_with_span span (fun _ -> Errors.test_with_requires fname)
                     | _ -> test_form_of decl)
                 | Some decl -> test_form_of decl
                 | None -> internal_err ("test: " ^ (ident_string fname) ^ " is not in the environment")
               in
               (match form with
                | Some form -> Some (fname, form)
                | None -> adorn_error_with_span span (fun _ -> Errors.wrong_test_form fname))
            | _ ->
               None)
          decls
      in
      match tests with
      | [] -> Errors.no_tests path
      | _ -> (name, tests))
