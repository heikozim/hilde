(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** Sources of the builtin modules and the prelude, injected into OCaml source
    by the concat_builtins.py script. *)

(** Source code of the Hilde.Pervasive interface file. *)
val pervasive_interface_source: string
(** Source code of the Hilde.Pervasive body file. *)
val pervasive_body_source: string

(** Source code of the Hilde.Memory interface file. *)
val memory_interface_source: string
(** Source code of the Hilde.Memory body file. *)
val memory_body_source: string

(** Source code of the Hilde.Array interface file. *)
val array_interface_source: string
(** Source code of the Hilde.Array body file. *)
val array_body_source: string

(** Source code of prelude.h *)
val prelude_h: string
(** Source code of prelude.c *)
val prelude_c: string
(** The C of ML-DSA: lib/mldsa.c with libcrux in the place of its include. *)
val mldsa_c: string

(** The version of zig the gates pin, from scripts/zig-version.txt: the
    only zig the compiler takes for WebAssembly. *)
val zig_version: string
