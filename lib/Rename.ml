(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* hilde rename: variables, parameters and constants to snake_case, and
   functions and methods with an underscore to camelCase; digits stay, so
   sha3_256 and hmacSha3_512 keep their form.  Types, type classes, modules
   and slots keep their names, also a slot named in a pattern.

   The work is done on the compiler's own tokens, so a string, a comment or a
   name inside another name is never touched by accident.  Each declaration is
   read for the names it binds, and a bare name then resolves to one of them,
   to a constant or function the file declares or imports, or to something
   that stays.  A slot and a function may share a name, so a name after a
   period stays: the receiver decides what it means.  Tokens and not the
   syntax tree: a test that is meant not to parse has variables too.

   A collision, or a new name that the lexer does not read as a name, ends the
   run with a list and writes nothing.

   The plan names every declaration and every use as file:line:column, so
   --apply --from applies a saved plan to exactly these positions, and
   --compare shows every token difference between two files that the plan
   does not name.  In a Markdown file a position is relative to the fenced
   block and carries the block: file#block:line:column. *)

open Parser

type token = { tok: Parser.token; start: int; stop: int; text: string }

type kind = Variable | Parameter | Constant | Function

let kind_name (k: kind): string =
  match k with
  | Variable -> "variable"
  | Parameter -> "parameter"
  | Constant -> "constant"
  | Function -> "function"

let snake (name: string): string =
  let n = String.length name in
  let out = Buffer.create (n + 4) in
  let is_upper c = (c >= 'A') && (c <= 'Z') in
  let is_lower c = (c >= 'a') && (c <= 'z') in
  let is_digit c = (c >= '0') && (c <= '9') in
  String.iteri (fun i c ->
      if is_upper c then begin
        if i > 0 then begin
          let p = name.[i - 1] in
          let starts_word =
            is_lower p || is_digit p
            || (is_upper p && (i + 1 < n) && is_lower name.[i + 1])
          in
          if starts_word then Buffer.add_char out '_'
        end;
        Buffer.add_char out (Char.lowercase_ascii c)
      end else
        Buffer.add_char out c) name;
  Buffer.contents out

(* The camelCase form of a function name: every underscore before a segment
   that begins with a letter goes away and that letter becomes a capital, the
   first letter becomes small.  An underscore before a segment that begins
   with a digit stays, with the segment as it is. *)
let camel (name: string): string =
  match String.split_on_char '_' name with
  | [] | [_] -> name
  | first :: rest ->
     let capital segment =
       if segment = "" then ""
       else if (segment.[0] >= '0') && (segment.[0] <= '9') then "_" ^ segment
       else
         let c = segment.[0] in
         let up = if (c >= 'a') && (c <= 'z') then Char.uppercase_ascii c else c in
         String.make 1 up ^ String.sub segment 1 (String.length segment - 1)
     in
     let small s =
       if (s <> "") && (s.[0] >= 'A') && (s.[0] <= 'Z') then
         String.make 1 (Char.lowercase_ascii s.[0])
         ^ String.sub s 1 (String.length s - 1)
       else s
     in
     small first ^ String.concat "" (List.map capital rest)

(* The form a name of the kind takes. *)
let style (k: kind) (name: string): string =
  match k with Function -> camel name | _ -> snake name

let lex (src: string): token array option =
  let lb = Lexing.from_string src in
  let rec go acc =
    let tok = Lexer.token lb in
    match tok with
    | EOF -> List.rev acc
    | _ ->
       let t = {
           tok;
           start = Lexing.lexeme_start lb;
           stop = Lexing.lexeme_end lb;
           text = Lexing.lexeme lb;
         } in
       go (t :: acc)
  in
  try Some (Array.of_list (go [])) with _ -> None

let reads_as_name (s: string): bool =
  match lex s with
  | Some [| { tok = IDENTIFIER _; _ } |] -> true
  | _ -> false

let is_ident (t: token): bool =
  match t.tok with IDENTIFIER _ -> true | _ -> false

(* The same token kind: the carried text of an identifier or a string
   constant is not part of the kind, so two identifiers compare the same
   whatever their spelling. *)
let same_tok (a: Parser.token) (b: Parser.token): bool =
  match (a, b) with
  | IDENTIFIER _, IDENTIFIER _ -> true
  | STRING_CONSTANT _, STRING_CONSTANT _ -> true
  | TRIPLE_STRING_CONSTANT _, TRIPLE_STRING_CONSTANT _ -> true
  | _ -> a = b

let starts_segment (t: Parser.token): bool =
  match t with
  | FUNCTION | METHOD | RECORD | UNION | TYPECLASS | INSTANCE | CONSTANT
  | IMPORT | PRAGMA | GENERIC | TYPE -> true
  | _ -> false

(* What the whole set of files declares.  A module may exist several times
   under one name in a tree of test programmes, so the table is by directory
   first and by module name after that. *)
type tables = {
    by_dir: (string * string, string list) Hashtbl.t;
    by_module: (string, string list) Hashtbl.t;
    callables: (string, unit) Hashtbl.t;
  }

let fresh_tables (): tables = {
    by_dir = Hashtbl.create 1;
    by_module = Hashtbl.create 1;
    callables = Hashtbl.create 16;
  }

let read_file (path: string): string =
  let ic = open_in_bin path in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let write_file (path: string) (s: string): unit =
  let oc = open_out_bin path in
  output_string oc s;
  close_out oc

(* The dotted name that starts at index i, and the index after it. *)
let dotted (toks: token array) (i: int): string * int =
  let n = Array.length toks in
  let rec go j acc =
    if j < n && is_ident toks.(j) then
      let acc = toks.(j).text :: acc in
      if j + 1 < n && toks.(j + 1).tok = PERIOD then go (j + 2) acc
      else (String.concat "." (List.rev acc), j + 1)
    else (String.concat "." (List.rev acc), j)
  in
  go i []

let scan_tables (tables: tables) (path: string) (toks: token array): unit =
  let n = Array.length toks in
  let constants = ref [] and modname = ref "" in
  Array.iteri (fun i t ->
      match t.tok with
      | CONSTANT when i + 1 < n -> constants := toks.(i + 1).text :: !constants
      | (FUNCTION | METHOD) when i + 1 < n -> Hashtbl.replace tables.callables toks.(i + 1).text ()
      | MODULE when !modname = "" && i + 1 < n ->
         let j = if toks.(i + 1).tok = BODY then i + 2 else i + 1 in
         modname := fst (dotted toks j)
      | _ -> ()) toks;
  if !modname <> "" then begin
    let add tbl key =
      let old = Option.value (Hashtbl.find_opt tbl key) ~default:[] in
      Hashtbl.replace tbl key (!constants @ old)
    in
    add tables.by_dir (Filename.dirname path, !modname);
    add tables.by_module !modname
  end

let constants_of (tables: tables) (dir: string) (m: string): string list =
  match Hashtbl.find_opt tables.by_dir (dir, m) with
  | Some l -> l
  | None -> Option.value (Hashtbl.find_opt tables.by_module m) ~default:[]

(* The modules a run is given but does not rename (--modules): what they
   declare is known to an importer, so an import of one of their constants or
   functions is renamed with the module of the importer. *)
let scan_module_roots (tables: tables) (files: string list): unit =
  List.iter (fun f ->
      match lex (read_file f) with
      | Some toks -> scan_tables tables f toks
      | None -> ()) files

(* The line and column of a byte offset: the offsets where the lines of the
   source begin, and the last one at or before the offset. *)
let line_starts (src: string): int array =
  let rec go i acc =
    if i >= String.length src then Array.of_list (0 :: List.rev acc)
    else if src.[i] = '\n' then go (i + 1) (i + 1 :: acc)
    else go (i + 1) acc
  in
  go 0 []

let linecol (starts: int array) (off: int): int * int =
  let rec go lo hi =
    if hi - lo <= 1 then lo
    else
      let mid = (lo + hi) / 2 in
      if starts.(mid) <= off then go mid hi else go lo mid
  in
  let idx = go 0 (Array.length starts) in
  (idx + 1, off - starts.(idx) + 1)

type occurrence = {
    index: int;
    o_old: string;
    o_new: string;
    o_kind: kind;
    o_decl: bool;
  }

type result = {
    edits: (int * int * string) list;
    kept: (string, unit) Hashtbl.t;
    occurrences: occurrence list;
    expansions: (int * string * string) list;
    collisions: string list;
  }

(* Reads the bindings of a destructuring or of a case from index i, which
   stands after the opening token, up to the closing one at depth 0.  Marks
   the binders and the slots written as shorthand.  The slot named before as
   is a slot and stays as it is, so it is handed to keep and never resolved
   as a name of its own; only the variable behind as is a binder. *)
let scan_bindings (toks: token array) (i: int) (closer: Parser.token)
    (mark: int -> unit) (shorthand: int -> unit) (keep: int -> unit): int =
  let n = Array.length toks in
  let rec skip_type j depth =
    if j >= n then j
    else match toks.(j).tok with
         | LBRACKET -> skip_type (j + 1) (depth + 1)
         | RBRACKET -> skip_type (j + 1) (depth - 1)
         | COMMA | RPAREN | RCURLY when depth = 0 -> j
         | _ -> skip_type (j + 1) depth
  in
  let rec go j depth =
    if j >= n then j
    else
      let t = toks.(j) in
      if t.tok = closer && depth = 0 then j
      else if t.tok = LPAREN then go (j + 1) (depth + 1)
      else if t.tok = RPAREN then go (j + 1) (depth - 1)
      else if is_ident t then begin
        let next = if j + 1 < n then toks.(j + 1).tok else EOF in
        match next with
        | COLON -> shorthand j; go (skip_type (j + 2) 0) depth
        | AS ->
           keep j;
           if j + 2 < n then mark (j + 2);
           go (skip_type (j + 4) 0) depth
        | LPAREN -> go (j + 1) depth
        | _ ->
           let c = t.text.[0] in
           if (c >= 'a') && (c <= 'z') then mark j;
           go (j + 1) depth
      end
      else go (j + 1) depth
  in
  go i 0

let process (tables: tables) (path: string) (toks: token array): result =
  let n = Array.length toks in
  let dir = Filename.dirname path in
  let tok i = if i >= 0 && i < n then toks.(i).tok else EOF in
  (* The constants and functions the file sees: its own and those it imports.
     The kind decides the form a bare use takes. *)
  let visible = Hashtbl.create 16 in
  let own_module =
    let rec find i =
      if i >= n then ""
      else if toks.(i).tok = MODULE then
        fst (dotted toks (if tok (i + 1) = BODY then i + 2 else i + 1))
      else find (i + 1)
    in
    find 0
  in
  List.iter (fun c -> Hashtbl.replace visible c Constant)
    (constants_of tables dir own_module);
  (* Marks by token index: the new name is given by the name itself. *)
  let renames: (int, kind) Hashtbl.t = Hashtbl.create 64 in
  let decls: (int, unit) Hashtbl.t = Hashtbl.create 32 in
  let expand: (int, unit) Hashtbl.t = Hashtbl.create 8 in
  let collisions = ref [] in
  (* Imports first, a constant may be used before any segment reads it. *)
  Array.iteri (fun i t ->
      if t.tok = IMPORT then begin
        let (m, j) = dotted toks (i + 1) in
        let known = constants_of tables dir m in
        let rec go j =
          if j < n && tok j <> RPAREN then begin
            if is_ident toks.(j) then begin
              let name = toks.(j).text in
              let nick = if tok (j + 1) = AS then Some (j + 2) else None in
              (* A module read with the module roots may carry the new form
                 already, so a name is held against what the module declares
                 in that form.  A name with a capital is a type and stays. *)
              let lower = name <> "" && (let c = name.[0] in (c >= 'a') && (c <= 'z')) in
              let kind =
                if List.mem name known then Some Constant
                else if lower && List.mem (snake name) known then Some Constant
                else if Hashtbl.mem tables.callables name then Some Function
                else if lower && Hashtbl.mem tables.callables (camel name) then Some Function
                else None
              in
              (match kind with
               | Some k ->
                  Hashtbl.replace renames j k;
                  (match nick with
                   | Some k2 ->
                      Hashtbl.replace renames k2 k;
                      Hashtbl.replace decls k2 ();
                      Hashtbl.replace visible toks.(k2).text k
                   | None -> Hashtbl.replace visible name k)
               | None -> ());
              go (match nick with Some k2 -> k2 + 1 | None -> j + 1)
            end else go (j + 1)
          end
        in
        go (j + 1)
      end) toks;
  let segment lo hi =
    let head = if lo < n then tok lo else EOF in
    let binders = Hashtbl.create 16 in
    let slot_keep = Hashtbl.create 8 in
    let bind j kind =
      Hashtbl.replace binders toks.(j).text kind;
      Hashtbl.replace renames j kind;
      Hashtbl.replace decls j ()
    in
    let is_code = match head with
      | IMPORT | PRAGMA | RECORD | UNION | TYPECLASS | INSTANCE | GENERIC | TYPE | CONSTANT -> false
      | _ -> true
    in
    if head = CONSTANT && lo + 1 < n then begin
      Hashtbl.replace renames (lo + 1) Constant;
      Hashtbl.replace decls (lo + 1) ()
    end;
    if (head = FUNCTION || head = METHOD) && tok (lo + 2) = LPAREN then begin
      let rec go j depth =
        if j < hi then
          match tok j with
          | LPAREN | LBRACKET -> go (j + 1) (depth + 1)
          | RBRACKET -> go (j + 1) (depth - 1)
          | RPAREN -> if depth > 1 then go (j + 1) (depth - 1)
          | IDENTIFIER _ when depth = 1 && tok (j + 1) = COLON ->
             bind j Parameter; go (j + 1) depth
          | _ -> go (j + 1) depth
      in
      go (lo + 3) 1
    end;
    if is_code then begin
      let mark j = bind j Variable in
      let shorthand j =
        Hashtbl.replace slot_keep j ();
        Hashtbl.replace expand j ();
        Hashtbl.replace binders toks.(j).text Variable
      in
      let keep j = Hashtbl.replace slot_keep j () in
      for j = lo to hi - 1 do
        match tok j with
        | LET | VAR ->
           if tok (j + 1) = LCURLY then
             ignore (scan_bindings toks (j + 2) RCURLY mark shorthand keep)
           else if is_ident toks.(j + 1) then mark (j + 1)
        | FOR | BORROW -> if j + 1 < n && is_ident toks.(j + 1) then mark (j + 1)
        | ELSE when tok (j + 2) = DO && j + 1 < n && is_ident toks.(j + 1) -> mark (j + 1)
        | WHEN ->
           let k = if j + 1 < n && is_ident toks.(j + 1) && tok (j + 2) = LPAREN then j + 3 else j + 1 in
           let closer = if k = j + 1 then DO else RPAREN in
           let stop = scan_bindings toks k closer mark shorthand keep in
           (* A pattern after the closing bracket: `A(x) | B(y) do'. *)
           if closer = RPAREN && tok (stop + 1) = BAR then
             ignore (scan_bindings toks (stop + 2) DO mark shorthand keep)
        | _ -> ()
      done
    end;
    (* Every other bare name in the segment. *)
    for j = lo to hi - 1 do
      if is_ident toks.(j) && not (Hashtbl.mem renames j) && not (Hashtbl.mem slot_keep j) then begin
        let t = toks.(j) in
        let prev = tok (j - 1) and next = tok (j + 1) in
        let is_slot_decl = (head = RECORD || head = UNION) && next = COLON in
        if head = IMPORT || head = PRAGMA || is_slot_decl
           || prev = PERIOD || prev = HYPHEN_RIGHT || prev = RAISE then ()
        else if prev = FUNCTION || prev = METHOD then begin
          (* The name a function or method declares. *)
          Hashtbl.replace renames j Function;
          Hashtbl.replace decls j ()
        end
        else if next = LPAREN then begin
          (* A call.  A name after a period stays: a slot and a function may
             share a name, and the receiver decides. *)
          if Hashtbl.mem tables.callables t.text then Hashtbl.replace renames j Function
        end
        else if next = RIGHT_ARROW then begin
          (* A named argument: a slot under a constructor, a parameter under a
             function.  Constructors are the names with a capital. *)
          let rec callee k depth =
            if k < lo then None
            else match tok k with
                 | RPAREN -> callee (k - 1) (depth + 1)
                 | LPAREN ->
                    if depth = 0 then
                      (if k > 0 && is_ident toks.(k - 1) then Some toks.(k - 1).text else None)
                    else callee (k - 1) (depth - 1)
                 | _ -> callee (k - 1) depth
          in
          match callee (j - 1) 0 with
          | Some c when (c.[0] >= 'a') && (c.[0] <= 'z') ->
             Hashtbl.replace renames j Parameter
          | _ -> ()
        end
        else
          match Hashtbl.find_opt binders t.text with
          | Some k -> Hashtbl.replace renames j k
          | None ->
             match Hashtbl.find_opt visible t.text with
             | Some k -> Hashtbl.replace renames j k
             | None ->
                if Hashtbl.mem tables.callables t.text then Hashtbl.replace renames j Function
      end
    done;
    (* A new name that something else in the segment already spells. *)
    let changes j =
      match Hashtbl.find_opt renames j with
      | Some k -> style k toks.(j).text <> toks.(j).text
      | None -> false
    in
    let others = Hashtbl.create 64 in
    for j = lo to hi - 1 do
      if is_ident toks.(j) && not (changes j) && not (Hashtbl.mem slot_keep j)
         && tok (j - 1) <> PERIOD && tok (j - 1) <> HYPHEN_RIGHT && tok (j + 1) <> RIGHT_ARROW then
        Hashtbl.replace others toks.(j).text ()
    done;
    let seen = Hashtbl.create 16 in
    for j = lo to hi - 1 do
      if Hashtbl.mem renames j || Hashtbl.mem expand j then begin
        let old = toks.(j).text in
        let nw = style (Option.value (Hashtbl.find_opt renames j) ~default:Variable) old in
        (match Hashtbl.find_opt seen nw with
         | Some o when o <> old ->
            collisions := Printf.sprintf "%s: %s and %s both become %s" path o old nw :: !collisions
         | _ -> Hashtbl.replace seen nw old);
        if old <> nw then begin
          if Hashtbl.mem others nw then
            collisions := Printf.sprintf "%s: %s -> %s, the name is taken" path old nw :: !collisions;
          if not (reads_as_name nw) then
            collisions := Printf.sprintf "%s: %s -> %s, not a name" path old nw :: !collisions
        end
      end
    done
  in
  let rec cut lo j =
    if j >= n then segment lo n
    else if starts_segment (tok j) && j > lo then (segment lo j; cut j (j + 1))
    else cut lo (j + 1)
  in
  cut 0 0;
  let kept = Hashtbl.create 64 in
  let edits = ref [] and occurrences = ref [] and expansions = ref [] in
  Array.iteri (fun j t ->
      if is_ident t then begin
        let kind_j = Hashtbl.find_opt renames j in
        let nw = style (Option.value kind_j ~default:Variable) t.text in
        if Hashtbl.mem expand j && nw <> t.text then begin
          edits := (t.start, t.stop, t.text ^ " as " ^ nw) :: !edits;
          expansions := (j, t.text, nw) :: !expansions
        end else
          match kind_j with
          | Some k when nw <> t.text ->
             edits := (t.start, t.stop, nw) :: !edits;
             occurrences := {
                 index = j;
                 o_old = t.text;
                 o_new = nw;
                 o_kind = k;
                 o_decl = Hashtbl.mem decls j;
               } :: !occurrences
          | _ -> Hashtbl.replace kept t.text ()
      end) toks;
  { edits = !edits; kept; occurrences = List.rev !occurrences;
    expansions = List.rev !expansions; collisions = !collisions }

let is_word_char (c: char): bool =
  ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c = '_')

(* Whole words of a comment or docstring, by the pairs given. *)
let rewrite_words (pairs: (string, string) Hashtbl.t) (s: string): string =
  let n = String.length s in
  let out = Buffer.create n in
  let rec go i =
    if i < n then
      if is_word_char s.[i] then begin
        let j = ref i in
        while !j < n && is_word_char s.[!j] do incr j done;
        let w = String.sub s i (!j - i) in
        Buffer.add_string out (Option.value (Hashtbl.find_opt pairs w) ~default:w);
        go !j
      end else begin
        Buffer.add_char out s.[i];
        go (i + 1)
      end
  in
  go 0;
  Buffer.contents out

(* The old and new names of a run that the words of its comments and
   docstrings follow. *)
let pairs_of (tables: tables) (r: result): (string, string) Hashtbl.t =
  let pairs = Hashtbl.create 16 in
  List.iter (fun oc ->
      if not (Hashtbl.mem r.kept oc.o_old) then
        match oc.o_kind with
        | Function -> Hashtbl.replace pairs oc.o_old oc.o_new
        | _ ->
           if not (Hashtbl.mem tables.callables oc.o_old) then
             Hashtbl.replace pairs oc.o_old oc.o_new)
    r.occurrences;
  pairs

(* The text with its edits made, and the comments and docstrings between the
   tokens brought along.  A string that is not a docstring stays as it is.
   blocks are (start, stop, text): a part of a docstring that is replaced by
   the given text instead of having its words rewritten.  extra are the pairs
   of the file around an example: a name the example does not rename follows
   them, as the words of the docstring do. *)
let apply_edits ?(extra: (string, string) Hashtbl.t = Hashtbl.create 1)
    ?(blocks: (int * int * string) list = [])
    (tables: tables) (src: string) (toks: token array) (r: result): string =
  let pairs = pairs_of tables r in
  Hashtbl.iter (fun k v -> if not (Hashtbl.mem pairs k) then Hashtbl.replace pairs k v) extra;
  let edits = Hashtbl.create 64 in
  List.iter (fun (s, e, t) -> Hashtbl.replace edits s (e, t)) r.edits;
  let out = Buffer.create (String.length src) in
  let pos = ref 0 in
  (* The words of src from a to b rewritten, a block inside replaced. *)
  let rewrite (a: int) (b: int): string =
    let buf = Buffer.create (b - a) in
    let at = ref a in
    List.iter (fun (s, e, text) ->
        if s >= !at && e <= b then begin
          Buffer.add_string buf (rewrite_words pairs (String.sub src !at (s - !at)));
          Buffer.add_string buf text;
          at := e
        end) blocks;
    Buffer.add_string buf (rewrite_words pairs (String.sub src !at (b - !at)));
    Buffer.contents buf
  in
  (* From pos to the end of the given token: white space and comments, and for
     a string token the string.  A plain string is copied, as its start is
     found by skipping the comments before it. *)
  let copy_gap upto plain =
    if plain then begin
      let i = ref !pos in
      let stop = ref false in
      while not !stop && !i < upto do
        if src.[!i] = '"' then stop := true
        else if !i + 1 < upto && src.[!i] = '-' && src.[!i + 1] = '-' then begin
          while !i < upto && src.[!i] <> '\n' do incr i done
        end else incr i
      done;
      Buffer.add_string out (rewrite !pos !i);
      Buffer.add_string out (String.sub src !i (upto - !i))
    end else
      Buffer.add_string out (rewrite !pos upto);
    pos := upto
  in
  Array.iter (fun t ->
      match t.tok with
      | STRING_CONSTANT _ -> copy_gap t.stop true
      | TRIPLE_STRING_CONSTANT _ -> copy_gap t.stop false
      | _ ->
         copy_gap t.start false;
         (match Hashtbl.find_opt edits t.start with
          | Some (e, nw) -> Buffer.add_string out nw; pos := e
          | None ->
             let text =
               match Hashtbl.find_opt extra t.text with
               | Some nw when is_ident t -> nw
               | _ -> t.text
             in
             Buffer.add_string out text; pos := t.stop)) toks;
  copy_gap (String.length src) false;
  Buffer.contents out

(* Fenced Hilde code of a Markdown file: (start, stop) of each block's text. *)
let markdown_blocks (src: string): (int * int) list =
  let lines = String.split_on_char '\n' src in
  let rec go pos ls inblock acc =
    match ls with
    | [] -> List.rev acc
    | l :: rest ->
       let next = pos + String.length l + 1 in
       let t = String.trim l in
       let is_fence = String.length t >= 3 && String.sub t 0 3 = "```" in
       (match inblock with
        | Some start when is_fence -> go next rest None ((start, pos) :: acc)
        | Some _ -> go next rest inblock acc
        | None ->
           if is_fence then begin
             let tag = String.sub t 3 (String.length t - 3) in
             let word = List.hd (String.split_on_char ' ' tag) in
             if word = "hilde" || word = "austral" then go next rest (Some next) acc
             else go next rest (Some (-1)) acc
           end else go next rest None acc)
  in
  List.filter (fun (s, _) -> s >= 0) (go 0 lines None [])

(* The examples in the docstrings of a source: (start, stop) of each run of
   lines indented four or more blanks deeper than the text of its docstring,
   blank lines inside a run included.  A line that holds the quotes of the
   docstring is never part of an example. *)
let docstring_blocks (src: string) (toks: token array): (int * int) list =
  let indent l =
    let n = String.length l in
    let rec go i = if i < n && l.[i] = ' ' then go (i + 1) else i in
    go 0
  in
  let blank l = String.trim l = "" in
  let has_quotes l =
    let n = String.length l in
    let rec go i = i + 2 < n && ((l.[i] = '"' && l.[i + 1] = '"' && l.[i + 2] = '"') || go (i + 1)) in
    go 0
  in
  let of_doc (t: token): (int * int) list =
    (* The lines of the docstring with their offsets, the quote lines out. *)
    let rec lines pos acc =
      if pos >= t.stop then List.rev acc
      else
        let e = match String.index_from_opt src pos '\n' with
          | Some e when e < t.stop -> e
          | _ -> t.stop
        in
        lines (e + 1) ((pos, e, String.sub src pos (e - pos)) :: acc)
    in
    (* The lexer reports the closing quotes as the start of the token, so
       the opening ones are found back from them; the text between holds no
       other three quotes. *)
    let close = t.stop - 3 in
    let rec opening i =
      if i < 0 then 0
      else if src.[i] = '"' && src.[i + 1] = '"' && src.[i + 2] = '"' then i
      else opening (i - 1)
    in
    let first = opening (close - 3) in
    let inner = List.filter (fun (_, _, l) -> not (has_quotes l)) (lines first []) in
    let texts = List.filter (fun (_, _, l) -> not (blank l)) inner in
    match texts with
    | [] -> []
    | _ ->
       let base = List.fold_left (fun m (_, _, l) -> min m (indent l)) max_int texts in
       let rec runs ls cur acc =
         match ls with
         | [] -> List.rev (match cur with Some r -> r :: acc | None -> acc)
         | (s, e, l) :: rest ->
            if blank l then
              (match cur with
               | Some (a, _) when List.exists (fun (_, _, l2) -> not (blank l2)) rest ->
                  runs rest (Some (a, e + 1)) acc
               | Some r -> runs rest None (r :: acc)
               | None -> runs rest None acc)
            else if indent l >= base + 4 then
              (match cur with
               | Some (a, _) -> runs rest (Some (a, e + 1)) acc
               | None -> runs rest (Some (s, e + 1)) acc)
            else
              (match cur with
               | Some r -> runs rest None (r :: acc)
               | None -> runs rest None acc)
       in
       (* A run never ends on a blank line: the stop is the end of its last
          line of code. *)
       List.map (fun (a, b) ->
           let rec back b = if b > a + 1 && src.[b - 2] = '\n' then back (b - 1) else b in
           (a, min (back b) t.stop))
         (runs inner None [])
  in
  List.concat_map (fun t ->
      match t.tok with TRIPLE_STRING_CONSTANT _ -> of_doc t | _ -> []) (Array.to_list toks)

(* The examples of a source with their tokens and their run, and the
   replacements apply_edits takes for them.  An example that does not lex is
   left to the words of its docstring and counted in skipped. *)
let docstring_units (tables: tables) (path: string) (src: string) (toks: token array)
    (skipped: int ref): (int * int * string * token array * result) list =
  List.filter_map (fun (s, e) ->
      let text = String.sub src s (e - s) in
      match lex text with
      | None -> incr skipped; None
      | Some btoks -> Some (s, e, text, btoks, process tables path btoks))
    (docstring_blocks src toks)

(* A source with its own edits and the edits of its examples made. *)
let apply_with_examples (tables: tables) (src: string) (toks: token array) (r: result)
    (units: (int * int * string * token array * result) list): string =
  let extra = pairs_of tables r in
  let blocks = List.map (fun (s, e, text, btoks, rb) ->
      (s, e, apply_edits ~extra tables text btoks rb)) units in
  apply_edits ~blocks tables src toks r

let rec walk (path: string) (acc: string list): string list =
  if Sys.is_directory path then
    Array.fold_left (fun acc e ->
        if e = "_build" || e = ".git" then acc
        else walk (Filename.concat path e) acc) acc (let a = Sys.readdir path in Array.sort compare a; a)
  else if List.exists (Filename.check_suffix path) [".hih"; ".hiq"; ".md"] then path :: acc
  else acc

(* One position of the plan.  In a Markdown file the position is relative to
   the fenced block, and p_block carries the number of the block. *)
type planned = {
    p_file: string;
    p_block: int option;
    p_line: int;
    p_col: int;
    p_old: string;
    p_new: string;
    p_kind: kind;
    p_decl: bool;
    p_expand: bool;
  }

(* The positions of one source: every declaration and every use the run
   renames or expands. *)
let planned_of (f: string) (block: int option) (src: string) (toks: token array) (r: result): planned list =
  let starts = line_starts src in
  let at j = linecol starts toks.(j).start in
  List.map (fun oc ->
      let (l, c) = at oc.index in
      { p_file = f; p_block = block; p_line = l; p_col = c;
        p_old = oc.o_old; p_new = oc.o_new; p_kind = oc.o_kind;
        p_decl = oc.o_decl; p_expand = false })
    r.occurrences
  @ List.map (fun (j, o, nw) ->
      let (l, c) = at j in
      { p_file = f; p_block = block; p_line = l; p_col = c;
        p_old = o; p_new = nw; p_kind = Variable; p_decl = true; p_expand = true })
    r.expansions

(* The plan of one source on its own, as --compare reads it without a plan
   file: the file is its own world. *)
let plan_of_text (path: string) (src: string): planned list * string list =
  match lex src with
  | None -> ([], [])
  | Some toks ->
     let tables = fresh_tables () in
     scan_tables tables path toks;
     let r = process tables path toks in
     let units = docstring_units tables path src toks (ref 0) in
     let examples = List.concat (List.mapi (fun i (_, _, text, btoks, rb) ->
         planned_of path (Some i) text btoks rb) units) in
     (planned_of path None src toks r @ examples,
      r.collisions @ List.concat_map (fun (_, _, _, _, rb) -> rb.collisions) units)

(* One source on its own: the new text and the collisions. *)
let rename_text (src: string): string * string list =
  let tables = fresh_tables () in
  match lex src with
  | None -> (src, ["not lexed"])
  | Some toks ->
     scan_tables tables "t.hiq" toks;
     let r = process tables "t.hiq" toks in
     let units = docstring_units tables "t.hiq" src toks (ref 0) in
     (apply_with_examples tables src toks r units,
      r.collisions @ List.concat_map (fun (_, _, _, _, rb) -> rb.collisions) units)

(* "file:line:column" or "file#block:line:column" back into its parts. *)
let split_pos (s: string): (string * int option * int * int) option =
  match String.rindex_opt s ':' with
  | None -> None
  | Some c1 ->
     match String.rindex_from_opt s (c1 - 1) ':' with
     | None -> None
     | Some c2 ->
        let head = String.sub s 0 c2 in
        let line = String.sub s (c2 + 1) (c1 - c2 - 1) in
        let col = String.sub s (c1 + 1) (String.length s - c1 - 1) in
        let (file, block) =
          match String.rindex_opt head '#' with
          | Some h ->
             (String.sub head 0 h,
              Some (int_of_string (String.sub head (h + 1) (String.length head - h - 1))))
          | None -> (head, None)
        in
        (try Some (file, block, int_of_string line, int_of_string col)
         with _ -> None)

(* A saved plan back into its positions.  The second list holds what did not
   read. *)
let load_plan (path: string): planned list * string list =
  let errors = ref [] in
  let json =
    try Yojson.Basic.from_file path
    with _ -> errors := "the plan file does not read" :: !errors; `Null
  in
  let str json name =
    match Yojson.Basic.Util.(member name json) with
    | `String s -> s
    | _ -> errors := ("the plan entry has no " ^ name) :: !errors; ""
  in
  let one_pos (q: planned) (decl: bool) (s: string): planned option =
    match split_pos s with
    | Some (f, b, l, c) -> Some { q with p_file = f; p_block = b; p_line = l; p_col = c; p_decl = decl }
    | None -> errors := ("the plan has a bad position: " ^ s) :: !errors; None
  in
  let positions (entry: Yojson.Basic.t) (q: planned) (name: string) (decl: bool): planned list =
    match Yojson.Basic.Util.(member name entry) with
    | `List l ->
       List.filter_map (fun p ->
           match p with
           | `String s -> one_pos q decl s
           | _ -> None) l
    | _ -> []
  in
  let one_entry (json: Yojson.Basic.t): planned list =
    let kind = match Yojson.Basic.Util.(member "kind" json) with
      | `String "variable" -> Variable
      | `String "parameter" -> Parameter
      | `String "constant" -> Constant
      | _ -> Function
    in
    let q = {
        p_file = ""; p_block = None; p_line = 0; p_col = 0;
        p_old = str json "old"; p_new = str json "new";
        p_kind = kind; p_decl = false; p_expand = false;
      } in
    positions json q "declarations" true @ positions json q "uses" false
  in
  let entries = match Yojson.Basic.Util.(member "plan" json) with
    | `List l -> List.concat_map one_entry l
    | _ -> errors := "the plan file has no plan list" :: !errors; []
  in
  let expansions = match Yojson.Basic.Util.(member "expansions" json) with
    | `List l ->
       List.filter_map (fun e ->
           let at = str e "at" and o = str e "old" and nw = str e "new" in
           match split_pos at with
           | Some (f, b, l2, c) ->
              Some { p_file = f; p_block = b; p_line = l2; p_col = c;
                     p_old = o; p_new = nw; p_kind = Variable;
                     p_decl = true; p_expand = true }
           | None -> errors := ("the plan has a bad expansion position: " ^ at) :: !errors; None) l
    | _ -> []
  in
  (entries @ expansions, List.sort_uniq compare !errors)

(* The text of one unit with the plan's positions applied.  The map loses a
   position when a token takes it, so the caller sees the positions that fit
   no token. *)
let apply_unit (map: (int * int, planned) Hashtbl.t) (unit: string) (mismatches: string list ref) (applied: int ref): string option =
  match lex unit with
  | None -> mismatches := "a file of the plan does not lex" :: !mismatches; None
  | Some toks ->
     let starts = line_starts unit in
     let out = Buffer.create (String.length unit) in
     let pos = ref 0 in
     Array.iter (fun t ->
         let (l, c) = linecol starts t.start in
         match Hashtbl.find_opt map (l, c) with
         | Some q ->
            Hashtbl.remove map (l, c);
            Buffer.add_string out (String.sub unit !pos (t.start - !pos));
            if t.text <> q.p_old then
              mismatches :=
                Printf.sprintf "%s:%d:%d: the plan renames %s, the file has %s"
                  q.p_file l c q.p_old t.text :: !mismatches
            else begin
              Buffer.add_string out (if q.p_expand then q.p_old ^ " as " ^ q.p_new else q.p_new);
              incr applied
            end;
            pos := t.stop
         | None ->
            Buffer.add_string out (String.sub unit !pos (t.stop - !pos));
            pos := t.stop) toks;
     Buffer.add_string out (String.sub unit !pos (String.length unit - !pos));
     Some (Buffer.contents out)

(* Applies a saved plan to exactly its positions.  A position that no longer
   holds the old name is a mismatch; nothing is written then. *)
let apply_plan (plan_path: string): int =
  let planned, load_errors = load_plan plan_path in
  (* By file and block, then by line and column. *)
  let units: (string * int option, (int * int, planned) Hashtbl.t) Hashtbl.t = Hashtbl.create 16 in
  List.iter (fun q ->
      let key = (q.p_file, q.p_block) in
      let map = Option.value (Hashtbl.find_opt units key) ~default:(Hashtbl.create 8) in
      Hashtbl.replace map (q.p_line, q.p_col) q;
      Hashtbl.replace units key map) planned;
  let mismatches = ref load_errors in
  let applied = ref 0 in
  let writes = ref [] in
  let files = List.sort_uniq compare (List.map (fun q -> q.p_file) planned) in
  List.iter (fun f ->
      match (try Some (read_file f) with _ -> None) with
      | None -> mismatches := ("the plan names a file that is not read: " ^ f) :: !mismatches
      | Some src ->
         if Filename.check_suffix f ".md" then begin
           let out = Buffer.create (String.length src) in
           let pos = ref 0 in
           List.iteri (fun i (s, e) ->
               let unit = String.sub src s (e - s) in
               Buffer.add_string out (String.sub src !pos (s - !pos));
               (match Hashtbl.find_opt units (f, Some i) with
                | Some map ->
                   (match apply_unit map unit mismatches applied with
                    | Some text -> Buffer.add_string out text
                    | None -> Buffer.add_string out unit)
                | None -> Buffer.add_string out unit);
               pos := e) (markdown_blocks src);
           Buffer.add_string out (String.sub src !pos (String.length src - !pos));
           let text = Buffer.contents out in
           if text <> src then writes := (f, text) :: !writes
         end else begin
           (* The examples first: they lie inside a docstring, which is one
              token of the file, so the lines and columns of the file's own
              tokens stay where they were. *)
           let examples =
             match lex src with
             | Some toks -> docstring_units (fresh_tables ()) f src toks (ref 0)
             | None -> []
           in
           let out = Buffer.create (String.length src) in
           let pos = ref 0 in
           List.iteri (fun i (s, e, text, _, _) ->
               Buffer.add_string out (String.sub src !pos (s - !pos));
               (match Hashtbl.find_opt units (f, Some i) with
                | Some map ->
                   (match apply_unit map text mismatches applied with
                    | Some t2 -> Buffer.add_string out t2
                    | None -> Buffer.add_string out text)
                | None -> Buffer.add_string out text);
               pos := e) examples;
           Buffer.add_string out (String.sub src !pos (String.length src - !pos));
           let src2 = Buffer.contents out in
           let text =
             match Hashtbl.find_opt units (f, None) with
             | Some map -> Option.value (apply_unit map src2 mismatches applied) ~default:src2
             | None -> src2
           in
           if text <> src then writes := (f, text) :: !writes
         end) files;
  (* A position no token took. *)
  Hashtbl.iter (fun (f, _) map ->
      Hashtbl.iter (fun (l, c) q ->
          mismatches :=
            Printf.sprintf "%s:%d:%d: the plan renames %s, no token is there" f l c q.p_old
            :: !mismatches) map) units;
  let mismatches = List.sort_uniq compare !mismatches in
  let ok = mismatches = [] in
  print_endline (Yojson.Basic.to_string (`Assoc [
      ("command", `String "rename-apply");
      ("applied", `Bool (ok && !writes <> []));
      ("plan", `String plan_path);
      ("files_read", `Int (List.length files));
      ("files_changed", `Int (List.length !writes));
      ("positions", `Int !applied);
      ("mismatches", `List (List.map (fun s -> `String s) mismatches))
    ]));
  if not ok then 1
  else begin
    List.iter (fun (f, text) -> write_file f text) !writes;
    0
  end

(* One unit pair: the tokens must agree except where the plan renames.  The
   map loses a position when the old token takes it.  Gives the identifiers
   changed and the token counts. *)
let compare_unit (map: (int option * int * int, planned) Hashtbl.t) (block: int option)
    (old_src: string) (new_src: string) (unexpected: (int * int * string * string) list ref)
  : int * int * int =
  match (lex old_src, lex new_src) with
  | None, _ | _, None ->
     unexpected := (0, 0, "a file does not lex", "") :: !unexpected;
     (0, 0, 0)
  | Some o_toks, Some n_toks ->
     let starts = line_starts old_src in
     let n_o = Array.length o_toks and n_n = Array.length n_toks in
     let i = ref 0 and j = ref 0 and changed = ref 0 in
     let note l c a b = unexpected := (l, c, a, b) :: !unexpected in
     while !i < n_o && !j < n_n do
       let t = o_toks.(!i) in
       let (l, c) = linecol starts t.start in
       match Hashtbl.find_opt map (block, l, c) with
       | Some q when is_ident t && t.text = q.p_old ->
          Hashtbl.remove map (block, l, c);
          incr changed;
          let good =
            if q.p_expand then
              (!j + 2 < n_n) && (same_tok n_toks.(!j).tok t.tok) && (n_toks.(!j + 1).tok = AS)
              && (is_ident n_toks.(!j + 2)) && (n_toks.(!j + 2).text = q.p_new)
            else
              (same_tok n_toks.(!j).tok t.tok) && (n_toks.(!j).text = q.p_new)
          in
          if good then j := !j + (if q.p_expand then 3 else 1)
          else begin
            let seen = if !j < n_n then n_toks.(!j).text else "(end)" in
            note l c q.p_old seen;
            j := !j + (if q.p_expand then 3 else 1)
          end;
          incr i
       | Some q ->
          Hashtbl.remove map (block, l, c);
          note l c q.p_old t.text;
          incr i;
          if !j < n_n then incr j
       | None ->
          if not (same_tok n_toks.(!j).tok t.tok) then note l c t.text n_toks.(!j).text;
          incr i; incr j
     done;
     while !i < n_o do
       let t = o_toks.(!i) in
       let (l, c) = linecol starts t.start in
       note l c t.text "(end of the new file)";
       incr i
     done;
     while !j < n_n do
       note 0 0 "(end of the old file)" n_toks.(!j).text;
       incr j
     done;
     (!changed, n_o, n_n)

(* The token comparison: the plan of the old file, or a saved one, against a
   new file.  Shows every difference the plan does not name. *)
let compare_sources (planned: planned list) (old_src: string) (new_src: string)
  : bool * (int * int * string * string) list * int * int * int =
  let map: (int option * int * int, planned) Hashtbl.t = Hashtbl.create 32 in
  List.iter (fun q -> Hashtbl.replace map (q.p_block, q.p_line, q.p_col) q) planned;
  let unexpected = ref [] in
  let (changed, n_o, n_n) = compare_unit map None old_src new_src unexpected in
  Hashtbl.iter (fun (_, l, c) q ->
      unexpected := (l, c, q.p_old, "(no token)") :: !unexpected) map;
  let unexpected = List.rev !unexpected in
  (unexpected = [], unexpected, changed, n_o, n_n)

let compare_files (plan_path: string option) (old_path: string) (new_path: string): int =
  let read p = try Some (read_file p) with _ -> None in
  match (read old_path, read new_path) with
  | None, _ | _, None ->
     print_endline (Yojson.Basic.to_string (`Assoc [
         ("command", `String "rename-compare");
         ("old", `String old_path);
         ("new", `String new_path);
         ("tokens_old", `Int 0);
         ("tokens_new", `Int 0);
         ("identifiers_changed", `Int 0);
         ("unexpected", `List []);
         ("problems", `List [`String (old_path ^ " or " ^ new_path ^ " does not read")])
       ]));
     1
  | Some old_src, Some new_src ->
  let planned, problems =
    match plan_path with
    | Some p ->
       let (pl, errs) = load_plan p in
       (List.filter (fun q -> q.p_file = old_path) pl, ref errs)
    | None -> let (pl, co) = plan_of_text old_path (read_file old_path) in (pl, ref co)
  in
  let map: (int option * int * int, planned) Hashtbl.t = Hashtbl.create 32 in
  List.iter (fun q -> Hashtbl.replace map (q.p_block, q.p_line, q.p_col) q) planned;
  let unexpected = ref [] in
  let changed = ref 0 and n_o = ref 0 and n_n = ref 0 in
  if Filename.check_suffix old_path ".md" then begin
    let blocks_o = markdown_blocks old_src and blocks_n = markdown_blocks new_src in
    if List.length blocks_o <> List.length blocks_n then
      problems := "the fenced blocks of the two files differ in number" :: !problems;
    List.iteri (fun i (s, e) ->
        match List.nth_opt blocks_n i with
        | Some (s2, e2) ->
           let (c, a, b) = compare_unit map (Some i)
               (String.sub old_src s (e - s)) (String.sub new_src s2 (e2 - s2)) unexpected in
           changed := !changed + c; n_o := !n_o + a; n_n := !n_n + b
        | None -> ()) blocks_o
  end else begin
    let (c, a, b) = compare_unit map None old_src new_src unexpected in
    changed := c; n_o := a; n_n := b;
    let examples src =
      match lex src with
      | Some toks -> docstring_units (fresh_tables ()) old_path src toks (ref 0)
      | None -> []
    in
    let ex_o = examples old_src and ex_n = examples new_src in
    if List.length ex_o <> List.length ex_n then
      problems := "the docstring examples of the two files differ in number" :: !problems;
    List.iteri (fun i (_, _, text, _, _) ->
        match List.nth_opt ex_n i with
        | Some (_, _, text2, _, _) ->
           let (c, a, b) = compare_unit map (Some i) text text2 unexpected in
           changed := !changed + c; n_o := !n_o + a; n_n := !n_n + b
        | None -> ()) ex_o
  end;
  Hashtbl.iter (fun (_, l, c) q ->
      problems :=
        Printf.sprintf "%s:%d:%d: the plan renames %s, no token is there" old_path l c q.p_old
        :: !problems) map;
  let problems = List.sort_uniq compare !problems in
  let unexpected = List.rev !unexpected in
  let ok = (problems = []) && (unexpected = []) in
  print_endline (Yojson.Basic.to_string (`Assoc [
      ("command", `String "rename-compare");
      ("old", `String old_path);
      ("new", `String new_path);
      ("tokens_old", `Int !n_o);
      ("tokens_new", `Int !n_n);
      ("identifiers_changed", `Int !changed);
      ("unexpected", `List (List.map (fun (l, c, a, b) ->
           `Assoc [("at", `String (Printf.sprintf "%s:%d:%d" old_path l c));
                   ("from", `String a); ("to", `String b)]) unexpected));
      ("problems", `List (List.map (fun s -> `String s) problems))
    ]));
  if ok then 0 else 1

(* Writes the plan to standard output.  Exit 0 done, 1 a collision and nothing
   written.  The module roots are read for what they declare and are not
   renamed themselves. *)
let run (paths: string list) (module_dirs: string list) (apply: bool): int =
  let files = List.rev (List.fold_left (fun acc p -> walk p acc) [] paths) in
  let tables = {
      by_dir = Hashtbl.create 512;
      by_module = Hashtbl.create 512;
      callables = Hashtbl.create 4096;
    } in
  let module_files =
    List.filter (fun f -> not (Filename.check_suffix f ".md") && not (List.mem f files))
      (List.rev (List.fold_left (fun acc d -> if Sys.file_exists d then walk d acc else acc) [] module_dirs)) in
  let sources = List.filter (fun f -> not (Filename.check_suffix f ".md")) files in
  let markdown = List.filter (fun f -> Filename.check_suffix f ".md") files in
  let unlexable = ref [] in
  let lexed = List.filter_map (fun f ->
      let src = read_file f in
      match lex src with
      | Some toks -> scan_tables tables f toks; Some (f, src, toks)
      | None -> unlexable := f :: !unlexable; None) sources in
  scan_module_roots tables module_files;
  let counts = Hashtbl.create 4 in
  let pairs = Hashtbl.create 1024 in
  (* (old, new, kind) -> (declarations, uses), each position a string. *)
  let entries: (string * string * kind, string list ref * string list ref) Hashtbl.t = Hashtbl.create 256 in
  let expansions = ref [] in
  let collisions = ref [] in
  let expanded = ref 0 in
  let writes = ref [] in
  let note (f: string) (block: int option) (src: string) (toks: token array) (r: result): unit =
    List.iter (fun q ->
        let c = Option.value (Hashtbl.find_opt counts q.p_kind) ~default:0 in
        Hashtbl.replace counts q.p_kind (c + 1);
        let key = (q.p_old, q.p_new, q.p_kind) in
        let c = Option.value (Hashtbl.find_opt pairs key) ~default:0 in
        Hashtbl.replace pairs key (c + 1);
        let at = match block with
          | Some b -> Printf.sprintf "%s#%d:%d:%d" f b q.p_line q.p_col
          | None -> Printf.sprintf "%s:%d:%d" f q.p_line q.p_col
        in
        if q.p_expand then
          expansions := (at, q.p_old, q.p_new) :: !expansions;
        let (decls, uses) =
          Option.value (Hashtbl.find_opt entries key) ~default:(ref [], ref [])
        in
        (if q.p_decl then decls := at :: !decls else uses := at :: !uses);
        Hashtbl.replace entries key (decls, uses))
      (planned_of f block src toks r);
    expanded := !expanded + List.length r.expansions;
    collisions := r.collisions @ !collisions
  in
  let blocks_skipped = ref 0 in
  let examples_skipped = ref 0 in
  List.iter (fun (f, src, toks) ->
      let r = process tables f toks in
      note f None src toks r;
      let units = docstring_units tables f src toks examples_skipped in
      List.iteri (fun i (_, _, text, btoks, rb) -> note f (Some i) text btoks rb) units;
      let text = apply_with_examples tables src toks r units in
      if text <> src then writes := (f, text) :: !writes) lexed;
  List.iter (fun f ->
      let src = read_file f in
      let out = Buffer.create (String.length src) in
      let pos = ref 0 in
      List.iteri (fun i (s, e) ->
          let block = String.sub src s (e - s) in
          Buffer.add_string out (String.sub src !pos (s - !pos));
          (match lex block with
           | None -> incr blocks_skipped; Buffer.add_string out block
           | Some toks ->
              let r = process tables f toks in
              note f (Some i) block toks r;
              Buffer.add_string out (apply_edits tables block toks r));
          pos := e) (markdown_blocks src);
      Buffer.add_string out (String.sub src !pos (String.length src - !pos));
      let text = Buffer.contents out in
      if text <> src then writes := (f, text) :: !writes) markdown;
  let count k = Option.value (Hashtbl.find_opt counts k) ~default:0 in
  let pair_list =
    Hashtbl.fold (fun (o, nw, k) c acc -> (o, nw, k, c) :: acc) pairs []
    |> List.sort compare
    |> List.map (fun (o, nw, k, c) ->
           `Assoc [("old", `String o); ("new", `String nw);
                   ("kind", `String (kind_name k)); ("count", `Int c);
                   ("callable", `Bool (Hashtbl.mem tables.callables o))])
  in
  let plan_list =
    Hashtbl.fold (fun k v acc -> (k, v) :: acc) entries []
    |> List.sort compare
    |> List.map (fun ((o, nw, k), (decls, uses)) ->
           `Assoc [("old", `String o); ("new", `String nw);
                   ("kind", `String (kind_name k));
                   ("declarations", `List (List.map (fun s -> `String s) (List.sort compare !decls)));
                   ("uses", `List (List.map (fun s -> `String s) (List.sort compare !uses)))])
  in
  let expansion_list =
    List.sort compare !expansions
    |> List.map (fun (at, o, nw) ->
           `Assoc [("at", `String at); ("old", `String o); ("new", `String nw)])
  in
  let collisions = List.sort_uniq compare !collisions in
  let ok = collisions = [] in
  print_endline (Yojson.Basic.to_string (`Assoc [
      ("command", `String "rename");
      ("applied", `Bool (apply && ok));
      ("files_read", `Int (List.length files));
      ("files_changed", `Int (List.length !writes));
      ("variables", `Int (count Variable));
      ("parameters", `Int (count Parameter));
      ("constants", `Int (count Constant));
      ("functions", `Int (count Function));
      ("shorthands_expanded", `Int !expanded);
      ("markdown_blocks_not_lexed", `Int !blocks_skipped);
      ("docstring_examples_not_lexed", `Int !examples_skipped);
      ("collisions", `List (List.map (fun s -> `String s) collisions));
      ("not_lexed", `List (List.map (fun s -> `String s) (List.sort compare !unlexable)));
      ("plan", `List plan_list);
      ("expansions", `List expansion_list);
      ("pairs", `List pair_list)
    ]));
  if not ok then 1
  else begin
    if apply then List.iter (fun (f, text) -> write_file f text) !writes;
    0
  end
