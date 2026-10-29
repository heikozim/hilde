(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

let unit_name = "Unit"
let never_name = "Never"
let bool_name = "Bool"

let nat_prefix = "Nat"
let int_prefix = "Int"

let nat8_name  = "Nat8"
let int8_name  = "Int8"
let nat16_name = "Nat16"
let int16_name = "Int16"
let nat32_name = "Nat32"
let int32_name = "Int32"
let nat64_name = "Nat64"
let int64_name = "Int64"

let single_float_name = "Float32"
let double_float_name = "Float64"

let read_ref_name  = "&"
let write_ref_name = "&!"

let address_name = "Address"
let pointer_name = "Pointer"

let root_cap_name: string = "RootCapability"
let exit_code_name: string = "ExitCode"

(* The parameter a function with a requires takes the call site of its
   callers in.  A name a programme cannot write: it begins with an
   underscore. *)
let contract_site_param: string = "_hilde_site"
