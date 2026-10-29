(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

(** This module implements the checking of various typeclass rules. *)
open Id
open Identifier
open Type
open TypeParameters
open Env
open EnvTypes

(** Given the universe a typeclass accepts types from, and the argument to an
    instance of that typeclass, check the argument's universe is acceptable. *)
val check_instance_argument_has_right_universe : universe -> ty -> unit

(** Given the set of type parameters of a generic instance, and the instance's
    argument type, check the argument has the right shape. That is, it is
    either:

    1. A concrete type.

    2. A generic type applid to a set of *distinct* type variables, which are
       all the variables in the type parameter set.

 *)
val check_instance_argument_has_right_shape : typarams -> ty -> unit

(** Given the argument types to two instances of the same typeclass, check
    whether they overlap. *)
val overlapping_instances : ty -> ty -> bool

(** Given every instance of a given typeclass in the PROGRAM, and a type
    argument, check whether an instance with that type argument would overlap
    with any of them.

    The check is program-wide and not per module: two modules may not both
    instantiate the same typeclass for the same type.  Method resolution in
    {!TypeMatch} treats more than one matching instance as an internal error,
    so this is what makes that assumption true.

    The environment and the module id of the new instance are there for the
    error message, which names the module of each of the two instances. *)
val check_instance_unique_in_program : env -> mod_id -> decl list -> ty -> unit

(** Given the ID of the module an instance is defined in, the ID of the module
    the typeclass being implemented is from, and the argument type, check the
    orphan rules.

    A typeclass is local if it is defined in this module, and foreign
    otherwise. A type is local if it is defined in this module, and foreign
    otherwise; a built-in type is local only in the modules the compiler
    injects, Hilde.Pervasive and Hilde.Memory.

    The four cases are unchanged:

        1. Local typeclass and local type = ok
        2. Local typeclass and foreign type = ok
        3. Foreign typeclass and local type = ok
        4. Foreign typeclass and foreign type = bad

    What changed in Hilde is which types fall under "local". Upstream a
    built-in type counted as local in every module, so case 4 could never
    arise for one: any module could give Nat8 an instance of any foreign
    typeclass, and the instance was then never consulted. Case 4 with a
    built-in type has its own message, because "both foreign" does not
    tell a reader who wrote `instance TrappingNegation(Nat8)` what is
    foreign about Nat8.
*)
val check_instance_orphan_rules : env -> mod_id -> mod_id -> ty -> unit

(** We don't allow any of the type parameters of a generic instance to have the
    same name as the type parameter of the corresponding typeclass.

  This is a hack to get around: https://github.com/austral/austral/issues/244

  But this might, I suspect, become part of the language because it reduces
  confusion. *)
val check_disjoint_typarams : identifier -> typarams -> unit
