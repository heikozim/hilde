(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The cache of compiled modules.  Layout of the directory:

     key              the secret of the checksums, 32 random bytes, mode 0600
     <64 hex>.bin     one entry: a line with the format, a line with the
                      key, a line with the checksum, then the object
     <name>.part      a write that has not been renamed into place yet

   Nothing in an entry is trusted before its checksum is checked over the
   bytes read, and the bytes handed out are those bytes, not the file read
   a second time. *)

module H = Digest.BLAKE256

type cache = { dir: string; secret: string }

type lookup =
  | Hit of string
  | Miss
  | Refused of string

let format_line: string = "hilde-module-cache 1"

let default_limit: int = 256 * 1024 * 1024

let secret_length: int = 32

(* When the compiler started, near enough: modules are initialised before
   the command line is read.  The trace gives the time since then, so
   that it shows where a run spends its time. *)
let started: float = Unix.gettimeofday ()

let trace (line: string): unit =
  if Sys.getenv_opt "HILDE_CACHE_TRACE" = Some "1" then
    prerr_endline (Printf.sprintf "hilde cache: %.0f ms: %s" ((Unix.gettimeofday () -. started) *. 1000.0) line)

(* HMAC of RFC 2104 over BLAKE2b-256, whose block is 128 bytes. *)
let hmac (secret: string) (message: string): string =
  let block = 128 in
  let k = if String.length secret > block then H.string secret else secret in
  let k = k ^ String.make (block - String.length k) '\000' in
  let pad (c: int): string = String.map (fun ch -> Char.chr (Char.code ch lxor c)) k in
  H.to_hex (H.string (pad 0x5c ^ H.string (pad 0x36 ^ message)))

(* Compares every byte whatever the first difference, so that the time
   taken does not tell how much of a forged checksum was right. *)
let equal_in_constant_time (a: string) (b: string): bool =
  String.length a = String.length b
  && (let d = ref 0 in
      String.iteri (fun i c -> d := !d lor (Char.code c lxor Char.code b.[i])) a;
      !d = 0)

let is_hex_key (s: string): bool =
  String.length s = 64
  && String.for_all (fun c -> match c with '0'..'9' | 'a'..'f' -> true | _ -> false) s

let field (s: string): string = string_of_int (String.length s) ^ ":" ^ s

let key ~(compiler: string) ~(target: string) ~(options: string list) ~(sources: (string * string) list): string =
  let b = Buffer.create 4096 in
  Buffer.add_string b (field format_line);
  Buffer.add_string b (field compiler);
  Buffer.add_string b (field target);
  Buffer.add_string b (field (string_of_int (List.length options)));
  List.iter (fun o -> Buffer.add_string b (field o)) options;
  Buffer.add_string b (field (string_of_int (List.length sources)));
  List.iter (fun (name, text) -> Buffer.add_string b (field name); Buffer.add_string b (field text)) sources;
  let k = H.to_hex (H.string (Buffer.contents b)) in
  assert (is_hex_key k);
  k

let compiler_identity_value: string option Lazy.t =
  lazy (try Some (Version.version_string ^ " " ^ H.to_hex (H.file Sys.executable_name))
        with Sys_error _ -> None)

let compiler_identity (): string option = Lazy.force compiler_identity_value

let toolchain (target: string): string =
  if target = "" then invalid_arg "BuildCache.toolchain: an empty target";
  let variable (name: string): string =
    name ^ "=" ^ (match Sys.getenv_opt name with Some v -> v | None -> "")
  in
  let cc =
    match Util.find_on_path "cc" with
    | None -> "cc=none"
    | Some path ->
       (try
          let real = Unix.realpath path in
          "cc=" ^ real ^ " " ^ H.to_hex (H.file real)
        with Unix.Unix_error _ | Sys_error _ -> "cc=" ^ path)
  in
  String.concat "\n"
    ([ "target=" ^ target;
       cc;
       (* The machine of --target the C is built for: a build for another
          machine of the same system must not take an entry of this one's. *)
       "cross_triple=" ^ !(Util.cross_triple) ]
     @ List.map variable [ "PATH"; "PKG_CONFIG_PATH"; "PKG_CONFIG_LIBDIR"; "HILDE_ZIG"; "HILDE_WASM_CC"; "WASI_SYSROOT" ])

(* A directory or file of the cache is used only when it is what it should
   be, belongs to this user and cannot be written by anyone else; for the
   secret, cannot be read by anyone else either. *)
let check_owned (path: string) (kind: Unix.file_kind) (forbidden: int): (Unix.stats, string) result =
  match Unix.lstat path with
  | exception Unix.Unix_error (e, _, _) -> Error (path ^ ": " ^ Unix.error_message e)
  | st ->
     if st.st_kind <> kind then Error (path ^ " is not a " ^ (if kind = Unix.S_DIR then "directory" else "regular file"))
     else if st.st_uid <> Unix.geteuid () then Error (path ^ " belongs to another user")
     else if st.st_perm land forbidden <> 0 then Error (path ^ " has the mode " ^ Printf.sprintf "%o" st.st_perm)
     else Ok st

let rec make_dirs (path: string): unit =
  if not (Sys.file_exists path) then begin
    let parent = Filename.dirname path in
    if parent <> path then make_dirs parent;
    try Unix.mkdir path 0o700 with Unix.Unix_error (Unix.EEXIST, _, _) -> ()
  end

(* Reads a file opened after its lstat, refusing it when the file opened is
   not the one looked at, or is larger than limit bytes. *)
let read_checked (path: string) (st: Unix.stats) (limit: int): (string, string) result =
  if st.st_size > limit then Error (path ^ " is larger than the limit")
  else
    match Unix.openfile path [Unix.O_RDONLY; Unix.O_CLOEXEC] 0 with
    | exception Unix.Unix_error (e, _, _) -> Error (path ^ ": " ^ Unix.error_message e)
    | fd ->
       let ic = Unix.in_channel_of_descr fd in
       Fun.protect ~finally:(fun () -> close_in_noerr ic)
         (fun () ->
           let now = Unix.fstat fd in
           if now.st_dev <> st.st_dev || now.st_ino <> st.st_ino then Error (path ^ " changed while it was opened")
           else Ok (In_channel.input_all ic))

let random_bytes (n: int): string option =
  try
    In_channel.with_open_bin "/dev/urandom" (fun ic -> In_channel.really_input_string ic n)
  with Sys_error _ -> None

(* Writes the bytes to a new file of the directory and moves it to the
   name: renamed over what stands there, or with replace false linked, so
   that a file already there is kept. *)
let write_new ?(replace: bool = true) (dir: string) (name: string) (perm: int) (bytes: string): bool =
  let suffix = match random_bytes 8 with Some r -> H.to_hex (H.string r) | None -> "x" in
  let part = Filename.concat dir (Printf.sprintf ".%s.%d.%s.part" name (Unix.getpid ()) (String.sub suffix 0 16)) in
  match Unix.openfile part [Unix.O_WRONLY; Unix.O_CREAT; Unix.O_EXCL; Unix.O_CLOEXEC] perm with
  | exception Unix.Unix_error _ -> false
  | fd ->
     let written =
       try
         let oc = Unix.out_channel_of_descr fd in
         output_string oc bytes;
         close_out oc;
         true
       with Sys_error _ | Unix.Unix_error _ -> (try Unix.close fd with Unix.Unix_error _ -> ()); false
     in
     if written then
       (try
          if replace then Unix.rename part (Filename.concat dir name)
          else (Fun.protect ~finally:(fun () -> try Sys.remove part with Sys_error _ -> ())
                  (fun () -> Unix.link part (Filename.concat dir name)));
          true
        with Unix.Unix_error _ -> (try Sys.remove part with Sys_error _ -> ()); false)
     else ((try Sys.remove part with Sys_error _ -> ()); false)

let read_secret (dir: string): (string, string) result =
  let path = Filename.concat dir "key" in
  let read () =
    match check_owned path Unix.S_REG 0o077 with
    | Error why -> Error why
    | Ok st ->
       (match read_checked path st secret_length with
        | Error why -> Error why
        | Ok s when String.length s = secret_length -> Ok s
        | Ok _ -> Error (path ^ " does not hold " ^ string_of_int secret_length ^ " bytes"))
  in
  if Sys.file_exists path then read ()
  else
    match random_bytes secret_length with
    | None -> Error "no random bytes for the secret"
    | Some s ->
       (* Two compilers may make the secret at once: the first link wins,
          and both read the file that stands afterwards. *)
       ignore (write_new ~replace:false dir "key" 0o600 s);
       read ()

let open_at (dir: string): (cache, string) result =
  if Filename.is_relative dir then Error (dir ^ " is not an absolute path")
  else begin
    (try make_dirs dir with Unix.Unix_error _ -> ());
    match check_owned dir Unix.S_DIR 0o022 with
    | Error why -> Error why
    | Ok _ ->
       (match read_secret dir with
        | Error why -> Error why
        | Ok secret -> Ok { dir; secret })
  end

let open_default (): (cache, string) result =
  let nonempty (v: string): string option =
    match Sys.getenv_opt v with Some s when s <> "" -> Some s | _ -> None
  in
  match Sys.getenv_opt "HILDE_CACHE" with
  | Some "off" | Some "0" -> Error "switched off by HILDE_CACHE"
  | _ ->
     match nonempty "HILDE_CACHE_DIR" with
     | Some dir -> open_at dir
     | None ->
        match nonempty "XDG_CACHE_HOME" with
        | Some base when not (Filename.is_relative base) -> open_at (Filename.concat (Filename.concat base "hilde") "modules")
        | _ ->
           match nonempty "HOME" with
           | Some home -> open_at (Filename.concat (Filename.concat (Filename.concat home ".cache") "hilde") "modules")
           | None -> Error "neither HILDE_CACHE_DIR, XDG_CACHE_HOME nor HOME is set"

let limit_from_environment (): int =
  match Sys.getenv_opt "HILDE_CACHE_LIMIT_MB" with
  | Some s when s <> "" && String.length s <= 6 && String.for_all (fun c -> c >= '0' && c <= '9') s
                && int_of_string s > 0 ->
     int_of_string s * 1024 * 1024
  | _ -> default_limit

let entry_path (c: cache) (key: string): string = Filename.concat c.dir (key ^ ".bin")

let header (key: string): string = format_line ^ "\n" ^ key ^ "\n"

let remove (path: string): unit = try Sys.remove path with Sys_error _ -> ()

let lookup (c: cache) (key: string): lookup =
  if not (is_hex_key key) then Refused "the key is not 64 hexadecimal digits"
  else
    let path = entry_path c key in
    match Unix.lstat path with
    | exception Unix.Unix_error (Unix.ENOENT, _, _) -> Miss
    | _ ->
      let refuse (why: string): lookup = remove path; Refused why in
      match check_owned path Unix.S_REG 0o022 with
      | Error why -> refuse why
      | Ok st ->
         match read_checked path st (limit_from_environment ()) with
         | Error why -> refuse why
         | Ok text ->
            let head = header key in
            let hl = String.length head in
            (* The header, 64 hex digits of the checksum and a line end. *)
            if String.length text < hl + 65 || String.sub text 0 hl <> head || text.[hl + 64] <> '\n' then
              refuse "the entry does not have the form of an entry for this key"
            else
              let mac = String.sub text hl 64 in
              let bytes = String.sub text (hl + 65) (String.length text - hl - 65) in
              if not (equal_in_constant_time mac (hmac c.secret (head ^ bytes))) then
                refuse "the checksum of the entry does not match"
              else begin
                (try Unix.utimes path 0.0 0.0 with Unix.Unix_error _ -> ());
                Hit bytes
              end

let is_entry_name (name: string): bool =
  Filename.check_suffix name ".bin" && is_hex_key (Filename.chop_suffix name ".bin")

let clean (c: cache) ~(limit: int): int =
  if limit < 0 then invalid_arg "BuildCache.clean: a limit below 0";
  let names = try Sys.readdir c.dir with Sys_error _ -> [||] in
  let now = Unix.time () in
  let removed = ref 0 in
  let entries = ref [] in
  Array.iter (fun name ->
      let path = Filename.concat c.dir name in
      match Unix.lstat path with
      | exception Unix.Unix_error _ -> ()
      | st ->
         if Filename.check_suffix name ".part" then begin
           if now -. st.st_mtime > 3600.0 then (remove path; incr removed)
         end
         else if is_entry_name name then
           entries := (st.st_mtime, st.st_size, path) :: !entries)
    names;
  let total = List.fold_left (fun acc (_, size, _) -> acc + size) 0 !entries in
  if total > limit then begin
    let oldest_first = List.sort (fun (a, _, p) (b, _, q) -> compare (a, p) (b, q)) !entries in
    let target = (limit / 4) * 3 in
    ignore (List.fold_left (fun left (_, size, path) ->
                if left > target then (remove path; incr removed; left - size) else left)
              total oldest_first)
  end;
  !removed

let store (c: cache) (key: string) (bytes: string): unit =
  if is_hex_key key then begin
    let head = header key in
    let text = head ^ hmac c.secret (head ^ bytes) ^ "\n" ^ bytes in
    if write_new c.dir (key ^ ".bin") 0o600 text then trace ("stored " ^ key)
    else trace ("could not store " ^ key);
    let removed = clean c ~limit:(limit_from_environment ()) in
    if removed > 0 then trace ("removed " ^ string_of_int removed ^ " old files")
  end
