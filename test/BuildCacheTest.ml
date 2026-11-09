(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open OUnit2
open Hilde_core.BuildCache

(* The cache of compiled modules: a hit for unchanged input, a new key for
   a changed source, compiler or target, and no entry handed out that does
   not carry this cache's checksum over its own bytes. *)

let sources = [("A.hih", "module A is end module.\n"); ("A.hiq", "module body A is end module body.\n")]

let key_of ?(compiler = "1.0.0 c0ffee") ?(target = "linux") ?(options = ["entrypoint=A:main"]) ?(sources = sources) () =
  key ~compiler ~target ~options ~sources

let opened (dir: string): cache =
  match open_at dir with
  | Ok c -> c
  | Error why -> assert_failure ("the cache did not open: " ^ why)

let fresh (ctxt: test_ctxt): string * cache =
  let dir = Filename.concat (bracket_tmpdir ctxt) "cache" in
  (dir, opened dir)

let entry (dir: string) (key: string): string = Filename.concat dir (key ^ ".bin")

let read (path: string): string = In_channel.with_open_bin path In_channel.input_all

let write (path: string) (text: string): unit =
  Out_channel.with_open_gen [Open_wronly; Open_creat; Open_trunc; Open_binary] 0o600 path
    (fun oc -> output_string oc text)

let is_refused (l: lookup): bool = match l with Refused _ -> true | _ -> false

let show (l: lookup): string =
  match l with Hit b -> "Hit " ^ b | Miss -> "Miss" | Refused why -> "Refused " ^ why

let test_hit_for_unchanged_input ctxt =
  let (_, c) = fresh ctxt in
  let k = key_of () in
  assert_equal ~printer:Fun.id k (key_of ());
  assert_equal ~printer:show Miss (lookup c k);
  store c k "object bytes";
  assert_equal ~printer:show (Hit "object bytes") (lookup c k);
  assert_equal ~printer:show (Hit "object bytes") (lookup c k)

(* The key is made of names and texts only: a file read again after its
   time was set to a day long past, or into the future, gives the same key,
   and an entry whose own time was moved the same way is still a hit. *)
let test_no_time_in_key ctxt =
  let (dir, c) = fresh ctxt in
  let src = Filename.concat (bracket_tmpdir ctxt) "A.hiq" in
  write src (List.assoc "A.hiq" sources);
  let key_from_file () = key_of ~sources:[("A.hih", List.assoc "A.hih" sources); ("A.hiq", read src)] () in
  let k = key_from_file () in
  assert_equal ~printer:Fun.id (key_of ()) k;
  store c k "object bytes";
  List.iter (fun t ->
      Unix.utimes src t t;
      Unix.utimes (entry dir k) t t;
      assert_equal ~msg:"the same key whatever the time of the file" ~printer:Fun.id k (key_from_file ());
      assert_equal ~msg:"a hit whatever the time of the entry" ~printer:show (Hit "object bytes") (lookup c k))
    [1.0; 946684800.0; 2145916800.0]

let test_changed_source_is_built_again ctxt =
  let (_, c) = fresh ctxt in
  let k = key_of () in
  store c k "old";
  let changed = [("A.hih", "module A is end module.\n"); ("A.hiq", "module body A is end module body. \n")] in
  let k' = key_of ~sources:changed () in
  assert_bool "a changed text gives a new key" (k <> k');
  assert_equal ~printer:show Miss (lookup c k');
  let renamed = [("B.hih", "module A is end module.\n"); ("A.hiq", "module body A is end module body.\n")] in
  assert_bool "a changed file name gives a new key" (k <> key_of ~sources:renamed ());
  (* The texts of two files may not run into each other. *)
  let moved = [("A.hih", "module A is end module.\nm"); ("A.hiq", "odule body A is end module body.\n")] in
  assert_bool "a byte moved between files gives a new key" (k <> key_of ~sources:moved ())

let test_other_compiler_is_built_again ctxt =
  let (_, c) = fresh ctxt in
  let k = key_of () in
  store c k "old";
  let k' = key_of ~compiler:"1.0.1 c0ffee" () in
  assert_bool "another version gives a new key" (k <> k');
  assert_bool "another executable gives a new key" (k <> key_of ~compiler:"1.0.0 c0ffef" ());
  assert_equal ~printer:show Miss (lookup c k')

let test_other_target_is_built_again ctxt =
  let (_, c) = fresh ctxt in
  let k = key_of () in
  store c k "old";
  let k' = key_of ~target:"wasm" () in
  assert_bool "another target gives a new key" (k <> k');
  assert_bool "another option gives a new key" (k <> key_of ~options:["entrypoint=A:other"] ());
  assert_equal ~printer:show Miss (lookup c k')

let test_other_toolchain_is_built_again _ =
  (* PATH is changed and put back as it was: OUnit fails a test that
     leaves the environment changed, and OCaml cannot unset a variable. *)
  let saved = Sys.getenv "PATH" in
  let before = toolchain "linux" in
  assert_equal ~printer:Fun.id before (toolchain "linux");
  assert_bool "another target name gives another platform" (before <> toolchain "wasm");
  Unix.putenv "PATH" (saved ^ ":/elsewhere/bin");
  let after = toolchain "linux" in
  Unix.putenv "PATH" saved;
  assert_bool "another search path gives another platform" (before <> after);
  assert_bool "another platform gives a new key" (key_of ~target:before () <> key_of ~target:after ())

let test_changed_byte_is_refused ctxt =
  let (dir, c) = fresh ctxt in
  let k = key_of () in
  store c k "object bytes";
  let text = read (entry dir k) in
  let last = String.length text - 1 in
  write (entry dir k) (String.sub text 0 last ^ "X");
  let l = lookup c k in
  assert_bool ("a changed byte is refused, got " ^ show l) (is_refused l);
  assert_bool "the refused entry is removed" (not (Sys.file_exists (entry dir k)));
  assert_equal ~printer:show Miss (lookup c k)

let test_wrong_checksum_is_refused ctxt =
  let (dir, c) = fresh ctxt in
  let k = key_of () in
  store c k "object bytes";
  let text = read (entry dir k) in
  let at = String.length "hilde-module-cache 1\n" + 65 in
  let forged = String.sub text 0 at ^ String.make 64 '0' ^ String.sub text (at + 64) (String.length text - at - 64) in
  assert_equal ~msg:"only the checksum line is changed" ~printer:Fun.id
    (String.make 64 '0') (List.nth (String.split_on_char '\n' forged) 2);
  write (entry dir k) forged;
  assert_bool "a wrong checksum is refused" (is_refused (lookup c k))

let test_entry_of_another_cache_is_refused ctxt =
  let (dir, c) = fresh ctxt in
  let other_dir = Filename.concat (bracket_tmpdir ctxt) "other" in
  let other = opened other_dir in
  let k = key_of () in
  (* Written by a hand that does not know this cache's secret, with a
     checksum of its own that is right for its own secret. *)
  store other k "forged object";
  write (entry dir k) (read (entry other_dir k));
  assert_bool "an entry of another secret is refused" (is_refused (lookup c k))

let test_entry_under_another_key_is_refused ctxt =
  let (dir, c) = fresh ctxt in
  let k = key_of () and k' = key_of ~target:"wasm" () in
  store c k "linux object";
  write (entry dir k') (read (entry dir k));
  assert_bool "an entry moved to another key is refused" (is_refused (lookup c k'))

let test_writable_entry_is_refused ctxt =
  let (dir, c) = fresh ctxt in
  let k = key_of () in
  store c k "object bytes";
  Unix.chmod (entry dir k) 0o620;
  assert_bool "an entry others may write is refused" (is_refused (lookup c k))

let test_linked_entry_is_refused ctxt =
  let (dir, c) = fresh ctxt in
  let k = key_of () in
  store c k "object bytes";
  let real = Filename.concat dir "elsewhere" in
  Sys.rename (entry dir k) real;
  Unix.symlink real (entry dir k);
  assert_bool "a symbolic link is refused" (is_refused (lookup c k))

let test_entry_of_another_user_is_refused ctxt =
  skip_if (Unix.geteuid () <> 0) "only root can give a file to another user";
  let (dir, c) = fresh ctxt in
  let k = key_of () in
  store c k "object bytes";
  Unix.chown (entry dir k) 65534 65534;
  assert_bool "an entry of another user is refused" (is_refused (lookup c k))

let test_unsafe_directories_are_refused ctxt =
  let base = bracket_tmpdir ctxt in
  assert_bool "a relative path is refused" (Result.is_error (open_at "relative/cache"));
  let open_dir = Filename.concat base "open" in
  Unix.mkdir open_dir 0o700;
  Unix.chmod open_dir 0o777;
  assert_bool "a directory others may write is refused" (Result.is_error (open_at open_dir));
  let readable = Filename.concat base "readable" in
  ignore (opened readable);
  Unix.chmod (Filename.concat readable "key") 0o644;
  assert_bool "a secret others may read is refused" (Result.is_error (open_at readable));
  let short = Filename.concat base "short" in
  Unix.mkdir short 0o700;
  write (Filename.concat short "key") "too short";
  assert_bool "a secret of the wrong length is refused" (Result.is_error (open_at short))

(* The checksum is HMAC over BLAKE2b-256 as RFC 2104 and RFC 7693 define
   them: the value was computed apart with Python's hmac and hashlib for
   the secret 0, 1, ..., 31. *)
let test_checksum_known_answer ctxt =
  let dir = Filename.concat (bracket_tmpdir ctxt) "known" in
  Unix.mkdir dir 0o700;
  write (Filename.concat dir "key") (String.init 32 Char.chr);
  let c = opened dir in
  let k = String.concat "" (List.init 32 (fun _ -> "ab")) in
  store c k "object bytes\n";
  let lines = String.split_on_char '\n' (read (entry dir k)) in
  assert_equal ~printer:Fun.id "9ee15209de1c38a7bb075cff3c85bef59d84266111de3027176b6ae83222445f" (List.nth lines 2);
  assert_equal ~printer:show (Hit "object bytes\n") (lookup c k)

(* A key is a file name in the cache directory; one that is not 64
   hexadecimal digits could name a path outside it. *)
let test_key_that_names_a_path_is_refused ctxt =
  let (dir, c) = fresh ctxt in
  let outside = Filename.concat (Filename.dirname dir) "outside" in
  let path_key = Filename.concat ".." "outside" in
  store c path_key "object bytes";
  assert_bool "nothing written outside the cache" (not (Sys.file_exists (outside ^ ".bin")));
  write (outside ^ ".bin") "planted";
  assert_bool "a key that is a path is refused" (is_refused (lookup c path_key));
  assert_bool "an upper-case key is refused" (is_refused (lookup c (String.uppercase_ascii (key_of ()))))

let test_negative_limit_is_refused ctxt =
  let (_, c) = fresh ctxt in
  assert_raises (Invalid_argument "BuildCache.clean: a limit below 0") (fun () -> clean c ~limit:(-1))

(* What the interfaces ask of a caller and promise: no empty target, no
   build without a unit, a key of 64 lowercase hexadecimal digits. *)
let test_contracts ctxt =
  let (_, c) = fresh ctxt in
  assert_raises (Invalid_argument "BuildCache.toolchain: an empty target") (fun () -> toolchain "");
  assert_bool "the platform begins with its target"
    (String.starts_with ~prefix:"target=linux\n" (toolchain "linux"));
  let k = key_of ~sources:[] ~options:[] () in
  assert_equal ~printer:string_of_int 64 (String.length k);
  assert_bool "lowercase hexadecimal" (String.for_all (fun ch -> (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f')) k);
  assert_bool "the limit is above 0" (default_limit > 0);
  assert_raises (Invalid_argument "ModuleBuild.build: no unit")
    (fun () -> Hilde_core.ModuleBuild.build c ~compiler:"c" ~target:"linux" [] ~libraries:[] "never")

let test_clean_removes_least_recently_used ctxt =
  let (dir, c) = fresh ctxt in
  let keys = List.map (fun t -> key_of ~target:t ()) ["a"; "b"; "c"; "d"] in
  List.iteri (fun i k ->
      store c k (String.make 1000 'x');
      let t = 1000000.0 +. float_of_int i in
      Unix.utimes (entry dir k) t t)
    keys;
  (* The oldest entry is used again and so becomes the youngest. *)
  ignore (lookup c (List.hd keys));
  let part = Filename.concat dir ".left.1.0.part" in
  write part "unfinished";
  Unix.utimes part 1.0 1.0;
  let removed = clean c ~limit:4000 in
  let left = List.filter (fun k -> Sys.file_exists (entry dir k)) keys in
  assert_equal ~printer:string_of_int 3 removed;
  assert_bool "the unfinished write is removed" (not (Sys.file_exists part));
  assert_equal ~printer:(String.concat " ") [List.hd keys; List.nth keys 3] left;
  assert_bool "the secret stays" (Sys.file_exists (Filename.concat dir "key"))

let suite =
  "BuildCache" >::: [
      "hit for unchanged input" >:: test_hit_for_unchanged_input;
      "no time in the key" >:: test_no_time_in_key;
      "changed source is built again" >:: test_changed_source_is_built_again;
      "other compiler is built again" >:: test_other_compiler_is_built_again;
      "other target is built again" >:: test_other_target_is_built_again;
      "other toolchain is built again" >:: test_other_toolchain_is_built_again;
      "changed byte is refused" >:: test_changed_byte_is_refused;
      "wrong checksum is refused" >:: test_wrong_checksum_is_refused;
      "entry of another cache is refused" >:: test_entry_of_another_cache_is_refused;
      "entry under another key is refused" >:: test_entry_under_another_key_is_refused;
      "writable entry is refused" >:: test_writable_entry_is_refused;
      "linked entry is refused" >:: test_linked_entry_is_refused;
      "entry of another user is refused" >:: test_entry_of_another_user_is_refused;
      "unsafe directories are refused" >:: test_unsafe_directories_are_refused;
      "checksum known answer" >:: test_checksum_known_answer;
      "clean removes least recently used" >:: test_clean_removes_least_recently_used;
      "key that names a path is refused" >:: test_key_that_names_a_path_is_refused;
      "negative limit is refused" >:: test_negative_limit_is_refused;
      "contracts" >:: test_contracts;
    ]

let _ = run_test_tt_main suite
