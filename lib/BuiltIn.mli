(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)
open Identifier
open Cst

(* Hilde.Pervasive *)

val pervasive_module_name : module_name

val pervasive_imports: concrete_import_list

(* Hilde.Memory *)

val memory_module_name : module_name

val is_address_type : qident -> bool
val is_pointer_type : qident -> bool
