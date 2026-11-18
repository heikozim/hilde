(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
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
(** lib/prelude/internal.h, which every programme's C begins with. *)
val prelude_internal_h: string
(** The parts of lib/prelude in the order a programme carries them: the
    name of each, its C without the line that includes internal.h, the
    names only it defines, and the other parts it needs. *)
val prelude_parts: (string * string * string list * string list) list
(** The parts of lib/prelude again, each as the translation units of a
    programme built in parts see it: its name, its C as the prelude's own
    unit compiles it, with the static variables that can change made
    shared, and its declarations for the other units.
    No contract: a constant made by concat_builtins.py from lib/prelude;
    test/ModuleUnitsTest.ml checks that the declarations define no data
    that can be written. *)
val prelude_split: (string * string * string) list
(** internal.h as the prelude's own unit of a programme built in parts
    reads it: the static variables it declares made shared.
    No contract: a constant made by concat_builtins.py from internal.h. *)
val prelude_internal_shared: string
(** internal.h as the other units read it: those variables extern.
    No contract: a constant made by concat_builtins.py from internal.h. *)
val prelude_internal_declarations: string
(** The C of ML-DSA: lib/mldsa.c with libcrux in the place of its include. *)
val mldsa_c: string

(** The version of zig the gates pin, from scripts/zig-version.txt: the
    only zig the compiler takes for WebAssembly. *)
val zig_version: string
