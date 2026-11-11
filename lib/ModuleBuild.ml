(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

open Compiler

(* The arguments of the C compiler for one translation unit, before its
   flags of pkg-config, its file and its object: the same as a programme
   built from one file gets.  They are part of the key, so a build with
   zig for a machine of --target and one with the native cc do not share
   an entry. *)
let compile_arguments (): string list =
  Util.cc_command () @ [ "-std=c17"; "-Wall"; "-Wextra" ] @ Util.programme_flags @ [ "-c" ]

(* The flags of pkg-config that change how a unit compiles: the search
   paths of headers and the macros.  The others are for the link. *)
let compile_flags (flags_of: string -> string list) (libraries: string list): string list =
  List.filter
    (fun f -> String.length f > 2 && (String.sub f 0 2 = "-I" || String.sub f 0 2 = "-D"))
    (List.concat_map flags_of libraries)

(* Util.library_flags asked once per library and build: it runs pkg-config
   up to four times, and every unit names the libraries of the modules up
   to it, so that asking each time cost about a tenth of a second in a
   build where every unit came from the cache. *)
let remembered_flags (): string -> string list =
  let known: (string, string list) Hashtbl.t = Hashtbl.create 16 in
  fun (library: string) ->
    match Hashtbl.find_opt known library with
    | Some flags -> flags
    | None ->
       let flags = Util.library_flags library in
       Hashtbl.replace known library flags;
       flags

(* What a child sees of the environment: the same as Util.run_command
   passes on, so that no variable outside the key, CPATH for one, changes
   what cc writes. *)
let child_environment (): string array =
  let passed =
    List.filter_map
      (fun name -> Option.map (fun value -> name ^ "=" ^ value) (Sys.getenv_opt name))
      [ "PATH"; "PKG_CONFIG_PATH"; "PKG_CONFIG_LIBDIR"; "HOME" ]
  in
  Array.of_list passed

type job = {
    index: int;
    name: string;
    key: string;
    source: string;
    output: string;
    log: string;
    flags: string list;
  }

let write_new_file (path: string) (bytes: string): bool =
  try
    Out_channel.with_open_gen [Open_wronly; Open_creat; Open_excl; Open_binary] 0o600 path
      (fun oc -> output_string oc bytes);
    true
  with Sys_error _ -> false

let read_whole (path: string): string option =
  try Some (In_channel.with_open_bin path In_channel.input_all) with Sys_error _ -> None

(* Starts cc for the job with its output going to the job's log, and gives
   the process number, or None when it could not be started. *)
let start (env: string array) (j: job): int option =
  let args = Array.of_list (compile_arguments () @ j.flags @ [ j.source; "-o"; j.output ]) in
  match Unix.openfile j.log [Unix.O_WRONLY; Unix.O_CREAT; Unix.O_EXCL; Unix.O_CLOEXEC] 0o600 with
  | exception Unix.Unix_error _ -> None
  | fd ->
     Fun.protect ~finally:(fun () -> Unix.close fd)
       (fun () ->
         match Unix.openfile "/dev/null" [Unix.O_RDONLY; Unix.O_CLOEXEC] 0 with
         | exception Unix.Unix_error _ -> None
         | null ->
            Fun.protect ~finally:(fun () -> Unix.close null)
              (fun () ->
                try Some (Unix.create_process_env args.(0) args env null fd fd)
                with Unix.Unix_error _ -> None))

let rec wait_for (pid: int): bool =
  match Unix.waitpid [] pid with
  | (_, Unix.WEXITED 0) -> true
  | (_, _) -> false
  | exception Unix.Unix_error (Unix.EINTR, _, _) -> wait_for pid
  | exception Unix.Unix_error _ -> false

(* Runs the jobs, at most width at a time.  True when every cc ended with
   0; after the first failure no job is started, and the running ones are
   waited for. *)
let run_all (width: int) (jobs: job list): bool =
  let env = child_environment () in
  let rec go (waiting: job list) (running: int list) (ok: bool): bool =
    match waiting with
    | j :: rest when ok && List.length running < width ->
       (match start env j with
        | Some pid -> go rest (pid :: running) ok
        | None -> go rest running false)
    | _ ->
       (match running with
        | [] -> ok
        | pid :: others ->
           let fine = wait_for pid in
           go (if ok && fine then waiting else []) others (ok && fine))
  in
  go jobs [] true

let build (cache: BuildCache.cache) ~(compiler: string) ~(target: string)
      (units: translation_unit list) ~(libraries: string list) (output: string): bool =
  if units = [] then invalid_arg "ModuleBuild.build: no unit";
  let dir = Filename.temp_dir "hilde_" ".parts" in
  let flags_of = remembered_flags () in
  let made: string list ref = ref [] in
  let note (path: string): string = made := path :: !made; path in
  Fun.protect
    ~finally:(fun () ->
      List.iter (fun p -> try Sys.remove p with Sys_error _ -> ()) !made;
      try Unix.rmdir dir with Unix.Unix_error _ -> ())
    (fun () ->
      let objects: string list = List.mapi (fun i _ -> Filename.concat dir (string_of_int i ^ ".o")) units in
      let plan (i: int) (u: translation_unit): (job option, unit) result =
        let flags = compile_flags flags_of u.unit_libraries in
        let key = BuildCache.key ~compiler ~target ~options:(compile_arguments () @ flags)
                    ~sources:(u.unit_sources @ [ (u.unit_name, u.unit_text) ]) in
        let output = note (List.nth objects i) in
        match BuildCache.lookup cache key with
        | BuildCache.Hit bytes ->
           BuildCache.trace ("hit " ^ key ^ " " ^ u.unit_name);
           if write_new_file output bytes then Ok None else Error ()
        | found ->
           (match found with
            | BuildCache.Refused why -> BuildCache.trace ("refused " ^ key ^ " " ^ u.unit_name ^ ": " ^ why)
            | _ -> BuildCache.trace ("miss " ^ key ^ " " ^ u.unit_name));
           let source = note (Filename.concat dir (string_of_int i ^ ".c")) in
           let log = note (Filename.concat dir (string_of_int i ^ ".log")) in
           if write_new_file source u.unit_text then
             Ok (Some { index = i; name = u.unit_name; key; source; output; log; flags })
           else Error ()
      in
      let planned = List.mapi plan units in
      if List.exists Result.is_error planned then false
      else begin
        let jobs = List.filter_map (fun r -> match r with Ok j -> j | Error () -> None) planned in
        BuildCache.trace (Printf.sprintf "%d of %d units from the cache" (List.length units - List.length jobs) (List.length units));
        let width = max 1 (Domain.recommended_domain_count ()) in
        if not (run_all width jobs) then begin
          BuildCache.trace "a unit did not compile alone";
          false
        end
        else begin
          BuildCache.trace (Printf.sprintf "%d units compiled" (List.length jobs));
          List.iter (fun j ->
              match read_whole j.output with
              | Some bytes -> BuildCache.store cache j.key bytes
              | None -> BuildCache.trace ("no object for " ^ j.name ^ " " ^ string_of_int j.index))
            jobs;
          let link = Array.of_list (Util.cc_command () @ [ "-std=c17" ] @ objects
                                    @ List.concat_map flags_of libraries
                                    @ [ "-o"; output ]) in
          match Util.run_command link with
          | Util.CommandOutput { code = 0; _ } -> BuildCache.trace "linked"; true
          | _ -> BuildCache.trace "the link failed"; false
          | exception Unix.Unix_error _ -> false
        end
      end)
