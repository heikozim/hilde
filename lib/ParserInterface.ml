(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

open Cst
open Span
open Error
open ErrorText
open Reporter

let raise_parse_error (span: span): 'a =
  adorn_error_with_span span (fun _ -> hilde_raise (H 5) ParseError [Text "Error during parse."])

(* The reserved words of docs/syntax.en.md, section 1, without those that
   may begin an expression or a type: where one of those stops the parser,
   the cause is elsewhere, and calling it a misused name would mislead. *)
let reserved_words: string list = [
    "and"; "as"; "body"; "case"; "constant"; "do"; "else"; "end"; "for";
    "from"; "function"; "generic"; "import"; "instance"; "is"; "let";
    "method"; "module"; "of"; "or"; "pragma"; "record"; "return"; "skip";
    "then"; "to"; "type"; "typeclass"; "union"; "var"; "when"; "while";
    "requires"; "ensures"; "invariant"; "raises";
    "Free"; "Linear"; "Region"; "Type"
  ]

(* The tokens after which a name stands: the name of a function, a method,
   a let, a var, a constant, the variable of a for, a parameter after ( or ,
   and the name a slot or binding gets after as. *)
let name_follows: string list = [
    "function"; "method"; "let"; "var"; "constant"; "for"; "("; ","; "as"
  ]

(* A reserved word where a name stands: H0008 names the word instead of the
   bare H0005 and suggests a free name, one that reads alike where there is
   one and the word with Value after it otherwise. *)
let free_names: (string * string) list = [
    ("from", "since"); ("to", "until"); ("body", "content"); ("end", "finish");
    ("type", "kind"); ("case", "choice"); ("record", "entry"); ("union", "variant");
    ("skip", "skipCount"); ("is", "holds"); ("as", "alias"); ("do", "act");
    ("of", "part"); ("for", "each"); ("method", "way"); ("module", "unit");
    ("return", "result"); ("var", "variable"); ("let", "binding"); ("when", "moment");
    ("while", "during"); ("then", "next"); ("else", "otherwise"); ("constant", "fixed");
    ("function", "callable"); ("generic", "general"); ("import", "imported");
    ("instance", "example"); ("typeclass", "classOf"); ("pragma", "hint");
    ("and", "both"); ("or", "either"); ("requires", "needs"); ("ensures", "promises");
    ("invariant", "rule"); ("raises", "throws");
    ("Free", "Plain"); ("Linear", "Owned"); ("Region", "Area"); ("Type", "Sort")
  ]

let free_name (word: string): string =
  match List.assoc_opt word free_names with
  | Some free -> free
  | None -> word ^ "Value"

let raise_reserved_word (span: span) (word: string): 'a =
  let free = free_name word in
  adorn_error_with_span span (fun _ ->
      hilde_raise (H 8) ParseError [
          Code word;
          Text " is a reserved word and cannot be a name. Rename it, for example to ";
          Code free;
          Text "; docs/syntax.en.md, section 1, lists the reserved words.";
          Suggest { replacement = free; at = None; certain = false }
        ])

(* A lexeme the parser read, with its place. *)
type seen = { lexeme: string; startp: Lexing.position; endp: Lexing.position }

(* The binary operators.  Only + * and or and and may be chained. *)
let binary_operators: string list = [
    "+"; "-"; "*"; "/"; "="; "/="; "<"; "<="; ">"; ">="; "and"; "or"
  ]

(* Whether a lexeme can end an operand: a name, a literal, or a closing
   bracket. *)
let ends_operand (s: string): bool =
  (s = ")") || (s = "]")
  || (String.length s > 0
      && (match s.[0] with
          | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '"' | '\'' | '#' -> true
          | _ -> false)
      && not (List.mem s reserved_words))

(* Whether a lexeme is or begins a literal. *)
let is_literal (s: string): bool =
  String.length s > 0
  && (match s.[0] with
      | '0' .. '9' | '"' | '\'' | '#' -> true
      | '-' | '+' -> String.length s > 1 && (match s.[1] with '0' .. '9' -> true | _ -> false)
      | _ -> false)

(* The first lexeme of the expression that ends with the newest of [rest],
   read backwards: over brackets as a whole, and up to a lexeme that cannot
   stand inside an expression at the depth where the walk began. *)
let expression_start (rest: seen list): seen option =
  let rec walk (depth: int) (first: seen option) (rest: seen list): seen option =
    match rest with
    | [] -> first
    | s :: older ->
       let l = s.lexeme in
       if (l = ")") || (l = "]") then
         walk (depth + 1) (Some s) older
       else if (l = "(") || (l = "[") || (l = "&(") || (l = "&!(") then
         (if depth = 0 then first else walk (depth - 1) (Some s) older)
       else if depth > 0 then
         walk depth (Some s) older
       else if (l = ":=") || (l = ",") || (l = ";") || (l = "=>")
               || ((List.mem l reserved_words) && not (List.mem l ["and"; "or"])) then
         first
       else
         walk depth (Some s) older
  in
  walk 0 None rest

(* An operator after an operand that already stands in an operation: a + b
   * c, or a + b = c, or a - b - c.  The suggested fix puts the expression
   before the operator in parentheses. *)
let raise_unparenthesized (code: string) (op: seen) (rest: seen list): 'a =
  let span: span = from_loc (op.startp, op.endp) in
  let suggestion: text_elem list =
    match (rest, expression_start rest) with
    | (last :: _, Some first) ->
       let a = first.startp.Lexing.pos_cnum
       and b = last.endp.Lexing.pos_cnum in
       if (0 <= a) && (a < b) && (b <= String.length code) then
         [Suggest {
              replacement = "(" ^ (String.sub code a (b - a)) ^ ")";
              at = Some (from_loc (first.startp, last.endp));
              certain = false
            }]
       else []
    | _ -> []
  in
  adorn_error_with_span span (fun _ ->
      hilde_raise (H 9) ParseError ([
          Text "Hilde has no operator precedence: an operator takes two operands, and only ";
          Code "+";
          Text ", ";
          Code "*";
          Text ", ";
          Code "and";
          Text " and ";
          Code "or";
          Text " can be chained with themselves. Put the operation before ";
          Code op.lexeme;
          Text " in parentheses, as in ";
          Code "(a + b) * c";
          Text "."
        ] @ suggestion))

(* An index after the closing bracket of a call. *)
let raise_index_on_call (span: span): 'a =
  adorn_error_with_span span (fun _ ->
      hilde_raise (H 10) ParseError [
          Text "An index stands after a name, not after a call. Bind the result of the call to a name first, ";
          Code "let text: Span[Nat8, R] := asSpan(&s);";
          Text ", and index the name, ";
          Code "text[i]";
          Text "."
        ])

(* A field after the closing bracket of a call. *)
let raise_field_on_call (span: span): 'a =
  adorn_error_with_span span (fun _ ->
      hilde_raise (H 12) ParseError [
          Text "A field stands after a name, not after a call. Bind the result of the call to a name first, ";
          Code "let node: Node := nodeAt();";
          Text ", and take the field of the name, ";
          Code "node.kind";
          Text "."
        ])

(* A literal after a borrow. *)
let raise_borrowed_literal (span: span) (literal: string): 'a =
  adorn_error_with_span span (fun _ ->
      hilde_raise (H 11) ParseError [
          Text "Only a variable can be borrowed, not the literal ";
          Code literal;
          Text ". Bind the value to a name first, ";
          Code ("let key: Nat64 := " ^ literal ^ ";");
          Text ", and borrow the name, ";
          Code "&key";
          Text "."
        ])

let parse' f (code: string) (filename: string) =
  let lexbuf = Lexing.from_string code in
  Lexing.set_filename lexbuf filename;
  CstUtil.parse_source := code;
  (* The lexemes read so far, the newest first, for the message of a parse
     error; at most the last 256. *)
  let history: seen list ref = ref [] in
  let token lb =
    let t = Lexer.token lb in
    let s = { lexeme = Lexing.lexeme lb; startp = Lexing.lexeme_start_p lb; endp = Lexing.lexeme_end_p lb } in
    history := s :: (List.filteri (fun i _ -> i < 255) !history);
    t
  in
  try
    f token lexbuf
  with Parser.Error ->
        (match !history with
         | last :: before :: older ->
            if List.mem last.lexeme reserved_words && List.mem before.lexeme name_follows then
              raise_reserved_word (from_lexbuf lexbuf) last.lexeme
            else if List.mem last.lexeme binary_operators && ends_operand before.lexeme then
              raise_unparenthesized code last (before :: older)
            else if (last.lexeme = "[") && (before.lexeme = ")") then
              raise_index_on_call (from_lexbuf lexbuf)
            else if (last.lexeme = ".") && (before.lexeme = ")") then
              raise_field_on_call (from_lexbuf lexbuf)
            else if List.mem before.lexeme ["&"; "&!"; "&~"] && is_literal last.lexeme then
              raise_borrowed_literal (from_lexbuf lexbuf) last.lexeme
            else
              raise_parse_error (from_lexbuf lexbuf)
         | _ ->
            raise_parse_error (from_lexbuf lexbuf))
     | Hilde_error error ->
        raise (Hilde_error error)

let parse_module_int (s:string) (filename: string): concrete_module_interface  =
  with_frame "Parse module interface"
    (fun _ ->
      ps ("Filename", filename);
      parse' Parser.module_int s filename)

let parse_module_body (s: string) (filename: string): concrete_module_body =
    with_frame "Parse module body"
      (fun _ ->
        ps ("Filename", filename);
        parse' Parser.module_body s filename)

let parse_stmt s =
  parse' Parser.standalone_statement s ""

let parse_expr s =
  parse' Parser.standalone_expression s ""
