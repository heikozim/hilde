(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* hilde fmt: the one form of a Hilde source file.  The text is cut into
   logical lines of tokens -- a string or docstring that runs over several
   lines belongs to the line it starts on -- with the comment that ends a
   line kept.  Each line is indented by the blocks it stands in and the
   brackets left open before it, and its tokens are joined by the spacing
   their kinds ask for.  Line breaks are the author's; runs of blank lines
   become one.  The result is lexed again by the compiler's lexer, and a
   token stream that differs from the one of the source is refused, so the
   formatter cannot change what a programme means. *)

open Error
open ErrorText

type kind =
  | Word
  | Number
  | Str
  | Triple
  | Chr
  | Op
  | Opening
  | Closing

type token = { text: string; kind: kind }

(* A logical line: its tokens, the comment that ends it, and where its first
   token stood in the source. *)
type line = { tokens: token list; comment: string option; column: int }

let keywords: string list = [
    "and"; "as"; "body"; "borrow"; "case"; "constant"; "do"; "else"; "end";
    "for"; "from"; "function"; "generic"; "if"; "import"; "instance"; "is";
    "let"; "method"; "module"; "not"; "of"; "or"; "pragma"; "raise";
    "raises"; "record"; "return"; "skip"; "then"; "to"; "typeclass"; "union";
    "var"; "when"; "while"; "requires"; "ensures"; "invariant"
  ]

let operators: string list = [
    "&!("; "&!"; "&("; "&~"; "/="; "<="; ">="; "->"; "=>"; ":="; "..";
    "&"; "+"; "-"; "*"; "/"; "="; "<"; ">"; ";"; ","; "."; "|"; ":"; "!"; "?"
  ]

let is_alpha (c: char): bool = ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z'))
let is_digit (c: char): bool = (c >= '0') && (c <= '9')
let is_word_char (c: char): bool = (is_alpha c) || (is_digit c) || (c = '_')

let starts_with (s: string) (i: int) (p: string): bool =
  let n = String.length p in
  (i + n <= String.length s) && (String.sub s i n = p)

(* --- Reading -------------------------------------------------------------- *)

let refuse (path: string) (what: string): 'a =
  internal_raise [Text ("hilde fmt cannot read " ^ path ^ ": " ^ what)]

(* The logical lines of a source.  A blank line is a line without tokens and
   without a comment. *)
let read_lines (path: string) (s: string): line list =
  let n = String.length s in
  let lines = ref [] in
  let tokens = ref [] in
  let column = ref (-1) in
  let line_start = ref 0 in
  let finish (comment: string option) =
    lines := { tokens = List.rev !tokens; comment; column = !column } :: !lines;
    tokens := [];
    column := -1
  in
  let add (text: string) (kind: kind) (at: int) =
    if !column < 0 then column := at - !line_start;
    tokens := { text; kind } :: !tokens
  in
  (* The end of a string literal that starts at i, a quote. *)
  let rec string_end (j: int): int =
    if j >= n then refuse path "a string runs to the end of the file"
    else if s.[j] = '\\' && j + 1 < n then string_end (j + 2)
    else if s.[j] = '"' then j + 1
    else string_end (j + 1)
  in
  let rec triple_end (j: int): int =
    if j + 2 >= n then refuse path "a docstring runs to the end of the file"
    else if s.[j] = '\\' && starts_with s (j + 1) "\"\"\"" then triple_end (j + 4)
    else if starts_with s j "\"\"\"" then j + 3
    else triple_end (j + 1)
  in
  let number_end (j: int): int =
    (* Digits, apostrophes, letters of a hexadecimal or binary literal, a
       point with digits after it and an exponent; not the .. of a range. *)
    let rec go (k: int): int =
      if k >= n then k
      else if is_word_char s.[k] || s.[k] = '\'' then go (k + 1)
      else if s.[k] = '.' && k + 1 < n && is_digit s.[k + 1] then go (k + 1)
      else if (s.[k] = '-' || s.[k] = '+') && k > 0 && (s.[k - 1] = 'e' || s.[k - 1] = 'E')
              && k + 1 < n && is_digit s.[k + 1] && not (starts_with s j "#x") then go (k + 1)
      else k
    in
    go j
  in
  let rec scan (i: int) =
    if i >= n then (if !tokens <> [] then finish None)
    else
      let c = s.[i] in
      if c = '\n' then begin
        finish None;
        line_start := i + 1;
        scan (i + 1)
      end else if c = ' ' || c = '\t' || c = '\r' then scan (i + 1)
      else if starts_with s i "--" then begin
        let j = (match String.index_from_opt s i '\n' with Some j -> j | None -> n) in
        let text = String.sub s i (j - i) in
        let text = (* trailing blanks of the comment *)
          let k = ref (String.length text) in
          while !k > 0 && (text.[!k - 1] = ' ' || text.[!k - 1] = '\t' || text.[!k - 1] = '\r') do decr k done;
          String.sub text 0 !k
        in
        if !column < 0 then column := i - !line_start;
        finish (Some text);
        line_start := j + 1;
        scan (j + 1)
      end else if starts_with s i "\"\"\"" then begin
        let j = triple_end (i + 3) in
        add (String.sub s i (j - i)) Triple i;
        scan j
      end else if c = '"' then begin
        let j = string_end (i + 1) in
        add (String.sub s i (j - i)) Str i;
        scan j
      end else if c = '\'' then begin
        (* A character literal: one character or an escape. *)
        let j = if i + 1 < n && s.[i + 1] = '\\' then i + 4 else i + 3 in
        if j > n || s.[j - 1] <> '\'' then refuse path "a character literal is not closed";
        add (String.sub s i (j - i)) Chr i;
        scan j
      end else if is_digit c || (c = '#' && i + 1 < n && is_alpha s.[i + 1])
              || ((c = '-' || c = '+') && i + 1 < n && is_digit s.[i + 1]) then begin
        let j = number_end (i + 1) in
        add (String.sub s i (j - i)) Number i;
        scan j
      end else if is_alpha c || c = '_' || c = '@' then begin
        let j = ref (i + 1) in
        while !j < n && is_word_char s.[!j] do incr j done;
        (* Span! is one token: the type of a span to write through. *)
        if String.sub s i (!j - i) = "Span" && !j < n && s.[!j] = '!' then incr j;
        add (String.sub s i (!j - i)) Word i;
        scan !j
      end else if c = '(' || c = '[' || c = '{' then begin
        add (String.make 1 c) Opening i;
        scan (i + 1)
      end else if c = ')' || c = ']' || c = '}' then begin
        add (String.make 1 c) Closing i;
        scan (i + 1)
      end else
        match List.find_opt (fun op -> starts_with s i op) operators with
        | Some op ->
           add op (if op = "&!(" || op = "&(" then Opening else Op) i;
           scan (i + String.length op)
        | None -> refuse path (Printf.sprintf "the character %C" c)
  in
  scan 0;
  List.rev !lines

(* --- Spacing ------------------------------------------------------------- *)

let is_keyword (t: token): bool = (t.kind = Word) && (List.mem t.text keywords)

(* Whether a minus or plus is the sign of the operand after it: it stands
   at the start of an expression. *)
let is_prefix_sign (before: token option): bool =
  match before with
  | None -> true
  | Some b ->
     (b.kind = Opening) || (b.kind = Op && b.text <> ")") || (is_keyword b && b.text <> "end")

let space (before: token option) (p: token) (c: token): string =
  if p.text = "{" && c.text = "}" then ""
  else if c.text = "}" || p.text = "{" then " "
  else if c.kind = Closing then ""
  else if c.text = ":" then
    (* After a literal the colon is a cast, 5 : Int64; after a name or a
       bracket it declares, count: Index. *)
    (if List.mem p.kind [Number; Str; Chr] then " " else "")
  else if List.mem c.text [","; ";"; "?"; "."; "->"] then ""
  else if List.mem p.text ["."; "->"] then ""
  else if p.kind = Opening then ""
  else if (c.text = "(" || c.text = "[") && not (is_keyword p)
          && (p.kind = Word || p.kind = Closing) then ""
  else if p.text = "&" then
    (* A borrow: glued to its operand, unless the two would make another
       token, &( &! or &~. *)
    (if c.text = "(" || c.text = "!" || c.text = "~" || c.text = "!(" then " " else "")
  else if p.text = "&!" then
    (if c.text = "(" then " " else "")
  else if List.mem p.text ["&~"; "!"] then ""
  else if (p.text = "-" || p.text = "+") && is_prefix_sign before then
    (* A sign glued to a number would make a literal of the two. *)
    (if c.kind = Number then " " else "")
  else " "

let join (tokens: token list): string =
  let b = Buffer.create 80 in
  (* The list of an import stands apart from the module's name. *)
  let import = (match tokens with t :: _ -> t.text = "import" | [] -> false) in
  let rec go (before: token option) (prev: token option) (rest: token list) =
    match rest with
    | [] -> ()
    | t :: more ->
       (match prev with
        | Some p ->
           Buffer.add_string b
             (if import && t.text = "(" && p.kind = Word then " " else space before p t)
        | None -> ());
       Buffer.add_string b t.text;
       go prev (Some t) more
  in
  go None None tokens;
  Buffer.contents b

(* --- Indentation ----------------------------------------------------------- *)

(* UnionCase: the slots of a case of a union, which the next case or the
   end of the union closes. *)
type frame = Block | Case | WhenBody | UnionCase

let openers: string list = ["is"; "then"; "else"; "do"; "of"]

(* What ends a statement: a line after one of these is no continuation. *)
let terminal: string list = [";"; "is"; "then"; "else"; "do"; "of"; "."]

let first_text (l: line): string = match l.tokens with t :: _ -> t.text | [] -> ""

let last_text (l: line): string =
  match List.rev l.tokens with t :: _ -> t.text | [] -> ""

let leading_closers (l: line): int =
  let rec go (ts: token list) (k: int): int =
    match ts with
    | t :: rest when t.kind = Closing -> go rest (k + 1)
    | _ -> k
  in
  go l.tokens 0

let blanks (k: int): string = String.make (4 * k) ' '

(* A docstring keeps its own indentation unless moving every line of it
   with its first leaves what the compiler makes of it unchanged. *)
let shift_triple (text: string) (delta: int): string =
  if delta = 0 then text
  else
    let lines = String.split_on_char '\n' text in
    match lines with
    | [] | [_] -> text
    | first :: rest ->
       let moved =
         List.map
           (fun l ->
             if l = "" then l
             else if delta > 0 then (String.make delta ' ') ^ l
             else
               let k = ref 0 in
               while !k < (- delta) && !k < String.length l && l.[!k] = ' ' do incr k done;
               if !k = (- delta) then String.sub l !k (String.length l - !k) else l)
           rest
       in
       let candidate = String.concat "\n" (first :: moved) in
       let body (t: string): string = String.sub t 3 (String.length t - 6) in
       if Util.process_triple_string (body candidate) = Util.process_triple_string (body text)
       then candidate else text

let format_lines (lines: line list): string =
  let out = Buffer.create 4096 in
  let frames: frame list ref = ref [] in
  (* One entry per line that left brackets open: how many of its brackets
     are still open.  Each entry is a level of indentation. *)
  let open_lines: int list ref = ref [] in
  let close (k: int) (stack: int list): int list =
    let rec go (k: int) (stack: int list): int list =
      if k <= 0 then stack
      else
        match stack with
        | c :: rest -> if k >= c then go (k - c) rest else (c - k) :: rest
        | [] -> []
    in
    go k stack
  in
  let continued = ref false in
  let pending_blank = ref false in
  let started = ref false in
  let just_opened = ref false in
  (* For every line, the first token of the next line with code. *)
  let next_code: string array =
    let a = Array.of_list lines in
    let n = Array.length a in
    let out = Array.make n "" in
    let following = ref "" in
    for i = n - 1 downto 0 do
      out.(i) <- !following;
      (match a.(i).tokens with
       | [t] when t.kind = Triple -> ()
       | t :: _ -> following := t.text
       | [] -> ())
    done;
    out
  in
  let index = ref (-1) in
  let emit_line (l: line) =
    incr index;
    let first = first_text l in
    (* A docstring or comment before the next case of a union, or before
       its end, stands with the cases and not with the slots. *)
    let before_case =
      (match l.tokens with [t] -> t.kind = Triple | [] -> l.comment <> None | _ -> false)
      && (match !frames with UnionCase :: _ -> true | _ -> false)
      && List.mem next_code.(!index) ["case"; "end"]
    in
    (* The blocks this line closes before it is written. *)
    (match first with
     | "end" ->
        (match !frames with
         | WhenBody :: Case :: rest -> frames := rest
         | UnionCase :: _ :: rest -> frames := rest
         | _ :: rest -> frames := rest
         | [] -> ())
     | "case" ->
        (match !frames with UnionCase :: rest -> frames := rest | _ -> ())
     | "else" ->
        (match !frames with _ :: rest -> frames := rest | [] -> ())
     | "when" ->
        (match !frames with WhenBody :: rest -> frames := rest | _ -> ())
     | _ -> ());
    let closers = leading_closers l in
    let depth = List.length (close closers !open_lines) in
    let level =
      (List.length !frames) + depth - (if before_case then 1 else 0)
      + (if !continued && !open_lines = [] && first <> "is" then 1 else 0)
    in
    if l.tokens = [] && l.comment = None then
      (if !started && not !just_opened then pending_blank := true)
    else begin
      if !pending_blank && first <> "end" && first <> "else" then Buffer.add_char out '\n';
      pending_blank := false;
      started := true;
      let code =
        match l.tokens with
        | [t] when t.kind = Triple -> shift_triple t.text ((4 * level) - l.column)
        | _ -> join l.tokens
      in
      let text =
        match (code, l.comment) with
        | ("", Some c) -> c
        | (_, Some c) -> code ^ " " ^ c
        | (_, None) -> code
      in
      Buffer.add_string out (blanks level);
      Buffer.add_string out text;
      Buffer.add_char out '\n';
      (* What the line opens. *)
      let last = last_text l in
      just_opened := false;
      if l.tokens <> [] then begin
        (* Token by token: a closing bracket closes one this line opened,
           or else one of an earlier line. *)
        let own = ref 0 in
        List.iter
          (fun t ->
            if t.kind = Opening then incr own
            else if t.kind = Closing then
              (if !own > 0 then decr own else open_lines := close 1 !open_lines))
          l.tokens;
        if !own > 0 then open_lines := !own :: !open_lines;
        if List.mem last openers && !open_lines = [] then begin
          let frame =
            if last = "of" then Case
            else if first = "when" then WhenBody
            else if first = "case" then UnionCase
            else Block
          in
          frames := frame :: !frames;
          just_opened := true
        end;
        let generic_line = (first = "generic") || (first = "pragma") in
        let docstring = (match l.tokens with [t] -> t.kind = Triple | _ -> false) in
        continued := (!open_lines = []) && not (List.mem last terminal) && not generic_line && not docstring
      end
    end
  in
  List.iter emit_line lines;
  Buffer.contents out

(* --- The check ------------------------------------------------------------- *)

(* The tokens of the compiler's lexer, with a range written as one token
   counted as its number and two points, as the parser takes both, and a
   docstring as the text the compiler makes of it. *)
let lexed (path: string) (s: string): Parser.token list =
  let lexbuf = Lexing.from_string s in
  Lexing.set_filename lexbuf path;
  let rec go (acc: Parser.token list) =
    match Lexer.token lexbuf with
    | Parser.EOF -> List.rev acc
    | Parser.RANGE_START low -> go (Parser.DOTDOT :: Parser.DEC_CONSTANT low :: acc)
    | Parser.TRIPLE_STRING_CONSTANT t -> go (Parser.TRIPLE_STRING_CONSTANT (Util.process_triple_string t) :: acc)
    | t -> go (t :: acc)
  in
  go []

(** The formatted text of a source.  Raises an internal error when the
    result would lex to other tokens than the source. *)
let format (path: string) (source: string): string =
  let result = format_lines (read_lines path source) in
  if lexed path result <> lexed path source then
    internal_raise [Text ("hilde fmt would change the tokens of " ^ path ^ "; the file is left as it is")]
  else
    result

(* --- The command ----------------------------------------------------------- *)

let read_file (path: string): string =
  match open_in_bin path with
  | exception Sys_error message ->
     Util.read_error path message
  | ic ->
     (try
        let n = in_channel_length ic in
        let s = really_input_string ic n in
        close_in ic;
        s
      with Sys_error message ->
        close_in_noerr ic;
        Util.read_error path message)

let write_file (path: string) (s: string): unit =
  Util.write_string_to_file path s

let is_source (path: string): bool =
  (Filename.check_suffix path ".hiq") || (Filename.check_suffix path ".hih")

(* The Hilde sources of a path: the file itself, or every .hih and .hiq file
   below a directory, in the order of their names. *)
let rec sources_of (path: string): string list =
  if Sys.file_exists path && Sys.is_directory path then
    let names = Array.to_list (Sys.readdir path) in
    let names = List.sort compare names in
    List.concat_map (fun n -> if n <> "" && n.[0] = '.' then [] else sources_of (Filename.concat path n)) names
  else if is_source path && Sys.file_exists path then [path]
  else if Sys.file_exists path then []
  else
    hilde_raise (H 1033) CliError [
        Text "hilde fmt: ";
        Code path;
        Text " is neither a directory nor a .hih or .hiq file."
      ]

(** hilde fmt: every source of the paths in its one form, written back, or
    with check only named when it is not in that form.  A file that cannot
    be read or would change its tokens is named on standard error with the
    reason and left as it is.  Returns the number of files not in the form,
    the number of files read and the number that could not be formatted. *)
let run ~(check: bool) (paths: string list): int * int * int =
  let files = List.concat_map sources_of paths in
  let differing = ref 0 and failed = ref 0 in
  List.iter
    (fun f ->
      try
        let source = read_file f in
        let result = format f source in
        if result <> source then begin
          incr differing;
          if check then print_endline f else write_file f result
        end
      with Hilde_error e ->
        incr failed;
        let (HildeError { text; _ }) = e in
        prerr_endline (f ^ ": " ^ (error_text_to_plain text)))
    files;
  (!differing, List.length files, !failed)
