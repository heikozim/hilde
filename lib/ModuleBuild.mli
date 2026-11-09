(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** A programme built in parts: every translation unit is compiled to an
    object of its own, or taken from the cache of compiled modules when an
    entry with a matching checksum stands under its key, and the objects
    are linked into the programme.  The key of a unit is a hash over the
    compiler's identity, the target, the arguments of cc, the files of its
    module and the unit's C. *)

val build : BuildCache.cache -> compiler:string -> target:string -> Compiler.translation_unit list -> libraries:string list -> string -> bool
(** [build cache ~compiler ~target units ~libraries output] builds the
    programme at [output], compiling at most as many units at once as the
    machine has cores, and keeps every object it compiled in the cache.
    False when a unit did not compile alone, an object could not be
    written or the link failed; the caller then builds the programme from
    one file, which reports what is wrong.  The files it made in its
    temporary directory are removed either way.
    Requires: at least one unit; Invalid_argument otherwise.
    Ensures: on true, [output] is the linked programme, made only of
    objects that cc compiled in this call or whose checksum the cache
    checked; the temporary directory is gone. *)
