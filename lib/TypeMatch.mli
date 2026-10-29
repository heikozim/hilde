(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Id
open Identifier
open Type
open TypeBindings
open TypeParameters
open Stages.Tast
open Env
open EnvTypes

(** We need the environment and the module name to find instances of typeclasses
    in the module where the typechecking happens. This is used to check that,
    when matching a constrained type variable to a type, that the type
    implements the constraints.*)
type ctx = env * module_name

val match_type_with_value : ctx -> ty -> texpr -> type_bindings

(** The smallest and the largest value of an integer type. *)
val int_bounds : signedness -> integer_width -> Z.t * Z.t

(** An integer literal as the parser leaves it. *)
val parse_bigint : string -> Z.t

val match_type : ctx -> ty -> ty -> type_bindings

val match_type_list : ctx -> ty list -> ty list -> type_bindings

val match_typarams : ctx -> typarams -> ty list -> type_bindings

(** Find an instance of the given typeclass given the dispatch type.

Parameters are: environment, source module name, dispatch type, and ID of the
typeclass. *)
val get_instance : env -> module_name -> ty -> decl_id -> (decl * type_bindings) option

(** Hilde: [get_instance] over every instance of the program, not only the
    ones the module sees.  For the monomorphizer; see
    Monomorphize.unmono_type. *)
val get_instance_anywhere : env -> module_name -> ty -> decl_id -> (decl * type_bindings) option
