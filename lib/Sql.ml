(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* `@query', `@execute' and `@migrations'.

   The migration files beside the module are read here, in the abstraction
   pass, and replayed into a schema: tables, their columns, each column's
   type and whether it can be NULL.  A query is then parsed and checked
   against that schema -- every table, every column, the type of every
   comparison and every parameter, the columns of the row -- and turned into
   ordinary statements that call Standard.Sqlite.  Nothing of the checking
   survives to run time; the SQL text goes to SQLite exactly as written.

   What SQLite accepts and this file does not is refused with a message.
   The line between the two is drawn so that what is accepted can be
   TYPED: a subquery, CASE, CAST, a compound SELECT or a function outside
   the short list would need a type this file cannot give,
   and a query that compiled without one would be the unchecked query the
   order rules out.

   Four parts, in the order they run:
     1. a lexer for SQL text;
     2. a parser into statements and expressions;
     3. the schema, built by replaying the migrations, and the checker;
     4. the generator of the Hilde statements. *)

open Identifier
open Span
open Error
open Escape
open Imports
open Qualifier
open ModuleNameSet
module Ast = Stages.Ast
open Ast

(* ---------------------------------------------------------------------- *)
(* Positions and errors                                                    *)
(* ---------------------------------------------------------------------- *)

type pos = { line: int; col: int }

(* Where a text came from: a query in a Hilde statement, or a migration
   file.  A query's errors point at the statement and say where in the SQL;
   a migration's point into the file. *)
type origin =
  | InQuery of span * string
  | InFile of string

let fail (code: error_code) (o: origin) (p: pos) (message: string): 'a =
  match o with
  | InQuery (span, construct) ->
     adorn_error_with_span span
       (fun () -> err code (Printf.sprintf "%s: %s (line %d, column %d of the SQL)" construct message p.line p.col))
  | InFile file ->
     let span = Span {
                    filename = file;
                    startp = Position { line = p.line; column = p.col };
                    endp = Position { line = p.line; column = p.col + 1 };
                  }
     in
     adorn_error_with_span span (fun () -> err code ("migration: " ^ message))

let lower = String.lowercase_ascii
let upper = String.uppercase_ascii

(* ---------------------------------------------------------------------- *)
(* 1. The lexer                                                            *)
(* ---------------------------------------------------------------------- *)

type tok =
  | Word of string
  | Quoted of string
  | Str of string
  | IntLit of string
  | RealLit of string
  | BlobLit of string
  | Param of int
  | Op of string
  | Eof

type token = { tok: tok; at: pos }

let is_start (c: char): bool =
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_'

let is_digit (c: char): bool = c >= '0' && c <= '9'

let is_part (c: char): bool = is_start c || is_digit c || c = '$'

let is_hex (c: char): bool =
  is_digit c || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')

let two_char_ops = ["||"; "=="; "!="; "<>"; "<="; ">="; "<<"; ">>"]
let one_char_ops = "(),.;*+-/%=<>&|~"

let lex (o: origin) (text: string): token list =
  let n = String.length text in
  let i = ref 0 and line = ref 1 and col = ref 1 in
  let params = ref 0 in
  let out = ref [] in
  let adv (k: int): unit =
    for _ = 1 to k do
      if !i < n then begin
        if text.[!i] = '\n' then (incr line; col := 1) else incr col;
        incr i
      end
    done
  in
  let here () = { line = !line; col = !col } in
  let push (t: tok) (p: pos) = out := { tok = t; at = p } :: !out in
  let peek_at (k: int): char option = if !i + k < n then Some text.[!i + k] else None in
  (* A string or a quoted name: the quote doubled stands for itself. *)
  let quoted (q: char) (p: pos) (what: string): string =
    adv 1;
    let b = Buffer.create 16 in
    let closed = ref false in
    while not !closed do
      if !i >= n then fail (H 8001) o p (what ^ " is not closed");
      if text.[!i] = q then begin
        if peek_at 1 = Some q then (Buffer.add_char b q; adv 2)
        else (adv 1; closed := true)
      end else begin
        Buffer.add_char b text.[!i];
        adv 1
      end
    done;
    Buffer.contents b
  in
  while !i < n do
    let c = text.[!i] in
    let p = here () in
    if c = ' ' || c = '\t' || c = '\n' || c = '\r' then
      adv 1
    else if c = '-' && peek_at 1 = Some '-' then
      (while !i < n && text.[!i] <> '\n' do adv 1 done)
    else if c = '/' && peek_at 1 = Some '*' then begin
      adv 2;
      while !i < n && not (text.[!i] = '*' && peek_at 1 = Some '/') do adv 1 done;
      if !i >= n then fail (H 8002) o p "a comment is not closed";
      adv 2
    end
    else if (c = 'x' || c = 'X') && peek_at 1 = Some '\'' then begin
      adv 1;
      let hex = quoted '\'' p "a blob literal" in
      if String.length hex mod 2 <> 0 || not (String.for_all is_hex hex) then
        fail (H 8003) o p "a blob literal is an even number of hexadecimal digits";
      push (BlobLit hex) p
    end
    else if is_start c then begin
      let s = !i in
      while !i < n && is_part text.[!i] do adv 1 done;
      push (Word (String.sub text s (!i - s))) p
    end
    else if is_digit c || (c = '.' && (match peek_at 1 with Some d -> is_digit d | None -> false)) then begin
      let s = !i in
      let real = ref false in
      if c = '0' && (peek_at 1 = Some 'x' || peek_at 1 = Some 'X') then begin
        adv 2;
        while !i < n && is_hex text.[!i] do adv 1 done
      end else begin
        while !i < n && is_digit text.[!i] do adv 1 done;
        if !i < n && text.[!i] = '.' then begin
          real := true;
          adv 1;
          while !i < n && is_digit text.[!i] do adv 1 done
        end;
        if !i < n && (text.[!i] = 'e' || text.[!i] = 'E') then begin
          real := true;
          adv 1;
          if !i < n && (text.[!i] = '+' || text.[!i] = '-') then adv 1;
          while !i < n && is_digit text.[!i] do adv 1 done
        end
      end;
      if !i < n && is_start text.[!i] then fail (H 8004) o p "a number runs into a name";
      let lit = String.sub text s (!i - s) in
      push (if !real then RealLit lit else IntLit lit) p
    end
    else if c = '\'' then
      push (Str (quoted '\'' p "a string")) p
    else if c = '"' then
      push (Quoted (quoted '"' p "a quoted name")) p
    else if c = '`' || c = '[' then
      fail (H 8005) o p "a name is quoted with double quotes here, not with ` or [ ]"
    else if c = '?' then begin
      adv 1;
      if !i < n && is_digit text.[!i] then
        fail (H 8006) o p "a numbered parameter (?NNN) is not accepted: write ? and give the values in order";
      incr params;
      push (Param !params) p
    end
    else if c = ':' || c = '@' || c = '$' then
      fail (H 8007) o p "a named parameter is not accepted: write ? and give the values in order"
    else begin
      let two = if !i + 1 < n then String.sub text !i 2 else "" in
      if List.mem two two_char_ops then (push (Op two) p; adv 2)
      else if String.contains one_char_ops c then (push (Op (String.make 1 c)) p; adv 1)
      else fail (H 8008) o p (Printf.sprintf "the character %C is not SQL this compiler reads" c)
    end
  done;
  List.rev ({ tok = Eof; at = here () } :: !out)

(* ---------------------------------------------------------------------- *)
(* 2. The parser                                                           *)
(* ---------------------------------------------------------------------- *)

type expr = { e: edesc; at: pos }
and edesc =
  | ENull
  | EBool
  | EInt
  | EReal
  | EStr
  | EBlob
  | EParam of int
  | ECol of string option * string
  | ENeg of expr
  | ENot of expr
  | EArith of string * expr * expr
  | EConcat of expr * expr
  | ECompare of string * expr * expr
  | EIs of bool * expr * expr
  | ENullTest of bool * expr
  | ELike of string * bool * expr * expr
  | EIn of bool * expr * expr list
  | EBetween of bool * expr * expr * expr
  | ELogic of string * expr * expr
  | ECall of string * bool * expr list
  | ECountStar

type result_col =
  | RStar of pos
  | RTableStar of string * pos
  | RExpr of expr * string option

type source = { table: string; alias: string option; sat: pos }

type join = { outer: bool; jsource: source; on: expr option }

type select = {
    results: result_col list;
    from: source option;
    joins: join list;
    where: expr option;
    group: expr list;
    having: expr option;
    order: expr list;
    limit: expr list;
  }

type coldef = {
    cname: string;
    ctype: string;
    cat: pos;
    notnull: bool;
    primary: bool;
    hasdefault: bool;
    default: expr option;
    checks: expr list;
    refs: (string * string list * pos) list;
  }

type tconstraint =
  | TPrimary of (string * pos) list
  | TUnique of (string * pos) list
  | TCheck of expr
  | TForeign of (string * pos) list * string * (string * pos) list * pos

type statement =
  | SSelect of select
  | SInsert of { itable: string; iat: pos; columns: (string * pos) list option; rows: expr list list; returning: result_col list }
  | SUpdate of { utable: string; uat: pos; sets: (string * pos * expr) list; uwhere: expr option; ureturning: result_col list }
  | SDelete of { dtable: string; dat: pos; dwhere: expr option; dreturning: result_col list }
  | SCreateTable of { ctable: string; ctat: pos; ifnot: bool; cols: coldef list; constraints: tconstraint list; strict: bool; norowid: bool }
  | SAddColumn of string * pos * coldef
  | SRenameTable of string * pos * string
  | SRenameColumn of string * pos * string * string * pos
  | SDropColumn of string * pos * string * pos
  | SDropTable of string * pos * bool
  | SCreateIndex of { xname: string; xat: pos; xtable: string; xtat: pos; xcols: (string * pos) list; xwhere: expr option; xifnot: bool }
  | SDropIndex of string * pos * bool

type cursor = { o: origin; mutable rest: token list }

let peek (c: cursor): token =
  match c.rest with t :: _ -> t | [] -> { tok = Eof; at = { line = 0; col = 0 } }

let peek_n (c: cursor) (k: int): tok =
  match List.nth_opt c.rest k with Some t -> t.tok | None -> Eof

let advance (c: cursor): token =
  match c.rest with
  | t :: rest when t.tok <> Eof -> c.rest <- rest; t
  | t :: _ -> t
  | [] -> { tok = Eof; at = { line = 0; col = 0 } }

let describe (t: tok): string =
  match t with
  | Word w -> w
  | Quoted q -> "\"" ^ q ^ "\""
  | Str _ -> "a string"
  | IntLit s | RealLit s -> s
  | BlobLit _ -> "a blob literal"
  | Param _ -> "?"
  | Op s -> s
  | Eof -> "the end of the SQL"

let here (c: cursor): pos = (peek c).at

let is_kw (t: tok) (w: string): bool =
  match t with Word s -> upper s = w | _ -> false

let at_kw (c: cursor) (w: string): bool = is_kw (peek c).tok w

let accept_kw (c: cursor) (w: string): bool =
  if at_kw c w then (ignore (advance c); true) else false

let expect_kw (c: cursor) (w: string): unit =
  if not (accept_kw c w) then
    fail (H 8009) c.o (here c) (Printf.sprintf "expected %s, found %s" w (describe (peek c).tok))

let at_op (c: cursor) (s: string): bool =
  match (peek c).tok with Op x -> x = s | _ -> false

let accept_op (c: cursor) (s: string): bool =
  if at_op c s then (ignore (advance c); true) else false

let expect_op (c: cursor) (s: string): unit =
  if not (accept_op c s) then
    fail (H 8010) c.o (here c) (Printf.sprintf "expected %s, found %s" s (describe (peek c).tok))

(* Words that are never a name here.  SQLite lets many keywords stand as
   names; this list keeps only those whose place in a query would be read
   two ways. *)
let reserved = [
    "SELECT"; "FROM"; "WHERE"; "AND"; "OR"; "NOT"; "NULL"; "ON"; "AS"; "SET";
    "VALUES"; "INTO"; "JOIN"; "ORDER"; "GROUP"; "BY"; "HAVING"; "LIMIT";
    "OFFSET"; "UNION"; "EXCEPT"; "INTERSECT"; "CASE"; "WHEN"; "THEN"; "ELSE";
    "END"; "IS"; "IN"; "LIKE"; "GLOB"; "BETWEEN"; "DISTINCT"; "RETURNING";
    "DEFAULT"; "CREATE"; "TABLE"; "INDEX"; "DROP"; "ALTER"; "INSERT";
    "UPDATE"; "DELETE"; "PRIMARY"; "FOREIGN"; "CONSTRAINT"; "REFERENCES";
    "CHECK"; "UNIQUE"; "EXISTS"; "CAST"; "COLLATE"; "LEFT"; "INNER"; "CROSS";
    "NATURAL"; "USING"; "ESCAPE"; "ISNULL"; "NOTNULL"; "TRUE"; "FALSE";
    "WITH"; "OUTER"; "ALL"; "WINDOW"; "OVER"; "FILTER"; "RIGHT"; "FULL";
  ]

let name_of (t: tok): string option =
  match t with
  | Word w when not (List.mem (upper w) reserved) -> Some w
  | Quoted q -> Some q
  | _ -> None

let expect_name (c: cursor) (what: string): string * pos =
  let t = peek c in
  match name_of t.tok with
  | Some s -> ignore (advance c); (s, t.at)
  | None -> fail (H 8011) c.o t.at (Printf.sprintf "expected %s, found %s" what (describe t.tok))

let not_accepted (c: cursor) (p: pos) (what: string): 'a =
  fail (H 8012) c.o p (what ^ " is not accepted in the SQL the compiler checks")

let rec parse_expr (c: cursor): expr = parse_or c

and parse_or (c: cursor): expr =
  let l = ref (parse_and c) in
  while at_kw c "OR" do
    let p = (advance c).at in
    let r = parse_and c in
    l := { e = ELogic ("OR", !l, r); at = p }
  done;
  !l

and parse_and (c: cursor): expr =
  let l = ref (parse_not c) in
  while at_kw c "AND" do
    let p = (advance c).at in
    let r = parse_not c in
    l := { e = ELogic ("AND", !l, r); at = p }
  done;
  !l

and parse_not (c: cursor): expr =
  if at_kw c "NOT" then
    let p = (advance c).at in
    { e = ENot (parse_not c); at = p }
  else
    parse_equality c

and parse_equality (c: cursor): expr =
  let l = ref (parse_comparison c) in
  let continue = ref true in
  while !continue do
    let t = peek c in
    let negated_next (w: string) = is_kw t.tok "NOT" && is_kw (peek_n c 1) w in
    if at_op c "=" || at_op c "==" then begin
      ignore (advance c);
      l := { e = ECompare ("=", !l, parse_comparison c); at = t.at }
    end else if at_op c "!=" || at_op c "<>" then begin
      ignore (advance c);
      l := { e = ECompare ("<>", !l, parse_comparison c); at = t.at }
    end else if at_kw c "IS" then begin
      ignore (advance c);
      let neg = accept_kw c "NOT" in
      if accept_kw c "NULL" then
        l := { e = ENullTest (neg, !l); at = t.at }
      else
        l := { e = EIs (neg, !l, parse_comparison c); at = t.at }
    end else if at_kw c "ISNULL" then begin
      ignore (advance c);
      l := { e = ENullTest (false, !l); at = t.at }
    end else if at_kw c "NOTNULL" || negated_next "NULL" then begin
      if at_kw c "NOT" then ignore (advance c);
      ignore (advance c);
      l := { e = ENullTest (true, !l); at = t.at }
    end else if at_kw c "IN" || negated_next "IN" then begin
      let neg = accept_kw c "NOT" in
      ignore (advance c);
      expect_op c "(";
      if at_kw c "SELECT" then not_accepted c (here c) "a subquery";
      let items = ref [parse_expr c] in
      while accept_op c "," do items := parse_expr c :: !items done;
      expect_op c ")";
      l := { e = EIn (neg, !l, List.rev !items); at = t.at }
    end else if at_kw c "LIKE" || at_kw c "GLOB" || negated_next "LIKE" || negated_next "GLOB" then begin
      let neg = accept_kw c "NOT" in
      let op = upper (describe (advance c).tok) in
      let r = parse_comparison c in
      if at_kw c "ESCAPE" then not_accepted c (here c) "ESCAPE";
      l := { e = ELike (op, neg, !l, r); at = t.at }
    end else if at_kw c "BETWEEN" || negated_next "BETWEEN" then begin
      let neg = accept_kw c "NOT" in
      ignore (advance c);
      let lo = parse_comparison c in
      expect_kw c "AND";
      let hi = parse_comparison c in
      l := { e = EBetween (neg, !l, lo, hi); at = t.at }
    end else
      continue := false
  done;
  !l

and parse_comparison (c: cursor): expr =
  let l = ref (parse_additive c) in
  let continue = ref true in
  while !continue do
    let t = peek c in
    match t.tok with
    | Op ("<" | "<=" | ">" | ">=" as op) ->
       ignore (advance c);
       l := { e = ECompare (op, !l, parse_additive c); at = t.at }
    | Op ("<<" | ">>" | "&" | "|") ->
       not_accepted c t.at "a bit operator"
    | _ -> continue := false
  done;
  !l

and parse_additive (c: cursor): expr =
  let l = ref (parse_multiplicative c) in
  let continue = ref true in
  while !continue do
    let t = peek c in
    match t.tok with
    | Op ("+" | "-" as op) ->
       ignore (advance c);
       l := { e = EArith (op, !l, parse_multiplicative c); at = t.at }
    | _ -> continue := false
  done;
  !l

and parse_multiplicative (c: cursor): expr =
  let l = ref (parse_concat c) in
  let continue = ref true in
  while !continue do
    let t = peek c in
    match t.tok with
    | Op ("*" | "/" | "%" as op) ->
       ignore (advance c);
       l := { e = EArith (op, !l, parse_concat c); at = t.at }
    | _ -> continue := false
  done;
  !l

and parse_concat (c: cursor): expr =
  let l = ref (parse_unary c) in
  while at_op c "||" do
    let p = (advance c).at in
    l := { e = EConcat (!l, parse_unary c); at = p }
  done;
  !l

and parse_unary (c: cursor): expr =
  let t = peek c in
  match t.tok with
  | Op "-" -> ignore (advance c); { e = ENeg (parse_unary c); at = t.at }
  | Op "+" -> ignore (advance c); { e = ENeg ({ e = ENeg (parse_unary c); at = t.at }); at = t.at }
  | Op "~" -> not_accepted c t.at "a bit operator"
  | _ -> parse_primary c

and parse_primary (c: cursor): expr =
  let t = peek c in
  match t.tok with
  | IntLit _ -> ignore (advance c); { e = EInt; at = t.at }
  | RealLit _ -> ignore (advance c); { e = EReal; at = t.at }
  | Str _ -> ignore (advance c); { e = EStr; at = t.at }
  | BlobLit _ -> ignore (advance c); { e = EBlob; at = t.at }
  | Param k -> ignore (advance c); { e = EParam k; at = t.at }
  | Op "(" ->
     ignore (advance c);
     if at_kw c "SELECT" then not_accepted c (here c) "a subquery";
     let inner = parse_expr c in
     expect_op c ")";
     inner
  | Word w when upper w = "NULL" -> ignore (advance c); { e = ENull; at = t.at }
  | Word w when upper w = "TRUE" || upper w = "FALSE" -> ignore (advance c); { e = EBool; at = t.at }
  | Word w when List.mem (upper w) ["CASE"; "CAST"; "EXISTS"; "SELECT"; "RAISE"] ->
     not_accepted c t.at (upper w)
  | _ ->
     let (name, p) = expect_name c "a column, a value or a function" in
     if accept_op c "(" then begin
       if at_op c "*" then begin
         ignore (advance c);
         expect_op c ")";
         if lower name <> "count" then fail (H 8013) c.o p (name ^ "(*): only count takes *");
         { e = ECountStar; at = p }
       end else begin
         let distinct = accept_kw c "DISTINCT" in
         let args = ref [] in
         if not (at_op c ")") then begin
           args := [parse_expr c];
           while accept_op c "," do args := parse_expr c :: !args done
         end;
         expect_op c ")";
         if at_kw c "FILTER" || at_kw c "OVER" then not_accepted c (here c) "a window or filter clause";
         { e = ECall (lower name, distinct, List.rev !args); at = p }
       end
     end else if at_op c "." then begin
       ignore (advance c);
       let (column, _) = expect_name c "a column name after the dot" in
       { e = ECol (Some name, column); at = p }
     end else
       { e = ECol (None, name); at = p }

let parse_result_columns (c: cursor): result_col list =
  let one () =
    let t = peek c in
    if at_op c "*" then (ignore (advance c); RStar t.at)
    else if (match name_of t.tok with Some _ -> true | None -> false)
            && peek_n c 1 = Op "." && peek_n c 2 = Op "*" then begin
      let (table, p) = expect_name c "a table" in
      ignore (advance c);
      ignore (advance c);
      RTableStar (table, p)
    end else begin
      let e = parse_expr c in
      if accept_kw c "AS" then
        let (alias, _) = expect_name c "a name after AS" in
        RExpr (e, Some alias)
      else begin
        (match name_of (peek c).tok with
         | Some _ -> fail (H 8014) c.o (here c) "a column alias is written with AS"
         | None -> ());
        RExpr (e, None)
      end
    end
  in
  let first = one () in
  let all = ref [first] in
  while accept_op c "," do all := one () :: !all done;
  List.rev !all

(* Words that end a table's place in FROM, so that the next word is not
   taken for an alias. *)
let clause_words = [
    "WHERE"; "GROUP"; "HAVING"; "ORDER"; "LIMIT"; "OFFSET"; "JOIN"; "INNER";
    "LEFT"; "CROSS"; "ON"; "SET"; "VALUES"; "RETURNING"; "UNION"; "EXCEPT";
    "INTERSECT"; "NATURAL"; "USING"; "RIGHT"; "FULL"; "WINDOW";
  ]

let parse_source (c: cursor): source =
  if at_op c "(" then not_accepted c (here c) "a subquery in FROM";
  let (table, p) = expect_name c "a table" in
  if at_op c "(" then not_accepted c (here c) "a table-valued function";
  if at_op c "." then not_accepted c (here c) "a schema name";
  let alias =
    if accept_kw c "AS" then Some (fst (expect_name c "an alias after AS"))
    else match (peek c).tok with
         | Word w when not (List.mem (upper w) clause_words) && not (List.mem (upper w) reserved) ->
            ignore (advance c); Some w
         | Quoted q -> ignore (advance c); Some q
         | _ -> None
  in
  if at_kw c "INDEXED" || (at_kw c "NOT" && is_kw (peek_n c 1) "INDEXED") then
    not_accepted c (here c) "INDEXED BY";
  { table; alias; sat = p }

let parse_select (c: cursor): select =
  expect_kw c "SELECT";
  if at_kw c "DISTINCT" || at_kw c "ALL" then ignore (advance c);
  let results = parse_result_columns c in
  let from = ref None and joins = ref [] in
  if accept_kw c "FROM" then begin
    from := Some (parse_source c);
    let continue = ref true in
    while !continue do
      if accept_op c "," then
        joins := { outer = false; jsource = parse_source c; on = None } :: !joins
      else if at_kw c "NATURAL" || at_kw c "RIGHT" || at_kw c "FULL" then
        not_accepted c (here c) (upper (describe (peek c).tok) ^ " JOIN")
      else if at_kw c "CROSS" then begin
        ignore (advance c);
        expect_kw c "JOIN";
        joins := { outer = false; jsource = parse_source c; on = None } :: !joins
      end else if at_kw c "JOIN" || at_kw c "INNER" || at_kw c "LEFT" then begin
        let outer = at_kw c "LEFT" in
        if at_kw c "INNER" || at_kw c "LEFT" then ignore (advance c);
        if outer then ignore (accept_kw c "OUTER");
        expect_kw c "JOIN";
        let jsource = parse_source c in
        if at_kw c "USING" then not_accepted c (here c) "USING";
        expect_kw c "ON";
        joins := { outer; jsource; on = Some (parse_expr c) } :: !joins
      end else
        continue := false
    done
  end;
  let where = if accept_kw c "WHERE" then Some (parse_expr c) else None in
  let group = ref [] and having = ref None in
  if accept_kw c "GROUP" then begin
    expect_kw c "BY";
    group := [parse_expr c];
    while accept_op c "," do group := parse_expr c :: !group done;
    if accept_kw c "HAVING" then having := Some (parse_expr c)
  end;
  if at_kw c "WINDOW" then not_accepted c (here c) "WINDOW";
  if at_kw c "UNION" || at_kw c "EXCEPT" || at_kw c "INTERSECT" then
    not_accepted c (here c) "a compound SELECT";
  let order = ref [] in
  if accept_kw c "ORDER" then begin
    expect_kw c "BY";
    let one () =
      let e = parse_expr c in
      if at_kw c "COLLATE" then not_accepted c (here c) "COLLATE in ORDER BY";
      if not (accept_kw c "ASC") then ignore (accept_kw c "DESC");
      if at_kw c "NULLS" then not_accepted c (here c) "NULLS FIRST or LAST";
      e
    in
    order := [one ()];
    while accept_op c "," do order := one () :: !order done
  end;
  let limit = ref [] in
  if accept_kw c "LIMIT" then begin
    limit := [parse_expr c];
    if accept_kw c "OFFSET" || accept_op c "," then limit := parse_expr c :: !limit
  end;
  { results; from = !from; joins = List.rev !joins; where; group = List.rev !group;
    having = !having; order = List.rev !order; limit = !limit }

let parse_returning (c: cursor): result_col list =
  if accept_kw c "RETURNING" then parse_result_columns c else []

let parse_name_list (c: cursor) (what: string): (string * pos) list =
  expect_op c "(";
  let one () =
    let n = expect_name c what in
    if at_kw c "COLLATE" then (ignore (advance c); ignore (expect_name c "a collation"));
    if not (accept_kw c "ASC") then ignore (accept_kw c "DESC");
    n
  in
  let names = ref [one ()] in
  while accept_op c "," do names := one () :: !names done;
  expect_op c ")";
  List.rev !names

let parse_conflict_clause (c: cursor): unit =
  if at_kw c "ON" && is_kw (peek_n c 1) "CONFLICT" then
    not_accepted c (here c) "ON CONFLICT"

let parse_or_conflict (c: cursor): unit =
  if accept_kw c "OR" then begin
    let t = peek c in
    if List.exists (is_kw t.tok) ["ABORT"; "FAIL"; "IGNORE"; "REPLACE"; "ROLLBACK"] then
      ignore (advance c)
    else
      fail (H 8015) c.o t.at "expected ABORT, FAIL, IGNORE, REPLACE or ROLLBACK after OR"
  end

let parse_insert (c: cursor): statement =
  if accept_kw c "REPLACE" then () else begin
    expect_kw c "INSERT";
    parse_or_conflict c
  end;
  expect_kw c "INTO";
  let (itable, iat) = expect_name c "a table" in
  if at_kw c "AS" then not_accepted c (here c) "an alias in INSERT";
  let columns =
    if at_op c "(" then Some (parse_name_list c "a column") else None
  in
  let rows =
    if accept_kw c "DEFAULT" then (expect_kw c "VALUES"; [])
    else begin
      if at_kw c "SELECT" || at_kw c "WITH" then not_accepted c (here c) "INSERT ... SELECT";
      expect_kw c "VALUES";
      let row () =
        expect_op c "(";
        let items = ref [parse_expr c] in
        while accept_op c "," do items := parse_expr c :: !items done;
        expect_op c ")";
        List.rev !items
      in
      let rows = ref [row ()] in
      while accept_op c "," do rows := row () :: !rows done;
      List.rev !rows
    end
  in
  parse_conflict_clause c;
  let returning = parse_returning c in
  SInsert { itable; iat; columns; rows; returning }

let parse_update (c: cursor): statement =
  expect_kw c "UPDATE";
  parse_or_conflict c;
  let (utable, uat) = expect_name c "a table" in
  expect_kw c "SET";
  let one () =
    if at_op c "(" then not_accepted c (here c) "a column list in SET";
    let (col, p) = expect_name c "a column" in
    expect_op c "=";
    (col, p, parse_expr c)
  in
  let sets = ref [one ()] in
  while accept_op c "," do sets := one () :: !sets done;
  if at_kw c "FROM" then not_accepted c (here c) "UPDATE ... FROM";
  let uwhere = if accept_kw c "WHERE" then Some (parse_expr c) else None in
  if at_kw c "ORDER" || at_kw c "LIMIT" then not_accepted c (here c) "ORDER BY or LIMIT in UPDATE";
  let ureturning = parse_returning c in
  SUpdate { utable; uat; sets = List.rev !sets; uwhere; ureturning }

let parse_delete (c: cursor): statement =
  expect_kw c "DELETE";
  expect_kw c "FROM";
  let (dtable, dat) = expect_name c "a table" in
  let dwhere = if accept_kw c "WHERE" then Some (parse_expr c) else None in
  if at_kw c "ORDER" || at_kw c "LIMIT" then not_accepted c (here c) "ORDER BY or LIMIT in DELETE";
  let dreturning = parse_returning c in
  SDelete { dtable; dat; dwhere; dreturning }

(* A default is a literal, a signed number, or an expression in brackets. *)
let parse_default (c: cursor): expr =
  let t = peek c in
  match t.tok with
  | Op "(" -> ignore (advance c); let e = parse_expr c in expect_op c ")"; e
  | Op ("-" | "+") -> parse_unary c
  | IntLit _ | RealLit _ | Str _ | BlobLit _ -> parse_primary c
  | Word w when List.mem (upper w) ["NULL"; "TRUE"; "FALSE"] -> parse_primary c
  | Word w when List.mem (upper w) ["CURRENT_TIME"; "CURRENT_DATE"; "CURRENT_TIMESTAMP"] ->
     ignore (advance c); { e = EStr; at = t.at }
  | _ -> fail (H 8016) c.o t.at (Printf.sprintf "expected a default value, found %s" (describe t.tok))

let parse_actions (c: cursor): unit =
  let continue = ref true in
  while !continue do
    if at_kw c "ON" && (is_kw (peek_n c 1) "DELETE" || is_kw (peek_n c 1) "UPDATE") then begin
      ignore (advance c);
      ignore (advance c);
      if accept_kw c "SET" then (if not (accept_kw c "NULL") then expect_kw c "DEFAULT")
      else if accept_kw c "CASCADE" || accept_kw c "RESTRICT" then ()
      else (expect_kw c "NO"; expect_kw c "ACTION")
    end else if at_kw c "MATCH" then
      not_accepted c (here c) "MATCH"
    else if at_kw c "DEFERRABLE" || (at_kw c "NOT" && is_kw (peek_n c 1) "DEFERRABLE") then
      not_accepted c (here c) "DEFERRABLE"
    else
      continue := false
  done

let parse_references (c: cursor): string * (string * pos) list * pos =
  let (table, p) = expect_name c "a table after REFERENCES" in
  let cols = if at_op c "(" then parse_name_list c "a column" else [] in
  parse_actions c;
  (table, cols, p)

let parse_coldef (c: cursor): coldef =
  let (cname, cat) = expect_name c "a column name" in
  let ctype =
    match (peek c).tok with
    | Word w when not (List.mem (upper w) reserved) -> ignore (advance c); upper w
    | _ -> ""
  in
  if at_op c "(" then
    fail (H 8017) c.o (here c) "a size after the type name is not a STRICT type (INT, INTEGER, REAL, TEXT, BLOB)";
  let d = ref { cname; ctype; cat; notnull = false; primary = false; hasdefault = false;
                default = None; checks = []; refs = [] } in
  let continue = ref true in
  while !continue do
    if accept_kw c "CONSTRAINT" then ignore (expect_name c "a constraint name");
    if at_kw c "PRIMARY" then begin
      ignore (advance c);
      expect_kw c "KEY";
      if not (accept_kw c "ASC") then ignore (accept_kw c "DESC");
      parse_conflict_clause c;
      ignore (accept_kw c "AUTOINCREMENT");
      d := { !d with primary = true }
    end else if at_kw c "NOT" && is_kw (peek_n c 1) "NULL" then begin
      ignore (advance c);
      ignore (advance c);
      parse_conflict_clause c;
      d := { !d with notnull = true }
    end else if accept_kw c "NULL" then
      ()
    else if accept_kw c "UNIQUE" then
      parse_conflict_clause c
    else if accept_kw c "CHECK" then begin
      expect_op c "(";
      let e = parse_expr c in
      expect_op c ")";
      d := { !d with checks = e :: !d.checks }
    end else if accept_kw c "DEFAULT" then
      d := { !d with hasdefault = true; default = Some (parse_default c) }
    else if accept_kw c "COLLATE" then
      ignore (expect_name c "a collation")
    else if accept_kw c "REFERENCES" then begin
      let (t, cols, p) = parse_references c in
      d := { !d with refs = (t, List.map fst cols, p) :: !d.refs }
    end else if at_kw c "GENERATED" || at_kw c "AS" then
      not_accepted c (here c) "a generated column"
    else
      continue := false
  done;
  !d

let parse_create_table (c: cursor): statement =
  expect_kw c "TABLE";
  let ifnot = if accept_kw c "IF" then (expect_kw c "NOT"; expect_kw c "EXISTS"; true) else false in
  let (ctable, ctat) = expect_name c "a table name" in
  if at_op c "." then not_accepted c (here c) "a schema name";
  if at_kw c "AS" then not_accepted c (here c) "CREATE TABLE ... AS";
  expect_op c "(";
  let cols = ref [] and constraints = ref [] in
  let table_constraint () =
    at_kw c "CONSTRAINT" || at_kw c "PRIMARY" || at_kw c "UNIQUE" || at_kw c "CHECK" || at_kw c "FOREIGN"
  in
  let continue = ref true in
  while !continue do
    if table_constraint () then begin
      if accept_kw c "CONSTRAINT" then ignore (expect_name c "a constraint name");
      let t = peek c in
      if accept_kw c "PRIMARY" then begin
        expect_kw c "KEY";
        let names = parse_name_list c "a column" in
        parse_conflict_clause c;
        constraints := TPrimary names :: !constraints
      end else if accept_kw c "UNIQUE" then begin
        let names = parse_name_list c "a column" in
        parse_conflict_clause c;
        constraints := TUnique names :: !constraints
      end else if accept_kw c "CHECK" then begin
        expect_op c "(";
        let e = parse_expr c in
        expect_op c ")";
        constraints := TCheck e :: !constraints
      end else if accept_kw c "FOREIGN" then begin
        expect_kw c "KEY";
        let names = parse_name_list c "a column" in
        expect_kw c "REFERENCES";
        let (table, tcols, p) = parse_references c in
        constraints := TForeign (names, table, tcols, p) :: !constraints
      end else
        fail (H 8018) c.o t.at (Printf.sprintf "expected a table constraint, found %s" (describe t.tok))
    end else
      cols := parse_coldef c :: !cols;
    if not (accept_op c ",") then continue := false
  done;
  expect_op c ")";
  let strict = ref false and norowid = ref false in
  let option () =
    if accept_kw c "STRICT" then strict := true
    else if accept_kw c "WITHOUT" then begin
      let t = peek c in
      (match t.tok with
       | Word w when upper w = "ROWID" -> ignore (advance c)
       | _ -> fail (H 8019) c.o t.at "expected ROWID after WITHOUT");
      norowid := true
    end else
      fail (H 8020) c.o (here c) (Printf.sprintf "expected STRICT or WITHOUT ROWID, found %s" (describe (peek c).tok))
  in
  if at_kw c "STRICT" || at_kw c "WITHOUT" then begin
    option ();
    while accept_op c "," do option () done
  end;
  SCreateTable { ctable; ctat; ifnot; cols = List.rev !cols; constraints = List.rev !constraints;
                 strict = !strict; norowid = !norowid }

let parse_create_index (c: cursor): statement =
  ignore (accept_kw c "UNIQUE");
  expect_kw c "INDEX";
  let xifnot = if accept_kw c "IF" then (expect_kw c "NOT"; expect_kw c "EXISTS"; true) else false in
  let (xname, xat) = expect_name c "an index name" in
  expect_kw c "ON";
  let (xtable, xtat) = expect_name c "a table" in
  if not (at_op c "(") then fail (H 8021) c.o (here c) "expected ( after the table";
  (* An index on an expression is not accepted: the columns are names. *)
  let xcols = parse_name_list c "a column (an index on an expression is not accepted)" in
  let xwhere = if accept_kw c "WHERE" then Some (parse_expr c) else None in
  SCreateIndex { xname; xat; xtable; xtat; xcols; xwhere; xifnot }

let parse_alter (c: cursor): statement =
  expect_kw c "TABLE";
  let (table, p) = expect_name c "a table" in
  if accept_kw c "RENAME" then begin
    if accept_kw c "TO" then
      SRenameTable (table, p, fst (expect_name c "a table name"))
    else begin
      ignore (accept_kw c "COLUMN");
      let (from, fp) = expect_name c "a column" in
      expect_kw c "TO";
      SRenameColumn (table, p, from, fst (expect_name c "a column name"), fp)
    end
  end else if accept_kw c "ADD" then begin
    ignore (accept_kw c "COLUMN");
    SAddColumn (table, p, parse_coldef c)
  end else if accept_kw c "DROP" then begin
    ignore (accept_kw c "COLUMN");
    let (col, cp) = expect_name c "a column" in
    SDropColumn (table, p, col, cp)
  end else
    fail (H 8022) c.o (here c) "expected RENAME, ADD or DROP after ALTER TABLE"

let parse_statement (c: cursor) (in_migration: bool): statement =
  let t = peek c in
  if at_kw c "SELECT" then SSelect (parse_select c)
  else if at_kw c "INSERT" || at_kw c "REPLACE" then parse_insert c
  else if at_kw c "UPDATE" then parse_update c
  else if at_kw c "DELETE" then parse_delete c
  else if at_kw c "WITH" then not_accepted c t.at "WITH"
  else if in_migration && accept_kw c "CREATE" then begin
    if at_kw c "TEMP" || at_kw c "TEMPORARY" then not_accepted c (here c) "a temporary table";
    if at_kw c "TABLE" then parse_create_table c
    else if at_kw c "UNIQUE" || at_kw c "INDEX" then parse_create_index c
    else fail (H 8023) c.o (here c) (Printf.sprintf "CREATE %s is not accepted in a migration, which creates a table (CREATE TABLE) or an index (CREATE INDEX, CREATE UNIQUE INDEX)" (describe (peek c).tok))
  end
  else if in_migration && accept_kw c "ALTER" then parse_alter c
  else if in_migration && accept_kw c "DROP" then begin
    if accept_kw c "TABLE" then begin
      let ifx = if accept_kw c "IF" then (expect_kw c "EXISTS"; true) else false in
      let (n, p) = expect_name c "a table" in
      SDropTable (n, p, ifx)
    end else if accept_kw c "INDEX" then begin
      let ifx = if accept_kw c "IF" then (expect_kw c "EXISTS"; true) else false in
      let (n, p) = expect_name c "an index" in
      SDropIndex (n, p, ifx)
    end else
      fail (H 8024) c.o (here c) (Printf.sprintf "DROP %s is not accepted in a migration" (describe (peek c).tok))
  end
  else if in_migration then
    fail (H 8025) c.o t.at (Printf.sprintf "a migration may hold CREATE TABLE, CREATE INDEX, ALTER TABLE, DROP TABLE, DROP INDEX, INSERT, UPDATE and DELETE, not %s" (describe t.tok))
  else
    fail (H 8026) c.o t.at (Printf.sprintf "a query is SELECT, INSERT, UPDATE or DELETE, not %s" (describe t.tok))

(* ---------------------------------------------------------------------- *)
(* 3. The schema and the checker                                           *)
(* ---------------------------------------------------------------------- *)

type sqlty = Integer | Real | Text | Blob

type column = { name: string; ty: sqlty; nonnull: bool; defaulted: bool }

type table = { tname: string; columns: column list }

type schema = { mutable tables: table list; mutable indexes: (string * string) list }

let ty_name (t: sqlty): string =
  match t with Integer -> "INTEGER" | Real -> "REAL" | Text -> "TEXT" | Blob -> "BLOB"

let numeric (t: sqlty): bool = t = Integer || t = Real

let compatible (a: sqlty) (b: sqlty): bool = a = b || (numeric a && numeric b)

let find_table (sc: schema) (name: string): table option =
  List.find_opt (fun t -> lower t.tname = lower name) sc.tables

let find_column (t: table) (name: string): column option =
  List.find_opt (fun col -> lower col.name = lower name) t.columns

(* The type of a value: `t' is None for the NULL literal. *)
type vty = { t: sqlty option; n: bool }

type entry = { alias: string; table: table; nullable: bool }

type env = {
    o: origin;
    scope: entry list;
    params: (sqlty * bool) option array;
    aggregates: bool;
  }

let the_table (o: origin) (sc: schema) (name: string) (p: pos): table =
  match find_table sc name with
  | Some t -> t
  | None -> fail (H 8027) o p (Printf.sprintf "there is no table %s in the schema the migrations build" name)

let the_column (o: origin) (t: table) (name: string) (p: pos): column =
  match find_column t name with
  | Some col -> col
  | None -> fail (H 8028) o p (Printf.sprintf "table %s has no column %s" t.tname name)

let describe_vty (v: vty): string =
  match v.t with None -> "NULL" | Some t -> ty_name t

let is_param (e: expr): bool = match e.e with EParam _ -> true | _ -> false

let hint (v: vty): (sqlty * bool) option =
  match v.t with Some t -> Some (t, false) | None -> None

let rec typ (env: env) (e: expr) (want: (sqlty * bool) option): vty =
  let f : 'a. error_code -> string -> 'a = fun code message -> fail code env.o e.at message in
  match e.e with
  | ENull -> { t = None; n = true }
  | EBool | EInt -> { t = Some Integer; n = false }
  | EReal -> { t = Some Real; n = false }
  | EStr -> { t = Some Text; n = false }
  | EBlob -> { t = Some Blob; n = false }
  | EParam k ->
     (match want with
      | Some (t, n) ->
         env.params.(k - 1) <- Some (t, n);
         { t = Some t; n }
      | None ->
         f (H 8029) (Printf.sprintf "the type of parameter %d cannot be told from where it stands: compare it with a column, or put it where a column's value goes" k))
  | ECol (q, name) ->
     let entry_col =
       match q with
       | Some qual ->
          (match List.filter (fun en -> lower en.alias = lower qual) env.scope with
           | [en] -> (en, the_column env.o en.table name e.at)
           | [] -> f (H 8030) (Printf.sprintf "there is no table or alias %s in this query" qual)
           | _ -> internal_err (Printf.sprintf "%s names more than one table of this query" qual))
       | None ->
          let hits = List.filter_map (fun en -> match find_column en.table name with Some col -> Some (en, col) | None -> None) env.scope in
          (match hits with
           | [hit] -> hit
           | [] ->
              if env.scope = [] then f (H 8032) (Printf.sprintf "%s: this query has no table to take a column from" name)
              else f (H 8033) (Printf.sprintf "no table of this query has a column %s (%s)" name
                        (String.concat ", " (List.map (fun en -> en.table.tname) env.scope)))
           | _ -> f (H 8034) (Printf.sprintf "more than one table of this query has a column %s: name the table, as in t.%s" name name))
     in
     let (en, col) = entry_col in
     { t = Some col.ty; n = (not col.nonnull) || en.nullable }
  | ENeg x ->
     let v = typ env x want in
     (match v.t with
      | Some t when numeric t -> v
      | _ -> f (H 8035) (Printf.sprintf "a sign in front of %s: only a number has one" (describe_vty v)))
  | ENot x ->
     let v = typ env x (Some (Integer, false)) in
     if v.t <> Some Integer then f (H 8036) (Printf.sprintf "NOT of %s: NOT takes a condition" (describe_vty v));
     v
  | EArith (op, a, b) ->
     let (va, vb) = pair env a b in
     (match va.t, vb.t with
      | Some ta, Some tb when numeric ta && numeric tb ->
         if op = "%" && (ta <> Integer || tb <> Integer) then f (H 8037) "% takes two INTEGERs";
         { t = Some (if ta = Integer && tb = Integer then Integer else Real); n = va.n || vb.n }
      | _ -> f (H 8038) (Printf.sprintf "%s %s %s: arithmetic takes numbers (INTEGER or REAL)" (describe_vty va) op (describe_vty vb)))
  | EConcat (a, b) ->
     let (va, vb) = pair env a b in
     if va.t <> Some Text || vb.t <> Some Text then
       f (H 8039) (Printf.sprintf "%s || %s: || joins TEXT to TEXT" (describe_vty va) (describe_vty vb));
     { t = Some Text; n = va.n || vb.n }
  | ECompare (op, a, b) ->
     let (va, vb) = pair env a b in
     (match va.t, vb.t with
      | None, _ | _, None -> f (H 8040) "a comparison with NULL is never true: write IS NULL or IS NOT NULL"
      | Some ta, Some tb ->
         if not (compatible ta tb) then
           f (H 8041) (Printf.sprintf "%s %s %s: SQLite compares these without converting, and the answer is always the same" (ty_name ta) op (ty_name tb));
         { t = Some Integer; n = va.n || vb.n })
  | EIs (_, a, b) ->
     let (va, vb) = pair env a b in
     (match va.t, vb.t with
      | Some ta, Some tb when not (compatible ta tb) ->
         f (H 8042) (Printf.sprintf "%s IS %s: the two can never be the same" (ty_name ta) (ty_name tb))
      | _ -> { t = Some Integer; n = false })
  | ENullTest (_, x) ->
     if is_param x then f (H 8043) "a parameter tested for NULL: the value is known where it is given";
     ignore (typ env x None);
     { t = Some Integer; n = false }
  | ELike (op, _, a, b) ->
     let (va, vb) = pair env a b in
     if va.t <> Some Text || vb.t <> Some Text then
       f (H 8044) (Printf.sprintf "%s %s %s: %s compares TEXT with TEXT" (describe_vty va) op (describe_vty vb) op);
     { t = Some Integer; n = va.n || vb.n }
  | EIn (_, x, items) ->
     if is_param x then f (H 8045) "a parameter on the left of IN: put a column there";
     let vx = typ env x None in
     let tx = (match vx.t with Some t -> t | None -> f (H 8046) "NULL IN (...) is never true") in
     let n = List.fold_left
               (fun acc item ->
                 let vi = typ env item (Some (tx, false)) in
                 (match vi.t with
                  | None -> fail (H 8047) env.o item.at "NULL in an IN list is never matched"
                  | Some ti when not (compatible tx ti) ->
                     fail (H 8048) env.o item.at (Printf.sprintf "%s IN (... %s ...): the two can never be equal" (ty_name tx) (ty_name ti))
                  | _ -> ());
                 acc || vi.n)
               vx.n items
     in
     { t = Some Integer; n }
  | EBetween (_, x, lo, hi) ->
     if is_param x then f (H 8049) "a parameter on the left of BETWEEN: put a column there";
     let vx = typ env x None in
     let tx = (match vx.t with Some t -> t | None -> f (H 8050) "NULL BETWEEN ... is never true") in
     let check (b: expr): bool =
       let vb = typ env b (Some (tx, false)) in
       (match vb.t with
        | Some tb when compatible tx tb -> ()
        | _ -> fail (H 8051) env.o b.at (Printf.sprintf "BETWEEN compares %s with %s" (ty_name tx) (describe_vty vb)));
       vb.n
     in
     let nlo = check lo in
     let nhi = check hi in
     { t = Some Integer; n = vx.n || nlo || nhi }
  | ELogic (op, a, b) ->
     let va = typ env a (Some (Integer, false)) in
     let vb = typ env b (Some (Integer, false)) in
     if va.t <> Some Integer || vb.t <> Some Integer then
       f (H 8052) (Printf.sprintf "%s %s %s: %s joins conditions" (describe_vty va) op (describe_vty vb) op);
     { t = Some Integer; n = va.n || vb.n }
  | ECountStar ->
     if not env.aggregates then f (H 8053) "count(*) here: an aggregate stands in the columns, HAVING or ORDER BY";
     { t = Some Integer; n = false }
  | ECall (name, distinct, args) ->
     let aggregate = List.mem name ["count"; "sum"; "total"; "avg"; "min"; "max"] in
     if aggregate && not env.aggregates then
       f (H 8054) (Printf.sprintf "%s() here: an aggregate stands in the columns, HAVING or ORDER BY" name);
     if distinct && not aggregate then f (H 8055) "DISTINCT inside a function that is not an aggregate";
     let one () =
       match args with
       | [x] -> x
       | _ -> f (H 8056) (Printf.sprintf "%s() takes one argument here" name)
     in
     let num (x: expr): vty =
       let v = typ env x None in
       (match v.t with
        | Some t when numeric t -> v
        | _ -> f (H 8057) (Printf.sprintf "%s() of %s: it takes a number" name (describe_vty v)))
     in
     (match name with
      | "count" ->
         let x = one () in
         if is_param x then f (H 8058) "count() of a parameter";
         ignore (typ env x None);
         { t = Some Integer; n = false }
      | "sum" -> let v = num (one ()) in { t = v.t; n = true }
      | "total" -> ignore (num (one ())); { t = Some Real; n = false }
      | "avg" -> ignore (num (one ())); { t = Some Real; n = true }
      | "min" | "max" ->
         let x = one () in
         if is_param x then f (H 8059) (name ^ "() of a parameter");
         let v = typ env x None in
         if v.t = None then f (H 8060) (name ^ "(NULL)");
         { t = v.t; n = true }
      | "coalesce" | "ifnull" ->
         if List.length args < 2 || (name = "ifnull" && List.length args <> 2) then
           f (H 8061) (Printf.sprintf "%s() takes %s" name (if name = "ifnull" then "two arguments" else "two or more arguments"));
         let first = (match List.find_opt (fun a -> not (is_param a)) args with
                      | Some a -> a
                      | None -> f (H 8062) (name ^ "() of parameters only has no type")) in
         let v0 = typ env first None in
         let t0 = (match v0.t with Some t -> t | None -> fail (H 8063) env.o first.at (name ^ "() whose first value is NULL")) in
         let n = List.fold_left
                   (fun acc a ->
                     if a == first then acc && v0.n
                     else begin
                       let va = typ env a (Some (t0, false)) in
                       (match va.t with
                        | Some ta when compatible t0 ta -> ()
                        | None -> ()
                        | Some ta -> fail (H 8064) env.o a.at (Printf.sprintf "%s() of %s and %s" name (ty_name t0) (ty_name ta)));
                       acc && va.n
                     end)
                   true args
         in
         { t = Some t0; n }
      | "length" ->
         let v = typ env (one ()) (Some (Text, false)) in
         if v.t <> Some Text && v.t <> Some Blob then f (H 8065) (Printf.sprintf "length() of %s: it takes TEXT or BLOB" (describe_vty v));
         { t = Some Integer; n = v.n }
      | "lower" | "upper" ->
         let v = typ env (one ()) (Some (Text, false)) in
         if v.t <> Some Text then f (H 8066) (Printf.sprintf "%s() of %s: it takes TEXT" name (describe_vty v));
         v
      | "abs" -> num (one ())
      | _ ->
         f (H 8067) (Printf.sprintf "%s() is not one of the functions whose type the compiler knows: count, sum, total, avg, min, max, coalesce, ifnull, length, lower, upper, abs" name))

(* Two operands of one operator: a parameter takes its type from the other
   side, so the other side is typed first. *)
and pair (env: env) (a: expr) (b: expr): vty * vty =
  if is_param a && is_param b then
    fail (H 8068) env.o a.at "two parameters meet, and neither says what type the other is";
  if is_param a then
    let vb = typ env b None in
    let va = typ env a (hint vb) in
    (va, vb)
  else
    let va = typ env a None in
    let vb = typ env b (hint va) in
    (va, vb)

let condition (env: env) (e: expr) (what: string): unit =
  let v = typ env e (Some (Integer, false)) in
  if v.t <> Some Integer then
    fail (H 8069) env.o e.at (Printf.sprintf "%s is %s, and it has to be a condition" what (describe_vty v))

(* A Hilde field is named after the column; a name that cannot be one needs
   an alias. *)
let hilde_keywords = [
    "and"; "or"; "not"; "module"; "is"; "body"; "import"; "as"; "end";
    "constant"; "type"; "function"; "generic"; "record"; "union"; "case";
    "of"; "when"; "typeclass"; "instance"; "method"; "if"; "then"; "else";
    "let"; "var"; "while"; "for"; "do"; "from"; "to"; "borrow"; "return";
    "skip"; "pragma"; "sizeof"; "nil"; "true"; "false";
  ]

let field_name (o: origin) (p: pos) (name: string): string =
  let ok = String.length name > 0
           && ((name.[0] >= 'a' && name.[0] <= 'z') || (name.[0] >= 'A' && name.[0] <= 'Z'))
           && String.for_all (fun ch -> is_start ch || is_digit ch) name
           && not (List.mem name hilde_keywords)
  in
  if not ok then
    fail (H 8070) o p (Printf.sprintf "the column %s cannot name a field of the row type: give it a name with AS" name);
  name

let result_columns (env: env) (cols: result_col list): (string * sqlty * bool * pos) list =
  let from_table (en: entry) (p: pos) =
    List.map (fun col -> (field_name env.o p col.name, col.ty, (not col.nonnull) || en.nullable, p)) en.table.columns
  in
  let out = List.concat_map
              (fun rc ->
                match rc with
                | RStar p ->
                   if env.scope = [] then fail (H 8071) env.o p "* without a table";
                   List.concat_map (fun en -> from_table en p) env.scope
                | RTableStar (t, p) ->
                   (match List.filter (fun en -> lower en.alias = lower t) env.scope with
                    | [en] -> from_table en p
                    | _ -> fail (H 8072) env.o p (Printf.sprintf "there is no table or alias %s in this query" t))
                | RExpr (e, alias) ->
                   let v = typ env e None in
                   let t = (match v.t with Some t -> t | None -> fail (H 8073) env.o e.at "this column is always NULL and has no type") in
                   let name = (match alias, e.e with
                               | Some a, _ -> a
                               | None, ECol (_, c) -> c
                               | None, _ -> fail (H 8074) env.o e.at "a column that is not a plain column needs a name: write AS") in
                   [(field_name env.o e.at name, t, v.n, e.at)])
              cols
  in
  List.iter
    (fun (name, _, _, p) ->
      if List.length (List.filter (fun (other, _, _, _) -> lower other = lower name) out) > 1 then
        fail (H 8075) env.o p (Printf.sprintf "two columns of the result are called %s: rename one with AS" name))
    out;
  out

let entry_of (o: origin) (sc: schema) (s: source) (nullable: bool): entry =
  let t = the_table o sc s.table s.sat in
  { alias = (match s.alias with Some a -> a | None -> t.tname); table = t; nullable }

(* A value stored into a column: what STRICT accepts without an error at
   run time -- an INTEGER into REAL is converted, nothing else is. *)
let store (env: env) (col: column) (e: expr): unit =
  let v = typ env e (Some (col.ty, not col.nonnull)) in
  (match v.t with
   | None ->
      if col.nonnull then fail (H 8076) env.o e.at (Printf.sprintf "NULL into %s, which is NOT NULL" col.name)
   | Some t ->
      let fits = t = col.ty || (col.ty = Real && t = Integer) in
      if not fits then
        fail (H 8077) env.o e.at (Printf.sprintf "%s into %s, a %s column: a STRICT table refuses it" (ty_name t) col.name (ty_name col.ty));
      if v.n && col.nonnull then
        fail (H 8078) env.o e.at (Printf.sprintf "a value that may be NULL into %s, which is NOT NULL" col.name))

type checked = {
    rows: (string * sqlty * bool * pos) list option;
    writes: bool;
  }

let check_statement (o: origin) (sc: schema) (params: (sqlty * bool) option array) (s: statement): checked =
  let env0 = { o; scope = []; params; aggregates = false } in
  match s with
  | SSelect q ->
     let first = (match q.from with Some src -> [entry_of o sc src false] | None -> []) in
     let scope = List.fold_left
                   (fun acc j ->
                     let en = entry_of o sc j.jsource j.outer in
                     if List.exists (fun other -> lower other.alias = lower en.alias) acc then
                       fail (H 8079) o j.jsource.sat (Printf.sprintf "%s stands twice in FROM: give one an alias" en.alias);
                     let acc' = acc @ [en] in
                     (match j.on with
                      | Some cond -> condition { env0 with scope = acc' } cond "the ON condition"
                      | None -> ());
                     acc')
                   first q.joins
     in
     let env = { env0 with scope } in
     (match q.where with Some w -> condition env w "the WHERE condition" | None -> ());
     List.iter (fun g -> ignore (typ env g None)) q.group;
     let aenv = { env with aggregates = true } in
     let results = result_columns aenv q.results in
     (match q.having with
      | Some h ->
         if q.group = [] then internal_err "HAVING without GROUP BY";
         condition aenv h "the HAVING condition"
      | None -> ());
     List.iter
       (fun (e: expr) ->
         match e.e with
         | ECol (None, name) when List.exists (fun (r, _, _, _) -> lower r = lower name) results
                                  && not (List.exists (fun en -> find_column en.table name <> None) scope) -> ()
         | EInt -> ()
         | _ -> ignore (typ aenv e None))
       q.order;
     List.iter
       (fun (e: expr) ->
         let v = typ env e (Some (Integer, false)) in
         if v.t <> Some Integer || v.n then fail (H 8081) o e.at "LIMIT and OFFSET take an INTEGER that is not NULL")
       q.limit;
     { rows = Some results; writes = false }
  | SInsert { itable; iat; columns; rows; returning } ->
     let t = the_table o sc itable iat in
     let named = (match columns with
                  | Some cols ->
                     List.iteri
                       (fun k (name, p) ->
                         if List.exists (fun (other, _) -> lower other = lower name) (List.filteri (fun j _ -> j < k) cols) then
                           fail (H 8082) o p (Printf.sprintf "%s is named twice" name))
                       cols;
                     List.map (fun (name, p) -> the_column o t name p) cols
                  | None -> t.columns) in
     List.iter
       (fun col ->
         if col.nonnull && not col.defaulted && not (List.memq col named) then
           fail (H 8083) o iat (Printf.sprintf "the INSERT leaves out %s, which is NOT NULL and has no DEFAULT" col.name))
       t.columns;
     if rows = [] && named <> [] && columns <> None then fail (H 8084) o iat "DEFAULT VALUES with a column list";
     let env = { env0 with scope = [{ alias = t.tname; table = t; nullable = false }] } in
     let valenv = { env0 with scope = [] } in
     List.iter
       (fun row ->
         if List.length row <> List.length named then
           fail (H 8085) o iat (Printf.sprintf "a row of %d values for %d columns" (List.length row) (List.length named));
         List.iter2 (fun col e -> store valenv col e) named row)
       rows;
     let results = if returning = [] then None else Some (result_columns env returning) in
     { rows = results; writes = true }
  | SUpdate { utable; uat; sets; uwhere; ureturning } ->
     let t = the_table o sc utable uat in
     let env = { env0 with scope = [{ alias = t.tname; table = t; nullable = false }] } in
     List.iter (fun (name, p, e) -> store env (the_column o t name p) e) sets;
     (match uwhere with Some w -> condition env w "the WHERE condition" | None -> ());
     let results = if ureturning = [] then None else Some (result_columns env ureturning) in
     { rows = results; writes = true }
  | SDelete { dtable; dat; dwhere; dreturning } ->
     let t = the_table o sc dtable dat in
     let env = { env0 with scope = [{ alias = t.tname; table = t; nullable = false }] } in
     (match dwhere with Some w -> condition env w "the WHERE condition" | None -> ());
     let results = if dreturning = [] then None else Some (result_columns env dreturning) in
     { rows = results; writes = true }
  | _ ->
     internal_err "Sql.check_statement: a schema statement in a query"

(* ---------------------------------------------------------------------- *)
(* Replaying a migration into the schema                                   *)
(* ---------------------------------------------------------------------- *)

let column_type (o: origin) (d: coldef): sqlty =
  match d.ctype with
  | "INT" | "INTEGER" -> Integer
  | "REAL" -> Real
  | "TEXT" -> Text
  | "BLOB" -> Blob
  | "ANY" -> fail (H 8086) o d.cat (d.cname ^ " is ANY: a column the compiler checks against has one of INT, INTEGER, REAL, TEXT, BLOB")
  | "" -> fail (H 8087) o d.cat (d.cname ^ " has no type: a STRICT table gives every column one")
  | other -> fail (H 8088) o d.cat (Printf.sprintf "%s is %s, which is not a STRICT type: INT, INTEGER, REAL, TEXT, BLOB" d.cname other)

let check_default (o: origin) (sc: schema) (col: column) (e: expr): unit =
  let params = Array.make 0 None in
  store { o; scope = []; params; aggregates = false } col e;
  ignore sc

let check_references (o: origin) (sc: schema) (self: table) (target: string) (cols: string list) (p: pos): unit =
  let t = if lower target = lower self.tname then self else the_table o sc target p in
  List.iter (fun c -> ignore (the_column o t c p)) cols

let apply (o: origin) (sc: schema) (s: statement): unit =
  let no_params = Array.make 0 None in
  match s with
  | SCreateTable { ctable; ctat; ifnot; cols; constraints; strict; norowid } ->
     (match find_table sc ctable with
      | Some _ when ifnot -> ()
      | Some _ -> fail (H 8089) o ctat (Printf.sprintf "table %s exists already" ctable)
      | None ->
         if not strict then
           fail (H 8090) o ctat (Printf.sprintf "table %s is not STRICT: without STRICT, SQLite stores a value of any type in any column, and the types the compiler checks would not hold" ctable);
         List.iteri
           (fun k d ->
             if List.exists (fun (other: coldef) -> lower other.cname = lower d.cname) (List.filteri (fun j _ -> j < k) cols) then
               fail (H 8091) o d.cat (Printf.sprintf "column %s is defined twice" d.cname))
           cols;
         let table_pk = List.concat_map (function TPrimary names -> List.map fst names | _ -> []) constraints in
         let column_pks = List.filter (fun (d: coldef) -> d.primary) cols in
         if List.length column_pks + (if table_pk = [] then 0 else 1) > 1 then
           fail (H 8092) o ctat (Printf.sprintf "table %s has more than one PRIMARY KEY" ctable);
         List.iter
           (fun name ->
             if not (List.exists (fun (d: coldef) -> lower d.cname = lower name) cols) then
               fail (H 8093) o ctat (Printf.sprintf "the PRIMARY KEY names %s, which is not a column of %s" name ctable))
           table_pk;
         let in_pk (d: coldef) = d.primary || List.exists (fun n -> lower n = lower d.cname) table_pk in
         (* The rowid alias: a column declared exactly INTEGER that is the
            whole primary key of a table with a rowid.  Measured with
            sqlite3 3.46.1: `INT PRIMARY KEY' is not one. *)
         let rowid (d: coldef) =
           (not norowid) && d.ctype = "INTEGER" && in_pk d
           && (d.primary || List.length table_pk = 1)
         in
         let columns = List.map
                         (fun d ->
                           let ty = column_type o d in
                           (* In a STRICT table every primary key column is
                              NOT NULL (measured); the rowid alias gets its
                              value from SQLite when none is given. *)
                           { name = d.cname; ty; nonnull = d.notnull || in_pk d; defaulted = d.hasdefault || rowid d })
                         cols
         in
         let table = { tname = ctable; columns } in
         List.iter2
           (fun (d: coldef) col ->
             (match d.default with Some e -> check_default o sc col e | None -> ());
             List.iter (fun (t, rcols, p) -> check_references o sc table t rcols p) d.refs)
           cols columns;
         let env = { o; scope = [{ alias = ctable; table; nullable = false }]; params = no_params; aggregates = false } in
         List.iter (fun (d: coldef) -> List.iter (fun e -> condition env e "a CHECK") d.checks) cols;
         List.iter
           (fun tc ->
             match tc with
             | TPrimary names | TUnique names -> List.iter (fun (n, p) -> ignore (the_column o table n p)) names
             | TCheck e -> condition env e "a CHECK"
             | TForeign (names, t, rcols, p) ->
                List.iter (fun (n, np) -> ignore (the_column o table n np)) names;
                check_references o sc table t (List.map fst rcols) p)
           constraints;
         sc.tables <- sc.tables @ [table])
  | SAddColumn (tname, p, d) ->
     let t = the_table o sc tname p in
     if find_column t d.cname <> None then fail (H 8094) o d.cat (Printf.sprintf "table %s has a column %s already" tname d.cname);
     if d.primary then fail (H 8095) o d.cat "ALTER TABLE ADD COLUMN cannot add a PRIMARY KEY";
     if d.notnull && not d.hasdefault then
       fail (H 8096) o d.cat (Printf.sprintf "%s is NOT NULL without a DEFAULT, and SQLite refuses to add such a column to a table that has rows" d.cname);
     let col = { name = d.cname; ty = column_type o d; nonnull = d.notnull; defaulted = d.hasdefault } in
     (match d.default with Some e -> check_default o sc col e | None -> ());
     List.iter (fun (rt, rcols, rp) -> check_references o sc t rt rcols rp) d.refs;
     let t' = { t with columns = t.columns @ [col] } in
     sc.tables <- List.map (fun x -> if x == t then t' else x) sc.tables
  | SRenameTable (tname, p, target) ->
     let t = the_table o sc tname p in
     if find_table sc target <> None then fail (H 8097) o p (Printf.sprintf "table %s exists already" target);
     sc.tables <- List.map (fun x -> if x == t then { t with tname = target } else x) sc.tables;
     sc.indexes <- List.map (fun (i, tb) -> if lower tb = lower tname then (i, target) else (i, tb)) sc.indexes
  | SRenameColumn (tname, p, from, target, fp) ->
     let t = the_table o sc tname p in
     ignore (the_column o t from fp);
     if find_column t target <> None then fail (H 8098) o fp (Printf.sprintf "table %s has a column %s already" tname target);
     let t' = { t with columns = List.map (fun c -> if lower c.name = lower from then { c with name = target } else c) t.columns } in
     sc.tables <- List.map (fun x -> if x == t then t' else x) sc.tables
  | SDropColumn (tname, p, col, cp) ->
     let t = the_table o sc tname p in
     ignore (the_column o t col cp);
     let t' = { t with columns = List.filter (fun c -> lower c.name <> lower col) t.columns } in
     if t'.columns = [] then fail (H 8099) o cp "a table cannot lose its last column";
     sc.tables <- List.map (fun x -> if x == t then t' else x) sc.tables
  | SDropTable (tname, p, ifx) ->
     (match find_table sc tname with
      | Some t ->
         sc.tables <- List.filter (fun x -> x != t) sc.tables;
         sc.indexes <- List.filter (fun (_, tb) -> lower tb <> lower tname) sc.indexes
      | None -> if not ifx then fail (H 8100) o p (Printf.sprintf "there is no table %s to drop" tname))
  | SCreateIndex { xname; xat; xtable; xtat; xcols; xwhere; xifnot } ->
     if List.exists (fun (i, _) -> lower i = lower xname) sc.indexes then begin
       if not xifnot then fail (H 8101) o xat (Printf.sprintf "index %s exists already" xname)
     end else begin
       let t = the_table o sc xtable xtat in
       List.iter (fun (c, cp) -> ignore (the_column o t c cp)) xcols;
       (match xwhere with
        | Some w -> condition { o; scope = [{ alias = t.tname; table = t; nullable = false }]; params = no_params; aggregates = false } w "the WHERE of an index"
        | None -> ());
       sc.indexes <- sc.indexes @ [(xname, xtable)]
     end
  | SDropIndex (xname, p, ifx) ->
     if List.exists (fun (i, _) -> lower i = lower xname) sc.indexes then
       sc.indexes <- List.filter (fun (i, _) -> lower i <> lower xname) sc.indexes
     else if not ifx then
       fail (H 8102) o p (Printf.sprintf "there is no index %s to drop" xname)
  | SSelect _ ->
     internal_err "Sql.apply: a SELECT in a migration"
  | SInsert _ | SUpdate _ | SDelete _ ->
     let checked = check_statement o sc no_params s in
     ignore checked

(* ---------------------------------------------------------------------- *)
(* The migrations directory                                                *)
(* ---------------------------------------------------------------------- *)

type migrations = { schema: schema; constant: string }

let migrations_cache: (string, migrations) Hashtbl.t = Hashtbl.create 4

let number_of (file: string): int option =
  let digits = ref 0 in
  while !digits < String.length file && is_digit file.[!digits] do incr digits done;
  if !digits = 0 || !digits >= String.length file || file.[!digits] <> '-' then None
  else int_of_string_opt (String.sub file 0 !digits)

let read_file (span: span) (construct: string) (path: string): string =
  let refuse (why: string) =
    adorn_error_with_span span (fun () -> err (H 8103) (Printf.sprintf "%s: cannot read %s: %s" construct path why))
  in
  (* A directory is refused before it is opened.  Opening one succeeds on
     Linux and fails on OpenBSD, and the two systems give different words
     for it, so the message says it in its own. *)
  if Sys.file_exists path && Sys.is_directory path then
    refuse "it is a directory, not a file"
  else
  try
    let stream = open_in_bin path in
    let size = in_channel_length stream in
    let contents = really_input_string stream size in
    close_in stream;
    contents
  with Sys_error message -> refuse message

(* The files `migrations/<n>-<name>.sql' beside the module, numbered from 1
   without a gap, each replayed in turn.  Read once per directory. *)
let load_migrations (span: span) (construct: string) (module_file: string): migrations =
  let dir = Filename.concat (Filename.dirname module_file) "migrations" in
  match Hashtbl.find_opt migrations_cache dir with
  | Some m -> m
  | None ->
     let fail_here : 'a. error_code -> string -> 'a = fun code message ->
       adorn_error_with_span span (fun () -> err code (construct ^ ": " ^ message))
     in
     if not (Sys.file_exists dir && Sys.is_directory dir) then
       fail_here (H 8104) (Printf.sprintf "there is no directory %s: the schema a query is checked against is the migrations beside the module" dir);
     let files = List.filter (fun f -> Filename.check_suffix f ".sql") (Array.to_list (Sys.readdir dir)) in
     if files = [] then fail_here (H 8105) (Printf.sprintf "%s holds no .sql file" dir);
     let numbered = List.map
                      (fun f ->
                        match number_of f with
                        | Some k when k >= 1 -> (k, f)
                        | _ -> fail_here (H 8106) (Printf.sprintf "%s/%s: a migration is called <number>-<name>.sql, numbered from 1" dir f))
                      files
     in
     let sorted = List.sort (fun (a, _) (b, _) -> compare a b) numbered in
     List.iteri
       (fun k (number, f) ->
         if number <> k + 1 then
           fail_here (H 8107) (Printf.sprintf "%s/%s: migration %d is missing or doubled; they are numbered 1, 2, 3 ... without a gap" dir f (k + 1)))
       sorted;
     let schema = { tables = []; indexes = [] } in
     let parts = Buffer.create 1024 in
     List.iter
       (fun (_, f) ->
         let path = Filename.concat dir f in
         let text = read_file span construct path in
         let o = InFile path in
         let tokens = lex o text in
         (* A migration is run as it stands, so a parameter has nothing to
            stand for.  The check comes before any statement is checked:
            the checks of VALUES, SET, WHERE and CHECK give a parameter the
            type its place asks for, in a table of the parameters that a
            migration does not have. *)
         (match List.find_opt (fun (t: token) -> match t.tok with Param _ -> true | _ -> false) tokens with
          | Some t -> fail (H 8109) o t.at "a migration has no parameters"
          | None -> ());
         let c = { o; rest = tokens } in
         while (peek c).tok <> Eof do
           if accept_op c ";" then ()
           else begin
             let s = parse_statement c true in
             (match (peek c).tok with
              | Op ";" | Eof -> ()
              | t -> fail (H 8108) o (here c) (Printf.sprintf "expected ; after the statement, found %s" (describe t)));
             apply o schema s
           end
         done;
         Buffer.add_string parts (string_of_int (String.length text));
         Buffer.add_char parts '\n';
         Buffer.add_string parts text)
       sorted;
     let m = { schema; constant = Buffer.contents parts } in
     Hashtbl.replace migrations_cache dir m;
     m

(* ---------------------------------------------------------------------- *)
(* 4. The generator                                                        *)
(* ---------------------------------------------------------------------- *)

(* The generated code calls Standard.Sqlite or Standard.SqlCipher,
   whichever the module imports -- the two have the same functions, and the
   import is what chooses the library.  `lib' is that module's
   name, found by require_import and handed to every function below that
   names one of its functions. *)
let sq (lib: string) (name: string): qident =
  make_qident (make_mod_name lib, make_ident name, make_ident name)

let call (q: qident) (args: aexpr list): aexpr =
  FunctionCall (q, Positional args)

(* A module that imports BOTH never gets here: its imports are compiled
   before it, and the second of the two bindings is refused where the
   libraries meet (H2044, lib/Compiler.ml), and a check written in here
   (H8117) is not reached.  So no third answer is given for it. *)
let require_import (im: import_map) (span: span) (construct: string): string =
  let has (m: string): bool = ModuleNameSet.mem (make_mod_name m) (modules_imported_from im) in
  if has "Standard.SqlCipher" then
    "Standard.SqlCipher"
  else if has "Standard.Sqlite" then
    "Standard.Sqlite"
  else
     adorn_error_with_span span
       (fun () -> err (H 8110) (construct ^ ": a module that uses " ^ construct ^ " imports Standard.Sqlite or Standard.SqlCipher -- e.g. `import Standard.Sqlite (Connection);' -- because the generated code calls it"))

let the_migrations (span: span) (construct: string): migrations =
  let Span { filename; _ } = span in
  load_migrations span construct filename

(* The query, parsed and checked.  The SQL text is the string after its
   escapes are processed -- exactly the bytes SQLite will be given. *)
let checked_query (span: span) (construct: string) (raw: string) (args: aexpr list)
    : escaped_string * checked * (sqlty * bool) array =
  let m = the_migrations span construct in
  let esc = escape_string raw in
  let text = escaped_to_string esc in
  let o = InQuery (span, construct) in
  let tokens = lex o text in
  let count = List.length (List.filter (fun (t: token) -> match t.tok with Param _ -> true | _ -> false) tokens) in
  let c = { o; rest = tokens } in
  let s = parse_statement c false in
  ignore (accept_op c ";");
  (match (peek c).tok with
   | Eof -> ()
   | t -> fail (H 8111) o (here c) (Printf.sprintf "one statement per query; found %s after it" (describe t)));
  if count <> List.length args then
    adorn_error_with_span span
      (fun () -> err (H 8112) (Printf.sprintf "%s: the SQL has %d parameter%s and %d value%s given" construct
                        count (if count = 1 then "" else "s")
                        (List.length args) (if List.length args = 1 then " is" else "s are")));
  let params = Array.make count None in
  let checked = check_statement o m.schema params s in
  let typed = Array.mapi
                (fun k p ->
                  match p with
                  | Some x -> x
                  | None -> internal_err (Printf.sprintf "Sql: parameter %d has no type" (k + 1)))
                params
  in
  (esc, checked, typed)

let hilde_type (region: identifier) (t: sqlty) (nullable: bool): Cst.typespec =
  let base =
    match t with
    | Integer -> Cst.TypeSpecifier (make_ident "Int64", [])
    | Real -> Cst.TypeSpecifier (make_ident "Float64", [])
    | Text | Blob -> Cst.ConcreteSpan (Cst.TypeSpecifier (make_ident "Nat8", []), Cst.TypeSpecifier (region, []))
  in
  if nullable then Cst.TypeSpecifier (make_ident "Option", [base]) else base

let reader (lib: string) (t: sqlty) (nullable: bool): qident =
  let base = match t with Integer -> "columnInt64" | Real -> "columnFloat64" | Text -> "columnText" | Blob -> "columnBlob" in
  sq lib (if nullable then base ^ "OrNone" else base)

let binder (lib: string) (t: sqlty) (nullable: bool): qident =
  let base = match t with Integer -> "withInt64" | Real -> "withFloat64" | Text -> "withText" | Blob -> "withBlob" in
  sq lib (if nullable then base ^ "OrNull" else base)

(* A number or a flag is cast to the parameter's type: a literal gets it,
   and anything else must already have it -- the cast says which two types
   differ.  A span is not cast: its region is the caller's. *)
let bound_value (im: import_map) (t: sqlty) (nullable: bool) (arg: aexpr): aexpr =
  match t with
  | Integer | Real ->
     let qty = qualify_typespec im (hilde_type (make_ident "Static") t nullable) in
     Typecast (arg, qty)
  | Text | Blob -> arg

(* The parameters' values, in the order of the `?'s: noValues() and one
   with... per value.  The connection is not named here, so a statement
   names it once. *)
let values_of (lib: string) (im: import_map) (typed: (sqlty * bool) array) (args: aexpr list): aexpr =
  let (_, chain) =
    List.fold_left
      (fun (k, acc) arg ->
        let (t, n) = typed.(k) in
        (k + 1, call (binder lib t n) [acc; bound_value im t n arg]))
      (0, call (sq lib "noValues") []) args
  in
  chain

type target =
  | TBorrow of identifier
  | TReborrow of identifier

let target_expr (im: import_map) (t: target): aexpr =
  match t with
  | TBorrow name -> BorrowExpr (Common.WriteBorrow, qualify_identifier im name)
  | TReborrow name -> Reborrow (qualify_identifier im name)

let let_in (span: span) (im: import_map) (mut: Common.mutability) (name: identifier) (ty: qtypespec) (value: aexpr) (rest: astmt): astmt =
  ALet (span, mut, name, ty, ABlock (span, AInitialAssign (qualify_identifier im name, ty, Typecast (value, ty)), rest))

(* The region the row is lent under: the one argument of the row type, as
   `User[R]' names it; a row type without arguments gets a fresh one. *)
let row_region (span: span) (ty: Cst.typespec): identifier =
  match ty with
  | Cst.TypeSpecifier (_, []) -> fresh_ident ()
  | Cst.TypeSpecifier (_, [Cst.TypeSpecifier (r, [])]) -> r
  | _ ->
     adorn_error_with_span span
       (fun () -> err (H 8113) "@query: the row type is a record, written `Name' or `Name[R]' with R the region the row's text is lent under")

let row_record (span: span) (ty: Cst.typespec): identifier =
  match ty with
  | Cst.TypeSpecifier (name, _) -> name
  | _ -> adorn_error_with_span span (fun () -> internal_err "@query: the row type is a record")

let expand_query (im: import_map) (span: span) (target: target) (raw: string) (args: aexpr list)
      (row: identifier) (row_ty: Cst.typespec) (body: astmt) (error: identifier) (handler: astmt): astmt =
  let construct = "@query" in
  let lib = require_import im span construct in
  let (esc, checked, typed) = checked_query span construct raw args in
  let columns =
    match checked.rows with
    | Some cols -> cols
    | None -> adorn_error_with_span span (fun () -> err (H 8115) "@query: this statement returns no rows: write it with @execute, or add RETURNING")
  in
  let region = row_region span row_ty in
  let record = row_record span row_ty in
  let db = target_expr im target in
  let start = call (sq lib (if checked.writes then "startWrite" else "start")) [db; StringConstant esc; values_of lib im typed args] in
  let cursor = fresh_ident () and lent = fresh_ident () in
  let cursor_q = qualify_identifier im cursor and lent_q = qualify_identifier im lent in
  let cursor_ty = QTypeSpecifier (sq lib "Cursor", []) in
  let values = List.mapi (fun k (name, t, n, _) -> (k, name, t, n, fresh_ident ())) columns in
  let row_ty_q = qualify_typespec im row_ty in
  let construct_row =
    FunctionCall (qualify_identifier im record,
                  Named (List.map (fun (_, name, _, _, id) -> (make_ident name, Variable (qualify_identifier im id))) values))
  in
  let per_row =
    List.fold_right
      (fun (k, _, t, n, id) acc ->
        let_in span im Common.Immutable id (qualify_typespec im (hilde_type region t n))
          (call (reader lib t n) [Variable lent_q; IntConstant (string_of_int k)]) acc)
      values
      (let_in span im Common.Immutable row row_ty_q construct_row body)
  in
  let lend = ABorrow { span; original = cursor; rename = lent; region; body = per_row; mode = Common.Read } in
  let loop = AWhile (span, call (sq lib "advance") [BorrowExpr (Common.WriteBorrow, cursor_q)], lend) in
  let error_ty = QTypeSpecifier (sq lib "SqlError", []) in
  let ending =
    ACase (span, call (sq lib "finish") [db; Variable cursor_q],
           [AbstractWhen (make_ident "Some", [QBinding { name = make_ident "value"; ty = error_ty; rename = error }], handler);
            AbstractWhen (make_ident "None", [], ASkip span)])
  in
  let_in span im Common.Mutable cursor cursor_ty start (ABlock (span, loop, ending))

let expand_execute (im: import_map) (span: span) (target: target) (raw: string) (args: aexpr list): aexpr =
  let construct = "@execute" in
  let lib = require_import im span construct in
  let (esc, checked, typed) = checked_query span construct raw args in
  (match checked.rows with
   | Some _ -> adorn_error_with_span span (fun () -> err (H 8116) "@execute: this statement returns rows: write it with @query ... for")
   | None -> ());
  call (sq lib "execute") [target_expr im target; StringConstant esc; values_of lib im typed args]

let expand_migrations (im: import_map) (span: span): aexpr =
  let construct = "@migrations" in
  let _ = require_import im span construct in
  let m = the_migrations span construct in
  StringConstant (escaped_of_raw m.constant)
