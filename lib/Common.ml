(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

(** Simple types used throughout the codebase. *)

(* The kinds the function being typed may end with, from its
   raises clause; None when the function is foreign.  Set around the
   typing of a body by TypingPass, read by the call check in
   TypeCheckExpr.  It lives here because TypingPass may not depend on
   TypeCheckExpr: the two are one check, and a module cycle would not
   build. *)
let current_raises: string list option ref = ref None

(* Whether the module being combined is the test programme that
   `hilde test --contracts' generates for one module.  Set around the
   combining of that programme by TestRunner, read by the import check in
   ImportResolution.  It lives here because ImportResolution may not depend
   on TestRunner: the driver imports the module under test, whose contracts
   it checks, and a module cycle would not build. *)
let test_driver_compiling: bool ref = ref false

(** The five arithmetic operators.  Remainder is what is left of the
    division that Divide makes, so it has the sign of the dividend. *)
type arithmetic_operator =
  | Add
  | Subtract
  | Multiply
  | Divide
  | Remainder
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
  | ThreadBoundPragma
  (** At a type declaration: a value of the type must stay on the thread
      that made it, so it is never handed to another task. *)

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
