(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

(** Compiler stages. *)

(** The AST is the CST, but imports are qualified and `let` statements are
    reshaped. *)
(* The error kinds of a raises clause.  Names as written, in the order
   written; the check compares sets, the docs keep the order.
   One alias, one place: every stage's function carries it. *)
type raises = string list

module Ast = struct
  open Identifier
  open Common
  open Span
  open Escape

  type qtypespec =
    | QTypeSpecifier of qident * qtypespec list
    | QReadRef of qtypespec * qtypespec
    | QWriteRef of qtypespec * qtypespec
    | QSpan of qtypespec * qtypespec
    | QSpanWrite of qtypespec * qtypespec
  [@@deriving show]

  type qbinding =
    QBinding of {
        name: identifier;
        ty: qtypespec;
        rename: identifier;
      }

  (* A pattern of a `when'.  Float and string literals are refused by the
     abstraction pass and never get this far. *)
  type apattern =
    | PVar of span * identifier
    | PWild of span
    | PBool of span * bool
    | PInt of span * string
    | PRange of span * string * string
    | PVariant of span * identifier * apattern list

  type astmt =
    | ASkip of span
    | ALet of span * mutability * identifier * qtypespec * astmt
    | ADestructure of span * mutability * qbinding list * aexpr * astmt
    | AAssign of span * aexpr * aexpr
    | AInitialAssign of qident * qtypespec * aexpr
    | AIf of span * aexpr * astmt * astmt
    | AWhen of span * aexpr * astmt
    | ACase of span * aexpr * abstract_when list
    (* A case with patterns. *)
    | APatternCase of span * aexpr * pattern_when list
    | AWhile of span * aexpr * astmt
    | AFor of {
        span: span;
        name: identifier;
        initial: aexpr;
        final: aexpr;
        body: astmt
      }
    | ABorrow of {
        span: span;
        original: identifier;
        rename: identifier;
        region: identifier;
        body: astmt;
        mode: borrow_stmt_kind
      }
    | ABlock of span * astmt * astmt
    | ADiscarding of span * aexpr
    | AReturn of span * aexpr
    (* The raise statement, with its error kind.  The kind rides the
       statement to the check, which holds it against the clause; the
       code generator writes the runtime stop with the kind as its message. *)
    | ARaise of span * string
    (* A variable whose type is its value's, written
       ONLY by the code generated for `@template' (lib/Jinja.ml) -- the
       language has no such statement, so a programme cannot write one.
       It becomes the LetTmp that LiftControlPass already makes. *)
    | ALetTmp of identifier * aexpr

  and aexpr =
    | NilConstant
    | BoolConstant of bool
    | IntConstant of string
    | FloatConstant of string
    | StringConstant of escaped_string
    | Variable of qident
    | FunctionCall of qident * abstract_arglist
    | ArithmeticExpression of arithmetic_operator * aexpr * aexpr
    | Comparison of comparison_operator * aexpr * aexpr
    | Conjunction of aexpr * aexpr
    | Disjunction of aexpr * aexpr
    | Negation of aexpr
    | ArithNegation of aexpr
    | IfExpression of aexpr * aexpr * aexpr
    | Path of qident * path_elem list
    | RefPath of qident * path_elem list * borrowing_mode
    | Embed of span * qtypespec * string * aexpr list
    | Deref of aexpr
    | Typecast of aexpr * qtypespec
    | SizeOf of qtypespec
    | BorrowExpr of borrowing_mode * qident
    | Reborrow of qident
    | Question of span * aexpr

  and abstract_when =
    | AbstractWhen of identifier * qbinding list * astmt

  and pattern_when =
    | PatternWhen of span * apattern list * astmt

  and abstract_arglist =
    | Positional of aexpr list
    | Named of (identifier * aexpr) list

  and path_elem =
    | SlotAccessor of identifier
    | PointerSlotAccessor of identifier
    | ArrayIndex of aexpr
end

(** The combined representation merges the interface and body. *)
module Combined = struct
  open Identifier
  open Common
  open Imports
  open Ast
  open Type
  open TypeParameter
  open TypeParameters
  open Span

  type combined_module = CombinedModule of {
        name: module_name;
        kind: module_kind;
        interface_docstring: docstring;
        interface_imports: import_map;
        body_docstring: docstring;
        body_imports: import_map;
        decls: combined_definition list;
      }

  and combined_definition =
    | CConstant of span * vis * identifier * qtypespec * aexpr * docstring
    | CRecord of span * type_vis * identifier * typarams * universe * qslot list * docstring
    | CUnion of span * type_vis * identifier * typarams * universe * qcase list * docstring
    | CFunction of span * vis * identifier * typarams * qparam list * qtypespec * astmt * docstring * raises * pragma list
    | CTypeclass of span * vis * identifier * type_parameter * combined_method_decl list * docstring
    | CInstance of span * vis * qident * typarams * qtypespec * combined_method_def list * docstring

  and qslot = QualifiedSlot of identifier * qtypespec

  and qcase = QualifiedCase of identifier * qslot list

  and qparam = QualifiedParameter of identifier * qtypespec

  and combined_method_decl = CMethodDecl of identifier * typarams * qparam list * qtypespec * docstring * raises

  and combined_method_def = CMethodDef of identifier * typarams * qparam list * qtypespec * docstring * astmt
end

(* The AST, but expressions in control structures are lifted into temporaries. *)
module AstLC = struct
  open Identifier
  open Common
  open Span
  open Escape

  type qtypespec = Ast.qtypespec

  type qbinding = Ast.qbinding

  type apattern = Ast.apattern

  type astmt =
    | ASkip of span
    | ALet of span * mutability * identifier * qtypespec * astmt
    | ADestructure of span * mutability * qbinding list * aexpr * astmt
    | AAssign of span * aexpr * aexpr
    | AInitialAssign of qident * qtypespec * aexpr
    | AIf of span * aexpr * astmt * astmt
    | AWhen of span * aexpr * astmt
    | ACase of span * aexpr * abstract_when list
    (* A case with patterns. *)
    | APatternCase of span * aexpr * pattern_when list
    | AWhile of span * aexpr * astmt
    | AFor of {
        span: span;
        name: identifier;
        initial: aexpr;
        final: aexpr;
        body: astmt
      }
    | ABorrow of {
        span: span;
        original: identifier;
        rename: identifier;
        region: identifier;
        body: astmt;
        mode: borrow_stmt_kind
      }
    | ABlock of span * astmt * astmt
    | ADiscarding of span * aexpr
    | AReturn of span * aexpr
    (* The raise statement with its error kind, as in Ast. *)
    | ARaise of span * string
    | LetTmp of identifier * aexpr
    | AssignTmp of identifier * aexpr

  and aexpr =
    | NilConstant
    | BoolConstant of bool
    | IntConstant of string
    | FloatConstant of string
    | StringConstant of escaped_string
    | Variable of qident
    | Temporary of identifier
    | FunctionCall of qident * abstract_arglist
    | ArithmeticExpression of arithmetic_operator * aexpr * aexpr
    | Comparison of comparison_operator * aexpr * aexpr
    | Conjunction of aexpr * aexpr
    | Disjunction of aexpr * aexpr
    | Negation of aexpr
    | ArithNegation of aexpr
    | IfExpression of aexpr * aexpr * aexpr
    | Path of qident * path_elem list
    | RefPath of qident * path_elem list * borrowing_mode
    | Embed of span * qtypespec * string * aexpr list
    | Deref of aexpr
    | Typecast of aexpr * qtypespec
    | SizeOf of qtypespec
    | BorrowExpr of borrowing_mode * qident
    | Reborrow of qident
    | Question of span * aexpr

  and abstract_when =
    | AbstractWhen of identifier * qbinding list * astmt

  and pattern_when =
    | PatternWhen of span * apattern list * astmt

  and abstract_arglist =
    | Positional of aexpr list
    | Named of (identifier * aexpr) list

  and path_elem =
    | SlotAccessor of identifier
    | PointerSlotAccessor of identifier
    | ArrayIndex of aexpr
end

(** The AstLC, but paths are desugared. *)
module AstDP = struct
  open Identifier
  open Common
  open Span
  open Escape

  type qtypespec = Ast.qtypespec

  type qbinding = Ast.qbinding

  type apattern = Ast.apattern

  type astmt =
    | ASkip of span
    | ALet of span * mutability * identifier * qtypespec * astmt
    | ADestructure of span * mutability * qbinding list * aexpr * astmt
    | AAssign of span * aexpr * aexpr
    | AAssignVar of span * qident * aexpr
    | AInitialAssign of qident * qtypespec * aexpr
    | AIf of span * aexpr * astmt * astmt
    | AWhen of span * aexpr * astmt
    | ACase of span * aexpr * abstract_when list
    (* A case with patterns. *)
    | APatternCase of span * aexpr * pattern_when list
    | AWhile of span * aexpr * astmt
    | AFor of {
        span: span;
        name: identifier;
        initial: aexpr;
        final: aexpr;
        body: astmt
      }
    | ABorrow of {
        span: span;
        original: identifier;
        rename: identifier;
        region: identifier;
        body: astmt;
        mode: borrow_stmt_kind
      }
    | ABlock of span * astmt * astmt
    | ADiscarding of span * aexpr
    | AReturn of span * aexpr
    (* The raise statement with its error kind, as in Ast. *)
    | ARaise of span * string
    | LetTmp of identifier * aexpr
    | AssignTmp of identifier * aexpr

  and aexpr =
    | NilConstant
    | BoolConstant of bool
    | IntConstant of string
    | FloatConstant of string
    | StringConstant of escaped_string
    | Variable of qident
    | Temporary of identifier
    | FunctionCall of qident * abstract_arglist
    | ArithmeticExpression of arithmetic_operator * aexpr * aexpr
    | Comparison of comparison_operator * aexpr * aexpr
    | Conjunction of aexpr * aexpr
    | Disjunction of aexpr * aexpr
    | Negation of aexpr
    | ArithNegation of aexpr
    | IfExpression of aexpr * aexpr * aexpr
    | Embed of span * qtypespec * string * aexpr list
    | Deref of aexpr
    | Typecast of aexpr * qtypespec
    | SizeOf of qtypespec
    | BorrowExpr of borrowing_mode * qident
    | Reborrow of qident
    (* The borrow of a path's head, which borrows the variable itself; a
       BorrowExpr is one the programmer wrote. *)
    | PathBorrow of borrowing_mode * qident
    | Question of span * aexpr
    (* Path expressions *)
    | SlotAccessor of aexpr * identifier
    | PointerSlotAccessor of aexpr * identifier
    | ArrayIndex of aexpr * aexpr
    (* A reference to part of a value, &(path) or &!(path).  The path
       inside is the chain of accessors DesugarPaths made; the mode is the
       kind of reference the programmer asked for. *)
    | RefTransform of borrowing_mode * aexpr

  and abstract_when =
    | AbstractWhen of identifier * qbinding list * astmt

  and pattern_when =
    | PatternWhen of span * apattern list * astmt

  and abstract_arglist =
    | Positional of aexpr list
    | Named of (identifier * aexpr) list
end

(** The AstDP, but anonymous borrows are desugared. *)
module AstDB = struct
  open Identifier
  open Common
  open Span
  open Escape

  type qtypespec = Ast.qtypespec

  type qbinding = Ast.qbinding

  type apattern = Ast.apattern

  type astmt =
    | ASkip of span
    | ALet of span * mutability * identifier * qtypespec * astmt
    | ADestructure of span * mutability * qbinding list * aexpr * astmt
    | AAssign of span * aexpr * aexpr
    | AAssignVar of span * qident * aexpr
    | AInitialAssign of qident * qtypespec * aexpr
    | AIf of span * aexpr * astmt * astmt
    | AWhen of span * aexpr * astmt
    | ACase of span * aexpr * abstract_when list
    (* A case with patterns. *)
    | APatternCase of span * aexpr * pattern_when list
    | AWhile of span * aexpr * astmt
    | AFor of {
        span: span;
        name: identifier;
        initial: aexpr;
        final: aexpr;
        body: astmt
      }
    | ABorrow of {
        span: span;
        original: identifier;
        rename: identifier;
        region: identifier;
        body: astmt;
        mode: borrow_stmt_kind
      }
    | ABlock of span * astmt * astmt
    | ADiscarding of span * aexpr
    | AReturn of span * aexpr
    (* The raise statement with its error kind, as in Ast. *)
    | ARaise of span * string
    | LetTmp of identifier * aexpr
    | AssignTmp of identifier * aexpr
    (* Written ONLY by the code the type checker
       generates for a pattern case.  An immutable variable whose type is
       its value's, scoped to the statement; and the branch of a case that
       the deciding phase has already ruled out. *)
    | ALetInfer of span * identifier * aexpr * astmt
    | AUnreachable of span

  and aexpr =
    | NilConstant
    | BoolConstant of bool
    | IntConstant of string
    | FloatConstant of string
    | StringConstant of escaped_string
    | Variable of qident
    | Temporary of identifier
    | FunctionCall of qident * abstract_arglist
    | ArithmeticExpression of arithmetic_operator * aexpr * aexpr
    | Comparison of comparison_operator * aexpr * aexpr
    | Conjunction of aexpr * aexpr
    | Disjunction of aexpr * aexpr
    | Negation of aexpr
    | ArithNegation of aexpr
    | IfExpression of aexpr * aexpr * aexpr
    | Embed of span * qtypespec * string * aexpr list
    | Deref of aexpr
    | Typecast of aexpr * qtypespec
    | SizeOf of qtypespec
    | Question of span * aexpr
    (* Path expressions *)
    | SlotAccessor of aexpr * identifier
    | PointerSlotAccessor of aexpr * identifier
    | ArrayIndex of aexpr * aexpr
    (* A reference to part of a value, &(path) or &!(path).  The path
       inside is the chain of accessors DesugarPaths made; the mode is the
       kind of reference the programmer asked for. *)
    | RefTransform of borrowing_mode * aexpr

  and abstract_when =
    | AbstractWhen of identifier * qbinding list * astmt
    (* Written ONLY by the code the type checker
       generates for a pattern case.  Every slot is bound, slot name to
       rename, with the slot's own type -- no type is written. *)
    | AbstractWhenSlots of identifier * (identifier * identifier) list * astmt

  and pattern_when =
    | PatternWhen of span * apattern list * astmt

  and abstract_arglist =
    | Positional of aexpr list
    | Named of (identifier * aexpr) list
end

(** The combined representation, but bodies are thoroughly desugared. *)
module SmallCombined = struct
  open Identifier
  open Common
  open Imports
  open AstDB
  open Type
  open TypeParameter
  open TypeParameters
  open Span

  type qslot = Combined.qslot
  type qcase = Combined.qcase
  type qparam = Combined.qparam

  type combined_module = CombinedModule of {
        name: module_name;
        kind: module_kind;
        interface_docstring: docstring;
        interface_imports: import_map;
        body_docstring: docstring;
        body_imports: import_map;
        decls: combined_definition list;
      }

  and combined_definition =
    | CConstant of span * vis * identifier * qtypespec * aexpr * docstring
    | CRecord of span * type_vis * identifier * typarams * universe * qslot
 list * docstring
    | CUnion of span * type_vis * identifier * typarams * universe * qcase list * docstring
    | CFunction of span * vis * identifier * typarams * qparam list * qtypespec * astmt * docstring * raises * pragma list
    | CTypeclass of span * vis * identifier * type_parameter * Combined.combined_method_decl list * docstring
    | CInstance of span * vis * qident * typarams * qtypespec * combined_method_def list * docstring

  and combined_method_def = CMethodDef of identifier * typarams * qparam list * qtypespec * docstring * astmt
end

(** The linked representation is essentially the same as the combined
    representation, but declarations are linked to their corresponding entry in
    the environment. *)
module Linked = struct
  open Identifier
  open Common
  open Imports
  open AstDB
  open Type
  open TypeParameter
  open TypeParameters
  open Id

  type linked_module = LinkedModule of {
        mod_id: mod_id;
        name: module_name;
        kind: module_kind;
        interface_docstring: docstring;
        interface_imports: import_map;
        body_docstring: docstring;
        body_imports: import_map;
        decls: linked_definition list;
      }

  and linked_definition =
    | LConstant of decl_id * vis * identifier * ty * aexpr * docstring
    | LRecord of decl_id * type_vis * identifier * typarams * universe * typed_slot list * docstring
    | LUnion of decl_id * type_vis * identifier * typarams * universe * linked_case list * docstring
    | LFunction of decl_id * vis * identifier * typarams * value_parameter list * ty * astmt * docstring * raises * pragma list
    | LTypeclass of decl_id * vis * identifier * type_parameter * linked_method_decl list * docstring
    | LInstance of decl_id * vis * qident * typarams * ty * linked_method_def list * docstring

  and linked_case = LCase of decl_id * identifier * typed_slot list

  and linked_method_decl = LMethodDecl of decl_id * identifier * value_parameter list * ty * docstring * raises

  and linked_method_def = LMethodDef of ins_meth_id * identifier * value_parameter list * ty * docstring * astmt
end

(** The typed AST. *)
module Tast = struct
  open Identifier
  open Common
  open Escape
  open Type
  open TypeParameter
  open TypeParameters
  open TypeBindings
  open Span
  open Linked
  open Id

  type typed_binding =
    TypedBinding of {
        name: identifier;
        ty: ty;
        rename: identifier;
      }
  [@@deriving (show, sexp)]

  type case_ref =
    | CasePlain
    | CaseRef
  [@@deriving (show, sexp)]

  type tstmt =
    | TSkip of span
    | TLet of span * mutability * identifier * ty * tstmt
    | TDestructure of span * mutability * typed_binding list * texpr * tstmt
    | TAssign of span * texpr * texpr
    | TAssignVar of span * qident * texpr
    | TInitialAssign of qident * texpr
    | TIf of span * texpr * tstmt * tstmt
    | TCase of span * texpr * typed_when list * case_ref
    | TWhile of span * texpr * tstmt
    | TFor of span * identifier * texpr * texpr * tstmt
    | TBorrow of {
        span: span;
        original: identifier;
        rename: identifier;
        region: identifier;
        orig_type: ty;
        ref_type: ty;
        body: tstmt;
        mode: borrow_stmt_kind
      }
    | TBlock of span * tstmt * tstmt
    | TDiscarding of span * texpr
    | TReturn of span * texpr
    (* The typed raise, its kind fixed at translation time. *)
    | TRaise of span * string
    | TLetTmp of identifier * ty * texpr
    | TAssignTmp of identifier * texpr
    (* A branch of a case that cannot run.  Generated
       only for a pattern case, only as the whole body of a when. *)
    | TUnreachable of span
    (* A case over an integer whose patterns are all literals and ranges.
       Each arm has the values that choose it, as decimal text, none of
       them in an arm before it; the last statement runs for every other
       value.  Generated only for a pattern case. *)
    | TSwitch of span * texpr * (string list * tstmt) list * tstmt
  [@@deriving show]

  and texpr =
    | TNilConstant
    | TBoolConstant of bool
    | TIntConstant of string
    | TFloatConstant of string
    | TStringConstant of escaped_string
    | TConstVar of qident * ty
    | TParamVar of identifier * ty
    | TLocalVar of identifier * ty
    | TFunVar of decl_id * ty * type_bindings
    | TTemporary of identifier * ty
    (** Represents accessing a function as a value. *)
    | TFuncall of decl_id * qident * texpr list * ty * type_bindings
    | TMethodCall of ins_meth_id * qident * typarams * texpr list * ty * type_bindings
    | TVarMethodCall of {
        source_module_name: module_name;
        typeclass_id: decl_id;
        params: value_parameter list;
        method_name: qident;
        args: texpr list;
        dispatch_ty: ty;
        rt: ty;
        bindings: type_bindings;
      }
    | TFptrCall of identifier * texpr list * ty
    | TCast of texpr * ty
    | TComparison of comparison_operator * texpr * texpr
    | TConjunction of texpr * texpr
    | TDisjunction of texpr * texpr
    | TNegation of texpr
    | TIfExpression of texpr * texpr * texpr
    | TRecordConstructor of ty * (identifier * texpr) list
    | TUnionConstructor of ty * identifier * (identifier * texpr) list
    | TSlotAccessor of texpr * identifier * ty
    | TPointerSlotAccessor of texpr * identifier * ty
    | TArrayIndex of texpr * texpr * ty
    | TSpanIndex of texpr * texpr * ty
    | TEmbed of ty * string * texpr list
    | TDeref of texpr
    | TSizeOf of ty
  [@@deriving show]

  and typed_when =
    TypedWhen of identifier * typed_binding list * tstmt
  [@@deriving show]

  and typed_arglist =
    | TPositionalArglist of texpr list
    | TNamedArglist of (identifier * texpr) list
  [@@deriving show]

  type typed_method_decl =
    TypedMethodDecl of decl_id * identifier * value_parameter list * ty

  type typed_method_def =
    TypedMethodDef of ins_meth_id * identifier * value_parameter list * ty * tstmt

  type typed_decl =
    | TConstant of decl_id * vis * identifier * ty * texpr * docstring
    | TRecord of decl_id * type_vis * identifier * typarams * universe * typed_slot list * docstring
    | TUnion of decl_id * type_vis * identifier * typarams * universe * linked_case list * docstring
    | TFunction of decl_id * vis * identifier * typarams * value_parameter list * ty * tstmt * docstring * raises
    | TForeignFunction of decl_id * vis * identifier * value_parameter list * ty * string * docstring
    | TTypeClass of decl_id * vis * identifier * type_parameter * typed_method_decl list * docstring
    | TInstance of decl_id * vis * qident * typarams * ty * typed_method_def list * docstring

  type typed_module = TypedModule of module_name * typed_decl list
end

(** Monomorphic typed AST. *)
module Mtast = struct
  open Id
  open Identifier
  open Common
  open Escape
  open MonoType

  type mono_binding =
    MonoBinding of {
        name: identifier;
        ty: mono_ty;
        rename: identifier;
      }

  type mono_module = MonoModule of module_name * mdecl list

  and mdecl =
    | MConstant of decl_id * identifier * mono_ty * mexpr
    | MRecord of decl_id * identifier * mono_slot list
    | MRecordMonomorph of mono_id * mono_slot list
    | MUnion of decl_id * identifier * mono_case list
    | MUnionMonomorph of mono_id * mono_case list
    | MFunction of decl_id * identifier * mvalue_parameter list * mono_ty * mstmt
    | MFunctionMonomorph of mono_id * mvalue_parameter list * mono_ty * mstmt
    | MForeignFunction of decl_id * identifier * mvalue_parameter list * mono_ty * string
    | MConcreteInstance of decl_id * qident * mono_ty  * concrete_method list
    | MMethodMonomorph of mono_id * mvalue_parameter list * mono_ty * mstmt

  and concrete_method =
    MConcreteMethod of ins_meth_id * identifier * mvalue_parameter list * mono_ty * mstmt

  and mstmt =
    | MSkip
    | MLet of identifier * mono_ty * mstmt
    | MDestructure of mono_binding list * mexpr * mstmt
    | MAssign of mexpr * mexpr
    | MAssignVar of qident * mexpr
    | MInitialAssign of qident * mexpr
    | MIf of mexpr * mstmt * mstmt
    | MCase of mexpr * mtyped_when list * Tast.case_ref
    | MWhile of mexpr * mstmt
    | MFor of identifier * mexpr * mexpr * mstmt
    | MBorrow of {
        original: identifier;
        rename: identifier;
        region: identifier;
        orig_type: mono_ty;
        ref_type: mono_ty;
        body: mstmt;
        mode: borrow_stmt_kind
      }
    | MBlock of mstmt * mstmt
    | MDiscarding of mexpr
    | MReturn of mexpr
    (* The mono raise, its kind carried to the code generator. *)
    | MRaise of string
    | MLetTmp of identifier * mono_ty * mexpr
    | MAssignTmp of identifier * mexpr
    | MUnreachable
    | MSwitch of mexpr * (string list * mstmt) list * mstmt

  and mexpr =
    | MNilConstant
    | MBoolConstant of bool
    | MIntConstant of string
    | MFloatConstant of string
    | MStringConstant of escaped_string
    | MConstVar of qident * mono_ty
    | MParamVar of identifier * mono_ty
    | MLocalVar of identifier * mono_ty
    | MTemporary of identifier * mono_ty
    | MGenericFunVar of mono_id * mono_ty
    | MConcreteFunVar of decl_id * mono_ty
    | MConcreteFuncall of decl_id * qident * mexpr list * mono_ty
    (** Represents a call to a concrete function. *)
    | MGenericFuncall of mono_id * mexpr list * mono_ty
    (** Represents a call to a generic function. *)
    | MConcreteMethodCall of ins_meth_id * qident * mexpr list * mono_ty
    (** Represents a call to an instance method of a concrete instance. *)
    | MGenericMethodCall of ins_meth_id * mono_id * mexpr list * mono_ty
    (** Represents a call to an instance method of a generic instance. *)
    | MFptrCall of identifier * mexpr list * mono_ty
    | MCast of mexpr * mono_ty
    | MComparison of comparison_operator * mexpr * mexpr
    | MConjunction of mexpr * mexpr
    | MDisjunction of mexpr * mexpr
    | MNegation of mexpr
    | MIfExpression of mexpr * mexpr * mexpr
    | MRecordConstructor of mono_ty * (identifier * mexpr) list
    | MUnionConstructor of mono_ty * identifier * (identifier * mexpr) list
    | MEmbed of mono_ty * string * mexpr list
    | MDeref of mexpr
    | MTypecast of mexpr * mono_ty
    | MSizeOf of mono_ty
    | MSlotAccessor of mexpr * identifier * mono_ty
    | MPointerSlotAccessor of mexpr * identifier * mono_ty
    | MArrayIndex of mexpr * mexpr * mono_ty
    | MSpanIndex of mexpr * mexpr * mono_ty

  and mtyped_when =
    MTypedWhen of identifier * mono_binding list * mstmt

  and mvalue_parameter =
    MValueParameter of identifier * mono_ty

  type mono_method =
    MonoMethod of {
        method_id: ins_meth_id;
        params: mvalue_parameter list;
        rt: mono_ty;
        body: mstmt;
      }
end
