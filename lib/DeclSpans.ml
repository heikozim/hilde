(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(** Where a declaration was written.

    The compiler drops source positions at the boundary between the abstract
    syntax tree and the environment: {!Stages.Ast} carries a span on every
    declaration, {!EnvTypes.decl} carries none, and neither does the
    monomorphised tree the code generator reads.  So a `#line' directive --
    which needs a line and a file at exactly the moment a C function is
    emitted -- has nothing to work from.

    This is the cheapest thing that changes that: ONE table, from a
    declaration's id to the span it was written at, filled where the two
    already meet and read where the directive is written.  The alternative
    was a new field on {!EnvTypes.decl}, which means editing every place the
    environment record is built -- 67 of them -- for a value only one caller
    wants.

    It is global mutable state and that is a cost, not a feature.  Two things
    make it bearable: a compiler run is one program over one set of sources,
    and {!CodeGen} already keeps its environment the same way.  {!val:reset}
    exists so that a caller which compiles twice in one process is not left
    reading the first run's table. *)
open Id
open Span

let decl_spans: (decl_id, span) Hashtbl.t = Hashtbl.create 256

let record_decl (id: decl_id) (span: span): unit =
  Hashtbl.replace decl_spans id span

let find_decl (id: decl_id): span option =
  Hashtbl.find_opt decl_spans id

let reset (): unit =
  Hashtbl.reset decl_spans

let count (): int =
  Hashtbl.length decl_spans
