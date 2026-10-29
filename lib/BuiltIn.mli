(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
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
