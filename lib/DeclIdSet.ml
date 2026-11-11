(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

module DeclIdSet =
  Set.Make(
      struct
        open Id
        type t = decl_id
        let compare (a: decl_id) (b: decl_id): int =
          let DeclId a' = a
          and DeclId b' = b in
          compare a' b'
      end
    )
