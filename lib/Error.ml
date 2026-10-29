(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open Span
open SourceContext
open ErrorText

(* Types *)

type error_kind =
  | GenericError
  | ParseError
  | CliError
  | TypeError
  | LinearityError
  | DeclarationError
  | EntrypointError
  | InternalError

(* A stable code per raise site: `H' and four digits, written as a literal
   where the error is raised, listed in docs/error-codes.md by
   scripts/error-codes.py. *)
type error_code = H of int

let code_string (H n: error_code): string =
  Printf.sprintf "H%04d" n

type hilde_error = HildeError of {
      module_name: module_name option;
      code: error_code;
      kind: error_kind;
      text: err_text;
      span: span option;
      source_ctx: source_ctx option;
    }

exception Hilde_error of hilde_error

(* Raising *)

let hilde_raise (code: error_code) (kind: error_kind) (text: err_text): 'a =
  let error: hilde_error =
    HildeError {
        module_name = None;
        code = code;
        kind = kind;
        text = text;
        span = None;
        source_ctx = None;
      }
  in
  raise (Hilde_error error)

(* Error context-augmenting functions *)

let add_source_ctx (error: hilde_error) (ctx: source_ctx): hilde_error =
  let (HildeError { module_name; code; kind; text; span; source_ctx }) = error in
  match source_ctx with
  | Some _ ->
     error
  | None ->
     HildeError { module_name; code; kind; text; span; source_ctx = Some ctx; }

let adorn_error_with_module_name (new_module_name: module_name) (f: unit -> 'a): 'a =
  try
    f ()
  with Hilde_error error ->
    let (HildeError { module_name; code; kind; text; span; source_ctx }) = error in
    match module_name with
    | Some _ ->
       (* The error already has a module name, do nothing. *)
       raise (Hilde_error error)
    | None ->
       (* Add the span *)
       let new_err = HildeError { module_name = Some new_module_name; code; kind; text; span; source_ctx } in
       raise (Hilde_error new_err)

let adorn_error_with_span (new_span: span) (f: unit -> 'a): 'a =
  try
    f ()
  with Hilde_error error ->
    let (HildeError { module_name; code; kind; text; span; source_ctx }) = error in
    match span with
    | Some span' ->
       (* The error already has a span. *)
       if span' = empty_span then
         (* The error has the empty span, add ours. *)
         let new_err = HildeError { module_name; code; kind; text; span = Some new_span; source_ctx } in
         raise (Hilde_error new_err)
       else
         (* The error has a non-empty span, reraise. *)
         raise (Hilde_error error)
    | None ->
       (* Add the span *)
       let new_err = HildeError { module_name; code; kind; text; span = Some new_span; source_ctx } in
       raise (Hilde_error new_err)

(* Error rendering to plain text *)

let error_title (kind: error_kind): string =
  match kind with
  | GenericError -> "Generic Error"
  | ParseError -> "Parse Error"
  | CliError -> "Command Line Arguments Error"
  | TypeError -> "Type Error"
  | LinearityError -> "Linearity Error"
  | DeclarationError -> "Declaration Error"
  | EntrypointError -> "Entrypoint Definition Error"
  | InternalError -> "Internal Error"

let indent_text (text: string) (indent: int): string =
  let lines = String.split_on_char '\n' text in
  let lines =
    List.map
      (fun line ->
        let pad = String.make indent ' '
        in
        pad ^ line)
      lines
  in
  String.concat "\n" lines

let render_error_to_plain (error: hilde_error): string =
  let (HildeError { span; code; kind; text; source_ctx; module_name }) = error in
  let mn_text: string =
    match module_name with
    | Some mn ->
       "  Module:\n"
       ^ "    " ^ (mod_name_string mn) ^ "\n"
    | None ->
       "  Module:\n"
       ^ "    [unknown]\n"
  in
  let title: string = error_title kind in
  let span_text =
    match span with
    | Some (Span { filename; startp; endp }) ->
       "  Location:\n"
       ^ "    Filename: '" ^ filename ^ "'\n"
       ^ "    From: " ^ (position_to_string startp) ^ "\n"
       ^ "    To: " ^ (position_to_string endp) ^ "\n"
    | None ->
       "  Location:\n"
       ^ "    [no span available]\n"
  and code_text =
    (match source_ctx with
     | Some ctx ->
        "  Code:\n"
        ^ (indent_text (source_ctx_to_plain_text ctx) 4)
     | None ->
        "  Code:\n"
        ^ "    [no span available]\n")
  in
  "Error:\n"
  ^ "  Title: " ^ title ^ "\n"
  ^ "  Error code: " ^ (code_string code) ^ "\n"
  ^ mn_text
  ^ span_text
  ^ "  Description:\n"
  ^ (indent_text (error_text_to_plain text) 4) ^ "\n"
  ^ code_text
  ^ "\n"

let pos_json (p: position): Yojson.Basic.t =
  let (Position { line; column; }) = p in
  `Assoc [
      ("line", `Int line);
      ("column", `Int column)
    ]

let span_json (span: span): Yojson.Basic.t =
  let (Span { filename; startp; endp; }) = span in
  `Assoc [
      ("filename", `String filename);
      ("startp", pos_json startp);
      ("end", pos_json endp)
    ]

let source_ctx_json (ctx: source_ctx): Yojson.Basic.t =
  let (SourceContext lines) = ctx in
  let line_json ((n, l): (int * string)): Yojson.Basic.t =
    `List [`Int n; `String l]
  in
  `List (List.map line_json lines)

let render_error_to_json (error: hilde_error): Yojson.Basic.t =
  (* Break up the error. *)
  let (HildeError { span; code; kind; text; source_ctx; module_name }) = error in
  (* Render components to JSON. *)
  let module_name: Yojson.Basic.t =
    match module_name with
    | Some mn -> `String (mod_name_string mn)
    | None -> `Null
  in
  let span: Yojson.Basic.t =
    match span with
    | Some span -> span_json span
    | None -> `Null
  in
  let source_ctx: Yojson.Basic.t =
    match source_ctx with
    | Some source_ctx -> source_ctx_json source_ctx
    | None -> `Null
  in
  (* Put it together. *)
  `Assoc [
      ("module", module_name);
      ("code", `String (code_string code));
      ("kind", `String (error_title kind));
      ("text", error_text_to_json text);
      ("span", span);
      ("context", source_ctx)
    ]

(* --error-format=json-lines: one object on one line, with the place and the
   text flat, as rustc writes its errors for a tool.  message is the text up
   to the first paragraph break, hint the rest or null.  A field the error
   has no value for is null. *)
let render_error_to_json_line (error: hilde_error): string =
  let (HildeError { span; code; kind; text; module_name; _ }) = error in
  let rec split (before: err_text) (rest: err_text): err_text * err_text option =
    match rest with
    | [] -> (List.rev before, None)
    | Break :: after -> (List.rev before, Some after)
    | elem :: after -> split (elem :: before) after
  in
  let (message, hint) = split [] text in
  let int_or_null (f: position -> int): Yojson.Basic.t =
    match span with
    | Some (Span { startp; _ }) -> `Int (f startp)
    | None -> `Null
  in
  let end_or_null (f: position -> int): Yojson.Basic.t =
    match span with
    | Some (Span { endp; _ }) -> `Int (f endp)
    | None -> `Null
  in
  let line (Position { line; _ }) = line
  and column (Position { column; _ }) = column in
  Yojson.Basic.to_string (`Assoc [
      ("code", `String (code_string code));
      ("kind", `String (error_title kind));
      ("module", (match module_name with Some mn -> `String (mod_name_string mn) | None -> `Null));
      ("file", (match span with Some (Span { filename; _ }) -> `String filename | None -> `Null));
      ("line", int_or_null line);
      ("column", int_or_null column);
      ("end_line", end_or_null line);
      ("end_column", end_or_null column);
      ("message", `String (error_text_to_plain message));
      ("hint", (match hint with
                | Some h -> `String (error_text_to_plain h)
                | None -> `Null))
    ])

(* --error-format=json: one object on one line in the form rustc gives its
   diagnostics to a tool, so that an editor or an agent that reads rustc
   reads Hilde without a reader of its own.  Lines count from 1 as in the
   compiler; columns count from 1 here, where the compiler counts from 0.
   The byte offsets come from the source of the file when [source_of] has
   it, and are 0 when it has not.  A suggestion of the text is a child of
   level help whose span carries the replacement; it is MachineApplicable
   only when the raise site marked it as the one fix. *)
let render_error_to_rustc (source_of: string -> string option) (error: hilde_error): string =
  let (HildeError { span; code; text; _ }) = error in
  let prose: err_text = without_suggestions text in
  let rec split (before: err_text) (rest: err_text): err_text * err_text option =
    match rest with
    | [] -> (List.rev before, None)
    | Break :: after -> (List.rev before, Some after)
    | elem :: after -> split (elem :: before) after
  in
  let (message, note) = split [] prose in
  (* The byte at which a line and a column begin, or 0. *)
  let offset (filename: string) (Position { line; column }): int =
    match source_of filename with
    | None -> 0
    | Some code ->
       let n = String.length code in
       let rec go (i: int) (l: int): int =
         if l >= line then min n (i + column)
         else match String.index_from_opt code i '\n' with
              | Some j -> go (j + 1) (l + 1)
              | None -> n
       in
       go 0 1
  in
  let line_text (filename: string) (line: int): string option =
    match source_of filename with
    | None -> None
    | Some code ->
       (match List.nth_opt (String.split_on_char '\n' code) (line - 1) with
        | Some l -> Some l
        | None -> None)
  in
  let span_json (s: span) (replacement: string option) (certain: bool): Yojson.Basic.t =
    let (Span { filename; startp; endp }) = s in
    let (Position { line = l0; column = c0 }) = startp
    and (Position { line = l1; column = c1 }) = endp in
    let texts: Yojson.Basic.t =
      match line_text filename l0 with
      | Some t ->
         let hi_end = if l1 = l0 then c1 + 1 else String.length t + 1 in
         `List [`Assoc [("text", `String t);
                        ("highlight_start", `Int (c0 + 1));
                        ("highlight_end", `Int hi_end)]]
      | None -> `List []
    in
    `Assoc [
        ("file_name", `String filename);
        ("byte_start", `Int (offset filename startp));
        ("byte_end", `Int (offset filename endp));
        ("line_start", `Int l0);
        ("line_end", `Int l1);
        ("column_start", `Int (c0 + 1));
        ("column_end", `Int (c1 + 1));
        ("is_primary", `Bool true);
        ("text", texts);
        ("label", `Null);
        ("suggested_replacement",
         (match replacement with Some r -> `String r | None -> `Null));
        ("suggestion_applicability",
         (match replacement with
          | Some _ -> `String (if certain then "MachineApplicable" else "MaybeIncorrect")
          | None -> `Null));
        ("expansion", `Null)
      ]
  in
  let spans: Yojson.Basic.t list =
    match span with
    | Some s -> [span_json s None false]
    | None -> []
  in
  let child (level: string) (msg: string) (spans: Yojson.Basic.t list): Yojson.Basic.t =
    `Assoc [
        ("message", `String msg);
        ("code", `Null);
        ("level", `String level);
        ("spans", `List spans);
        ("children", `List []);
        ("rendered", `Null)
      ]
  in
  let notes: Yojson.Basic.t list =
    match note with
    | Some n when n <> [] -> [child "note" (error_text_to_plain n) []]
    | _ -> []
  in
  let helps: Yojson.Basic.t list =
    List.map (fun { replacement; at; certain } ->
        let place = match at with Some a -> Some a | None -> span in
        let spans = match place with
          | Some s -> [span_json s (Some replacement) certain]
          | None -> []
        in
        child "help" ("replace with `" ^ replacement ^ "`") spans)
      (suggestions_of text)
  in
  let rendered: string =
    let head = "error[" ^ (code_string code) ^ "]: " ^ (error_text_to_plain message) in
    let place =
      match span with
      | Some (Span { filename; startp = Position { line; column }; _ }) ->
         Printf.sprintf "\n --> %s:%d:%d" filename line (column + 1)
      | None -> ""
    in
    head ^ place ^ "\n"
  in
  Yojson.Basic.to_string (`Assoc [
      ("$message_type", `String "diagnostic");
      ("message", `String (error_text_to_plain message));
      ("code", `Assoc [("code", `String (code_string code)); ("explanation", `Null)]);
      ("level", `String "error");
      ("spans", `List spans);
      ("children", `List (notes @ helps));
      ("rendered", `String rendered)
    ])

(* Utility functions. *)

let err (code: error_code) (message: string) =
  let e: hilde_error =
    HildeError {
        module_name = None;
        code = code;
        kind = GenericError;
        text = [Text message];
        span = None;
        source_ctx = None;
      }
  in
  raise (Hilde_error e)

let internal_err (message: string) =
  let e: hilde_error =
    HildeError {
        module_name = None;
        code = H 9999;
        kind = InternalError;
        text = [
            Text "Internal compiler error: ";
            Text message;
            Break;
            Text "This is a bug in the compiler."
          ];
        span = None;
        source_ctx = None;
      }
  in
  raise (Hilde_error e)

(* The same, for a message that names code or types.  A check that only a
   defect of the compiler can reach raises this and not a code of its own:
   a code in the registry is one a program can reach. *)
let internal_raise (text: err_text) =
  let e: hilde_error =
    HildeError {
        module_name = None;
        code = H 9999;
        kind = InternalError;
        text = [Text "Internal compiler error: "] @ text @ [
            Break;
            Text "This is a bug in the compiler."
          ];
        span = None;
        source_ctx = None;
      }
  in
  raise (Hilde_error e)
