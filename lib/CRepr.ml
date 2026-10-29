(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Common
open Escape

(** This module defines types for representing C code. *)

type c_function_linkage =
  | LinkageInternal
  | LinkageExternal

type c_ty =
  | CNamedType of string
  | CPointer of c_ty
  | CStructType of c_struct
  | CUnionType of c_slot list
[@@deriving show]

and c_slot = CSlot of string * c_ty
and c_struct = CStruct of string option * c_slot list
and c_param = CValueParam of string * c_ty

type c_expr =
  | CBool of bool
  | CInt of string
  | CFloat of string
  | CString of escaped_string
  | CVar of string
  | CFuncall of string * c_expr list
  | CFptrCall of c_expr * c_ty * c_ty list * c_expr list
  | CCast of c_expr * c_ty
  | CArithmetic of arithmetic_operator * c_expr * c_expr
  | CComparison of comparison_operator * c_expr * c_expr
  | CConjunction of c_expr * c_expr
  | CDisjunction of c_expr * c_expr
  | CNegation of c_expr
  | CIfExpression of c_expr * c_expr * c_expr
  | CStructInitializer of (string * c_expr) list
  | CStructAccessor of c_expr * string
  | CPointerStructAccessor of c_expr * string
  | CIndex of c_expr * c_expr
  | CAddressOf of c_expr
  | CPath of c_expr * c_path_elem list
  | CEmbed of c_ty option * string * c_expr list
  | CDeref of c_expr
  | CSizeOf of c_ty

and c_path_elem =
  | CPathSlot of string
  | CPathPointer of string

type c_stmt =
  | CLet of string * c_ty * c_expr option
  | CAssign of c_expr * c_expr
  | CDiscarding of c_expr
  | CIf of c_expr * c_stmt * c_stmt
  | CSwitch of c_expr * c_switch_case list
  (* A switch over an integer: each arm with its labels, and the statement
     of the default. *)
  | CIntSwitch of c_expr * (c_expr list * c_stmt) list * c_stmt
  | CWhile of c_expr * c_stmt
  | CFor of string * c_expr * c_stmt
  | CReturn of c_expr
  | CBlock of c_stmt list
  | CExplicitBlock of c_stmt list
  | CLocalFunctionDeclaration of string * c_param list * c_ty * c_function_linkage

(** Represents a case of a C switch statement *)
and c_switch_case =
  CSwitchCase of c_expr * c_stmt

(* The comment written above a declaration, and optionally
   where the declaration was written.

   The position lives HERE and not in a declaration of its own, because
   `decl_order' in CodeGen sorts declarations by kind so that the C
   compiler never meets an incomplete type.  A `#line' of its own kind
   would be sorted away from the function it belongs to; carried in the
   desc it cannot be, because the two are one value. *)
type desc =
  | Desc of string
  | DescAt of string * int * string

type c_decl =
  | CMacro of desc * string * c_expr
  | CConstantDefinition of desc * string * c_ty * c_expr
  | CByteArrayDefinition of desc * string * string
  | CStructForwardDeclaration of desc * string
  | CTypeDefinition of desc * string * c_ty
  | CStructDefinition of desc * c_struct
  | CNamedStructDefinition of desc * string * c_slot list
  | CEnumDefinition of desc * string * string list
  | CFunctionDeclaration of desc * string * c_param list * c_ty * c_function_linkage
  | CFunctionDefinition of desc * string * c_param list * c_ty * c_stmt

type c_unit = CUnit of string * c_decl list
