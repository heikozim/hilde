(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

%{
open Identifier
open Common
open Cst
open CstUtil
open Type
open Util
open Span
%}

/* Brackets */
%token LPAREN
%token RPAREN
%token LBRACKET
%token RBRACKET
%token LCURLY
%token RCURLY
/* Arithmetic operators */
%token PLUS
%token MINUS
%token MUL
%token DIV
/* Comparison operators */
%token EQ
%token NEQ
%token LT
%token LTE
%token GT
%token GTE
/* Logical operators */
%token AND
%token OR
%token NOT
/* Borrowing */
%token BORROW_WRITE
%token BORROW_READ
%token SPAN_READ
%token SPAN_WRITE
%token REBORROW
%token REF_TRANSFORM
%token REF_TRANSFORM_WRITE
%token QUESTION
/* Keywords */
%token MODULE
%token IS
%token BODY
%token IMPORT
%token AS
%token END
%token CONSTANT
%token TYPE
%token FUNCTION
%token GENERIC
%token RECORD
%token UNION
%token CASE
%token OF
%token WHEN
%token TYPECLASS
%token INSTANCE
%token METHOD
%token IF
%token THEN
%token ELSE
%token ELSE_IF
%token LET
%token VAR
%token WHILE
%token FOR
%token DO
%token FROM
%token TO
%token BORROW
%token RETURN
%token SKIP
%token UNIVERSE_FREE
%token UNIVERSE_LINEAR
%token UNIVERSE_TYPE
%token UNIVERSE_REGION
%token PRAGMA
%token SIZEOF
%token REQUIRES
%token ENSURES
%token INVARIANT
/* The raises clause of a signature, and the raise statement. */
%token RAISES
%token RAISE
/* Symbols */
%token SEMI
%token COMMA
%token PERIOD
%token COLON
%token HYPHEN_RIGHT
%token RIGHT_ARROW
%token ASSIGN
%token DEREF
/* Patterns */
%token DOTDOT
%token BAR
%token UNDERSCORE
%token <string> RANGE_START
/* Strings and docstrings */
%token <string> STRING_CONSTANT
%token <string> TRIPLE_STRING_CONSTANT
/* Identifiers and constants */
%token NIL
%token TRUE
%token FALSE
%token <string> DEC_CONSTANT
%token <string> HEX_CONSTANT
%token <string> BIN_CONSTANT
%token <string> OCT_CONSTANT
%token <string> CHAR_CONSTANT
%token <string> FLOAT_CONSTANT
%token <string> IDENTIFIER
/* Specials */
%token EMBED
%token BYTES
%token TEMPLATE
%token QUERY
%token EXECUTE
%token MIGRATIONS
/* etc. */
%token EOF

/* Types */

%type <Cst.concrete_module_interface> module_int
%type <Cst.concrete_module_body> module_body
%type <Cst.concrete_decl> standalone_interface_decl
%type <Cst.cstmt> standalone_statement
%type <Cst.cexpr> standalone_expression
%type <Identifier.identifier> standalone_identifier

/* These two lines exist to turn ONE arbitrary resolution into a
   decision.  `!e?` can be read as `(!e)?` or as `!(e?)`, and without a
   precedence menhir reports a shift/reduce conflict in that one state and
   picks the second anyway.  Declaring QUESTION above DEREF says so on
   purpose: the postfix operator binds tighter than the prefix `!`, which is
   how Rust reads the same pair, and `(!e)?` is written with the brackets.
   The grammar has no conflict since the two it had before were removed,
   both about a docstring after a union case's slots (see union_cases). */
%nonassoc DEREF
%nonassoc QUESTION

%start module_int
%start module_body
%start standalone_interface_decl
%start standalone_statement
%start standalone_expression
%start standalone_identifier

%%

/* Entrypoints */

standalone_interface_decl:
  | interface_decl EOF { $1 }
  ;

standalone_statement:
  | statement EOF { $1 }
  ;

standalone_expression:
  | expression EOF { $1 }
  ;

standalone_identifier:
  | identifier EOF { $1 }
  ;

/* Module interfaces and bodies */

module_int:
  | doc=docstringopt pragmas=pragma* imports=import_stmt* MODULE
    name=module_name IS decls=interface_decl*
    END MODULE PERIOD EOF
    { make_module_int name doc pragmas imports decls }
  ;

module_body:
  | doc=docstringopt pragmas=pragma* imports=import_stmt* MODULE BODY
    name=module_name IS decls=body_decl*
    END MODULE BODY PERIOD EOF
    { make_module_body name imports pragmas decls doc }
  ;

/* Imports */

import_stmt:
  | IMPORT name=module_name LPAREN
    symbols=separated_list(COMMA, imported_symbol)
    RPAREN SEMI
    { ConcreteImportList (name, symbols) }
  ;

imported_symbol:
  | name=identifier { ConcreteImport (name, None) }
  | name=identifier AS nickname=identifier { ConcreteImport (name, Some nickname) }
  ;

/* Declarations */

interface_decl:
  | docstringopt pragma* interface_decl_inner { decl_replace_docstring_and_pragmas $3 $1 $2 }
  ;

interface_decl_inner:
  | constant_decl { $1 }
  | type_decl { $1 }
  | record { ConcreteRecordDecl $1 }
  | union { ConcreteUnionDecl $1 }
  | function_decl { $1 }
  | typeclass { ConcreteTypeClassDecl $1 }
  | instance_decl { $1 }
  ;

constant_decl:
  | CONSTANT n=identifier COLON t=typespec SEMI { ConcreteConstantDecl (from_loc $loc, n, t, Docstring "") }
  ;

type_decl:
  | TYPE name=identifier
    typarams=type_parameter_list COLON universe=universe
    SEMI { ConcreteOpaqueTypeDecl (from_loc $loc, name, typarams, universe, Docstring "") }
  ;

record:
  | RECORD name=identifier
    typarams=type_parameter_list COLON universe=universe
    IS items=record_item*
    END SEMI
    { let slots = List.filter_map (fun i -> match i with `Slot s -> Some s | `Invariant _ -> None) items
      and invariants = List.filter_map (fun i -> match i with `Invariant c -> Some c | `Slot _ -> None) items in
      ConcreteRecord (from_loc $loc, name, typarams, universe, slots, Docstring "", invariants) }
  ;

/* A slot of a record, or an invariant of it. */
record_item:
  | s=slot { `Slot s }
  | INVARIANT cond=expression SEMI
    { `Invariant (make_contract_clause Invariant $startpos $startpos(cond) $endpos(cond) cond) }
  ;

slot:
  | docstringopt name=identifier COLON ty=typespec SEMI { ConcreteSlot (name, ty) }
  ;

union:
  | UNION name=identifier
    typarams=type_parameter_list COLON universe=universe
    IS cases=union_cases
    END SEMI { ConcreteUnion (from_loc $loc, name, typarams, universe, cases, Docstring "") }
  ;

/* The cases of a union.  A docstring before a slot and one before a case
   look the same until the token after them, a name or CASE, and one token
   of lookahead cannot see that far.  Written as case* over slot*, the
   parser had to decide at the docstring after a case's slots and took it
   for the next slot's, so a documented case after a case with slots did
   not parse.  Here the docstring after a case's slots is read first and
   the token after it decides.  A docstring is read and dropped, as it was
   before. */
union_cases:
  | { [] }
  | docstringopt cases=next_case { cases }
  ;

/* A case and all the cases after it. */
next_case:
  | CASE name=identifier SEMI rest=union_cases { ConcreteCase (name, []) :: rest }
  | CASE name=identifier IS rest=case_slots
    { let (slots, cases) = rest in ConcreteCase (name, slots) :: cases }
  ;

/* The slots of a case, and the cases after it. */
case_slots:
  | { ([], []) }
  | name=identifier COLON ty=typespec SEMI rest=case_slots
    { let (slots, cases) = rest in (ConcreteSlot (name, ty) :: slots, cases) }
  | docstring rest=slot_or_case { rest }
  | cases=next_case { ([], cases) }
  ;

/* What follows a docstring after a case's slots: a slot or a case. */
slot_or_case:
  | name=identifier COLON ty=typespec SEMI rest=case_slots
    { let (slots, cases) = rest in (ConcreteSlot (name, ty) :: slots, cases) }
  | cases=next_case { ([], cases) }
  ;

function_decl:
  | typarams=generic_segment
    FUNCTION name=identifier LPAREN params=parameter_list RPAREN
    COLON rt=typespec contract=contract_clause* SEMI
    /* $symbolstartpos, as in function_def below: with no
       `generic', $startpos would be where the previous token ended.  Found
       by `hilde query', which reports these spans. */
    { ConcreteFunctionDecl (from_loc ($symbolstartpos, $endpos), name, typarams, params, rt, Docstring "", contract, []) }
  ;

/* A clause of a function's contract.  The raises clause
   rides on the same list: it is part of what the signature
   says, and every pass that walks the clauses already walks it. */
contract_clause:
  | REQUIRES cond=expression
    { make_contract_clause Requires $startpos $startpos(cond) $endpos(cond) cond }
  | ENSURES cond=expression
    { make_contract_clause Ensures $startpos $startpos(cond) $endpos(cond) cond }
  | clause=raises_clause
    { clause }
  ;

/* The raises clause of a signature.  A typeclass's method
   declaration takes it alone: its instances inherit it. */
raises_clause:
  | RAISES kinds=separated_nonempty_list(COMMA, identifier)
    { make_raises_clause $startpos $endpos kinds }
  ;

generic_segment:
  | option(generic_segment_inner) { Option.value $1 ~default:[] }
  ;

generic_segment_inner:
  | GENERIC type_parameter_list { $2 }
  ;

typeclass:
  | TYPECLASS name=identifier LPAREN typaram=type_parameter RPAREN
    IS methods=method_decl* END SEMI
    { ConcreteTypeClass (from_loc $loc, name, typaram, methods, Docstring "") }
  ;

method_decl:
  | doc=docstringopt typarams=generic_segment
    METHOD name=identifier
    LPAREN params=parameter_list RPAREN COLON rt=typespec
    contract=raises_clause* SEMI
   { ConcreteMethodDecl (name, typarams, params, rt, doc, contract) }
  ;

instance_decl:
  | typarams=generic_segment
    INSTANCE name=identifier LPAREN arg=typespec RPAREN SEMI
    /* $symbolstartpos: see function_decl above. */
    { ConcreteInstanceDecl (from_loc ($symbolstartpos, $endpos), name, typarams, arg, Docstring "") }
  ;

body_decl:
  | docstringopt pragma* body_decl_inner { def_replace_docstring_and_pragmas $3 $1 $2 }
  ;

body_decl_inner:
  | constant_def { $1 }
  | record { ConcreteRecordDef $1 }
  | union { ConcreteUnionDef $1 }
  | function_def { $1 }
  | typeclass { ConcreteTypeClassDef $1 }
  | instance_def { $1 }
  ;

constant_def:
  | CONSTANT name=identifier COLON ty=typespec
    ASSIGN v=expression SEMI { ConcreteConstantDef (from_loc $loc, name, ty, v, Docstring "") }
  ;

function_def:
  | typarams=generic_segment
    FUNCTION name=identifier LPAREN params=parameter_list RPAREN
    COLON rt=typespec contract=contract_clause* IS body=block? END SEMI
    /* $symbolstartpos and not $startpos: `generic_segment' is EMPTY for a
       function that is not generic, and menhir's $startpos then falls back to
       where the PREVIOUS token ended -- one or two lines above the word
       `function'.  $symbolstartpos skips leading symbols with no semantic
       value, which is exactly this case.  The position is
       what a `#line' directive is made of, and one that points at the line
       above is worse than none. */
    { ConcreteFunctionDef (from_loc ($symbolstartpos, $endpos), name, typarams, params, rt, Option.value body ~default:(CBlock (from_loc $loc, [])), Docstring "", [], contract) }
  ;

pragma:
  | PRAGMA name=identifier SEMI
    { make_pragma name (ConcretePositionalArgs []) }
  | PRAGMA name=identifier args=argument_list SEMI
    { make_pragma name args }
  ;

instance_def:
  | typarams=generic_segment
    INSTANCE name=identifier LPAREN arg=typespec RPAREN IS
    methods=method_def*
    END SEMI
    /* $symbolstartpos: see function_decl above. */
    { ConcreteInstanceDef (ConcreteInstance (from_loc ($symbolstartpos, $endpos), name, typarams, arg, methods, Docstring "")) }
  ;

method_def:
  | doc=docstringopt typarams=generic_segment
    METHOD name=identifier
    LPAREN params=parameter_list RPAREN COLON rt=typespec
    contract=raises_clause* IS body=block END SEMI
   { ConcreteMethodDef (name, typarams, params, rt, body, doc, contract) }
  ;

/* Statements */

statement:
  | if_statement { $1 }
  | let_stmt { $1 }
  | lvalue ASSIGN expression SEMI { CAssign (from_loc $loc, $1, $3) }
  | expression SEMI { CDiscarding (from_loc $loc, $1) }
  | CASE expression OF when_stmt* END CASE SEMI { CCase (from_loc $loc, $2, $4) }
  | WHILE expression DO block END WHILE SEMI { CWhile (from_loc $loc, $2, $4) }
  | FOR identifier FROM expression TO expression DO block END FOR SEMI { CFor (from_loc $loc, $2, $4, $6, $8) }
  | borrow_stmt { $1 }
  | RETURN expression SEMI { CReturn (from_loc $loc, $2) }
  /* End the function with a named error kind. */
  | RAISE kind=identifier SEMI { CRaise (from_loc $loc, kind) }
  | TEMPLATE LPAREN path=STRING_CONSTANT COMMA data=identifier COMMA out=identifier RPAREN SEMI
    { CTemplate (from_loc $loc, path, [], data, out) }
  | TEMPLATE LPAREN path=STRING_CONSTANT COMMA data=identifier COMMA out=identifier COMMA options=STRING_CONSTANT RPAREN SEMI
    { CTemplate (from_loc $loc, path, List.filter (fun (w: string) -> w <> "") (String.split_on_char ' ' options), data, out) }
  | QUERY LPAREN target=query_target COMMA sql=STRING_CONSTANT args=list(preceded(COMMA, expression)) RPAREN
    FOR row=identifier COLON row_ty=typespec DO body=block
    ELSE error=identifier DO handler=block END FOR SEMI
    { CQuery { span = from_loc $loc; target; sql; args; row; row_ty; body; error; handler } }
  | SKIP SEMI { CSkip (from_loc $loc) }
  ;

if_statement:
  | IF expression THEN block else_clause { CIf (from_loc $loc, $2, $4, $5) }
  ;

else_clause:
  | ELSE_IF expression THEN block else_clause { CIf (from_loc $loc, $2, $4, $5) }
  | ELSE block END IF SEMI { $2 }
  | END IF SEMI { CSkip (from_loc $loc) }
  ;

let_stmt:
  | let_destructure { $1 }
  | let_simple { $1 }
  ;

let_simple:
  | mut=var_mutability name=identifier COLON ty=typespec ASSIGN e=expression SEMI { CLet (from_loc $loc, mut, name, ty, e) }
  ;

let_destructure:
  | mut=var_mutability LCURLY b=binding_list RCURLY ASSIGN e=expression SEMI { CDestructure (from_loc $loc, mut, b, e) }
  ;

binding_list:
  | separated_list(COMMA, binding) { $1 }
  ;

binding:
  | name=identifier COLON ty=typespec { ConcreteBinding { name = name; ty = ty; rename = name } }
  | name=identifier AS rename=identifier COLON ty=typespec { ConcreteBinding { name = name; ty = ty; rename = rename } }
  ;

var_mutability:
  | LET { Immutable }
  | VAR { Mutable }
  ;

lvalue:
  | n=identifier elems=path_rest* { CPath (from_loc $loc, n, elems) }
  ;

/* Patterns.  The old form, a variant with named and typed
   bindings, stays as it was.  A bare `when X do' is parsed as a pattern
   and the abstraction pass turns it back into the old form when every
   `when' of the case is one. */
when_stmt:
  | WHEN identifier LPAREN binding_list RPAREN DO block { ConcreteWhen ($2, $4, $7) }
  | WHEN pats=separated_nonempty_list(BAR, pattern) DO body=block { ConcretePatternWhen (from_loc $loc, pats, body) }
  ;

pattern:
  | UNDERSCORE { CPWild (from_loc $loc) }
  | TRUE { CPBool (from_loc $loc, true) }
  | FALSE { CPBool (from_loc $loc, false) }
  | lit=pattern_int { CPInt (from_loc $loc, lit) }
  | lo=pattern_int DOTDOT hi=pattern_int { CPRange (from_loc $loc, lo, hi) }
  | lo=RANGE_START hi=pattern_int { CPRange (from_loc $loc, remove_char lo '\'', hi) }
  | f=FLOAT_CONSTANT { CPFloat (from_loc $loc, f) }
  | s=STRING_CONSTANT { CPString (from_loc $loc, s) }
  | s=TRIPLE_STRING_CONSTANT { CPString (from_loc $loc, s) }
  | name=identifier { CPName (from_loc $loc, name) }
  | name=identifier LPAREN args=separated_nonempty_list(COMMA, pattern) RPAREN { CPVariant (from_loc $loc, name, args) }
  ;

/* The same five forms as int_constant, and the same conversions. */
pattern_int:
  | DEC_CONSTANT { remove_char $1 '\'' }
  | HEX_CONSTANT { string_of_int (parse_hex (remove_leading (remove_char $1 '\'') 2)) }
  | BIN_CONSTANT { string_of_int (parse_bin (remove_leading (remove_char $1 '\'') 2)) }
  | OCT_CONSTANT { string_of_int (parse_oct (remove_leading (remove_char $1 '\'') 2)) }
  | CHAR_CONSTANT { string_of_int (parse_ascii_char (char_body $1)) }
  ;

borrow_stmt:
  | BORROW name=identifier COLON borrow_stmt_read_or_write LBRACKET typespec COMMA reg=identifier RBRACKET ASSIGN mode=borrow_stmt_mode orig=identifier DO body=block END BORROW SEMI
    { CBorrow { span=from_loc $loc; original=orig; rename=name; region=reg; body=body; mode=mode } }
  ;

borrow_stmt_read_or_write:
  | BORROW_READ { () }
  | BORROW_WRITE { () }
  ;

borrow_stmt_mode:
  | BORROW_READ { Read }
  | BORROW_WRITE { Write }
  | REBORROW { Reborrow }
  ;

block:
  | blocklist { CBlock (from_loc $loc, $1) }

blocklist:
  | statement blocklist { $1 :: $2 }
  | statement { [$1] }
  ;

/* Expressions */

expression:
  | atomic_expression { $1 }
  | compound_expression { $1 }
  ;

atomic_expression:
  | NIL { CNilConstant (from_loc $loc) }
  | TRUE { CBoolConstant (from_loc $loc, true) }
  | FALSE { CBoolConstant (from_loc $loc, false) }
  | int_constant { $1 }
  | float_constant { $1 }
  | string_constant { $1 }
  | path { $1 }
  | ref_path { $1 }
  | variable { $1 }
  | funcall { $1 }
  | parenthesized_expr { $1 }
  | intrinsic { $1 }
  | SIZEOF LPAREN typespec RPAREN { CSizeOf (from_loc $loc, $3) }
  | BORROW_READ identifier { CBorrowExpr (from_loc $loc, ReadBorrow, $2) }
  | BORROW_WRITE identifier { CBorrowExpr (from_loc $loc, WriteBorrow, $2) }
  | REBORROW identifier { CReborrow (from_loc $loc, $2) }
  | DEREF atomic_expression { CDeref (from_loc $loc, $2) }
  (* The propagation operator.  It is postfix and it binds to an
     atomic expression, so `f()?` is the operand and `a + f()?` does not
     parse as `(a + f())?`. *)
  | atomic_expression QUESTION { CQuestion (from_loc $loc, $1) }
  ;

int_constant:
  | DEC_CONSTANT { CIntConstant (from_loc $loc, remove_char $1 '\'') }
  | HEX_CONSTANT { CIntConstant (from_loc $loc, string_of_int (parse_hex (remove_leading (remove_char $1 '\'') 2))) }
  | BIN_CONSTANT { CIntConstant (from_loc $loc, string_of_int (parse_bin (remove_leading (remove_char $1 '\'') 2))) }
  | OCT_CONSTANT { CIntConstant (from_loc $loc, string_of_int (parse_oct (remove_leading (remove_char $1 '\'') 2))) }
  | CHAR_CONSTANT { CIntConstant (from_loc $loc, string_of_int (parse_ascii_char (char_body $1))) }
  ;

float_constant:
  | FLOAT_CONSTANT { CFloatConstant (from_loc $loc, remove_char $1 '\'') }
  ;

string_constant:
  | STRING_CONSTANT { CStringConstant (from_loc $loc, $1) }
  | TRIPLE_STRING_CONSTANT { CStringConstant (from_loc $loc, process_triple_string $1) }
  ;

variable:
  | identifier { CVariable (from_loc $loc, $1) }
  ;

funcall:
  | identifier argument_list { CFuncall (from_loc $loc, $1, $2) }
  ;

parenthesized_expr:
  | LPAREN expression RPAREN { $2 }
  ;

argument_list:
  | LPAREN positional_arglist RPAREN { ConcretePositionalArgs $2 }
  | LPAREN named_arglist RPAREN { ConcreteNamedArgs $2 }
  | LPAREN RPAREN { ConcretePositionalArgs [] }
  ;

positional_arglist:
  | separated_nonempty_list(COMMA, expression) { $1 }
  ;

named_arglist:
  | separated_nonempty_list(COMMA, named_arg) { $1 }
  ;

named_arg:
  | identifier RIGHT_ARROW expression { ($1, $3) }

intrinsic:
  | EMBED LPAREN ty=typespec COMMA exp=STRING_CONSTANT COMMA args=separated_list(COMMA, expression) RPAREN
    { CEmbed (from_loc $loc, ty, exp, args) }
  | EMBED LPAREN ty=typespec COMMA exp=STRING_CONSTANT RPAREN
    { CEmbed (from_loc $loc, ty, exp, []) }
  | BYTES LPAREN path=STRING_CONSTANT RPAREN
    { CEmbedFile (from_loc $loc, path) }
  | EXECUTE LPAREN target=query_target COMMA sql=STRING_CONSTANT args=list(preceded(COMMA, expression)) RPAREN
    { CExecute (from_loc $loc, target, sql, args) }
  | MIGRATIONS
    { CMigrations (from_loc $loc) }
  ;

query_target:
  | BORROW_WRITE identifier { QueryBorrow $2 }
  | REBORROW identifier { QueryReborrow $2 }
  ;

/* There is no precedence: the operands of an operator are atomic, so that
   a + b * c does not parse and the reader never has to know an order.  A
   chain of one associative operator, a + b + c or a and b and c, has only
   one reading and is grouped from the left, (a + b) + c; the other
   operators take two operands. */
compound_expression:
  | atomic_expression comp_op atomic_expression { CComparison (from_loc $loc, $2, $1, $3) }
  | and_chain { $1 }
  | or_chain { $1 }
  | NOT atomic_expression { CNegation (from_loc $loc, $2) }
  | arith_expr { $1 }
  | IF expression THEN expression ELSE expression { CIfExpression (from_loc $loc, $2, $4, $6) }
  | atomic_expression COLON typespec { CTypecast (from_loc $loc, $1, $3) }
  ;

path:
  | initial=identifier elems=path_rest+ { CPath (from_loc $loc, initial, elems) }
  ;

path_rest:
  | slot_accessor { $1 }
  | pointer_slot_accessor { $1 }
  | array_index { $1 }
  ;

slot_accessor:
  | PERIOD identifier { CSlotAccessor $2 }
  ;

pointer_slot_accessor:
  | HYPHEN_RIGHT identifier { CPointerSlotAccessor $2 }
  ;

array_index:
  | LBRACKET expression RBRACKET { CArrayIndex $2 }
  ;

ref_path:
  | REF_TRANSFORM initial=identifier elems=path_rest+ RPAREN { CRefPath (from_loc $loc, initial, elems, ReadBorrow) }
  | REF_TRANSFORM_WRITE initial=identifier elems=path_rest+ RPAREN { CRefPath (from_loc $loc, initial, elems, WriteBorrow) }
  ;

comp_op:
  | EQ { Equal }
  | NEQ { NotEqual }
  | LT { LessThan }
  | LTE { LessThanOrEqual }
  | GT { GreaterThan }
  | GTE { GreaterThanOrEqual }
  ;

and_chain:
  | atomic_expression AND atomic_expression { CConjunction (from_loc $loc, $1, $3) }
  | and_chain AND atomic_expression { CConjunction (from_loc $loc, $1, $3) }
  ;

or_chain:
  | atomic_expression OR atomic_expression { CDisjunction (from_loc $loc, $1, $3) }
  | or_chain OR atomic_expression { CDisjunction (from_loc $loc, $1, $3) }
  ;

arith_expr:
  | add_chain                                 { $1 }
  | atomic_expression MINUS atomic_expression { CArith (from_loc $loc, Subtract, $1, $3) }
  | mul_chain                                 { $1 }
  | atomic_expression DIV atomic_expression   { CArith (from_loc $loc, Divide, $1, $3) }
  | MINUS atomic_expression                   { CArithNegation (from_loc $loc, $2) }
  ;

add_chain:
  | atomic_expression PLUS atomic_expression { CArith (from_loc $loc, Add, $1, $3) }
  | add_chain PLUS atomic_expression { CArith (from_loc $loc, Add, $1, $3) }
  ;

mul_chain:
  | atomic_expression MUL atomic_expression { CArith (from_loc $loc, Multiply, $1, $3) }
  | mul_chain MUL atomic_expression { CArith (from_loc $loc, Multiply, $1, $3) }
  ;

/* Common */

identifier:
  | IDENTIFIER { make_ident $1 }
  ;

module_name:
  | module_name_inner { make_mod_name (String.concat "." $1) }
  ;

module_name_inner:
  | IDENTIFIER PERIOD module_name_inner { $1 :: $3 }
  | IDENTIFIER { [$1] }
  ;

typespec:
  | identifier LBRACKET separated_list(COMMA, typespec) RBRACKET { TypeSpecifier ($1, $3) }
  | identifier { TypeSpecifier ($1, []) }
  | BORROW_READ LBRACKET typespec COMMA typespec RBRACKET { ConcreteReadRef ($3, $5) }
  | BORROW_WRITE LBRACKET typespec COMMA typespec RBRACKET { ConcreteWriteRef ($3, $5) }
  | SPAN_READ LBRACKET typespec COMMA typespec RBRACKET { ConcreteSpan ($3, $5) }
  | SPAN_WRITE LBRACKET typespec COMMA typespec RBRACKET { ConcreteSpanWrite ($3, $5) }
  ;

universe:
  | UNIVERSE_FREE { FreeUniverse }
  | UNIVERSE_LINEAR { LinearUniverse }
  | UNIVERSE_TYPE { TypeUniverse }
  | UNIVERSE_REGION { RegionUniverse }
  ;

parameter_list:
  | separated_list(COMMA, parameter) { $1 }
  ;

parameter:
  | identifier COLON typespec { ConcreteParam ($1, $3) }
  ;

type_parameter_list:
  | option(type_parameter_list_inner) { Option.value $1 ~default:[] }
  ;

type_parameter_list_inner:
  | LBRACKET separated_list(COMMA, type_parameter) RBRACKET { $2 }
  ;

type_parameter:
  | identifier COLON universe { ConcreteTypeParam ($1, $3, []) }
  | identifier COLON universe LPAREN separated_list(COMMA, identifier) RPAREN { ConcreteTypeParam ($1, $3, $5) }
  ;

docstring:
  | TRIPLE_STRING_CONSTANT { Docstring (process_triple_string $1) }
  ;

docstringopt:
  | option(docstring) { Option.value $1 ~default:(Docstring "") }
  ;
