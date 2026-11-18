(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** The cache of compiled modules.  The object that cc made of one module
    of a programme is kept under a key that is a BLAKE2b-256 hash (the
    BLAKE2b function of RFC 7693 with a result of 32 bytes) over the names
    and texts of the module's files and its C, the compiler's identity, the
    target and the arguments of cc.  No clock and no file time enters the
    key.  Every entry carries a keyed checksum, a hash-based message
    authentication code (HMAC, RFC 2104) over BLAKE2b-256 with a secret
    that only this user can read; an entry whose checksum does not match is
    removed and never handed out, and the module is compiled again. *)

type cache
(** An opened cache directory, its secret read. *)

type lookup =
  | Hit of string
  (** The entry was there and its checksum matched: the bytes of the
      object. *)
  | Miss
  (** No entry under the key. *)
  | Refused of string
  (** An entry was there and was refused, for the reason given; it has
      been removed. *)

val default_limit : int
(** The size the entries of a cache may take together, in bytes, unless
    HILDE_CACHE_LIMIT_MB says otherwise: 256 MiB.
    Ensures: greater than 0. *)

val open_at : string -> (cache, string) result
(** [open_at dir] opens the cache in [dir], an absolute path, making it and
    its secret when they are missing.  Error with the reason when [dir] is
    not absolute, is not a directory, belongs to another user, may be
    written by others, or its secret is not a file of 32 bytes that only
    this user may read.
    Requires: [dir] absolute; Error otherwise, and nothing is made.
    Ensures: on Ok, [dir] is a directory of this user that no one else may
    write, and its secret is a file of this user of 32 bytes that no one
    else may read or write. *)

val open_default : unit -> (cache, string) result
(** The cache named by the environment: HILDE_CACHE=off switches it off,
    HILDE_CACHE_DIR names it, else XDG_CACHE_HOME/hilde/modules, else
    HOME/.cache/hilde/modules.  Error with the reason when it is switched off
    or cannot be opened as [open_at] says.
    No contract: it reads only the environment; what holds of the cache
    opened is what [open_at] ensures. *)

val compiler_identity : unit -> string option
(** The version of this compiler and a BLAKE2b-256 hash of its executable,
    so that two builds of one version do not share entries.  None when the
    executable cannot be read.
    No contract: the answer is the content of a file. *)

val toolchain : string -> string
(** [toolchain target] describes the target platform as far as it changes
    the objects built: the target's name, the cc found on PATH with a
    BLAKE2b-256 hash of the file it resolves to, and the variables that
    choose the tools and libraries (PATH, PKG_CONFIG_PATH,
    PKG_CONFIG_LIBDIR, HILDE_ZIG, HILDE_WASM_CC, WASI_SYSROOT).
    Requires: [target] not empty; Invalid_argument otherwise.
    Ensures: the result begins with "target=" and the target's name. *)

val key : compiler:string -> target:string -> options:string list -> sources:(string * string) list -> string
(** The key of an entry, 64 hexadecimal digits: a hash over the
    compiler's identity, the target, the options and every pair of name
    and text, each field preceded by its length so that no two different
    inputs give the same bytes.  No clock and no time of a file is read.
    Ensures: 64 lowercase hexadecimal digits, the same for the same
    arguments. *)

val lookup : cache -> string -> lookup
(** The entry under the key.  A hit marks the entry as used for the
    clean-up.  Requires a key of 64 lowercase hexadecimal digits, as [key]
    gives; any other string, which could name a path, is Refused and no
    file is read.
    Ensures: a Hit carries bytes whose checksum under this cache's secret
    was checked over exactly those bytes; a Refused entry is removed. *)

val store : cache -> string -> string -> unit
(** [store cache key bytes] keeps the bytes under the key, written to a
    file of its own and renamed into place, and then cleans up.  A failure
    to write leaves the cache without the entry and is not an error.
    Requires a key of 64 lowercase hexadecimal digits, as [key] gives;
    under any other string nothing is written.
    Ensures: an entry written carries the checksum of its bytes under this
    cache's secret and the mode 0600. *)

val clean : cache -> limit:int -> int
(** Removes unfinished writes older than an hour and, while the entries
    take more than [limit] bytes, the least recently used ones until they
    take at most three quarters of it.  Gives the number of files
    removed.
    Requires: [limit >= 0]; Invalid_argument otherwise.
    Ensures: a result of 0 or more; the secret is never removed. *)

val trace : string -> unit
(** Writes the line to standard error when HILDE_CACHE_TRACE is 1.
    No contract: any line may be written, and nothing comes back. *)
