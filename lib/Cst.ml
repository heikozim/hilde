(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** This module implements Hilde's concrete syntax tree, the first
    intermediate representation in the compiler. *)
open Identifier
open Common
open Type
open Span

type concrete_module_interface =
  ConcreteModuleInterface of module_name * docstring * concrete_import_list list * concrete_decl list

and concrete_module_body =
  (* The `foreign_c' is the C the module names in its head: the libraries of
     `pragma Foreign_Library(Name => "...")' and the headers of
     `pragma Foreign_Header(Name => "...")', each in the order written.  It
     is a property of the body and never of the interface: a calling module
     never sees C, and an interface survives a change of library unchanged,
     so a declaration that can change without the interface changing does
     not belong in the interface. *)
  ConcreteModuleBody of module_name * module_kind * foreign_c * docstring * concrete_import_list list * concrete_def list

and foreign_c = {
    c_libraries: string list;
    c_headers: string list;
  }

and concrete_import_list =
  ConcreteImportList of module_name * concrete_import list

and concrete_import =
  ConcreteImport of identifier * identifier option

and concrete_decl =
  | ConcreteConstantDecl of span * identifier * typespec * docstring
  | ConcreteOpaqueTypeDecl of span * identifier * concrete_type_param list * universe * docstring
  | ConcreteRecordDecl of concrete_record
  | ConcreteUnionDecl of concrete_union
  | ConcreteFunctionDecl of span * identifier * concrete_type_param list * concrete_param list * typespec * docstring * contract_clause list * pragma list
  | ConcreteTypeClassDecl of concrete_typeclass
  | ConcreteInstanceDecl of span * identifier * concrete_type_param list * typespec * docstring

and concrete_def =
  | ConcreteConstantDef of span * identifier * typespec * cexpr * docstring
  | ConcreteRecordDef of concrete_record
  | ConcreteUnionDef of concrete_union
  | ConcreteFunctionDef of span * identifier * concrete_type_param list * concrete_param list * typespec * cstmt * docstring * pragma list * contract_clause list
  | ConcreteTypeClassDef of concrete_typeclass
  | ConcreteInstanceDef of concrete_instance

(* A clause of a function's contract: requires or ensures and its
   condition.  The text is the condition as written, each run of white
   space made one space; a violated condition prints it. *)
and contract_clause = ContractClause of {
    kind: contract_kind;
    span: span;
    condition: cexpr;
    text: string;
  }

and contract_kind =
  | Requires
  | Ensures
  | Invariant
  (* The raises clause of the signature.  Its "condition" is the
     text of the kind names joined with ", " (make_raises_clause), the span
     is the clause's. *)
  | RaisesClause

and concrete_record =
  ConcreteRecord of span * identifier * concrete_type_param list * universe * concrete_slot list * docstring * contract_clause list

and concrete_union =
  ConcreteUnion of span * identifier * concrete_type_param list * universe * concrete_case list * docstring

and concrete_slot =
  ConcreteSlot of identifier * typespec

and concrete_case =
  ConcreteCase of identifier * concrete_slot list

and concrete_typeclass =
  ConcreteTypeClass of span * identifier * concrete_type_param * concrete_method_decl list * docstring

and concrete_instance =
  ConcreteInstance of span * identifier * concrete_type_param list * typespec * concrete_method_def list * docstring

and concrete_method_decl =
  ConcreteMethodDecl of identifier * concrete_type_param list * concrete_param list * typespec * docstring * contract_clause list

and concrete_method_def =
  ConcreteMethodDef of identifier * concrete_type_param list * concrete_param list * typespec * cstmt * docstring * contract_clause list

and typespec =
  | TypeSpecifier of identifier * typespec list
  | ConcreteReadRef of typespec * typespec
  | ConcreteWriteRef of typespec * typespec
  | ConcreteSpan of typespec * typespec
  | ConcreteSpanWrite of typespec * typespec

and cexpr =
  | CNilConstant of span
  | CBoolConstant of span * bool
  | CIntConstant of span * string
  | CFloatConstant of span * string
  | CStringConstant of span * string
  (* The CONTENTS of a file, read at compile time.
     It becomes a string constant in the abstraction pass, so nothing
     downstream has to know about it. *)
  | CEmbedFile of span * string
  | CVariable of span * identifier
  | CArith of span * arithmetic_operator * cexpr * cexpr
  | CFuncall of span * identifier * concrete_arglist
  | CComparison of span * comparison_operator * cexpr * cexpr
  | CConjunction of span * cexpr * cexpr
  | CDisjunction of span * cexpr * cexpr
  | CNegation of span * cexpr
  | CArithNegation of span * cexpr
  | CIfExpression of span * cexpr * cexpr * cexpr
  | CPath of span * identifier * concrete_path_elem list
  (* &(path) reads, &!(path) writes; the mode says which. *)
  | CRefPath of span * identifier * concrete_path_elem list * borrowing_mode
  | CEmbed of span * typespec * string * cexpr list
  | CDeref of span * cexpr
  | CTypecast of span * cexpr * typespec
  | CSizeOf of span * typespec
  | CBorrowExpr of span * borrowing_mode * identifier
  | CReborrow of span * identifier
  | CQuestion of span * cexpr
  (* `@execute(&!db, "SQL", values)' and `@migrations'.
     Checked against the migrations and expanded by the abstraction pass
     (lib/Sql.ml). *)
  | CExecute of span * query_target * string * cexpr list
  | CMigrations of span

(* The connection of a query, written `&!db' or `&~db': a borrow the
   generated code may repeat, which an arbitrary expression is not. *)
and query_target =
  | QueryBorrow of identifier
  | QueryReborrow of identifier

and cstmt =
  | CSkip of span
  | CLet of span * mutability * identifier * typespec * cexpr
  | CDestructure of span * mutability * concrete_binding list * cexpr
  | CAssign of span * cexpr * cexpr
  | CIf of span * cexpr * cstmt * cstmt
  | CCase of span * cexpr * concrete_when list
  | CWhile of span * cexpr * cstmt
  | CFor of span * identifier * cexpr * cexpr * cstmt
  | CBorrow of {
      span: span;
      original: identifier;
      rename: identifier;
      region: identifier;
      body: cstmt;
      mode: borrow_stmt_kind
    }
  | CBlock of span * cstmt list
  | CDiscarding of span * cexpr
  | CReturn of span * cexpr
  (* Ends the function with a named error kind.  The name is the
     kind as written; the code generator writes the runtime stop with the
     kind as its message, so the runtime keeps one stop mechanism. *)
  | CRaise of span * identifier
  (* `@template("page.jinja", data, out);', and with the whitespace
     options as a fourth argument.  Expanded
     into ordinary statements by the abstraction pass (lib/Jinja.ml). *)
  | CTemplate of span * string * string list * identifier * identifier
  (* `@query(&!db, "SQL", values) for row: T do ...
     else error do ... end for;'.  Expanded by the abstraction pass
     (lib/Sql.ml). *)
  | CQuery of {
      span: span;
      target: query_target;
      sql: string;
      args: cexpr list;
      row: identifier;
      row_ty: typespec;
      body: cstmt;
      error: identifier;
      handler: cstmt
    }

and concrete_binding =
  ConcreteBinding of  {
      name: identifier;
      ty: typespec;
      rename: identifier;
    }

and condition_branch =
  ConditionBranch of cexpr * cstmt

and concrete_when =
  | ConcreteWhen of identifier * concrete_binding list * cstmt
  (* One or more patterns separated by `|'. *)
  | ConcretePatternWhen of span * concrete_pattern list * cstmt

(* CPName is a bare name: a variable when it begins
   with a lower-case letter, a variant without sub-patterns otherwise --
   the abstraction pass decides.  Float and string literals are parsed only
   so that they can be refused with a message of their own. *)
and concrete_pattern =
  | CPWild of span
  | CPBool of span * bool
  | CPInt of span * string
  | CPRange of span * string * string
  | CPFloat of span * string
  | CPString of span * string
  | CPName of span * identifier
  | CPVariant of span * identifier * concrete_pattern list

and concrete_arglist =
  | ConcretePositionalArgs of cexpr list
  | ConcreteNamedArgs of (identifier * cexpr) list

and concrete_param =
  ConcreteParam of identifier * typespec

and concrete_type_param =
  ConcreteTypeParam of identifier * universe * identifier list

and concrete_path_elem =
  | CSlotAccessor of identifier
  | CPointerSlotAccessor of identifier
  | CArrayIndex of cexpr
