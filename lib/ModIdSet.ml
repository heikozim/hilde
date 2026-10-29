(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

module ModIdSet =
  Set.Make(
      struct
        open Id
        type t = mod_id
        let compare (a: t) (b: t): int =
          let ModId a' = a
          and ModId b' = b in
          compare a' b'
      end
    )
