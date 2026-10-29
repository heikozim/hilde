(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** Simple types used throughout the codebase. *)

(* The kinds the function being typed may end with, from its
   raises clause; None when the function is foreign.  Set around the
   typing of a body by TypingPass, read by the call check in
   TypeCheckExpr.  It lives here because TypingPass may not depend on
   TypeCheckExpr: the two are one check, and a module cycle would not
   build. *)
let current_raises: string list option ref = ref None

(** The four arithmetic operators. *)
type arithmetic_operator =
  | Add
  | Subtract
  | Multiply
  | Divide
[@@deriving (show, sexp)]

(** The comparison operators. *)
type comparison_operator =
  | Equal
  | NotEqual
  | LessThan
  | LessThanOrEqual
  | GreaterThan
  | GreaterThanOrEqual
[@@deriving (show, sexp)]

(** The type of documentation strings. *)
type docstring = Docstring of string

(** The type of declaration pragmas. *)
type pragma =
  | ForeignImportPragma of string
  | ForeignExportPragma of string
  | ForeignLibraryPragma of string * string option
  (** The library, and the one system it is linked on when the pragma
      names one. *)
  | ForeignHeaderPragma of string
  | UnsafeModulePragma
  | SlotPragma
  (** At a function declaration in an interface: the function is a slot,
      which one function of the programme may implement. *)
  | ImplementsPragma of string
  (** At a function definition: it implements the slot of that full name,
      Module.function. *)
  | TargetsPragma of string list * string option
  (** Before a module interface: the targets the module is there for, and
      the module to take instead on another target, if there is one. *)

(** Whether a variable is immutable or mutable. *)
type mutability =
  | Immutable
  | Mutable
[@@deriving (show)]

(** Whether a reference is a read reference or a write reference. *)
type borrowing_mode =
  | ReadBorrow
  | WriteBorrow
[@@deriving (show, sexp)]

(** Whether a borrow statement is borrowing as read, write, or reborrow.

    [Read] is a read borrow the programmer wrote, [&x] or a borrow
    statement.  When [x] is a write reference it borrows what the write
    reference points to, and gives a read reference to that.  [PathRead] is
    the read borrow of a path's head, made by DesugarPaths for [x->f] and
    [x.f]; it borrows the variable itself, whatever its type. *)
type borrow_stmt_kind =
  | Read
  | Write
  | Reborrow
  | PathRead
[@@deriving (show, sexp)]

(** Whether a module is safe or unsafe. *)
type module_kind =
  | SafeModule
  | UnsafeModule

(** The visibility of a type: public, opaque, or private. *)
type type_vis =
  | TypeVisPublic
  | TypeVisOpaque
  | TypeVisPrivate

(** The visibility of another declaration: public or private. *)
type vis =
  | VisPublic
  | VisPrivate
