(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

{
open Lexing
open Error
open Parser

module Errors = struct
  let raise_err code lexbuf kind text : 'a =
    let error =
      HildeError {
        module_name = None;
        code = code;
        kind = kind;
        text = text;
        span = Some (Span.from_lexbuf lexbuf);
        source_ctx = None
      }
    in
    raise (Hilde_error error)

  let invalid_character lexbuf =
    raise_err (H 1) lexbuf ParseError [
      Text "Character not allowed in source text: ";
      Code (Lexing.lexeme lexbuf)
    ]

  let single_string_invalid_character lexbuf =
    internal_raise [
      Text "Character not allowed in string literal: ";
      Code (Lexing.lexeme lexbuf)
    ]

  let single_string_eof lexbuf =
    raise_err (H 3) lexbuf ParseError [
      Text "End of file in string literal."
    ]

  let triple_string_eof lexbuf =
    raise_err (H 4) lexbuf ParseError [
      Text "End of file in triple string literal."
    ]
end

let advance_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  let pos' = { pos with
    pos_bol = lexbuf.lex_curr_pos;
    pos_lnum = pos.pos_lnum + 1
  } in
  lexbuf.lex_curr_p <- pos'

let string_acc: Buffer.t = Buffer.create 64

let triple_string_acc: Buffer.t = Buffer.create 64
}

(* Helper regexes *)

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let alphanum = (alpha|digit)
let whitespace = [' ' '\t']+
let hex_digit = ['0'-'9' 'a'-'f' 'A'-'F']
let bin_digit = ['0'-'1']
let oct_digit = ['0'-'7']

let ascii_char = ['a'-'z' 'A'-'Z' '0'-'9' ' ' '!' '"' '#' '$' '%' '&' ''' ')' '(' '*' '+' ',' '-' '.' '/' ':' ';' '<' '=' '>' '?' '@' '`' '~' ']' '[' '^' '_' '{' '|' '}']

let newline = "\r\n" | '\n'

let exponent = 'e' | 'E'
let sign = '+' | '-'
let period = '.'

let comment = "--" [^ '\r' '\n']* newline?

(* Token regexes *)

let identifier = (alpha) ('_'|alphanum)*
let dec_constant = sign? digit (digit|'\'')*
let hex_constant = '#' 'x' hex_digit (hex_digit|'\'')*
let bin_constant = '#' 'b' bin_digit (bin_digit|'\'')*
let oct_constant = '#' 'o' oct_digit (oct_digit|'\'')*
let float_constant = sign? dec_constant period dec_constant? (exponent sign? dec_constant)?
let char_constant = '\'' (ascii_char | '\\' ['n' 'r' 't' '\\' '\'']) '\''

(* Rules *)

rule token = parse
  (* Comments *)
  | comment { advance_line lexbuf; token lexbuf }
  (* Brackets *)
  | "(" { LPAREN }
  | ")" { RPAREN }
  | "[" { LBRACKET }
  | "]" { RBRACKET }
  | "{" { LCURLY }
  | "}" { RCURLY }
  (* Arithmetic operators *)
  | "+" { PLUS }
  | "-" { MINUS }
  | "*" { MUL }
  | "/" { DIV }
  (* Comparison operators *)
  | "=" { EQ }
  | "/=" { NEQ }
  | "<=" { LTE }
  | "<" { LT }
  | ">=" { GTE }
  | ">" { GT }
  (* Logical operators *)
  | "and" { AND }
  | "or" { OR }
  | "not" { NOT }
  (* Borrowing *)
  (* A write reference to part of a value.  Longer than "&!", so it wins
     where both match; "&!" is followed by a name, never by "(". *)
  | "&!(" { REF_TRANSFORM_WRITE }
  | "&!" { BORROW_WRITE }
  | "&(" { REF_TRANSFORM }
  | "&" { BORROW_READ }
  | "Span" { SPAN_READ }
  | "Span!" { SPAN_WRITE }
  | "&~" { REBORROW }
  (* Keywords *)
  | "module" { MODULE }
  | "is" { IS }
  | "body" { BODY }
  | "import" { IMPORT }
  | "as" { AS }
  | "end" { END }
  | "constant" { CONSTANT }
  | "type" { TYPE }
  | "function" { FUNCTION }
  | "generic" { GENERIC }
  | "record" { RECORD }
  | "union" { UNION }
  | "case" { CASE }
  | "of" { OF }
  | "when" { WHEN }
  | "typeclass" { TYPECLASS }
  | "instance" { INSTANCE }
  | "method" { METHOD }
  | "if" { IF }
  | "else" whitespace+ "if" { ELSE_IF }
  | "then" { THEN }
  | "else" { ELSE }
  | "let" { LET }
  | "var" { VAR }
  | "while" { WHILE }
  | "for" { FOR }
  | "do" { DO }
  | "from" { FROM }
  | "to" { TO }
  | "borrow" { BORROW }
  | "return" { RETURN }
  | "skip" { SKIP }
  | "Free" { UNIVERSE_FREE }
  | "Linear" { UNIVERSE_LINEAR }
  | "Type" { UNIVERSE_TYPE }
  | "Region" { UNIVERSE_REGION }
  | "pragma" { PRAGMA }
  | "sizeof" { SIZEOF }
  (* The clauses of a function's contract. *)
  | "requires" { REQUIRES }
  | "ensures" { ENSURES }
  | "invariant" { INVARIANT }
  (* The raises clause of a signature, and the statement that ends the
     function with a named error kind.  One line each: a rename touches
     the lexer line, the parser's tokens and the docs, nothing else. *)
  | "raises" { RAISES }
  | "raise" { RAISE }
  (* Symbols *)
  | ";" { SEMI }
  | "," { COMMA }
  (* The range of a pattern, `97 .. 122'.  `..' is longer than `.', so it
     is one token wherever it stands. *)
  | ".." { DOTDOT }
  | "." { PERIOD }
  (* `|' between the alternatives of a `when', and `_', the
     pattern that matches anything and binds nothing. *)
  | "|" { BAR }
  | "_" { UNDERSCORE }
  | ":" { COLON }
  | "->" { HYPHEN_RIGHT }
  | "=>" { RIGHT_ARROW }
  | ":=" { ASSIGN }
  | "!" { DEREF }
  | "?" { QUESTION }
  (* Strings and docstrings *)
  | "\"\"\"" { read_triple_string lexbuf }
  | '"' { read_string lexbuf }
  (* Identifiers and constants *)
  | "nil" { NIL }
  | "true" { TRUE }
  | "false" { FALSE }
  (* A range `0..127' written without spaces.  Without this
     rule the longest match is the float `0.', and the range would not
     parse.  The rule is longer than the float, so it wins; the range's
     upper bound follows as a token of its own. *)
  | (dec_constant as low) ".." { RANGE_START low }
  | float_constant { FLOAT_CONSTANT (Lexing.lexeme lexbuf) }
  | dec_constant { DEC_CONSTANT (Lexing.lexeme lexbuf) }
  | hex_constant { HEX_CONSTANT (Lexing.lexeme lexbuf) }
  | bin_constant { BIN_CONSTANT (Lexing.lexeme lexbuf) }
  | oct_constant { OCT_CONSTANT (Lexing.lexeme lexbuf) }
  | char_constant { CHAR_CONSTANT (Lexing.lexeme lexbuf) }
  | identifier { IDENTIFIER (Lexing.lexeme lexbuf) }
  (* Specials *)
  | "@embed" { EMBED }
  (* A different name from `@embed' on purpose: one puts C code into the
     programme and the other puts a file's bytes into it, and a reader has
     to be able to tell them apart at a glance. *)
  | "@bytes" { BYTES }
  (* A statement: a template read when the programme is compiled and
     turned into code that writes into a builder. *)
  | "@template" { TEMPLATE }
  | "@query" { QUERY }
  | "@execute" { EXECUTE }
  | "@migrations" { MIGRATIONS }
  (* etc. *)
  | whitespace { token lexbuf }
  | newline { advance_line lexbuf; token lexbuf }
  | eof { EOF }
  | _ {
    Errors.invalid_character lexbuf
  }

and read_string = parse
  | '"' { let c = Buffer.contents string_acc in Buffer.clear string_acc; STRING_CONSTANT c }
  (* An escaped backslash is read as a pair, before the escaped quote below:
     without it the second backslash of "\\" took the closing quote for an
     escaped one, and the string did not end.  Both backslashes stay; the
     escape pass (Escape.escape_string) makes one of them. *)
  | '\\' '\\' { Buffer.add_string string_acc "\\\\"; read_string lexbuf }
  | '\\' '"' { Buffer.add_char string_acc '"'; read_string lexbuf }
  (* A string may span lines.  Each line break inside it is counted, as
     read_triple_string counts it: without that every position after the
     string stood as many lines too high as the string had breaks. *)
  | newline { advance_line lexbuf; Buffer.add_string string_acc (Lexing.lexeme lexbuf); read_string lexbuf }
  | [^ '"'] { Buffer.add_string string_acc (Lexing.lexeme lexbuf); read_string lexbuf }
  | eof { Errors.single_string_eof lexbuf }
  | _ { Errors.single_string_invalid_character lexbuf }

and read_triple_string = parse
  | "\"\"\"" { let c = Buffer.contents triple_string_acc in Buffer.clear triple_string_acc; TRIPLE_STRING_CONSTANT c }
  | '\n' { advance_line lexbuf; Buffer.add_string triple_string_acc "\n"; read_triple_string lexbuf }
  | '\\' "\"\"\"" { Buffer.add_string triple_string_acc "\"\"\""; read_triple_string lexbuf }
  | eof { Errors.triple_string_eof lexbuf }
  | _ { Buffer.add_string triple_string_acc (Lexing.lexeme lexbuf); read_triple_string lexbuf }
