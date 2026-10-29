(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* `@template("page.jinja", data, out);'.

   The template is read and parsed here, in the abstraction pass, and turned
   into ordinary statements: text is written as it stands, a `{{ value }}'
   is a call of Standard.Template.display on a reference into `data',
   escaped for the place in the HTML where it lands, an `{% if %}' is an
   `if', a `{% for %}' a `while' over a Buffer.  Nothing of the template
   survives to run time; what the type checker then sees is Hilde, so a name
   the data record does not have, a value that cannot be printed and an
   Option printed without asking are type errors -- reported at the
   template's line, because every generated statement carries a span into
   the template file.

   The syntax is Jinja2's, written from its published documentation; Jinja2's
   sources were not read.  What is not accepted is refused with a message.

   Three parts, in the order they run:
     1. a lexer that splits the source into text, `{{ }}' and `{% %}'
        (comments dropped, `-' whitespace control applied, `raw' kept);
     2. a parser into a tree of nodes and expressions;
     3. a generator that walks the tree, follows the HTML context of the
        text around each value, and emits Ast statements. *)

open Identifier
open Span
open Error
open Common
open Escape
open Imports
open Qualifier
open ModuleNameSet
module Ast = Stages.Ast
open Ast

(* ---------------------------------------------------------------------- *)
(* Positions and errors                                                    *)
(* ---------------------------------------------------------------------- *)

type pos = { file: string; line: int; col: int }

let span_at (p: pos): span =
  Span {
      filename = p.file;
      startp = Position { line = p.line; column = p.col };
      endp = Position { line = p.line; column = p.col + 1 };
    }

let fail (code: error_code) (p: pos) (message: string): 'a =
  adorn_error_with_span (span_at p) (fun () -> err code ("@template: " ^ message))

(* ---------------------------------------------------------------------- *)
(* Files                                                                   *)
(* ---------------------------------------------------------------------- *)

(* The same rule as `@bytes': relative to the module's directory,
   never absolute, never through `..'.  Every template name -- the one the
   statement gives, and the ones `extends' and `include' give -- is resolved
   against the MODULE's directory, the way Jinja2's file system loader
   resolves every name against its one root. *)
let resolve (p: pos) (root: string) (name: string): string =
  if name = "" then
    fail (H 7001) p "the template name is empty"
  else if not (Filename.is_relative name) then
    fail (H 7002) p ("\"" ^ name ^ "\": the path is absolute, and a template may only be read from beside the module")
  else if List.exists (fun (part: string) -> part = "..") (String.split_on_char '/' name) then
    fail (H 7003) p ("\"" ^ name ^ "\": the path leaves the module's own directory, which is not allowed")
  else
    Filename.concat root name

let read_template (p: pos) (full: string) (name: string): string =
  try
    let stream = open_in_bin full in
    let size: int = in_channel_length stream in
    let contents: string = really_input_string stream size in
    close_in stream;
    contents
  with Sys_error message ->
    fail (H 7004) p ("\"" ^ name ^ "\": cannot read it: " ^ message)

(* ---------------------------------------------------------------------- *)
(* 1. The lexer                                                            *)
(* ---------------------------------------------------------------------- *)

type chunk =
  | CText of string * pos
  | CVar of string * pos
  | CBlock of string * pos

let is_space (c: char): bool =
  c = ' ' || c = '\t' || c = '\n' || c = '\r' || c = '\011' || c = '\012'

let rstrip (s: string): string =
  let n = ref (String.length s) in
  while !n > 0 && is_space s.[!n - 1] do decr n done;
  String.sub s 0 !n

let lstrip (s: string): string =
  let n = String.length s in
  let i = ref 0 in
  while !i < n && is_space s.[!i] do incr i done;
  String.sub s !i (n - !i)

let starts_at (s: string) (i: int) (w: string): bool =
  let n = String.length w in
  i + n <= String.length s && String.sub s i n = w

(* Split the source.  Jinja2 drops ONE newline at the end of a template
   (its keep_trailing_newline is off by default), so this does too. *)
let lex (trim_blocks: bool) (lstrip_blocks: bool) (file: string) (source: string): chunk list =
  let source =
    let n = String.length source in
    if n > 0 && source.[n - 1] = '\n' then String.sub source 0 (n - 1) else source
  in
  let n = String.length source in
  (* Line and column of an offset. *)
  let line_starts: int list ref = ref [0] in
  String.iteri (fun i c -> if c = '\n' then line_starts := (i + 1) :: !line_starts) source;
  let starts = Array.of_list (List.rev !line_starts) in
  let pos_of (off: int): pos =
    let line = ref 0 in
    Array.iteri (fun k s -> if s <= off then line := k) starts;
    { file; line = !line + 1; col = off - starts.(!line) }
  in
  let chunks: chunk list ref = ref [] in
  (* Set by a `-' before a closing delimiter: the next text loses its
     leading white space. *)
  let strip_next = ref false in
  let add_text (s: string) (off: int) =
    let s = if !strip_next then lstrip s else s in
    strip_next := false;
    if s <> "" then chunks := CText (s, pos_of off) :: !chunks
  in
  (* A `-' after an opening delimiter: the text before loses its trailing
     white space. *)
  let strip_previous () =
    match !chunks with
    | CText (s, p) :: rest ->
       let s' = rstrip s in
       chunks := (if s' = "" then rest else CText (s', p) :: rest)
    | _ -> ()
  in
  (* lstrip_blocks: the text before a block tag loses the spaces and tabs
     after its last newline, when nothing else stands there. *)
  let strip_line_start () =
    match !chunks with
    | CText (s, p) :: rest ->
       let k = ref (String.length s) in
       while !k > 0 && (s.[!k - 1] = ' ' || s.[!k - 1] = '\t') do decr k done;
       if (!k = 0 && p.col = 0) || (!k > 0 && s.[!k - 1] = '\n') then begin
           let s' = String.sub s 0 !k in
           chunks := (if s' = "" then rest else CText (s', p) :: rest)
         end
    | _ -> ()
  in
  (* Find the closing delimiter of a tag that starts at `from', skipping
     string literals.  Answers the offset of the closer. *)
  let find_close (from: int) (closer: string) (opened: pos): int =
    let i = ref from in
    let found = ref (-1) in
    while !found < 0 do
      if !i >= n then fail (H 7005) opened ("this tag is never closed with " ^ closer)
      else if source.[!i] = '\'' || source.[!i] = '"' then begin
          let q = source.[!i] in
          incr i;
          while !i < n && source.[!i] <> q do
            if source.[!i] = '\\' then incr i;
            incr i
          done;
          incr i
        end
      else if starts_at source !i closer then found := !i
      else incr i
    done;
    !found
  in
  let i = ref 0 in
  let text_start = ref 0 in
  while !i < n do
    if starts_at source !i "{{" || starts_at source !i "{%" || starts_at source !i "{#" then begin
        let kind = source.[!i + 1] in
        let tag_off = !i in
        add_text (String.sub source !text_start (tag_off - !text_start)) !text_start;
        let opened = pos_of tag_off in
        let body_start = ref (tag_off + 2) in
        if !body_start < n && source.[!body_start] = '-' then begin
            strip_previous ();
            incr body_start
          end
        else if !body_start < n && source.[!body_start] = '+' then
          incr body_start
        else if lstrip_blocks && kind <> '{' then
          strip_line_start ();
        let closer = (match kind with '{' -> "}}" | '%' -> "%}" | _ -> "#}") in
        let close =
          if kind = '#' then
            (* A comment holds no strings to skip. *)
            (let j = ref !body_start in
             while !j < n && not (starts_at source !j "#}") do incr j done;
             if !j >= n then fail (H 7006) opened "this comment is never closed with #}";
             !j)
          else
            find_close !body_start closer opened
        in
        let body_end, strip_after, keep_newline =
          if close > !body_start && source.[close - 1] = '-' then (close - 1, true, false)
          else if close > !body_start && source.[close - 1] = '+' then (close - 1, false, true)
          else (close, false, false)
        in
        let body = String.sub source !body_start (body_end - !body_start) in
        i := close + 2;
        if trim_blocks && kind <> '{' && not keep_newline && not strip_after then begin
            if !i < n && source.[!i] = '\n' then incr i
            else if !i + 1 < n && source.[!i] = '\r' && source.[!i + 1] = '\n' then i := !i + 2
          end;
        text_start := !i;
        strip_next := strip_after;
        (match kind with
         | '{' -> chunks := CVar (body, opened) :: !chunks
         | '%' ->
            if String.trim body = "raw" then begin
                (* Everything up to `{% endraw %}' is text, as it stands. *)
                let j = ref !i in
                let found = ref (-1) in
                let end_open = ref 0 in
                while !found < 0 do
                  if !j >= n then fail (H 7007) opened "this {% raw %} is never closed with {% endraw %}"
                  else if starts_at source !j "{%" then begin
                      let k = ref (!j + 2) in
                      let lstrip_raw = !k < n && source.[!k] = '-' in
                      if lstrip_raw then incr k;
                      while !k < n && is_space source.[!k] do incr k done;
                      if starts_at source !k "endraw" then begin
                          found := !j;
                          end_open := (if lstrip_raw then 1 else 0);
                          let m = ref (!k + 6) in
                          while !m < n && is_space source.[!m] do incr m done;
                          let strip_after_raw = !m < n && source.[!m] = '-' in
                          if strip_after_raw then incr m;
                          if not (starts_at source !m "%}") then fail (H 7008) opened "{% endraw %} is not closed with %}";
                          let raw = String.sub source !i (!j - !i) in
                          let raw = if !strip_next then lstrip raw else raw in
                          let raw = if !end_open = 1 then rstrip raw else raw in
                          (* lstrip_blocks before {% endraw %}: the spaces and
                             tabs after the last newline of the raw text. *)
                          let raw =
                            if lstrip_blocks && !end_open = 0 && not (!j + 2 < n && source.[!j + 2] = '+') then begin
                                let e = ref (String.length raw) in
                                while !e > 0 && (raw.[!e - 1] = ' ' || raw.[!e - 1] = '\t') do decr e done;
                                if !e > 0 && raw.[!e - 1] = '\n' then String.sub raw 0 !e else raw
                              end
                            else raw
                          in
                          if raw <> "" then chunks := CText (raw, pos_of !i) :: !chunks;
                          strip_next := strip_after_raw;
                          i := !m + 2;
                          if trim_blocks && not strip_after_raw then begin
                              if !i < n && source.[!i] = '\n' then incr i
                              else if !i + 1 < n && source.[!i] = '\r' && source.[!i + 1] = '\n' then i := !i + 2
                            end;
                          text_start := !i
                        end
                      else j := !j + 2
                    end
                  else incr j
                done
              end
            else
              chunks := CBlock (body, opened) :: !chunks
         | _ -> ())
      end
    else
      incr i
  done;
  add_text (String.sub source !text_start (n - !text_start)) !text_start;
  List.rev !chunks

(* ---------------------------------------------------------------------- *)
(* 2. The parser                                                           *)
(* ---------------------------------------------------------------------- *)

type expr =
  | EPath of string list * pos
  | EStr of string * pos
  | EInt of string * pos
  | EBool of bool * pos
  | ENone of pos
  | EFilter of expr * string * expr list * pos
  | ENot of expr * pos
  | EAnd of expr * expr * pos
  | EOr of expr * expr * pos
  | ECmp of comparison_operator * expr * expr * pos
  | ETest of expr * bool * string * pos
  | ECall of string * expr list * pos
  (* `a ~ b' *)
  | EConcat of expr * expr * pos
  (* `a + b', `a - b', `a * b', `a // b', `a % b', by the operator's text *)
  | EArith of string * expr * expr * pos
  (* `a in b', and `a not in b' when the flag is true *)
  | EIn of expr * expr * bool * pos
  (* `a if c else b'; without `else' the value is empty *)
  | ECond of expr * expr * expr option * pos
  (* `_("Key", name=value, ...)': the text of a key of the template's catalog
     in the language of the data, with the named arguments put in *)
  | ETrans of string * (string * expr) list * pos

type node =
  | NText of string * pos
  | NOut of expr * pos
  | NIf of (expr * node list * pos) list * node list
  (* The names (one, or two or three unpacking a Pair or a Triple), the
     sequence, the condition after it, the body and the `else'. *)
  | NFor of string list * expr * expr option * node list * node list * pos
  | NSet of string * expr * pos
  | NSetBlock of string * node list * pos
  | NWith of (string * expr) list * node list * pos
  | NFilterBlock of (string * expr list) list * node list * pos
  | NCallBlock of string * expr list * node list * pos
  | NImportAs of string * string * pos
  | NBlock of string * node list * bool * pos
  | NExtends of string * pos
  | NInclude of string * pos
  | NMacro of string * (string * expr option) list * node list * pos
  | NFromImport of string * string list * pos
  (* A block after inheritance is resolved: its body, and whether it is
     `scoped' -- whether it sees the loop variables around it. *)
  | NScope of node list * bool
  (* An included template's tree: it sees the loop variables around it, and
     not `loop' (Jinja2 3.1.6, measured). *)
  | NIncluded of node list
  (* `{% catalog name %}': the function of no arguments that gives the
     catalog the translations of the template come from *)
  | NCatalog of string * pos

let expr_pos (e: expr): pos =
  match e with
  | EPath (_, p) | EStr (_, p) | EInt (_, p) | EBool (_, p) | ENone p
  | EFilter (_, _, _, p) | ENot (_, p) | EAnd (_, _, p) | EOr (_, _, p)
  | ECmp (_, _, _, p) | ETest (_, _, _, p) | ECall (_, _, p)
  | EConcat (_, _, p) | EArith (_, _, _, p) | EIn (_, _, _, p) | ECond (_, _, _, p)
  | ETrans (_, _, p) -> p

type tok =
  | TName of string
  | TString of string
  | TInt of string
  | TOp of string

let is_name_start (c: char): bool =
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_'

let is_name_char (c: char): bool =
  is_name_start c || (c >= '0' && c <= '9')

(* The tokens of what stands between the delimiters. *)
let tokenize (p: pos) (s: string): tok list =
  let n = String.length s in
  let out = ref [] in
  let i = ref 0 in
  while !i < n do
    let c = s.[!i] in
    if is_space c then incr i
    else if is_name_start c then begin
        let j = ref !i in
        while !j < n && is_name_char s.[!j] do incr j done;
        out := TName (String.sub s !i (!j - !i)) :: !out;
        i := !j
      end
    else if c >= '0' && c <= '9' then begin
        let j = ref !i in
        while !j < n && s.[!j] >= '0' && s.[!j] <= '9' do incr j done;
        if !j < n && (s.[!j] = '.' || s.[!j] = '_' || is_name_start s.[!j]) then
          fail (H 7009) p "only whole decimal numbers are supported";
        out := TInt (String.sub s !i (!j - !i)) :: !out;
        i := !j
      end
    else if c = '\'' || c = '"' then begin
        let buf = Buffer.create 16 in
        let j = ref (!i + 1) in
        while !j < n && s.[!j] <> c do
          if s.[!j] = '\\' then begin
              if !j + 1 >= n then internal_err "a string ends in a backslash";
              (match s.[!j + 1] with
               | 'n' -> Buffer.add_char buf '\n'
               | 't' -> Buffer.add_char buf '\t'
               | 'r' -> Buffer.add_char buf '\r'
               | '\\' -> Buffer.add_char buf '\\'
               | '\'' -> Buffer.add_char buf '\''
               | '"' -> Buffer.add_char buf '"'
               | other -> fail (H 7011) p ("the escape \\" ^ String.make 1 other ^ " in a string is not supported"));
              j := !j + 2
            end
          else begin
              Buffer.add_char buf s.[!j];
              incr j
            end
        done;
        if !j >= n then internal_err "a string is never closed";
        out := TString (Buffer.contents buf) :: !out;
        i := !j + 1
      end
    else begin
        let two = if !i + 1 < n then String.sub s !i 2 else "" in
        if List.mem two ["=="; "!="; "<="; ">="; "//"; "**"] then begin
            out := TOp two :: !out;
            i := !i + 2
          end
        else if String.contains ".|(),<>=+-*/~%[]{}:" c then begin
            out := TOp (String.make 1 c) :: !out;
            incr i
          end
        else
          fail (H 7013) p ("the character " ^ String.make 1 c ^ " cannot stand here")
      end
  done;
  List.rev !out

(* A recursive-descent parser over one tag's tokens. *)
type cursor = { mutable toks: tok list; at: pos }

let peek (c: cursor): tok option =
  match c.toks with t :: _ -> Some t | [] -> None

let advance (c: cursor): unit =
  match c.toks with _ :: rest -> c.toks <- rest | [] -> ()

let expect_op (c: cursor) (op: string): unit =
  match peek c with
  | Some (TOp o) when o = op -> advance c
  | _ -> fail (H 7014) c.at ("expected " ^ op)

let expect_name (c: cursor): string =
  match peek c with
  | Some (TName n) -> advance c; n
  | _ -> fail (H 7015) c.at "expected a name"

let unsupported_operator (c: cursor) (rest: string): 'a =
  fail (H 7016) c.at ("the operator " ^ rest)

(* The one place of each code that more than one place raises: the
   registry gives a code one message, and each helper's message begins with
   the same words. *)
let expected_comma_or_close (c: cursor): 'a =
  fail (H 7019) c.at "expected , or )"

let refuse_in (p: pos) (rest: string): 'a =
  fail (H 7018) p ("`in' asks " ^ rest)

let refuse_inline_if (p: pos) (rest: string): 'a =
  fail (H 7017) p ("an inline if " ^ rest)

let refuse_dotted_call (p: pos) (name: string) (rest: string): 'a =
  fail (H 7022) p ("calling " ^ name ^ rest)

let refuse_import (p: pos) (rest: string): 'a =
  fail (H 7032) p ("{% import %} takes " ^ rest)

let imports_itself (p: pos) (file: string): 'a =
  fail (H 7055) p ("\"" ^ file ^ "\" imports from itself")

let dropped_after_extends (p: pos) (what: string): 'a =
  fail (H 7061) p (what ^ " after {% extends %} and outside a block is dropped by Jinja2; here it is refused")

let without_end (p: pos) (tag: string) (closer: string): 'a =
  fail (H 7100) p ("{% " ^ tag ^ " %} without {% " ^ closer ^ " %}")

let tag_form (p: pos) (tag: string) (rule: string): 'a =
  fail (H 7101) p ("{% " ^ tag ^ " %} takes " ^ rule)

let refuse_import_name (p: pos) (name: string) (rest: string): 'a =
  fail (H 7102) p ("the name " ^ name ^ rest)

let bad_divisor (p: pos) (op: string) (rest: string): 'a =
  fail (H 7105) p (op ^ " divides " ^ rest)

let bad_arguments (p: pos) (what: string) (rule: string): 'a =
  fail (H 7108) p (what ^ " takes " ^ rule)

let set_in_branch (p: pos) (name: string): 'a =
  fail (H 7110) p ("{% set " ^ name ^ " %} inside an {% if %} is refused: in Jinja2 the name is still there after the {% endif %} when the branch ran, and missing when it did not, which a compiled template cannot follow; set it before the {% if %}, or use {% with %}")

let block_place (p: pos) (rest: string): 'a =
  fail (H 7111) p ("a {% set %} or {% filter %} block stands in HTML text and ends there; this one " ^ rest)

let refuse_caller (p: pos) (rest: string): 'a =
  fail (H 7112) p ("caller() " ^ rest)

(* The levels, loosest first, as Jinja2 documents them: the inline if, or,
   and, not, the comparisons with `in' and `is', ~, + and -, *, // and %,
   the minus sign of a number, the filters, and what a filter applies to. *)
let rec parse_expr (c: cursor): expr =
  let e = parse_or c in
  match peek c with
  | Some (TName "if") ->
     advance c;
     let cond = parse_or c in
     let otherwise =
       if peek c = Some (TName "else") then (advance c; Some (parse_expr c)) else None
     in
     ECond (e, cond, otherwise, c.at)
  | _ -> e

and parse_or (c: cursor): expr =
  let left = ref (parse_and c) in
  while peek c = Some (TName "or") do
    advance c;
    left := EOr (!left, parse_and c, c.at)
  done;
  !left

and parse_and (c: cursor): expr =
  let left = ref (parse_not c) in
  while peek c = Some (TName "and") do
    advance c;
    left := EAnd (!left, parse_not c, c.at)
  done;
  !left

and parse_not (c: cursor): expr =
  if peek c = Some (TName "not") then begin
      advance c;
      ENot (parse_not c, c.at)
    end
  else
    parse_compare c

and parse_compare (c: cursor): expr =
  let left = parse_concat c in
  let op_of = function
    | "==" -> Some Equal | "!=" -> Some NotEqual
    | "<" -> Some LessThan | "<=" -> Some LessThanOrEqual
    | ">" -> Some GreaterThan | ">=" -> Some GreaterThanOrEqual
    | _ -> None
  in
  match c.toks with
  | TOp o :: _ when op_of o <> None ->
     advance c;
     let right = parse_concat c in
     (match op_of o with Some op -> ECmp (op, left, right, c.at) | None -> left)
  | TName "is" :: _ ->
     advance c;
     let negated = (peek c = Some (TName "not")) in
     if negated then advance c;
     let test = expect_name c in
     ETest (left, negated, test, c.at)
  | TName "in" :: _ ->
     advance c;
     EIn (left, parse_concat c, false, c.at)
  | TName "not" :: TName "in" :: _ ->
     advance c;
     advance c;
     EIn (left, parse_concat c, true, c.at)
  | _ -> left

and parse_concat (c: cursor): expr =
  let left = ref (parse_additive c) in
  while peek c = Some (TOp "~") do
    advance c;
    left := EConcat (!left, parse_additive c, c.at)
  done;
  !left

and parse_additive (c: cursor): expr =
  let left = ref (parse_multiplicative c) in
  let continue_ = ref true in
  while !continue_ do
    match peek c with
    | Some (TOp ("+" | "-" as o)) ->
       advance c;
       left := EArith (o, !left, parse_multiplicative c, c.at)
    | _ -> continue_ := false
  done;
  !left

and parse_multiplicative (c: cursor): expr =
  let left = ref (parse_unary c) in
  let continue_ = ref true in
  while !continue_ do
    match peek c with
    | Some (TOp ("*" | "//" | "%" as o)) ->
       advance c;
       left := EArith (o, !left, parse_unary c, c.at)
    | Some (TOp "/") ->
       unsupported_operator c "/ divides into a fraction, and @template has no fractions; // divides into a whole number"
    | _ -> continue_ := false
  done;
  !left

and parse_unary (c: cursor): expr =
  let e =
    match c.toks with
    | TOp "-" :: TInt i :: _ ->
       advance c;
       advance c;
       EInt ("-" ^ i, c.at)
    | TOp "-" :: _ ->
       fail (H 7024) c.at "a minus sign stands before a number only; write 0 - x to subtract from zero"
    | _ -> parse_filtered c
  in
  if peek c = Some (TOp "**") then
    unsupported_operator c "** is not supported: a power leaves every integer type after a few steps";
  e

and parse_filtered (c: cursor): expr =
  let e = ref (parse_primary c) in
  while peek c = Some (TOp "|") do
    advance c;
    let name = expect_name c in
    let args =
      if peek c = Some (TOp "(") then begin
          advance c;
          let args = ref [] in
          while peek c <> Some (TOp ")") do
            args := parse_expr c :: !args;
            if peek c = Some (TOp ",") then advance c
            else if peek c <> Some (TOp ")") then expected_comma_or_close c
          done;
          advance c;
          List.rev !args
        end
      else []
    in
    e := EFilter (!e, name, args, c.at)
  done;
  !e

and parse_primary (c: cursor): expr =
  match peek c with
  | Some (TString s) -> advance c; EStr (s, c.at)
  | Some (TInt i) -> advance c; EInt (i, c.at)
  | Some (TName ("true" | "True")) -> advance c; EBool (true, c.at)
  | Some (TName ("false" | "False")) -> advance c; EBool (false, c.at)
  | Some (TName ("none" | "None")) -> advance c; ENone c.at
  | Some (TName first) ->
     advance c;
     let path = ref [first] in
     let continue_ = ref true in
     while !continue_ do
       match c.toks with
       | TOp "." :: _ ->
          advance c;
          path := expect_name c :: !path
       | TOp "[" :: TString key :: TOp "]" :: _ ->
          advance c;
          advance c;
          advance c;
          path := key :: !path
       | TOp "[" :: _ ->
          fail (H 7023) c.at "[ ] takes a name in quotes, as in a[\"b\"]: an index into a list fails when the page is rendered if the list is shorter, which a compiled template cannot allow"
       | _ -> continue_ := false
     done;
     (match peek c with
      | Some (TOp "(") ->
         (match !path with
          | ["_"] ->
             (* `_("Key", name=value, ...)': the one call that takes named
                arguments, as jinja2.ext.i18n's does. *)
             advance c;
             let key =
               (match c.toks with
                | TString k :: _ -> advance c; k
                | _ -> fail (H 7115) c.at "_( ) takes the key first, as a string literal, as in _(\"Greeting\")")
             in
             let args = ref [] in
             while peek c = Some (TOp ",") do
               advance c;
               (match c.toks with
                | TName n :: TOp "=" :: _ ->
                   advance c;
                   advance c;
                   if List.mem_assoc n !args then fail (H 7116) c.at ("_( ) is given " ^ n ^ " twice");
                   args := (n, parse_expr c) :: !args
                | _ -> fail (H 7125) c.at "after the key, _( ) takes its arguments as name=value")
             done;
             expect_op c ")";
             ETrans (key, List.rev !args, c.at)
          | [_] | [_; _] ->
             advance c;
             let args = ref [] in
             while peek c <> Some (TOp ")") do
               (match c.toks with
                | TName _ :: TOp "=" :: _ -> fail (H 7020) c.at "keyword arguments are not supported"
                | _ -> ());
               args := parse_expr c :: !args;
               if peek c = Some (TOp ",") then advance c
               else if peek c <> Some (TOp ")") then fail (H 7021) c.at "expected , or )"
             done;
             advance c;
             ECall (String.concat "." (List.rev !path), List.rev !args, c.at)
          | _ -> refuse_dotted_call c.at (String.concat "." (List.rev !path)) " is not supported; a macro is called by its name, or by the name an {% import %} gave and its own")
      | _ -> EPath (List.rev !path, c.at))
  | Some (TOp "(") ->
     advance c;
     let e = parse_expr c in
     expect_op c ")";
     e
  | Some (TOp o) -> fail (H 7025) c.at ("unexpected " ^ o)
  | None -> fail (H 7026) c.at "an expression is missing"

let parse_whole (p: pos) (s: string): expr =
  let c = { toks = tokenize p s; at = p } in
  let e = parse_expr c in
  if c.toks <> [] then fail (H 7027) p "unexpected text after the expression";
  e

(* The tree.  A block tag is parsed as a keyword followed by the rest. *)
let block_keyword (p: pos) (body: string): string * string =
  let body = String.trim body in
  let n = String.length body in
  let i = ref 0 in
  while !i < n && is_name_char body.[!i] do incr i done;
  if !i = 0 then fail (H 7028) p "a {% %} tag must begin with a keyword";
  (String.sub body 0 !i, String.trim (String.sub body !i (n - !i)))

let not_supported_yet (p: pos) (keyword: string): 'a =
  fail (H 7029) p ("{% " ^ keyword ^ " %} is not supported")

(* The one string literal a tag takes: `extends "x"', `include "x"'.  A name
   in its place would be a template chosen at run time, which cannot be
   compiled. *)
let only_string (p: pos) (keyword: string) (arg: string): string =
  match tokenize p arg with
  | [TString s] -> s
  | TString _ :: _ -> fail (H 7030) p ("{% " ^ keyword ^ " %} takes the template's name and nothing after it")
  | _ -> fail (H 7031) p ("{% " ^ keyword ^ " %} takes a string literal: a template chosen when the page is rendered cannot be compiled")

(* `catalog name': the name of the function that gives the catalog. *)
let catalog_name (p: pos) (arg: string): string =
  match tokenize p arg with
  | [TName n] -> n
  | _ -> fail (H 7117) p "{% catalog %} takes the name of a function of no arguments that gives the catalog, as in {% catalog messages %}"

(* The key a {% trans %} block's text names: one name, white space around
   it allowed. *)
let trans_key (p: pos) (body: node list): string =
  let text = String.concat "" (List.map (function NText (s, _) -> s | _ -> "\001") body) in
  let key = String.trim text in
  let n = String.length key in
  let is_key = n > 0 && is_name_start key.[0] && key.[0] <> '_' && String.for_all is_name_char key in
  if not is_key then
    fail (H 7118) p "the text of a {% trans %} block is its key, one name such as Greeting; the texts of the languages stand in the catalog";
  key

(* Parse chunks up to one of `stop' keywords; answer the nodes, the keyword
   that stopped it (or "" at the end) with its argument and position. *)
let rec parse_nodes (chunks: chunk list ref) (stop: string list): node list * string * string * pos =
  let out = ref [] in
  let result = ref None in
  while !result = None do
    match !chunks with
    | [] ->
       result := Some ("", "", { file = ""; line = 0; col = 0 })
    | CText (s, p) :: rest ->
       chunks := rest;
       out := NText (s, p) :: !out
    | CVar (body, p) :: rest ->
       chunks := rest;
       out := NOut (parse_whole p body, p) :: !out
    | CBlock (body, p) :: rest ->
       chunks := rest;
       let (kw, arg) = block_keyword p body in
       if List.mem kw stop then
         result := Some (kw, arg, p)
       else
         (match kw with
          | "if" -> out := parse_if chunks (parse_whole p arg) p :: !out
          | "for" -> out := parse_for chunks arg p :: !out
          | "block" -> out := parse_block chunks arg p :: !out
          | "macro" -> out := parse_macro chunks arg p :: !out
          | "extends" -> out := NExtends (only_string p "extends" arg, p) :: !out
          | "include" -> out := NInclude (only_string p "include" arg, p) :: !out
          | "from" -> out := parse_from arg p :: !out
          | "import" -> out := parse_import arg p :: !out
          | "set" -> out := parse_set chunks arg p :: !out
          | "with" -> out := parse_with chunks arg p :: !out
          | "filter" -> out := parse_filter_block chunks arg p :: !out
          | "call" -> out := parse_call chunks arg p :: !out
          | "catalog" -> out := NCatalog (catalog_name p arg, p) :: !out
          | "trans" -> out := parse_trans chunks arg p :: !out
          | "autoescape" ->
             fail (H 7033) p "{% autoescape %} is refused: escaping cannot be switched off for a stretch of template -- write |safe on the one value that is meant to go out unescaped, where a grep finds it"
          | "elif" | "else" | "endif" | "endfor" | "endblock" | "endmacro"
          | "endset" | "endwith" | "endfilter" | "endcall" | "pluralize" | "endtrans" ->
             fail (H 7034) p ("{% " ^ kw ^ " %} without the tag it belongs to")
          | other -> not_supported_yet p other)
  done;
  match !result with
  | Some (kw, arg, p) -> (List.rev !out, kw, arg, p)
  | None -> (List.rev !out, "", "", { file = ""; line = 0; col = 0 })

and parse_if (chunks: chunk list ref) (cond: expr) (p: pos): node =
  let branches = ref [] in
  let cond = ref cond and cpos = ref p in
  let else_nodes = ref [] in
  let finished = ref false in
  while not !finished do
    let (nodes, kw, arg, kp) = parse_nodes chunks ["elif"; "else"; "endif"] in
    branches := (!cond, nodes, !cpos) :: !branches;
    (match kw with
     | "elif" -> cond := parse_whole kp arg; cpos := kp
     | "else" ->
        let (nodes, kw2, _, _) = parse_nodes chunks ["endif"] in
        if kw2 <> "endif" then fail (H 7035) kp "{% else %} without {% endif %}";
        else_nodes := nodes;
        finished := true
     | "endif" -> finished := true
     | _ -> fail (H 7036) p "{% if %} without {% endif %}")
  done;
  NIf (List.rev !branches, !else_nodes)

and parse_for (chunks: chunk list ref) (arg: string) (p: pos): node =
  let c = { toks = tokenize p arg; at = p } in
  let vars = ref [expect_name c] in
  while peek c = Some (TOp ",") do
    advance c;
    vars := expect_name c :: !vars
  done;
  let vars = List.rev !vars in
  if List.length vars > 3 then
    fail (H 7037) p "{% for %} takes one name, or two or three that unpack a Pair or a Triple of Standard.Tuples";
  (match peek c with
   | Some (TName "in") -> advance c
   | _ -> fail (H 7038) p "expected `in' in {% for %}");
  (* The sequence stops before `if': an inline if cannot stand here. *)
  let seq = parse_or c in
  let cond =
    if peek c = Some (TName "if") then (advance c; Some (parse_or c)) else None
  in
  if c.toks <> [] then fail (H 7039) p "after {% for ... in ... %} only `if' and a condition may follow";
  let (body, kw, _, kp) = parse_nodes chunks ["else"; "endfor"] in
  match kw with
  | "endfor" -> NFor (vars, seq, cond, body, [], p)
  | "else" ->
     let (empty, kw2, _, _) = parse_nodes chunks ["endfor"] in
     if kw2 <> "endfor" then fail (H 7040) kp "{% else %} without {% endfor %}";
     NFor (vars, seq, cond, body, empty, p)
  | _ -> fail (H 7041) p "{% for %} without {% endfor %}"

(* `set x = value', or `set x' and the text up to `endset'. *)
and parse_set (chunks: chunk list ref) (arg: string) (p: pos): node =
  let c = { toks = tokenize p arg; at = p } in
  let name = expect_name c in
  match c.toks with
  | [] ->
     let (body, kw, _, _) = parse_nodes chunks ["endset"] in
     if kw <> "endset" then without_end p ("set " ^ name) "endset";
     NSetBlock (name, body, p)
  | TOp "=" :: _ ->
     advance c;
     let e = parse_expr c in
     if c.toks <> [] then tag_form p "set" "one name, = and one value";
     NSet (name, e, p)
  | _ -> tag_form p "set" "one name, = and one value"

(* `with a = value, b = value' and the text up to `endwith'. *)
and parse_with (chunks: chunk list ref) (arg: string) (p: pos): node =
  let c = { toks = tokenize p arg; at = p } in
  let binds = ref [] in
  while c.toks <> [] do
    let name = expect_name c in
    expect_op c "=";
    binds := (name, parse_expr c) :: !binds;
    if peek c = Some (TOp ",") then advance c
    else if c.toks <> [] then tag_form p "with" "names, each with = and a value, separated by commas"
  done;
  let (body, kw, _, _) = parse_nodes chunks ["endwith"] in
  if kw <> "endwith" then without_end p "with" "endwith";
  NWith (List.rev !binds, body, p)

(* `trans a = value, b = value', the key up to `pluralize' or `endtrans',
   and after `pluralize' nothing up to `endtrans'.  It stands for the
   same _(...) with the key and the arguments. *)
and parse_trans (chunks: chunk list ref) (arg: string) (p: pos): node =
  let c = { toks = tokenize p arg; at = p } in
  let args = ref [] in
  while c.toks <> [] do
    let name = expect_name c in
    expect_op c "=";
    if List.mem_assoc name !args then fail (H 7126) p ("{% trans %} is given " ^ name ^ " twice");
    args := (name, parse_expr c) :: !args;
    if peek c = Some (TOp ",") then advance c
    else if c.toks <> [] then tag_form p "trans" "names, each with = and a value, separated by commas"
  done;
  let (body, kw, _, kp) = parse_nodes chunks ["pluralize"; "endtrans"] in
  let key = trans_key p body in
  (match kw with
   | "endtrans" -> ()
   | "pluralize" ->
      if not (List.mem_assoc "count" !args) then
        fail (H 7119) kp "{% pluralize %} needs count=... in its {% trans %}: the count chooses the form";
      let (rest, kw2, _, _) = parse_nodes chunks ["endtrans"] in
      if kw2 <> "endtrans" then without_end p "trans" "endtrans";
      if not (List.for_all (function NText (s, _) -> String.trim s = "" | _ -> false) rest) then
        fail (H 7120) kp "between {% pluralize %} and {% endtrans %} nothing may stand: the plural forms are in the catalog"
   | _ -> without_end p "trans" "endtrans");
  NOut (ETrans (key, List.rev !args, p), p)

(* `filter f(args)|g' and the text up to `endfilter'. *)
and parse_filter_block (chunks: chunk list ref) (arg: string) (p: pos): node =
  let c = { toks = tokenize p arg; at = p } in
  let filters = ref [] in
  let continue_ = ref true in
  while !continue_ do
    let name = expect_name c in
    let args =
      if peek c = Some (TOp "(") then begin
          advance c;
          let args = ref [] in
          while peek c <> Some (TOp ")") do
            args := parse_expr c :: !args;
            if peek c = Some (TOp ",") then advance c
            else if peek c <> Some (TOp ")") then expected_comma_or_close c
          done;
          advance c;
          List.rev !args
        end
      else []
    in
    filters := (name, args) :: !filters;
    if peek c = Some (TOp "|") then advance c else continue_ := false
  done;
  if c.toks <> [] then tag_form p "filter" "filters separated by |, and nothing else";
  let (body, kw, _, _) = parse_nodes chunks ["endfilter"] in
  if kw <> "endfilter" then without_end p "filter" "endfilter";
  NFilterBlock (List.rev !filters, body, p)

(* `call m(args)' and the text up to `endcall': the body is what caller()
   stands for in the macro. *)
and parse_call (chunks: chunk list ref) (arg: string) (p: pos): node =
  let c = { toks = tokenize p arg; at = p } in
  if peek c = Some (TOp "(") then
    tag_form p "call" "one macro call, and caller() takes no parameters: {% call(x) m() %} is not supported";
  let e = parse_expr c in
  if c.toks <> [] then tag_form p "call" "one macro call";
  let (body, kw, _, _) = parse_nodes chunks ["endcall"] in
  if kw <> "endcall" then without_end p "call" "endcall";
  match e with
  | ECall (name, args, _) -> NCallBlock (name, args, body, p)
  | _ -> tag_form p "call" "one macro call"

(* `import "file" as name' *)
and parse_import (arg: string) (p: pos): node =
  match tokenize p arg with
  | [TString file; TName "as"; TName name] -> NImportAs (file, name, p)
  | [TString _; TName "as"; TName _; TName ("with" | "without"); TName "context"] ->
     refuse_import p "no `with context': an imported macro does not see the template's data, as in Jinja2 without it"
  | _ -> refuse_import p "a string literal, `as' and a name: {% import \"file\" as name %}"

and parse_block (chunks: chunk list ref) (arg: string) (p: pos): node =
  let (name, scoped) =
    match tokenize p arg with
    | [TName n] -> (n, false)
    | [TName n; TName "scoped"] -> (n, true)
    | TName _ :: TName "required" :: _ | TName _ :: TName "scoped" :: TName "required" :: _ ->
       fail (H 7042) p "a `required' block is not supported"
    | _ -> fail (H 7043) p "{% block %} takes a name, and `scoped' after it"
  in
  let (body, kw, endarg, kp) = parse_nodes chunks ["endblock"] in
  if kw <> "endblock" then fail (H 7044) p ("{% block " ^ name ^ " %} without {% endblock %}");
  if endarg <> "" && endarg <> name then
    fail (H 7045) kp ("{% endblock " ^ endarg ^ " %} closes {% block " ^ name ^ " %}");
  NBlock (name, body, scoped, p)

and parse_macro (chunks: chunk list ref) (arg: string) (p: pos): node =
  let c = { toks = tokenize p arg; at = p } in
  let name = expect_name c in
  expect_op c "(";
  let params = ref [] in
  while peek c <> Some (TOp ")") do
    let param = expect_name c in
    let default =
      if peek c = Some (TOp "=") then begin
          advance c;
          match parse_primary c with
          | (EStr _ | EInt _ | EBool _) as lit -> Some lit
          | _ -> fail (H 7046) p "a macro parameter's default is a literal"
        end
      else None
    in
    params := (param, default) :: !params;
    if peek c = Some (TOp ",") then advance c
    else if peek c <> Some (TOp ")") then fail (H 7047) p "expected , or ) in the macro's parameters"
  done;
  advance c;
  if c.toks <> [] then fail (H 7048) p "unexpected text after the macro's parameters";
  let (body, kw, _, _) = parse_nodes chunks ["endmacro"] in
  if kw <> "endmacro" then fail (H 7049) p ("{% macro " ^ name ^ " %} without {% endmacro %}");
  NMacro (name, List.rev !params, body, p)

and parse_from (arg: string) (p: pos): node =
  match tokenize p arg with
  | TString file :: TName "import" :: rest ->
     let rec names = function
       | [TName n] -> [n]
       | TName n :: TOp "," :: more -> n :: names more
       | TName _ :: TName "as" :: _ -> fail (H 7050) p "`as' in {% from ... import %} is not supported"
       | _ -> fail (H 7051) p "{% from \"file\" import a, b %} names the macros to import, and nothing else"
     in
     NFromImport (file, names rest, p)
  | _ -> fail (H 7052) p "{% from %} takes a string literal and `import'"

let parse (chunks: chunk list): node list =
  let r = ref chunks in
  let (nodes, kw, _, _) = parse_nodes r [] in
  if kw <> "" then internal_err ("unexpected {% " ^ kw ^ " %}");
  nodes

(* ---------------------------------------------------------------------- *)
(* 2b. Inheritance, include and macros, resolved before anything is        *)
(*     generated                                                            *)
(* ---------------------------------------------------------------------- *)

(* What the generator gets is ONE tree with no extends, block, include or
   macro definition left in it: a block is replaced by the definition that
   wins -- the most derived template's -- with `super()' replaced by the
   next one up; an include by the included template's tree.  Macro
   definitions are collected into a table, and a call is expanded where it
   stands, by the generator, because its arguments are references that only
   the generator can make.

   Measured with Jinja2 3.1.6 on 2026-09-24, before this was written:
   text before `extends' is rendered and text after it outside
   blocks is dropped; a child block the parents do not have is dropped
   without a word; an include sees the loop variable; a macro sees the
   template's data; a block inside a `for' does not see the loop variable
   unless it is `scoped'.  Two of these are refused here instead of copied
: the dropped text and the dropped block. *)

type block_def = { bbody: node list; bscoped: bool; bpos: pos }

(* mspace: the name an {% import ... as %} gave the file the macro is in,
   "" otherwise; a call in its body is looked up there first. *)
type macro = { mparams: (string * expr option) list; mbody: node list; mpos: pos; mimported: bool; mspace: string }

type resolver = {
    root: string;
    mutable loaded: (string * node list) list;
    mutable macros: (string * macro) list;
    mutable used_blocks: string list;
    mutable defined_blocks: (string * pos) list;
    (* The names {% import ... as %} gave, with the file each names. *)
    mutable spaces: (string * string) list;
    (* The whitespace options of the statement. *)
    trim_blocks: bool;
    lstrip_blocks: bool;
  }

let load (r: resolver) (p: pos) (name: string): node list =
  match List.assoc_opt name r.loaded with
  | Some nodes -> nodes
  | None ->
     let full = resolve p r.root name in
     let nodes = parse (lex r.trim_blocks r.lstrip_blocks full (read_template p full name)) in
     r.loaded <- (name, nodes) :: r.loaded;
     nodes

let blank (n: node): bool =
  match n with
  | NText (s, _) -> String.trim s = ""
  | _ -> false

(* Macro definitions at the top level of a template, and the ones a
   `from ... import' names, go into the table.  A name defined twice with
   two bodies is refused: which one wins would be an accident of order. *)
let rec collect_macros (r: resolver) (stack: string list) (imported: bool) (space: string) (nodes: node list): unit =
  List.iter
    (fun n ->
      match n with
      | NMacro (name, params, body, p) ->
         let key = if space = "" then name else space ^ "." ^ name in
         (match List.assoc_opt key r.macros with
          | Some m when m.mpos <> p -> fail (H 7054) p ("the macro " ^ key ^ " is defined twice")
          | Some _ -> ()
          | None -> r.macros <- (key, { mparams = params; mbody = body; mpos = p; mimported = imported; mspace = space }) :: r.macros)
      | NFromImport (file, names, p) ->
         if List.mem file stack then imports_itself p file;
         let nodes = load r p file in
         collect_macros r (file :: stack) true "" nodes;
         List.iter
           (fun name ->
             if not (List.mem_assoc name r.macros) then
               fail (H 7056) p ("\"" ^ file ^ "\" has no macro " ^ name))
           names
      | NImportAs (file, space', p) ->
         if List.mem file stack then imports_itself p file;
         if List.exists (fun (k, _) -> String.length k > String.length space' && String.sub k 0 (String.length space' + 1) = space' ^ ".") r.macros
            && not (List.mem (space', file) r.spaces) then
           refuse_import_name p space' " is given to two imports";
         r.spaces <- (space', file) :: r.spaces;
         let nodes = load r p file in
         collect_macros r (file :: stack) true space' nodes
      | _ -> ())
    nodes

let rec collect_blocks (nodes: node list): (string * block_def) list =
  List.concat_map
    (fun n ->
      match n with
      | NBlock (name, body, scoped, p) -> (name, { bbody = body; bscoped = scoped; bpos = p }) :: collect_blocks body
      | NIf (branches, els) -> List.concat_map (fun (_, b, _) -> collect_blocks b) branches @ collect_blocks els
      | NFor (_, _, _, body, empty, _) -> collect_blocks body @ collect_blocks empty
      | NSetBlock (_, body, _) | NWith (_, body, _) | NFilterBlock (_, body, _) | NCallBlock (_, _, body, _) ->
         collect_blocks body
      | _ -> [])
    nodes

let rec expand_template (r: resolver) (stack: string list) (p: pos) (name: string)
          (overrides: (string * block_def list) list): node list =
  if List.mem name stack then
    fail (H 7057) p ("\"" ^ name ^ "\" includes or extends itself: " ^ String.concat " -> " (List.rev (name :: stack)));
  let stack = name :: stack in
  let nodes = load r p name in
  collect_macros r stack false "" nodes;
  let rec split before = function
    | [] -> None
    | NExtends (parent, ep) :: rest -> Some (List.rev before, parent, ep, rest)
    | n :: rest -> split (n :: before) rest
  in
  match split [] nodes with
  | Some (before, parent, ep, after) ->
     List.iter
       (fun n ->
         match n with
         | NBlock _ | NMacro _ | NFromImport _ | NImportAs _ -> ()
         | NExtends (_, xp) -> fail (H 7058) xp "a template extends one other template, once"
         | NText (_, tp) when not (blank n) ->
            fail (H 7059) tp "text after {% extends %} and outside a block is dropped by Jinja2; here it is refused"
         | NText _ -> ()
         | NOut (_, op) -> fail (H 7060) op "a value after {% extends %} and outside a block is dropped by Jinja2; here it is refused"
         | NIf (_, _) | NFor (_, _, _, _, _, _) ->
            dropped_after_extends ep "an if or a for"
         | NSet (_, _, sp) | NSetBlock (_, _, sp) ->
            fail (H 7103) sp "a {% set %} after {% extends %} and outside a block is refused: whether a block sees it depends on the order in which Jinja2 runs the two templates"
         | NWith (_, _, wp) | NFilterBlock (_, _, wp) | NCallBlock (_, _, _, wp) ->
            dropped_after_extends wp "a with, a filter or a call"
         | NInclude (_, ip) -> fail (H 7062) ip "an include after {% extends %} and outside a block is dropped by Jinja2; here it is refused"
         | NCatalog (_, cp) ->
            fail (H 7128) cp "{% catalog %} after {% extends %} stands in the template that is extended or in a block, where the text it serves is"
         | NScope _ | NIncluded _ -> ())
       after;
     let defs = collect_blocks after in
     List.iter (fun (n, d) -> r.defined_blocks <- (n, d.bpos) :: r.defined_blocks) defs;
     let names = List.sort_uniq compare (List.map fst overrides @ List.map fst defs) in
     let merged =
       List.map
         (fun n ->
           let deeper = (match List.assoc_opt n overrides with Some ds -> ds | None -> []) in
           let mine = List.filter_map (fun (m, d) -> if m = n then Some d else None) defs in
           (n, deeper @ mine))
         names
     in
     expand_nodes r stack overrides [] before @ expand_template r stack ep parent merged
  | None ->
     expand_nodes r stack overrides [] nodes

(* `supers' is the chain above the block being expanded: what `super()'
   stands for inside it. *)
and expand_nodes (r: resolver) (stack: string list) (overrides: (string * block_def list) list)
      (supers: block_def list) (nodes: node list): node list =
  List.concat_map (expand_node r stack overrides supers) nodes

and expand_node (r: resolver) (stack: string list) (overrides: (string * block_def list) list)
      (supers: block_def list) (n: node): node list =
  match n with
  | NBlock (name, body, scoped, p) ->
     r.used_blocks <- name :: r.used_blocks;
     let chain = (match List.assoc_opt name overrides with Some ds -> ds | None -> [])
                 @ [{ bbody = body; bscoped = scoped; bpos = p }] in
     [expand_chain r stack overrides chain scoped]
  | NOut (ECall ("super", [], _), p) ->
     (match supers with
      | [] -> fail (H 7063) p "super() in a block that no template above this one has"
      | _ -> [expand_chain r stack overrides supers true])
  | NOut (ECall ("super", _, _), p) -> fail (H 7064) p "super() takes no arguments"
  | NInclude (name, p) -> [NIncluded (expand_template r stack p name [])]
  | NIf (branches, els) ->
     [NIf (List.map (fun (c, b, p) -> (c, expand_nodes r stack overrides supers b, p)) branches,
           expand_nodes r stack overrides supers els)]
  | NFor (v, s, cond, body, empty, p) ->
     [NFor (v, s, cond, expand_nodes r stack overrides supers body, expand_nodes r stack overrides supers empty, p)]
  | NSetBlock (name, body, p) -> [NSetBlock (name, expand_nodes r stack overrides supers body, p)]
  | NWith (binds, body, p) -> [NWith (binds, expand_nodes r stack overrides supers body, p)]
  | NFilterBlock (fs, body, p) -> [NFilterBlock (fs, expand_nodes r stack overrides supers body, p)]
  | NCallBlock (name, args, body, p) -> [NCallBlock (name, args, expand_nodes r stack overrides supers body, p)]
  | NMacro _ | NFromImport _ | NImportAs _ -> []
  | NExtends (_, p) -> fail (H 7065) p "{% extends %} stands at the top level of a template, once"
  | NText _ | NOut _ | NSet _ | NScope _ | NIncluded _ | NCatalog _ -> [n]

(* The winning definition of a block, with `super()' in it standing for the
   rest of the chain.  Whether the result sees the loop variables around it
   is decided by the block where it is PLACED -- `scoped' there. *)
and expand_chain (r: resolver) (stack: string list) (overrides: (string * block_def list) list)
      (chain: block_def list) (scoped: bool): node =
  match chain with
  | d :: above -> NScope (expand_nodes r stack overrides above d.bbody, scoped)
  | [] -> NScope ([], scoped)

let resolve_all (r: resolver) (p: pos) (name: string): node list =
  let nodes = expand_template r [] p name [] in
  (* A macro's body may include another template. *)
  r.macros <- List.map (fun (n, m) -> (n, { m with mbody = expand_nodes r [] [] [] m.mbody })) r.macros;
  List.iter
    (fun (n, bp) ->
      if not (List.mem n r.used_blocks) then
        fail (H 7066) bp ("the block " ^ n ^ " is defined here, and no template this one extends has a block of that name; Jinja2 drops it without a word, and here it is refused"))
    (List.rev r.defined_blocks);
  nodes

(* ---------------------------------------------------------------------- *)
(* 3a. The HTML context                                                    *)
(* ---------------------------------------------------------------------- *)

(* Where in the HTML the text so far has left us, followed character by
   character through the template's own text -- the values, escaped, never
   move it.  Go's html/template does the same, and the idea is taken from
   there; its code was not read. *)
(* A URL attribute's value is followed through its parts, as Go's
   html/template does: 0 its start, where a scheme can stand; 1 the rest of
   the path; 2 after `?' or `#', the query and the fragment. *)
(* JavaScript, followed far enough to know whether a value lands where an
   expression goes, inside a quoted string, or where no escaping helps (a
   comment, a template literal, a regular expression).  A `/' begins a
   regular expression after an operator, an opening bracket, a comma, a
   keyword that takes an expression, or at the start, and is a division after
   a name, a number or a closing bracket -- the rule Go's html/template
   follows, taken from its behaviour, not from its code. *)
type js =
  | JCode of bool                  (* may a `/' here begin a regexp? *)
  | JWord of string                (* in a name or a number *)
  | JSlash of bool
  | JStr of char
  | JStrEsc of char
  | JTemplate
  | JTemplateEsc
  | JLineComment
  | JBlockComment of bool          (* was the last character a star? *)
  | JRegex of bool                 (* inside [ ] *)
  | JRegexEsc of bool

(* CSS, followed as far as: in a value, in a quoted string, in a comment,
   or in url( ... ).  SCode keeps its last few characters, to see `url('. *)
type css =
  | SCode of string
  | SSlash of string
  | SStr of char
  | SStrEsc of char
  | SComment of bool
  | SUrl

type kind = KNormal | KUrl of int | KJs of js | KCss of css

type ctx =
  | XText
  | XLt                            (* just after "<" *)
  | XBang of int                   (* after "<!", with n dashes *)
  | XComment of int                (* in a comment, n dashes just seen *)
  | XDecl                          (* in "<!DOCTYPE ...>" *)
  | XTagName of bool * string      (* reading a tag's name; end tag? *)
  | XInTag of string               (* between the attributes of a tag *)
  | XInEndTag
  | XAttrName of string * string
  | XAfterAttr of string * string
  | XBeforeValue of string * string
  | XValue of string * string * char * kind (* tag, attribute, quote or ' ' *)
  | XRaw of string * int           (* title, textarea: text up to their end tag *)
  | XScript of js * int            (* the int: how much of "</script" is seen *)
  | XStyle of css * int

let js_where (j: js): string =
  match j with
  | JCode _ | JSlash false -> ""
  | JSlash true -> ", at the start of a regular expression"
  | JWord _ -> ", right after a name or a number"
  | JStr _ | JStrEsc _ -> ", in a string"
  | JTemplate | JTemplateEsc -> ", in a template literal"
  | JLineComment | JBlockComment _ -> ", in a comment"
  | JRegex _ | JRegexEsc _ -> ", in a regular expression"

let css_where (s: css): string =
  match s with
  | SCode _ | SSlash _ -> ""
  | SStr _ | SStrEsc _ -> ", in a string"
  | SComment _ -> ", in a comment"
  | SUrl -> ", in url( )"

let describe (x: ctx): string =
  match x with
  | XText -> "HTML text"
  | XLt -> "right after <, where a tag name goes"
  | XBang _ | XDecl -> "a <! declaration"
  | XComment _ -> "an HTML comment"
  | XTagName _ -> "a tag name"
  | XInTag _ -> "a tag, between its attributes"
  | XInEndTag -> "an end tag"
  | XAttrName _ -> "an attribute name"
  | XAfterAttr (_, a) -> "a tag, after the attribute name " ^ a
  | XBeforeValue (_, a) | XValue (_, a, ' ', _) -> "the unquoted value of the attribute " ^ a ^ " (quote the value)"
  | XValue (_, a, _, KUrl 0) -> "the start of the URL in the attribute " ^ a
  | XValue (_, a, _, KUrl 1) -> "the path of the URL in the attribute " ^ a
  | XValue (_, a, _, KUrl _) -> "the query of the URL in the attribute " ^ a
  | XValue (_, a, _, KJs j) -> "the JavaScript of the attribute " ^ a ^ js_where j
  | XValue (_, a, _, KCss s) -> "the CSS of the attribute " ^ a ^ css_where s
  | XValue (_, a, _, KNormal) -> "the value of the attribute " ^ a
  | XScript (j, _) -> "a <script> element" ^ js_where j
  | XStyle (s, _) -> "a <style> element" ^ css_where s
  | XRaw (t, _) -> "a <" ^ t ^ "> element"

let url_attributes = [
    "action"; "archive"; "background"; "cite"; "classid"; "codebase";
    "data"; "formaction"; "href"; "icon"; "longdesc"; "manifest"; "ping";
    "poster"; "profile"; "src"; "srcset"; "usemap"; "xmlns"
  ]

let contains (s: string) (w: string): bool =
  let n = String.length s and m = String.length w in
  let rec go i = i + m <= n && (String.sub s i m = w || go (i + 1)) in
  go 0

let attribute_kind (name: string): kind =
  let name = String.lowercase_ascii name in
  let name =
    if String.length name > 5 && String.sub name 0 5 = "data-" then
      String.sub name 5 (String.length name - 5)
    else name
  in
  match String.index_opt name ':' with
  | Some k when String.sub name 0 k = "xmlns" ->
     (* A namespace declaration, xmlns:svg, names a URI, as it does for
        Go's html/template. *)
     KUrl 0
  | found ->
     let name =
       match found with
       | Some k -> String.sub name (k + 1) (String.length name - k - 1)
       | None -> name
     in
     if String.length name > 2 && String.sub name 0 2 = "on" then KJs (JCode true)
     else if name = "style" then KCss (SCode "")
     else if List.mem name url_attributes || contains name "src" || contains name "uri" || contains name "url" then KUrl 0
     else KNormal

let close_tag (tag: string): ctx =
  match String.lowercase_ascii tag with
  | "script" -> XScript (JCode true, 0)
  | "style" -> XStyle (SCode "", 0)
  | ("title" | "textarea") as t -> XRaw (t, 0)
  | _ -> XText

let js_keywords = [
    "return"; "typeof"; "void"; "delete"; "in"; "instanceof"; "new";
    "throw"; "case"; "do"; "else"; "yield"; "await"
  ]

let rec js_step (j: js) (c: char): js =
  match j with
  | JCode r ->
     if c = '"' || c = '\'' then JStr c
     else if c = '`' then JTemplate
     else if c = '/' then JSlash r
     else if is_space c then JCode r
     else if is_name_char c || c = '$' then JWord (String.make 1 c)
     else if String.contains ")]}." c then JCode false
     else JCode true
  | JWord w ->
     if is_name_char c || c = '$' then JWord (w ^ String.make 1 c)
     else js_step (JCode (List.mem w js_keywords)) c
  | JSlash r ->
     if c = '/' then JLineComment
     else if c = '*' then JBlockComment false
     else if r then js_step (JRegex false) c
     else js_step (JCode true) c
  | JStr q -> if c = '\\' then JStrEsc q else if c = q then JCode false else JStr q
  | JStrEsc q -> JStr q
  | JTemplate -> if c = '\\' then JTemplateEsc else if c = '`' then JCode false else JTemplate
  | JTemplateEsc -> JTemplate
  | JLineComment -> if c = '\n' then JCode true else JLineComment
  | JBlockComment star -> if star && c = '/' then JCode true else JBlockComment (c = '*')
  | JRegex cls ->
     if c = '\\' then JRegexEsc cls
     else if c = '[' then JRegex true
     else if c = ']' then JRegex false
     else if c = '/' && not cls then JCode false
     else JRegex cls
  | JRegexEsc cls -> JRegex cls

let rec css_step (s: css) (c: char): css =
  match s with
  | SCode tail ->
     let n = String.length tail in
     if c = '"' || c = '\'' then SStr c
     else if c = '/' then SSlash tail
     else if c = '(' && n >= 3 && String.sub tail (n - 3) 3 = "url" then SUrl
     else
       let t = tail ^ String.make 1 (Char.lowercase_ascii c) in
       let m = String.length t in
       SCode (if m > 4 then String.sub t (m - 4) 4 else t)
  | SSlash tail -> if c = '*' then SComment false else css_step (SCode tail) c
  | SStr q -> if c = '\\' then SStrEsc q else if c = q then SCode "" else SStr q
  | SStrEsc q -> SStr q
  | SComment star -> if star && c = '/' then SCode "" else SComment (c = '*')
  | SUrl -> if c = ')' then SCode "" else SUrl

(* How much of "</tag" is seen after `c', from `k' seen before it. *)
let closer_step (tag: string) (k: int) (c: char): int =
  let closer = "</" ^ tag in
  if Char.lowercase_ascii c = closer.[k] then k + 1
  else if c = '<' then 1
  else 0

let step (x: ctx) (c: char): ctx =
  let letter = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') in
  match x with
  | XText ->
     if c = '<' then XLt else XText
  | XLt ->
     if letter then XTagName (false, String.make 1 c)
     else if c = '/' then XTagName (true, "")
     else if c = '!' then XBang 0
     else if c = '<' then XLt
     else XText
  | XBang k ->
     if c = '-' then (if k = 1 then XComment 0 else XBang 1)
     else if c = '>' then XText
     else XDecl
  | XDecl ->
     if c = '>' then XText else XDecl
  | XComment k ->
     if c = '-' then XComment (min 2 (k + 1))
     else if c = '>' && k = 2 then XText
     else XComment 0
  | XTagName (end_tag, name) ->
     if letter || (c >= '0' && c <= '9') || c = '-' || c = ':' then XTagName (end_tag, name ^ String.make 1 c)
     else if end_tag then (if c = '>' then XText else XInEndTag)
     else if c = '>' then close_tag name
     else if is_space c || c = '/' then XInTag name
     else XInTag name
  | XInEndTag ->
     if c = '>' then XText else XInEndTag
  | XInTag tag ->
     if c = '>' then close_tag tag
     else if is_space c || c = '/' then XInTag tag
     else XAttrName (tag, String.make 1 c)
  | XAttrName (tag, a) ->
     if c = '=' then XBeforeValue (tag, a)
     else if c = '>' then close_tag tag
     else if is_space c then XAfterAttr (tag, a)
     else if c = '/' then XInTag tag
     else XAttrName (tag, a ^ String.make 1 c)
  | XAfterAttr (tag, a) ->
     if c = '=' then XBeforeValue (tag, a)
     else if c = '>' then close_tag tag
     else if is_space c then XAfterAttr (tag, a)
     else if c = '/' then XInTag tag
     else XAttrName (tag, String.make 1 c)
  | XBeforeValue (tag, a) ->
     if is_space c then XBeforeValue (tag, a)
     else if c = '"' || c = '\'' then XValue (tag, a, c, attribute_kind a)
     else if c = '>' then close_tag tag
     else XValue (tag, a, ' ', attribute_kind a)
  | XValue (tag, a, q, k) ->
     if q = ' ' then
       (if is_space c then XInTag tag else if c = '>' then close_tag tag else XValue (tag, a, q, k))
     else if c = q then XInTag tag
     else
       (match k with
        | KUrl part ->
           let part' = if c = '?' || c = '#' then 2 else if part = 0 then 1 else part in
           XValue (tag, a, q, KUrl part')
        | KJs j -> XValue (tag, a, q, KJs (js_step j c))
        | KCss s -> XValue (tag, a, q, KCss (css_step s c))
        | KNormal -> XValue (tag, a, q, k))
  | XRaw (tag, k) ->
     let k' = closer_step tag k c in
     if k' = String.length tag + 2 then XInEndTag else XRaw (tag, k')
  (* The end tag ends the element whatever state the script is in, as it
     does in a browser. *)
  | XScript (j, k) ->
     let k' = closer_step "script" k c in
     if k' = 8 then XInEndTag else XScript (js_step j c, k')
  | XStyle (s, k) ->
     let k' = closer_step "style" k c in
     if k' = 7 then XInEndTag else XStyle (css_step s c, k')

let advance_ctx (x: ctx) (s: string): ctx =
  let x = ref x in
  String.iter (fun c -> x := step !x c) s;
  !x

(* What a value's text is escaped with, where it may stand at all. *)
let writer_for (p: pos) (x: ctx): string =
  match x with
  | XText | XRaw (("title" | "textarea"), _) -> "writeHtml"
  | XValue (_, _, ('"' | '\''), KNormal) -> "writeHtml"
  | XValue (_, _, ('"' | '\''), KUrl 0) -> "writeUrl"
  | XValue (_, _, ('"' | '\''), KUrl 1) -> "writeUrlPath"
  | XValue (_, _, ('"' | '\''), KUrl _) -> "writeUrlQuery"
  | XScript ((JCode _ | JSlash false), _) -> "jsScript"
  | XValue (_, _, ('"' | '\''), KJs (JCode _ | JSlash false)) -> "jsAttribute"
  | XScript (JStr _, _) -> "writeJsString"
  | XValue (_, _, ('"' | '\''), KJs (JStr _)) -> "writeJsStringAttribute"
  | XStyle (SCode _, _) -> "writeCssValue"
  | XValue (_, _, ('"' | '\''), KCss (SCode _)) -> "writeCssValueAttribute"
  | XStyle (SStr _, _) -> "writeCssString"
  | XValue (_, _, ('"' | '\''), KCss (SStr _)) -> "writeCssStringAttribute"
  | _ ->
     fail (H 7067) p ("a value cannot stand in " ^ describe x ^ ": there is no escaping that makes that safe")

(* Values in the tag's own name must never be quietly accepted, whatever
   the context says afterwards: the machine does not move on a value, so
   `<{{ x }}' would leave it in XLt and the check above refuses it. *)

(* ---------------------------------------------------------------------- *)
(* 3b. The generator                                                       *)
(* ---------------------------------------------------------------------- *)

let tq (name: string): qident =
  make_qident (make_mod_name "Standard.Template", make_ident name, make_ident name)

let sq (name: string): qident =
  make_qident (make_mod_name "Standard.String", make_ident name, make_ident name)

type loop_info = { counter: qident; total: qident }

(* What a name the template binds stands for.  BRef: a reference -- a loop
   variable, a macro parameter, a {% set %} of a name.  BNumber: a number
   the template computed, kept in a variable.  BText: a text the template
   computed, kept until the end of its scope, escaped when printed.
   BMarkup: the text a {% set %} block wrote, escaped already, printed as
   it is and only in HTML text.  depth: how many loops were open where the
   name was bound; a block that is not `scoped' sees only the names bound
   outside every loop. *)
type bkind = BRef | BNumber | BText | BMarkup

type binding = { q: qident; kind: bkind; depth: int }

type genv = {
    im: import_map;
    data: qident;
    out: qident;
    vars: (string * binding) list;
    loops: loop_info list;
    narrowed: (string list * qident) list;
    macros: (string * macro) list;
    calling: string list;
    (* false inside a macro brought in with `from ... import' or `import' *)
    sees_data: bool;
    (* the import name of the macro being expanded, "" outside one *)
    space: string;
    (* what caller() stands for in the macro being expanded *)
    caller: caller option;
    (* true inside a branch of an {% if %}, where a {% set %} is refused *)
    in_branch: bool;
    (* the function a {% catalog %} named, which gives the translations *)
    catalog: (string * pos) option;
  }

and caller = { cbody: node list; cenv: genv }

let local (g: genv) (i: identifier): qident =
  make_qident (importing_module g.im, i, i)

let call (q: qident) (args: aexpr list): aexpr =
  FunctionCall (q, Positional args)

let lit (s: string): aexpr =
  call (sq "fromLiteral") [StringConstant (escaped_of_raw s)]

let accessors (rest: string list): path_elem list =
  match rest with
  | [] -> []
  | first :: more -> PointerSlotAccessor (make_ident first) :: List.map (fun s -> SlotAccessor (make_ident s)) more

let from_ref (q: qident) (rest: string list): aexpr =
  if rest = [] then Variable q else RefPath (q, accessors rest, ReadBorrow)

let rec strip_prefix (prefix: string list) (path: string list): string list option =
  match prefix, path with
  | [], rest -> Some rest
  | a :: pa, b :: pb when a = b -> strip_prefix pa pb
  | _ -> None

let bind_var (g: genv) (name: string) (q: qident) (kind: bkind): genv =
  { g with vars = (name, { q; kind; depth = List.length g.loops }) :: g.vars }

(* A reference to what a path names: a narrowed Option's value, a name the
   template bound, or a field of the data. *)
let ref_of_path (g: genv) (p: pos) (path: string list): aexpr =
  let best =
    List.fold_left
      (fun acc (prefix, q) ->
        match strip_prefix prefix path, acc with
        | Some rest, None -> Some (q, rest, List.length prefix)
        | Some rest, Some (_, _, len) when List.length prefix > len -> Some (q, rest, List.length prefix)
        | _ -> acc)
      None g.narrowed
  in
  match best with
  | Some (q, rest, _) -> from_ref q rest
  | None ->
     (match path with
      | [] -> internal_err "an empty name"
      | "loop" :: _ -> fail (H 7069) p "`loop' can only be asked for loop.index, loop.index0, loop.revindex, loop.revindex0, loop.length, loop.first, loop.last and loop.cycle(...), inside a {% for %}"
      | first :: rest ->
         (match List.assoc_opt first g.vars with
          | Some { q; kind = BRef; _ } -> from_ref q rest
          | Some { q; _ } when rest = [] -> BorrowExpr (ReadBorrow, q)
          | Some _ -> fail (H 7104) p (first ^ " is a value that a {% set %} or a {% with %} computed, and a computed value has no fields")
          | None when List.exists (fun (k, _) -> String.length k > String.length first && String.sub k 0 (String.length first + 1) = first ^ ".") g.macros ->
             (* In Jinja2 the name of an import hides a field of the data
                of the same name. *)
             refuse_import_name p first " is an import's: it stands for the macros of a file, and a macro is called, not printed"
          | None ->
             if not g.sees_data then
               fail (H 7070) p (first ^ ": a macro brought in with {% from ... import %} or {% import %} does not see the template's data, as in Jinja2 -- pass it as an argument");
             RefPath (g.data, accessors path, ReadBorrow)))

let innermost_loop (g: genv) (p: pos): loop_info =
  match g.loops with
  | l :: _ -> l
  | [] -> fail (H 7071) p "`loop' only exists inside a {% for %}"

let literal_int (p: pos) (digits: string): int =
  match int_of_string_opt digits with
  | Some v -> v
  | None -> fail (H 7072) p "this number is too large"

let int_constant (p: pos) (digits: string): aexpr =
  IntConstant (string_of_int (literal_int p digits))

(* A number the loop knows, as an Index expression. *)
let loop_number (g: genv) (p: pos) (attr: string): aexpr =
  let l = innermost_loop g p in
  match attr with
  | "index" -> ArithmeticExpression (Add, Variable l.counter, IntConstant "1")
  | "index0" -> Variable l.counter
  | "length" -> Variable l.total
  | "revindex" -> ArithmeticExpression (Subtract, Variable l.total, Variable l.counter)
  | "revindex0" -> ArithmeticExpression (Subtract, ArithmeticExpression (Subtract, Variable l.total, Variable l.counter), IntConstant "1")
  | other -> fail (H 7080) p ("loop." ^ other ^ " is not a number")

(* The remainder of C's division, x - (x / l) * l, written with the
   operators so that l takes the type of x. *)
let remainder (x: aexpr) (l: aexpr): aexpr =
  ArithmeticExpression (Subtract, x, ArithmeticExpression (Multiply, ArithmeticExpression (Divide, x, l), l))

(* Python's integer division and remainder, which round towards minus
   infinity, for constants folded here. *)
let floor_div (a: int) (b: int): int =
  let q = a / b in
  if (a mod b <> 0) && ((a < 0) <> (b < 0)) then q - 1 else q

let floor_mod (a: int) (b: int): int =
  let r = a mod b in
  if r <> 0 && ((r < 0) <> (b < 0)) then r + b else r

(* An arithmetic of numbers written in the template alone, computed here. *)
let rec fold (e: expr): int option =
  match e with
  | EInt (i, p) -> Some (literal_int p i)
  | EArith (op, a, b, p) ->
     (match fold a, fold b with
      | Some x, Some y ->
         (match op with
          | "+" -> Some (x + y)
          | "-" -> Some (x - y)
          | "*" -> Some (x * y)
          | "//" | "%" when y = 0 -> bad_divisor p op "by zero"
          | "//" -> Some (floor_div x y)
          | _ -> Some (floor_mod x y))
      | _ -> None)
  | _ -> None

let is_numeric (e: expr): bool =
  match e with
  | EArith _ | EInt _ -> true
  | EPath (["loop"; ("index" | "index0" | "length" | "revindex" | "revindex0")], _) -> true
  | _ -> false

(* A number: an expression of the type the data gives it. *)
let rec numeric (g: genv) (e: expr): aexpr =
  match fold e with
  | Some v -> IntConstant (string_of_int v)
  | None ->
     (match e with
      | EPath (["loop"; attr], p) -> loop_number g p attr
      | EPath (path, p) -> Deref (ref_of_path g p path)
      | EArith (op, a, b, p) ->
         let x = numeric g a in
         (match op with
          | "+" -> ArithmeticExpression (Add, x, numeric g b)
          | "-" -> ArithmeticExpression (Subtract, x, numeric g b)
          | "*" -> ArithmeticExpression (Multiply, x, numeric g b)
          | _ ->
             let l =
               (match fold b with
                | Some v -> v
                | None -> bad_divisor p op "by a number written in the template only: a divisor from the data could be zero, and a division by zero stops the programme")
             in
             if l = 0 then bad_divisor p op "by zero";
             let lc = IntConstant (string_of_int l) in
             let q = ArithmeticExpression (Divide, x, lc) in
             let r = remainder x lc in
             let zero = IntConstant "0" in
             (* C's division rounds towards zero, Jinja2's (Python's) towards
                minus infinity: they part when the remainder and the divisor
                have different signs. *)
             let off = if l > 0 then Comparison (LessThan, r, zero) else Comparison (GreaterThan, r, zero) in
             if op = "//" then IfExpression (off, ArithmeticExpression (Subtract, q, IntConstant "1"), q)
             else IfExpression (off, ArithmeticExpression (Add, r, lc), r))
      | other -> fail (H 7106) (expr_pos other) "this is not a number: + - * // % take numbers, names of the data and the numbers of loop")

(* A value to print: an expression of type String, and whether it is
   marked `|safe' or is a {% set %} block's text, escaped already. *)
and value (g: genv) (e: expr): aexpr * bool =
  match e with
  | EPath (["loop"; ("first" | "last")], _) ->
     (IfExpression (condition g e, lit "True", lit "False"), false)
  | EPath (["loop"; (("index" | "index0" | "length" | "revindex" | "revindex0") as attr)], p) ->
     (call (tq "displayIndex") [loop_number g p attr], false)
  | EPath (["loop"; attr], p) ->
     fail (H 7073) p ("loop." ^ attr ^ " cannot be printed")
  | EPath ([name], p) when (match List.assoc_opt name g.vars with Some { kind = BMarkup; _ } -> true | _ -> false) ->
     (call (tq "display") [ref_of_path g p [name]], true)
  | EPath (path, p) ->
     (call (tq "display") [ref_of_path g p path], false)
  | EStr (s, _) -> (lit s, false)
  | EInt (i, p) -> (lit (string_of_int (literal_int p i)), false)
  | EBool (b, _) -> (lit (if b then "True" else "False"), false)
  | EArith _ ->
     (match fold e with
      | Some v -> (lit (string_of_int v), false)
      | None -> (call (tq "displayValue") [numeric g e], false))
  | EConcat (a, b, p) ->
     let (va, sa) = value g a and (vb, sb) = value g b in
     if sa || sb then
       fail (H 7107) p "~ joins texts that are escaped when printed; a |safe value or a {% set %} block's text cannot be joined to them -- print it on its own";
     (call (tq "concat") [va; vb], false)
  | ECond (a, c, otherwise, p) ->
     let (va, sa) = value g a in
     let (vb, sb) = (match otherwise with Some b -> value g b | None -> (lit "", sa)) in
     if sa <> sb then
       refuse_inline_if p "prints its two values the same way: both |safe, or neither";
     (IfExpression (condition g c, va, vb), sa)
  | EFilter (inner, "safe", [], _) ->
     let (v, _) = value g inner in (v, true)
  | EFilter (inner, ("e" | "escape"), [], _) ->
     (* Escaping is on already; Jinja2 does not escape twice. *)
     value g inner
  | EFilter (inner, (("upper" | "lower" | "trim" | "capitalize" | "title") as f), [], _) ->
     let (v, safe) = value g inner in
     (call (tq f) [v], safe)
  | EFilter (inner, "replace", args, p) ->
     let (v, safe) = value g inner in
     (match args with
      | [EStr ("", _); _] | [EStr ("", _); _; _] ->
         bad_arguments p "|replace" "a text to replace that is not empty"
      | [EStr (old, _); EStr (nw, _)] ->
         (call (tq "replaceText") [v; StringConstant (escaped_of_raw old); StringConstant (escaped_of_raw nw); BoolConstant false; call (tq "zero") []], safe)
      | [EStr (old, _); EStr (nw, _); EInt (n, np)] when literal_int np n >= 0 ->
         (call (tq "replaceText") [v; StringConstant (escaped_of_raw old); StringConstant (escaped_of_raw nw); BoolConstant true; int_constant np n], safe)
      | _ -> bad_arguments p "|replace" "two strings in quotes, and a count of at least 0 after them")
  | EFilter (inner, "truncate", args, p) ->
     let (v, safe) = value g inner in
     let length, kill, ending, leeway =
       (match args with
        | [] -> (255, false, "...", 5)
        | [EInt (n, np)] -> (literal_int np n, false, "...", 5)
        | [EInt (n, np); EBool (k, _)] -> (literal_int np n, k, "...", 5)
        | [EInt (n, np); EBool (k, _); EStr (s, _)] -> (literal_int np n, k, s, 5)
        | [EInt (n, np); EBool (k, _); EStr (s, _); EInt (l, lp)] -> (literal_int np n, k, s, literal_int lp l)
        | _ -> bad_arguments p "|truncate" "a length, then true or false, a text in quotes and a leeway, each a literal")
     in
     (* Python's len counts code points, and so does Standard.Template. *)
     let ending_points = List.length (List.filter (fun c -> Char.code c < 0x80 || Char.code c >= 0xC0) (List.of_seq (String.to_seq ending))) in
     if length < ending_points || leeway < 0 then
       bad_arguments p "|truncate" "a length at least as long as its ending, and a leeway of at least 0";
     (call (tq "truncate") [v; IntConstant (string_of_int length); BoolConstant kill; StringConstant (escaped_of_raw ending); IntConstant (string_of_int leeway)], safe)
  | EFilter (inner, "center", args, p) ->
     let (v, safe) = value g inner in
     (match args with
      | [] -> (call (tq "center") [v; IntConstant "80"], safe)
      | [EInt (n, np)] when literal_int np n >= 0 -> (call (tq "center") [v; int_constant np n], safe)
      | _ -> bad_arguments p "|center" "a width of at least 0, as a literal")
  | EFilter (EPath (path, p), "join", args, fp) ->
     let sep = (match args with [] -> "" | [EStr (s, _)] -> s | _ -> bad_arguments fp "|join" "a separator in quotes, or none") in
     (call (tq "joinDisplayed") [ref_of_path g p path; StringConstant (escaped_of_raw sep)], false)
  | EFilter (_, "join", _, p) ->
     bad_arguments p "|join" "a name of the data to join, and nothing else"
  | EFilter (EPath (path, p), ("length" | "count"), [], _) ->
     (call (tq "displayIndex") [call (tq "size") [ref_of_path g p path]], false)
  | EFilter (_, ("length" | "count"), [], p) ->
     fail (H 7075) p "|length is supported on a name of the data only"
  | EFilter (_, name, _, p) ->
     fail (H 7076) p ("the filter |" ^ name ^ " is not supported")
  | ENone p ->
     fail (H 7077) p "none cannot be printed: an Option is printed by asking `is not none' first"
  | ENot _ | EAnd _ | EOr _ | ECmp _ | ETest _ | EIn _ ->
     (IfExpression (condition g e, lit "True", lit "False"), false)
  | ECall ("loop.cycle", args, p) ->
     let l = innermost_loop g p in
     let texts = List.map (function EStr (s, _) -> s | other -> bad_arguments (expr_pos other) "loop.cycle" "texts in quotes") args in
     if texts = [] then bad_arguments p "loop.cycle" "at least one text";
     let n = List.length texts in
     let which = remainder (Variable l.counter) (IntConstant (string_of_int n)) in
     let rec pick k = function
       | [last] -> lit last
       | t :: rest -> IfExpression (Comparison (Equal, which, IntConstant (string_of_int k)), lit t, pick (k + 1) rest)
       | [] -> lit ""
     in
     (pick 0 texts, false)
  | ECall (_, _, p) ->
     fail (H 7079) p "a macro call stands alone in {{ }}, without filters"
  | ETrans (_, _, p) ->
     fail (H 7124) p "a translation stands alone in {{ }} or a {% trans %} block, without filters and without ~"

and mirror (op: comparison_operator): comparison_operator =
  match op with
  | LessThan -> GreaterThan | GreaterThan -> LessThan
  | LessThanOrEqual -> GreaterThanOrEqual | GreaterThanOrEqual -> LessThanOrEqual
  | other -> other

(* A condition: an expression of type Bool. *)
and condition (g: genv) (e: expr): aexpr =
  match e with
  | EPath (["loop"; "first"], p) ->
     let l = innermost_loop g p in
     Comparison (Equal, Variable l.counter, IntConstant "0")
  | EPath (["loop"; "last"], p) ->
     let l = innermost_loop g p in
     Comparison (Equal, ArithmeticExpression (Add, Variable l.counter, IntConstant "1"), Variable l.total)
  | EPath (path, p) ->
     call (tq "truthy") [ref_of_path g p path]
  | EBool (b, _) -> BoolConstant b
  | ENot (inner, _) -> Negation (condition g inner)
  | EAnd (a, b, _) -> Conjunction (condition g a, condition g b)
  | EOr (a, b, _) -> Disjunction (condition g a, condition g b)
  | ETest (EPath (path, p), negated, "none", _) ->
     let present = call (tq "isPresent") [ref_of_path g p path] in
     if negated then present else Negation present
  | ETest (_, _, ("defined" | "undefined"), p) ->
     fail (H 7082) p "`is defined' cannot be asked: the template is compiled against one data type, so every name is known when the programme is compiled, and a name that does not exist is a compile error already"
  | ETest (_, _, "none", p) ->
     fail (H 7083) p "`is none' is supported on a name of the data only"
  | ETest (_, _, t, p) ->
     fail (H 7084) p ("the test `is " ^ t ^ "' is not supported")
  | EIn (needle, EPath (path, p), negated, _) ->
     let text =
       (match needle with
        | EStr (s, _) -> StringConstant (escaped_of_raw s)
        | EPath (npath, np) -> call (sq "asSpan") [ref_of_path g np npath]
        | other -> refuse_in (expr_pos other) "for a text in quotes or a name of a string")
     in
     let held = call (tq "holds") [ref_of_path g p path; text] in
     if negated then Negation held else held
  | EIn (_, other, _, _) ->
     refuse_in (expr_pos other) "a name of the data: a string for a part of it, or a buffer for an element"
  | ECmp (op, EPath (["loop"; attr], p), EInt (i, ip), _) ->
     Comparison (op, loop_number g p attr, int_constant ip i)
  | ECmp (op, EInt (i, ip), EPath (["loop"; attr], p), _) ->
     Comparison (mirror op, loop_number g p attr, int_constant ip i)
  | ECmp (op, EPath (path, p), EStr (s, _), _) ->
     let eq = call (tq "textEquals") [call (sq "asSpan") [ref_of_path g p path]; StringConstant (escaped_of_raw s)] in
     (match op with
      | Equal -> eq
      | NotEqual -> Negation eq
      | _ -> fail (H 7085) p "a string can only be compared with == and !=")
  | ECmp (op, EStr (s, sp), EPath (path, p), cp) ->
     condition g (ECmp (op, EPath (path, p), EStr (s, sp), cp))
  | ECmp (op, EPath (path, p), EInt (i, ip), _) ->
     Comparison (op, Deref (ref_of_path g p path), int_constant ip i)
  | ECmp (op, EInt (i, ip), EPath (path, p), _) ->
     Comparison (mirror op, Deref (ref_of_path g p path), int_constant ip i)
  | ECmp (op, a, b, _) when is_numeric a && (is_numeric b || (match b with EPath _ -> true | _ -> false)) ->
     Comparison (op, numeric g a, numeric g b)
  | ECmp (op, a, b, _) when is_numeric b && (match a with EPath _ -> true | _ -> false) ->
     Comparison (op, numeric g a, numeric g b)
  | ECmp (_, _, _, p) ->
     fail (H 7086) p "only a name compared with a literal, or with a computed number, is supported"
  | ECond (_, _, _, p) ->
     refuse_inline_if p "cannot stand in a condition; write an {% if %} with and and or"
  | EStr (_, p) | EInt (_, p) | ENone p | EFilter (_, _, _, p) | ECall (_, _, p) | EConcat (_, _, p) | EArith (_, _, _, p)
  | ETrans (_, _, p) ->
     fail (H 7087) p "this cannot be used as a condition"

(* A value where a JavaScript expression goes: the JS source text as a
   String, and whether it was marked |safe (then it is written as it is). *)
let js_value (g: genv) (e: expr): aexpr * bool =
  match e with
  | EFilter (inner, "safe", [], _) -> let (v, _) = value g inner in (v, true)
  | EPath (["loop"; ("first" | "last")], _) ->
     (IfExpression (condition g e, lit " true ", lit " false "), false)
  | EPath (["loop"; attr], p) -> (call (tq "jsIndex") [loop_number g p attr], false)
  | EPath (path, p) -> (call (tq "jsValue") [ref_of_path g p path], false)
  | EInt (i, p) -> (lit (" " ^ string_of_int (literal_int p i) ^ " "), false)
  | EBool (b, _) -> (lit (if b then " true " else " false "), false)
  | EArith _ -> (call (tq "concat") [lit " "; call (tq "concat") [call (tq "displayValue") [numeric g e]; lit " "]], false)
  | _ -> (call (tq "jsQuote") [fst (value g e)], false)

(* The names a condition proves present when it is TRUE: `x is not none',
   alone or as a term of an `and'. *)
let rec present_when_true (e: expr): string list list =
  match e with
  | ETest (EPath (path, _), true, "none", _) -> [path]
  | EAnd (a, b, _) -> present_when_true a @ present_when_true b
  | ENot (inner, _) -> present_when_false inner
  | _ -> []

(* ... and when it is FALSE: `x is none'. *)
and present_when_false (e: expr): string list list =
  match e with
  | ETest (EPath (path, _), false, "none", _) -> [path]
  | EOr (a, b, _) -> present_when_false a @ present_when_false b
  | ENot (inner, _) -> present_when_true inner
  | _ -> []

let block (stmts: astmt list): astmt =
  match List.rev stmts with
  | [] -> ASkip empty_span
  | last :: before ->
     List.fold_left (fun acc s -> ABlock (empty_span, s, acc)) last before

(* Bind every name a branch may take as present, at the head of the
   branch. *)
let narrow (g: genv) (p: pos) (paths: string list list): genv * astmt list =
  List.fold_left
    (fun (g', stmts) path ->
      let tmp = fresh_ident () in
      let binding = ALetTmp (tmp, call (tq "present") [ref_of_path g p path]) in
      ({ g' with narrowed = (path, local g tmp) :: g'.narrowed }, stmts @ [binding]))
    (g, []) paths

(* The names a {% set %} or a loop binds hide a narrowed path that starts
   with the same name. *)
let unnarrow (g: genv) (name: string): genv =
  { g with narrowed = List.filter (fun (path, _) -> match path with h :: _ -> h <> name | [] -> false) g.narrowed }

let rec subst_expr (param: string) (lit_e: expr) (e: expr): expr =
  let s = subst_expr param lit_e in
  match e with
  | EPath ([n], _) when n = param -> lit_e
  | EPath (n :: _, p) when n = param -> fail (H 7088) p ("the parameter " ^ param ^ " is a literal here, and a literal has no fields")
  | EFilter (inner, f, args, p) -> EFilter (s inner, f, List.map s args, p)
  | ENot (a, p) -> ENot (s a, p)
  | EAnd (a, b, p) -> EAnd (s a, s b, p)
  | EOr (a, b, p) -> EOr (s a, s b, p)
  | ECmp (op, a, b, p) -> ECmp (op, s a, s b, p)
  | ETest (a, neg, t, p) -> ETest (s a, neg, t, p)
  | ECall (f, args, p) -> ECall (f, List.map s args, p)
  | EConcat (a, b, p) -> EConcat (s a, s b, p)
  | EArith (op, a, b, p) -> EArith (op, s a, s b, p)
  | EIn (a, b, neg, p) -> EIn (s a, s b, neg, p)
  | ECond (a, c, b, p) -> ECond (s a, s c, Option.map s b, p)
  | ETrans (k, args, p) -> ETrans (k, List.map (fun (n, a) -> (n, s a)) args, p)
  | other -> other

(* A name bound anew hides the parameter from there on: in the rest of the
   list after a {% set %}, in the body of a {% with %} or a {% for %} that
   binds it. *)
and subst_nodes (param: string) (lit_e: expr) (nodes: node list): node list =
  match nodes with
  | [] -> []
  | n :: rest ->
     let se = subst_expr param lit_e and sn = subst_nodes param lit_e in
     (match n with
      | NSet (name, e, p) when name = param -> NSet (name, se e, p) :: rest
      | NSetBlock (name, body, p) when name = param -> NSetBlock (name, sn body, p) :: rest
      | NSet (name, e, p) -> NSet (name, se e, p) :: sn rest
      | NSetBlock (name, body, p) -> NSetBlock (name, sn body, p) :: sn rest
      | NOut (e, p) -> NOut (se e, p) :: sn rest
      | NIf (branches, els) ->
         NIf (List.map (fun (c, b, p) -> (se c, sn b, p)) branches, sn els) :: sn rest
      | NFor (vs, seq, cond, body, empty, p) ->
         if List.mem param vs then NFor (vs, se seq, cond, body, sn empty, p) :: sn rest
         else NFor (vs, se seq, Option.map se cond, sn body, sn empty, p) :: sn rest
      | NWith (binds, body, p) ->
         let binds' = List.map (fun (k, e) -> (k, se e)) binds in
         if List.mem_assoc param binds then NWith (binds', body, p) :: sn rest
         else NWith (binds', sn body, p) :: sn rest
      | NFilterBlock (fs, body, p) ->
         NFilterBlock (List.map (fun (f, args) -> (f, List.map se args)) fs, sn body, p) :: sn rest
      | NCallBlock (name, args, body, p) -> NCallBlock (name, List.map se args, sn body, p) :: sn rest
      | NScope (b, scoped) -> NScope (sn b, scoped) :: sn rest
      | NIncluded b -> NIncluded (sn b) :: sn rest
      | other -> other :: sn rest)

(* The filters a {% filter %} block applies to what it wrote, escaped
   already: those that do not need escaping to be undone. *)
let block_filter (g: genv) (v: aexpr) (f: string * expr list) (p: pos): aexpr =
  match f with
  | (("e" | "escape" | "safe"), []) -> v
  | ((("upper" | "lower" | "trim" | "capitalize" | "title") as name), []) -> call (tq name) [v]
  | (name, args) ->
     (match name with
      | "replace" | "truncate" | "center" ->
         (* The same checks as for a value, on a stand-in. *)
         let stand_in = EFilter (EStr ("", p), name, args, p) in
         (match fst (value g stand_in) with
          | FunctionCall (q, Positional (_ :: rest)) -> FunctionCall (q, Positional (v :: rest))
          | _ -> internal_err "a filter of a block did not come back as a call")
      | other -> fail (H 7109) p ("the filter |" ^ other ^ " cannot stand in {% filter %}: it applies to a value, not to written text"))

let rec generate (g: genv) (x: ctx) (nodes: node list): astmt list * ctx =
  match nodes with
  | [] -> ([], x)
  | NSet (name, e, p) :: rest ->
     if g.in_branch then set_in_branch p name;
     (match e with
      | EStr _ | EInt _ | EBool _ -> generate g x (subst_nodes name e rest)
      | _ ->
         let (stmts, g', cleanup) = bind g name e p in
         let (more, x') = generate g' x rest in
         (stmts @ more @ cleanup, x'))
  | NSetBlock (name, body, p) :: rest ->
     if g.in_branch then set_in_branch p name;
     let (text, stmts) = capture g p body in
     let g' = bind_var (unnarrow g name) name (local g text) BMarkup in
     let (more, x') = generate g' x rest in
     (stmts @ more @ [ADiscarding (span_at p, call (tq "discard") [Variable (local g text)])], x')
  | NCatalog (name, p) :: rest ->
     (match g.catalog with
      | Some _ -> fail (H 7121) p "a template names its catalog once, with one {% catalog %}"
      | None -> ());
     if not (ModuleNameSet.mem (make_mod_name "Standard.I18n") (modules_imported_from g.im)) then
       fail (H 7127) p "a module whose template translates imports Standard.I18n -- e.g. import Standard.I18n (Catalog); -- because the generated code calls it";
     generate { g with catalog = Some (name, p) } x rest
  | n :: rest ->
     let (s1, x1) = generate_node g x n in
     let (s2, x2) = generate g x1 rest in
     (s1 @ s2, x2)

(* What `name = e' binds: the statements before, the environment after, and
   the statements that give back a text at the end of the scope. *)
and bind (g: genv) (name: string) (e: expr) (p: pos): astmt list * genv * astmt list =
  let tmp = fresh_ident () in
  let g0 = unnarrow g name in
  match e with
  | EPath (path, pp) when not (is_numeric e) && not (match path with ["loop"; ("first" | "last")] -> true | _ -> false) ->
     ([ALetTmp (tmp, ref_of_path g pp path)], bind_var g0 name (local g tmp) BRef, [])
  | _ when is_numeric e ->
     ([ALetTmp (tmp, numeric g e)], bind_var g0 name (local g tmp) BNumber, [])
  | _ ->
     let (v, safe) = value g e in
     ([ALetTmp (tmp, v)], bind_var g0 name (local g tmp) (if safe then BMarkup else BText),
      [ADiscarding (span_at p, call (tq "discard") [Variable (local g tmp)])])

(* The text a body writes, into a builder of its own, starting in HTML
   text and ending there.  Answers the variable that holds the text and the
   statements that make it. *)
and capture (g: genv) (p: pos) (body: node list): identifier * astmt list =
  let builder = fresh_ident () and text = fresh_ident () in
  let (stmts, x') = generate { g with out = local g builder; in_branch = false } XText body in
  if x' <> XText then
    block_place p ("ends in " ^ describe x');
  (text, [ALetTmp (builder, call (tq "makeCapture") [])] @ stmts @ [ALetTmp (text, call (tq "captured") [Variable (local g builder)])])

and expand_macro (g: genv) (x: ctx) (name: string) (args: expr list) (caller_body: node list option) (p: pos): astmt list * ctx =
  let key, m =
    let lookup k = Option.map (fun m -> (k, m)) (List.assoc_opt k g.macros) in
    let found =
      match (if g.space <> "" && not (String.contains name '.') then lookup (g.space ^ "." ^ name) else None) with
      | Some km -> Some km
      | None -> lookup name
    in
    match found with
    | Some km -> km
    | None ->
       if String.contains name '.' then
         refuse_dotted_call p name ": there is no such macro; the part before the dot is not a name an {% import ... as %} gave, or the file has no macro of that name"
       else
         fail (H 7089) p ("there is no macro " ^ name ^ "")
  in
  if List.mem key g.calling then
    fail (H 7090) p ("the macro " ^ key ^ " calls itself: " ^ String.concat " -> " (List.rev (key :: g.calling)) ^ "; a template is expanded when the programme is compiled, and a recursion would not end");
  if List.length args > List.length m.mparams then
    fail (H 7091) p ("the macro " ^ key ^ " takes " ^ string_of_int (List.length m.mparams) ^ " arguments");
  let (binds, vars, body) =
    List.fold_left
      (fun (binds, vars, body) (k, (param, default)) ->
        let arg = (if k < List.length args then Some (List.nth args k) else default) in
        match arg with
        | None -> fail (H 7092) p ("the macro " ^ key ^ " needs a value for " ^ param)
        | Some (EPath (path, pp)) ->
           let tmp = fresh_ident () in
           (binds @ [ALetTmp (tmp, ref_of_path g pp path)], (param, { q = local g tmp; kind = BRef; depth = 1 }) :: vars, body)
        | Some ((EStr _ | EInt _ | EBool _) as l) ->
           (binds, vars, subst_nodes param l body)
        | Some other -> fail (H 7093) (expr_pos other) "a macro argument is a name or a literal")
      ([], [], m.mbody)
      (List.mapi (fun k pd -> (k, pd)) m.mparams)
  in
  (* A macro sees its parameters and the template's data, and not the
     caller's loop variables -- as in Jinja2. *)
  let g_macro = { g with vars; loops = [];
                         narrowed = List.filter (fun (path, _) -> match path with h :: _ -> not (List.mem_assoc h g.vars) | [] -> false) g.narrowed;
                         calling = key :: g.calling;
                         sees_data = g.sees_data && not m.mimported;
                         space = m.mspace;
                         caller = Option.map (fun b -> { cbody = b; cenv = g }) caller_body;
                         in_branch = false } in
  let (stmts, x') = generate g_macro x body in
  (binds @ stmts, x')

(* A translation: each argument displayed into a text of its own and added
   by its name, the call of Standard.I18n.translate with the catalog, the
   language the data's slot lang names, the key and the count, the text
   written with the escaping of the place it lands in, and the arguments
   given back.  The key is the constructor of that name, so the type
   checker refuses an unknown key at this line. *)
and translation (g: genv) (x: ctx) (key: string) (args: (string * expr) list) (p: pos): astmt list * ctx =
  let catalog =
    match g.catalog with
    | Some (name, _) -> name
    | None -> fail (H 7122) p "a translation needs the template's catalog: {% catalog name %} before it"
  in
  let writer = writer_for p x in
  if writer = "jsScript" || writer = "jsAttribute" then
    fail (H 7123) p ("a translation is text for HTML and cannot stand in " ^ describe x);
  (* A name the module imports, else one of its own; a name it has neither
     way is refused by the type checker at this line. *)
  let named (name: string): qident =
    match get_symbol g.im (make_ident name) with
    | Some q -> q
    | None -> local g (make_ident name)
  in
  let catalog_q = named catalog and key_q = named key in
  let iq (name: string): qident = make_qident (make_mod_name "Standard.I18n", make_ident name, make_ident name) in
  let pq (name: string): qident = make_qident (make_mod_name "Hilde.Pervasive", make_ident name, make_ident name) in
  let sp = span_at p in
  let arguments = fresh_ident () in
  let (fills, frees) =
    List.fold_left
      (fun (fills, frees) (name, e) ->
        let t = fresh_ident () in
        let (v, _) = value g e in
        (fills @ [ ALetTmp (t, v);
                   ADiscarding (sp, call (iq "addText") [ BorrowExpr (WriteBorrow, local g arguments);
                                                          StringConstant (escaped_of_raw name);
                                                          call (sq "asSpan") [BorrowExpr (ReadBorrow, local g t)] ]) ],
         frees @ [ADiscarding (sp, call (sq "destroyString") [Variable (local g t)])]))
      ([], []) args
  in
  let count =
    match List.assoc_opt "count" args with
    | Some e -> call (pq "toInt64") [numeric g e]
    | None -> call (iq "noCount") []
  in
  let text = call (iq "translate") [ call catalog_q [];
                                     call (sq "asSpan") [ref_of_path g p ["lang"]];
                                     call key_q [];
                                     count;
                                     BorrowExpr (ReadBorrow, local g arguments) ] in
  ([ALetTmp (arguments, call (iq "makeArguments") [])]
   @ fills
   @ [ADiscarding (sp, call (tq writer) [BorrowExpr (WriteBorrow, g.out); text]);
      ADiscarding (sp, call (iq "destroyArguments") [Variable (local g arguments)])]
   @ frees,
   x)

and generate_node (g: genv) (x: ctx) (node: node): astmt list * ctx =
  match node with
  | NOut (ECall ("caller", [], _), p) ->
     (match g.caller with
      | Some c -> generate c.cenv x c.cbody
      | None -> refuse_caller p "stands in a macro that a {% call %} block calls")
  | NOut (ECall ("caller", _, _), p) ->
     refuse_caller p "takes no arguments"
  | NOut (ECall (name, args, _), p) when name <> "loop.cycle" ->
     expand_macro g x name args None p
  | NCallBlock (name, args, body, p) ->
     expand_macro g x name args (Some body) p
  | NScope (nodes, scoped) ->
     let g' =
       if scoped then g
       else { g with vars = List.filter (fun (_, b) -> b.depth = 0) g.vars; loops = [];
                     narrowed = List.filter (fun (path, _) -> match path with h :: _ -> not (List.mem_assoc h g.vars) | [] -> false) g.narrowed }
     in
     generate { g' with in_branch = false } x nodes
  | NIncluded nodes ->
     generate { g with loops = []; in_branch = false } x nodes
  | NBlock _ | NExtends _ | NInclude _ | NMacro _ | NFromImport _ | NImportAs _ ->
     internal_err "an unresolved template tag reached the generator"
  | NSet _ | NSetBlock _ ->
     internal_err "a {% set %} reached generate_node"
  | NCatalog _ ->
     internal_err "a {% catalog %} reached generate_node"
  | NOut (ETrans (key, args, p), _) ->
     translation g x key args p
  | NText (s, p) ->
     ([ADiscarding (span_at p, call (tq "writeText") [BorrowExpr (WriteBorrow, g.out); StringConstant (escaped_of_raw s)])],
      advance_ctx x s)
  | NOut (e, p) ->
     let writer = writer_for p x in
     let markup = (match e with EPath ([n], _) -> (match List.assoc_opt n g.vars with Some { kind = BMarkup; _ } -> true | _ -> false) | _ -> false) in
     if markup && x <> XText then
       fail (H 7113) p ("the text of a {% set %} block is HTML, escaped already, and is printed in HTML text only, not in " ^ describe x);
     if writer = "jsScript" || writer = "jsAttribute" then begin
         (* Where a JavaScript expression goes the value is written as one:
            a string quoted, a number or a boolean bare between spaces -- the
            type decides, through JsValue.  Afterwards the script is behind
            an expression, so a `/' is a division. *)
         let (v, raw) = js_value g e in
         let w = if raw then "writeRaw" else if writer = "jsScript" then "writeRaw" else "writeHtml" in
         let x' =
           (match x with
            | XScript (_, k) -> XScript (JCode false, k)
            | XValue (t, a, q, KJs _) -> XValue (t, a, q, KJs (JCode false))
            | other -> other)
         in
         ([ADiscarding (span_at p, call (tq w) [BorrowExpr (WriteBorrow, g.out); v])], x')
       end
     else
       let (v, safe) = value g e in
       let writer = if safe then "writeRaw" else writer in
       ([ADiscarding (span_at p, call (tq writer) [BorrowExpr (WriteBorrow, g.out); v])], x)
  | NWith (binds, body, p) ->
     (* Every value is taken where the {% with %} stands; the names are
        seen in its body only. *)
     let (stmts, g', cleanup, body') =
       List.fold_left
         (fun (stmts, g', cleanup, body') (name, e) ->
           match e with
           | EStr _ | EInt _ | EBool _ -> (stmts, unnarrow g' name, cleanup, subst_nodes name e body')
           | _ ->
              let (s, g'', c) = bind { g' with vars = g.vars } name e p in
              (stmts @ s, { (unnarrow g' name) with vars = (List.hd g''.vars) :: g'.vars }, c @ cleanup, body'))
         ([], g, [], body) binds
     in
     let (body_stmts, x') = generate { g' with in_branch = false } x body' in
     ([block (stmts @ body_stmts @ cleanup)], x')
  | NFilterBlock (filters, body, p) ->
     if x <> XText then
       block_place p ("stands in " ^ describe x);
     let (text, stmts) = capture g p body in
     let v = List.fold_left (fun v f -> block_filter g v f p) (Variable (local g text)) filters in
     ([block (stmts @ [ADiscarding (span_at p, call (tq "writeRaw") [BorrowExpr (WriteBorrow, g.out); v])])], x)
  | NIf (branches, else_nodes) ->
     let gb = { g with in_branch = true } in
     let rec chain (bs: (expr * node list * pos) list) (g: genv): astmt * ctx list =
       match bs with
       | [] ->
          let (stmts, x') = generate g x else_nodes in
          (block stmts, [x'])
       | (cond, body, p) :: rest ->
          let c = condition g cond in
          let (g_true, head_true) = narrow g p (present_when_true cond) in
          let (g_false, head_false) = narrow g p (present_when_false cond) in
          let (stmts, x_true) = generate g_true x body in
          let (else_stmt, xs) = chain rest g_false in
          (AIf (span_at p, c, block (head_true @ stmts), block (head_false @ [else_stmt])), x_true :: xs)
     in
     let (stmt, ends) = chain branches gb in
     let first_pos = (match branches with (_, _, p) :: _ -> p | [] -> { file = ""; line = 0; col = 0 }) in
     (match ends with
      | e :: others ->
         List.iter
           (fun o ->
             if o <> e then
               fail (H 7095) first_pos ("the branches of this {% if %} end in different places in the HTML: " ^ describe e ^ " and " ^ describe o ^ ""))
           others;
         ([stmt], e)
      | [] -> ([stmt], x))
  | NFor (vars, seq, cond, body, empty, p) ->
     let path = (match seq with EPath (path, _) -> path | _ -> fail (H 7096) p "{% for %} walks over a name of the data only") in
     let seq_t = fresh_ident () and total_t = fresh_ident () and counter_t = fresh_ident ()
     and all_t = fresh_ident () and at_t = fresh_ident () and item_t = fresh_ident () in
     let seq_q = local g seq_t and total_q = local g total_t and counter_q = local g counter_t
     and all_q = local g all_t and at_q = local g at_t and item_q = local g item_t in
     (* The names: one for the element, or the fields of a Pair or a Triple. *)
     let fields = ["first"; "second"; "third"] in
     let name_binds (item: qident) (g0: genv) (depth_loops: loop_info list): astmt list * genv =
       match vars with
       | [v] -> ([], { (unnarrow g0 v) with vars = (v, { q = item; kind = BRef; depth = List.length depth_loops }) :: g0.vars })
       | vs ->
          List.fold_left
            (fun (stmts, g1) (k, v) ->
              let t = fresh_ident () in
              (stmts @ [ALetTmp (t, from_ref item [List.nth fields k])],
               { (unnarrow g1 v) with vars = (v, { q = local g t; kind = BRef; depth = List.length depth_loops }) :: g1.vars }))
            ([], g0) (List.mapi (fun k v -> (k, v)) vs)
     in
     let loop_info = { counter = counter_q; total = total_q } in
     let (head_binds, g_body0) = name_binds item_q g (loop_info :: g.loops) in
     let g_body = { g_body0 with loops = loop_info :: g.loops; in_branch = false } in
     let (body_stmts, x_body) = generate g_body x body in
     if x_body <> x then
       fail (H 7097) p ("the body of this {% for %} ends in a different place in the HTML than it begins: " ^ describe x ^ " and " ^ describe x_body ^ "");
     let (empty_stmts, x_empty) = generate g x empty in
     if x_empty <> x then
       fail (H 7098) p ("the {% else %} of this {% for %} ends in a different place in the HTML than it begins");
     let span = span_at p in
     let incr (q: qident) = AAssign (span, Path (q, []), ArithmeticExpression (Add, Variable q, IntConstant "1")) in
     let element = ALetTmp (item_t, call (tq "element") [Variable seq_q; Variable at_q]) in
     let (loop, count_stmts) =
       match cond with
       | None ->
          (AWhile (span, Comparison (LessThan, Variable at_q, Variable all_q),
                   block ([element] @ head_binds @ body_stmts @ [incr counter_q; incr at_q])),
           [ALetTmp (total_t, Variable all_q)])
       | Some c ->
          (* Jinja2 counts only the elements the condition lets through:
             loop.index, loop.length and loop.last are theirs.  So the
             elements are counted first, then walked. *)
          (* The counting pass has an element variable of its own: a name is
             declared once in a function. *)
          let counted_t = fresh_ident () in
          let counted_q = local g counted_t in
          let (filter_binds, g_filter) = name_binds counted_q g g.loops in
          let c_count = condition { g_filter with in_branch = false } c in
          let c_walk = condition { g_body0 with in_branch = false } c in
          (AWhile (span, Comparison (LessThan, Variable at_q, Variable all_q),
                   block ([element] @ head_binds
                          @ [AIf (span, c_walk, block (body_stmts @ [incr counter_q]), ASkip span); incr at_q])),
           [ALetTmp (total_t, call (tq "zero") []);
            AWhile (span, Comparison (LessThan, Variable at_q, Variable all_q),
                    block ([ALetTmp (counted_t, call (tq "element") [Variable seq_q; Variable at_q])] @ filter_binds
                           @ [AIf (span, c_count, incr total_q, ASkip span); incr at_q]));
            AAssign (span, Path (at_q, []), call (tq "zero") [])])
     in
     let head = [
         ALetTmp (seq_t, ref_of_path g p path);
         ALetTmp (all_t, call (tq "count") [Variable seq_q]);
         ALetTmp (at_t, call (tq "zero") []);
         ALetTmp (counter_t, call (tq "zero") []);
       ] @ count_stmts
     in
     let body_stmt =
       if empty = [] then loop
       else AIf (span, Comparison (Equal, Variable total_q, IntConstant "0"), block empty_stmts, loop)
     in
     ([block (head @ [body_stmt])], x)

(* ---------------------------------------------------------------------- *)
(* The statement                                                           *)
(* ---------------------------------------------------------------------- *)

let expand (im: import_map) (span: span) (name: string) (options: string list) (data: identifier) (out: identifier): astmt =
  let Span { filename; startp = Position { line; column }; _ } = span in
  let here = { file = filename; line; col = column } in
  if not (ModuleNameSet.mem (make_mod_name "Standard.Template") (modules_imported_from im)) then
    fail (H 7099) here "a module that uses @template imports Standard.Template -- e.g. `import Standard.Template (Render);' -- because the generated code calls it, and its instances come with the import";
  List.iter
    (fun o ->
      if o <> "trim_blocks" && o <> "lstrip_blocks" then
        fail (H 7114) here ("\"" ^ o ^ "\": @template knows the options trim_blocks and lstrip_blocks"))
    options;
  let root = Filename.dirname filename in
  let r = { root; loaded = []; macros = []; used_blocks = []; defined_blocks = []; spaces = [];
            trim_blocks = List.mem "trim_blocks" options; lstrip_blocks = List.mem "lstrip_blocks" options } in
  let nodes = resolve_all r here name in
  let g = {
      im;
      data = qualify_identifier im data;
      out = qualify_identifier im out;
      vars = [];
      loops = [];
      narrowed = [];
      macros = r.macros;
      calling = [];
      sees_data = true;
      space = "";
      caller = None;
      in_branch = false;
      catalog = None;
    }
  in
  let (stmts, _) = generate g XText nodes in
  block stmts
