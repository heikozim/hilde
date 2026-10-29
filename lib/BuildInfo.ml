(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* What a programme learns about its own build through Standard.BuildInfo:
   the commit and whether the work tree differed from it, the time of the
   build, the compiler's version, and the values given with --build-value.
   The C macros below are written only into a programme that compiles
   Bindings.BuildInfo, so git runs only for such a programme. *)

open Error
open ErrorText

let values: (string * string) list ref = ref []
let vcs: bool ref = ref true

(* A name starts with a letter and holds letters, digits, '_', '.' and '-',
   at most 64 bytes; a value is printable ASCII, at most 1024 bytes. *)
let valid_name (s: string): bool =
  let n = String.length s in
  n >= 1 && n <= 64
  && (match s.[0] with 'A'..'Z' | 'a'..'z' -> true | _ -> false)
  && String.for_all (fun c -> match c with
       | 'A'..'Z' | 'a'..'z' | '0'..'9' | '_' | '.' | '-' -> true
       | _ -> false) s

let valid_value (s: string): bool =
  String.length s <= 1024 && String.for_all (fun c -> c >= ' ' && c <= '~') s

let build_value_refused (arg: string) (why: string) =
  hilde_raise (H 1035) CliError [
      Text "The build value ";
      Code arg;
      Text " is refused: ";
      Text why;
      Text ".";
      Break;
      Text "It is written --build-value=name=value, the name a letter and then letters, digits, _, . or -, at most 64 bytes, the value printable ASCII, at most 1024 bytes, each name once."
    ]

(* Takes the text after --build-value=, which is name=value. *)
let add_value (arg: string): unit =
  match String.index_opt arg '=' with
  | None -> build_value_refused arg "it has no ="
  | Some i ->
     let name = String.sub arg 0 i
     and value = String.sub arg (i + 1) (String.length arg - i - 1) in
     if not (valid_name name) then build_value_refused arg "the name is not valid"
     else if not (valid_value value) then build_value_refused arg "the value is not printable ASCII of at most 1024 bytes"
     else if List.mem_assoc name !values then build_value_refused arg "the name is given twice"
     else values := !values @ [(name, value)]

let set_vcs (on: bool): unit = vcs := on

(* Runs git with the arguments in the current directory, without a shell,
   standard input and standard error on /dev/null.  Gives its standard
   output when it exits with 0, else None, also when there is no git. *)
let run_git (args: string list): string option =
  match Unix.openfile "/dev/null" [Unix.O_RDWR; Unix.O_CLOEXEC] 0 with
  | exception Unix.Unix_error _ -> None
  | null ->
     let (r, w) = Unix.pipe ~cloexec:true () in
     let started =
       try Some (Unix.create_process "git" (Array.of_list ("git" :: args)) null w null)
       with Unix.Unix_error _ -> None
     in
     Unix.close w;
     Unix.close null;
     let ic = Unix.in_channel_of_descr r in
     let out = In_channel.input_all ic in
     close_in ic;
     (match started with
      | None -> None
      | Some pid ->
         (match snd (Unix.waitpid [] pid) with
          | Unix.WEXITED 0 -> Some out
          | _ -> None))

let is_hex (s: string): bool =
  String.for_all (fun c -> match c with '0'..'9' | 'a'..'f' -> true | _ -> false) s

(* The commit of HEAD, 40 or 64 hex digits, and whether git status lists
   anything.  core.fsmonitor is switched off, so that the status does not
   start a command named in the repository's configuration. *)
let vcs_state (): string * bool =
  if not !vcs then ("", false) else
  match run_git ["rev-parse"; "HEAD"] with
  | None -> ("", false)
  | Some out ->
     let hash = String.trim out in
     if not ((String.length hash = 40 || String.length hash = 64) && is_hex hash) then ("", false)
     else
       let dirty = match run_git ["-c"; "core.fsmonitor=false"; "status"; "--porcelain"] with
         | Some s -> String.trim s <> ""
         | None -> false
       in
       (hash, dirty)

let source_date_refused (value: string) =
  hilde_raise (H 1036) CliError [
      Text "SOURCE_DATE_EPOCH is ";
      Code value;
      Text ", which is not a number of seconds since 1970: one to eighteen decimal digits."
    ]

(* SOURCE_DATE_EPOCH when it is set, for a build that gives the same bytes
   every time; the clock otherwise.  A value that is not a number ends the
   compilation, whether or not the programme reads it, as the
   specification of the variable asks. *)
let build_time (): string =
  match Sys.getenv_opt "SOURCE_DATE_EPOCH" with
  | Some v ->
     let n = String.length v in
     if n >= 1 && n <= 18 && String.for_all (fun c -> c >= '0' && c <= '9') v
     then v else source_date_refused v
  | None -> Printf.sprintf "%.0f" (Unix.time ())

let check_source_date (): unit = ignore (build_time ())

(* A C string literal of printable ASCII: every byte that could end the
   literal, escape or form a trigraph is written in octal. *)
let c_literal (s: string): string =
  let b = Buffer.create (String.length s + 2) in
  Buffer.add_char b '"';
  String.iter (fun c -> match c with
    | '"' | '\\' | '?' -> Buffer.add_string b (Printf.sprintf "\\%03o" (Char.code c))
    | c -> Buffer.add_char b c) s;
  Buffer.add_char b '"';
  Buffer.contents b

let c_block (): string =
  let (hash, dirty) = vcs_state () in
  let pairs = List.concat_map (fun (k, v) -> [c_literal k; c_literal v]) !values in
  "\n/* Standard.BuildInfo: the build of this programme. */\n"
  ^ "#define HILDE_BUILD_COMMIT " ^ c_literal hash ^ "\n"
  ^ "#define HILDE_BUILD_DIRTY " ^ (if dirty then "1" else "0") ^ "\n"
  ^ "#define HILDE_BUILD_TIME INT64_C(" ^ build_time () ^ ")\n"
  ^ "#define HILDE_BUILD_COMPILER " ^ c_literal Version.version_string ^ "\n"
  ^ "#define HILDE_BUILD_VALUE_COUNT " ^ string_of_int (List.length !values) ^ "\n"
  ^ "static const char *const hilde_build_values[] = { "
  ^ String.concat ", " (pairs @ ["0"]) ^ " };\n"
