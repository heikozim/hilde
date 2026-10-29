(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* hilde lsp: a language server over standard input and output.  A document
   that is opened, changed or saved is checked as hilde check checks it, and
   its first error is published as a diagnostic.  Hover and go to
   definition read the declarations of the document's module and of the
   modules it imports from their sources as parsed, so that they work while
   the document has an error: a name gives its declaration as written, with
   its type parameters, parameters, result and contract, and its docstring.
   The text of an open document is the editor's, not the file's. *)

open Identifier
open Common
open Span
open Error
open ErrorText
open Cst

(* --- Messages -------------------------------------------------------------- *)

(* A message of the protocol: a header with Content-Length, a blank line,
   the JSON.  None at the end of the input. *)
let read_message (ic: in_channel): Yojson.Basic.t option =
  let rec headers (length: int option): int option =
    match In_channel.input_line ic with
    | None -> None
    | Some line ->
       let line = String.trim line in
       if line = "" then (match length with Some _ -> length | None -> headers None)
       else
         let lower = String.lowercase_ascii line in
         let key = "content-length:" in
         if String.length lower > String.length key && String.sub lower 0 (String.length key) = key then
           headers (int_of_string_opt (String.trim (String.sub line (String.length key) (String.length line - String.length key))))
         else headers length
  in
  match headers None with
  | None -> None
  | Some n ->
     (match In_channel.really_input_string ic n with
      | Some body -> (try Some (Yojson.Basic.from_string body) with _ -> Some `Null)
      | None -> None)

let write_message (oc: out_channel) (j: Yojson.Basic.t): unit =
  let body = Yojson.Basic.to_string j in
  Printf.fprintf oc "Content-Length: %d\r\n\r\n%s" (String.length body) body;
  flush oc

let member (name: string) (j: Yojson.Basic.t): Yojson.Basic.t =
  match j with
  | `Assoc fields -> (match List.assoc_opt name fields with Some v -> v | None -> `Null)
  | _ -> `Null

let to_string_opt (j: Yojson.Basic.t): string option =
  match j with `String s -> Some s | _ -> None

let to_int (j: Yojson.Basic.t): int =
  match j with `Int i -> i | _ -> 0

(* --- Places ------------------------------------------------------------------- *)

let hex_value (c: char): int =
  match c with
  | '0' .. '9' -> Char.code c - 48
  | 'a' .. 'f' -> Char.code c - 87
  | 'A' .. 'F' -> Char.code c - 55
  | _ -> 0

(* The path of a file URI, with %XX undone. *)
let path_of_uri (uri: string): string =
  let p = if String.length uri > 7 && String.sub uri 0 7 = "file://" then String.sub uri 7 (String.length uri - 7) else uri in
  let b = Buffer.create (String.length p) in
  let i = ref 0 in
  while !i < String.length p do
    if p.[!i] = '%' && !i + 2 < String.length p then begin
      Buffer.add_char b (Char.chr ((16 * hex_value p.[!i + 1]) + hex_value p.[!i + 2]));
      i := !i + 3
    end else begin
      Buffer.add_char b p.[!i];
      incr i
    end
  done;
  Buffer.contents b

let uri_of_path (path: string): string =
  let b = Buffer.create (String.length path + 7) in
  Buffer.add_string b "file://";
  String.iter
    (fun c ->
      match c with
      | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '/' | '-' | '_' | '.' | '~' -> Buffer.add_char b c
      | _ -> Buffer.add_string b (Printf.sprintf "%%%02X" (Char.code c)))
    (if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path else path);
  Buffer.contents b

(* A place of the compiler -- lines from 1, columns from 0 -- as the
   protocol has it, lines and characters from 0. *)
let position_json (Position { line; column }): Yojson.Basic.t =
  `Assoc [("line", `Int (max 0 (line - 1))); ("character", `Int (max 0 column))]

let range_json (Span { startp; endp; _ }): Yojson.Basic.t =
  `Assoc [("start", position_json startp); ("end", position_json endp)]

let zero_range: Yojson.Basic.t =
  `Assoc [("start", `Assoc [("line", `Int 0); ("character", `Int 0)]);
          ("end", `Assoc [("line", `Int 0); ("character", `Int 0)])]

(* --- State ----------------------------------------------------------------- *)

(* The open documents by path, with the editor's text. *)
let documents: (string, string) Hashtbl.t = Hashtbl.create 16

let module_dirs: string list ref = ref []

let read_file (path: string): string option =
  try
    let ic = open_in_bin path in
    let n = in_channel_length ic in
    let s = really_input_string ic n in
    close_in ic;
    Some s
  with Sys_error _ -> None

(* The text of a path: the editor's when the document is open. *)
let text_of (path: string): string option =
  match Hashtbl.find_opt documents path with
  | Some t -> Some t
  | None -> read_file path

(* The module of a document: its interface and its body when both are
   there, with the editor's texts. *)
let source_of (path: string): Compiler.module_source option =
  let stem = Filename.remove_extension path in
  let int_path = stem ^ ".hih" and body_path = stem ^ ".hiq" in
  match (text_of int_path, text_of body_path) with
  | (Some int_code, Some body_code) ->
     Some (Compiler.TwoFileModuleSource { int_filename = int_path; int_code; body_filename = body_path; body_code })
  | (None, Some body_code) ->
     Some (Compiler.BodyModuleSource { body_filename = body_path; body_code })
  | _ -> None

(* The directories searched for imports: those given to hilde lsp, the
   directory of the document, and the standard library beside the
   compiler. *)
let dirs_for (path: string): string list =
  let beside = Filename.dirname Sys.executable_name in
  let library =
    List.filter (fun d -> Sys.file_exists d && Sys.is_directory d)
      [Filename.concat beside "standard/src"; Filename.concat beside "bindings/generated"]
  in
  !module_dirs @ [Filename.dirname path] @ library

let modules_for (path: string): Compiler.module_source list =
  match source_of path with
  | None -> []
  | Some given ->
     (try TestRunner.modules_for_compile (dirs_for path) [given] with Hilde_error _ -> [given])

(* --- Diagnostics -------------------------------------------------------------- *)

(* The first error of the document's module and its imports, or none.  An
   error in another file stands at the start of the document, with the
   file named. *)
let diagnostics (path: string): Yojson.Basic.t list =
  match modules_for path with
  | [] -> []
  | mods ->
     (try
        let _ = Compiler.check_multiple Compiler.empty_compiler mods in
        []
      with Hilde_error (HildeError { code; text; span; _ }) ->
        let message = error_text_to_plain (without_suggestions text) in
        let (range, message) =
          match span with
          | Some (Span { filename; _ } as s) when filename = path -> (range_json s, message)
          | Some (Span { filename; startp = Position { line; _ }; _ }) ->
             (zero_range, Printf.sprintf "In %s, line %d: %s" filename line message)
          | None -> (zero_range, message)
        in
        [`Assoc [
             ("range", range);
             ("severity", `Int 1);
             ("code", `String (code_string code));
             ("source", `String "hilde");
             ("message", `String message)
           ]])

(* --- The declarations ------------------------------------------------------------ *)

type declaration = {
    name: string;
    file: string;
    span: span;
    shown: string;
    (** The declaration as Hilde, its contract under it. *)
    doc: string;
  }

let rec typespec_string (t: typespec): string =
  match t with
  | TypeSpecifier (n, []) -> ident_string n
  | TypeSpecifier (n, args) -> (ident_string n) ^ "[" ^ (String.concat ", " (List.map typespec_string args)) ^ "]"
  | ConcreteReadRef (t, r) -> "&[" ^ (typespec_string t) ^ ", " ^ (typespec_string r) ^ "]"
  | ConcreteWriteRef (t, r) -> "&![" ^ (typespec_string t) ^ ", " ^ (typespec_string r) ^ "]"
  | ConcreteSpan (t, r) -> "Span[" ^ (typespec_string t) ^ ", " ^ (typespec_string r) ^ "]"
  | ConcreteSpanWrite (t, r) -> "Span![" ^ (typespec_string t) ^ ", " ^ (typespec_string r) ^ "]"

let generic_line (tps: concrete_type_param list): string =
  match tps with
  | [] -> ""
  | _ ->
     "generic ["
     ^ (String.concat ", "
          (List.map
             (fun (ConcreteTypeParam (n, u, cs)) ->
               (ident_string n) ^ ": " ^ (Type.universe_string u)
               ^ (match cs with [] -> "" | _ -> "(" ^ (String.concat ", " (List.map ident_string cs)) ^ ")"))
             tps))
     ^ "]\n"

let params_string (ps: concrete_param list): string =
  String.concat ", " (List.map (fun (ConcreteParam (n, t)) -> (ident_string n) ^ ": " ^ (typespec_string t)) ps)

let contract_lines (cs: contract_clause list): string =
  String.concat ""
    (List.filter_map
       (fun (ContractClause { kind; text; _ }) ->
         match kind with
         | Requires -> Some ("\n    requires " ^ text)
         | Ensures -> Some ("\n    ensures " ^ text)
         | Invariant -> Some ("\n    invariant " ^ text)
         | RaisesClause -> Some ("\n    raises " ^ text))
       cs)

let doc_string (Docstring d: docstring): string = String.trim d

let function_shown (name: identifier) tps ps rt cs: string =
  (generic_line tps) ^ "function " ^ (ident_string name) ^ "(" ^ (params_string ps) ^ "): "
  ^ (typespec_string rt) ^ (contract_lines cs)

let record_shown (ConcreteRecord (_, name, tps, u, slots, _, cs)): string =
  (generic_line tps) ^ "record " ^ (ident_string name) ^ ": " ^ (Type.universe_string u) ^ " is\n"
  ^ (String.concat "" (List.map (fun (ConcreteSlot (n, t)) -> "    " ^ (ident_string n) ^ ": " ^ (typespec_string t) ^ ";\n") slots))
  ^ (String.concat "" (List.map (fun (ContractClause { text; _ }) -> "    invariant " ^ text ^ ";\n") cs))
  ^ "end;"

let union_shown (ConcreteUnion (_, name, tps, u, cases, _)): string =
  (generic_line tps) ^ "union " ^ (ident_string name) ^ ": " ^ (Type.universe_string u) ^ " is\n"
  ^ (String.concat ""
       (List.map
          (fun (ConcreteCase (n, slots)) ->
            "    case " ^ (ident_string n)
            ^ (match slots with
               | [] -> ";\n"
               | _ -> " is\n" ^ (String.concat "" (List.map (fun (ConcreteSlot (s, t)) -> "        " ^ (ident_string s) ^ ": " ^ (typespec_string t) ^ ";\n") slots))))
          cases))
  ^ "end;"

let of_decl (file: string) (d: concrete_decl): declaration list =
  match d with
  | ConcreteConstantDecl (span, n, t, doc) ->
     [{ name = ident_string n; file; span; shown = "constant " ^ (ident_string n) ^ ": " ^ (typespec_string t); doc = doc_string doc }]
  | ConcreteOpaqueTypeDecl (span, n, tps, u, doc) ->
     [{ name = ident_string n; file; span; doc = doc_string doc;
        shown = (generic_line tps) ^ "type " ^ (ident_string n) ^ ": " ^ (Type.universe_string u) }]
  | ConcreteRecordDecl (ConcreteRecord (span, n, _, _, _, doc, _) as r) ->
     [{ name = ident_string n; file; span; shown = record_shown r; doc = doc_string doc }]
  | ConcreteUnionDecl (ConcreteUnion (span, n, _, _, cases, doc) as u) ->
     { name = ident_string n; file; span; shown = union_shown u; doc = doc_string doc }
     :: List.map (fun (ConcreteCase (c, _)) -> { name = ident_string c; file; span; shown = union_shown u; doc = doc_string doc }) cases
  | ConcreteFunctionDecl (span, n, tps, ps, rt, doc, cs, _) ->
     [{ name = ident_string n; file; span; shown = function_shown n tps ps rt cs; doc = doc_string doc }]
  | ConcreteTypeClassDecl (ConcreteTypeClass (span, n, _, methods, doc)) ->
     { name = ident_string n; file; span; shown = "typeclass " ^ (ident_string n); doc = doc_string doc }
     :: List.map
          (fun (ConcreteMethodDecl (m, tps, ps, rt, mdoc, cs)) ->
            { name = ident_string m; file; span; doc = doc_string mdoc;
              shown = (generic_line tps) ^ "method " ^ (ident_string m) ^ "(" ^ (params_string ps) ^ "): "
                      ^ (typespec_string rt) ^ (contract_lines cs) })
          methods
  | ConcreteInstanceDecl _ -> []

let of_def (file: string) (d: concrete_def): declaration list =
  match d with
  | ConcreteConstantDef (span, n, t, _, doc) ->
     [{ name = ident_string n; file; span; shown = "constant " ^ (ident_string n) ^ ": " ^ (typespec_string t); doc = doc_string doc }]
  | ConcreteRecordDef r -> of_decl file (ConcreteRecordDecl r)
  | ConcreteUnionDef u -> of_decl file (ConcreteUnionDecl u)
  | ConcreteFunctionDef (span, n, tps, ps, rt, _, doc, _, cs) ->
     [{ name = ident_string n; file; span; shown = function_shown n tps ps rt cs; doc = doc_string doc }]
  | ConcreteTypeClassDef tc -> of_decl file (ConcreteTypeClassDecl tc)
  | ConcreteInstanceDef _ -> []

(* The name, the imports and the declarations of a module; the interface's
   declarations first, so that a public name is found where it is
   declared for its callers. *)
let read_module (source: Compiler.module_source): (module_name * concrete_import_list list * declaration list) option =
  try
    match source with
    | Compiler.TwoFileModuleSource { int_filename; int_code; body_filename; body_code } ->
       let (ConcreteModuleInterface (name, _, int_imports, decls)) = ParserInterface.parse_module_int int_code int_filename in
       let body =
         try Some (ParserInterface.parse_module_body body_code body_filename) with Hilde_error _ -> None
       in
       let (body_imports, body_decls) =
         match body with
         | Some (ConcreteModuleBody (_, _, _, _, imports, defs)) -> (imports, List.concat_map (of_def body_filename) defs)
         | None -> ([], [])
       in
       Some (name, int_imports @ body_imports, (List.concat_map (of_decl int_filename) decls) @ body_decls)
    | Compiler.BodyModuleSource { body_filename; body_code } ->
       let (ConcreteModuleBody (name, _, _, _, imports, defs)) = ParserInterface.parse_module_body body_code body_filename in
       Some (name, imports, List.concat_map (of_def body_filename) defs)
  with Hilde_error _ -> None

(* The pervasive module, which every module sees without an import: from
   lib/builtin beside the compiler when it is there. *)
let pervasive (): declaration list =
  let dir = Filename.concat (Filename.dirname Sys.executable_name) "lib/builtin" in
  let file = Filename.concat dir "Pervasive.hih" in
  match read_file file with
  | Some code ->
     (try
        let (ConcreteModuleInterface (_, _, _, decls)) = ParserInterface.parse_module_int code file in
        List.concat_map (of_decl file) decls
      with Hilde_error _ -> [])
  | None -> []

(* The declaration a name of the document means: one of its own module,
   then one it imports under that name, then a pervasive one. *)
let resolve (path: string) (word: string): declaration option =
  let mods = modules_for path in
  let read = List.filter_map read_module mods in
  let own_stem = Filename.remove_extension path in
  let own =
    List.find_opt
      (fun (_, _, decls) ->
        List.exists (fun d -> Filename.remove_extension d.file = own_stem) decls)
      read
  in
  let own =
    match own with
    | Some m -> Some m
    | None -> (match source_of path with Some s -> read_module s | None -> None)
  in
  match own with
  | None -> None
  | Some (_, imports, decls) ->
     (match List.find_opt (fun d -> d.name = word) decls with
      | Some d -> Some d
      | None ->
         let imported =
           List.find_map
             (fun (ConcreteImportList (mn, names)) ->
               List.find_map
                 (fun (ConcreteImport (orig, rename)) ->
                   let local = match rename with Some r -> r | None -> orig in
                   if ident_string local = word then Some (mn, ident_string orig) else None)
                 names)
             imports
         in
         (match imported with
          | Some (mn, orig) ->
             List.find_map
               (fun (name, _, ds) ->
                 if equal_module_name name mn then List.find_opt (fun d -> d.name = orig) ds else None)
               read
          | None -> List.find_opt (fun d -> d.name = word) (pervasive ())))

(* The name under a position of a text: letters, digits and underscores
   around it on its line. *)
let word_at (text: string) (line: int) (character: int): string option =
  let lines = String.split_on_char '\n' text in
  match List.nth_opt lines line with
  | None -> None
  | Some l ->
     let ok c = (c = '_') || ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || ('0' <= c && c <= '9') in
     let n = String.length l in
     let at = min character n in
     let a = ref at and b = ref at in
     while !a > 0 && ok l.[!a - 1] do decr a done;
     while !b < n && ok l.[!b] do incr b done;
     if !b > !a then Some (String.sub l !a (!b - !a)) else None

let hover_json (d: declaration): Yojson.Basic.t =
  let value = "```hilde\n" ^ d.shown ^ "\n```" ^ (if d.doc = "" then "" else "\n\n" ^ d.doc) in
  `Assoc [("contents", `Assoc [("kind", `String "markdown"); ("value", `String value)])]

let location_json (d: declaration): Yojson.Basic.t =
  `Assoc [("uri", `String (uri_of_path d.file)); ("range", range_json d.span)]

(* --- The server -------------------------------------------------------------- *)

let publish (oc: out_channel) (path: string): unit =
  write_message oc (`Assoc [
      ("jsonrpc", `String "2.0");
      ("method", `String "textDocument/publishDiagnostics");
      ("params", `Assoc [("uri", `String (uri_of_path path)); ("diagnostics", `List (diagnostics path))])
    ])

let respond (oc: out_channel) (id: Yojson.Basic.t) (result: Yojson.Basic.t): unit =
  write_message oc (`Assoc [("jsonrpc", `String "2.0"); ("id", id); ("result", result)])

let respond_error (oc: out_channel) (id: Yojson.Basic.t) (code: int) (message: string): unit =
  write_message oc (`Assoc [("jsonrpc", `String "2.0"); ("id", id);
                            ("error", `Assoc [("code", `Int code); ("message", `String message)])])

let document_path (params: Yojson.Basic.t): string option =
  Option.map path_of_uri (to_string_opt (member "uri" (member "textDocument" params)))

(** Serve the protocol on ic and oc until exit.  Returns the exit code: 0
    when shutdown came before exit, 1 otherwise. *)
let serve ~(dirs: string list) (ic: in_channel) (oc: out_channel): int =
  module_dirs := dirs;
  let shut = ref false in
  let rec loop () =
    match read_message ic with
    | None -> if !shut then 0 else 1
    | Some msg ->
       let meth = to_string_opt (member "method" msg) in
       let id = member "id" msg in
       let params = member "params" msg in
       (match meth with
        | Some "initialize" ->
           respond oc id (`Assoc [
               ("capabilities", `Assoc [
                   ("textDocumentSync", `Int 1);
                   ("hoverProvider", `Bool true);
                   ("definitionProvider", `Bool true)
                 ]);
               ("serverInfo", `Assoc [("name", `String "hilde")])
             ]);
           loop ()
        | Some "shutdown" -> shut := true; respond oc id `Null; loop ()
        | Some "exit" -> if !shut then 0 else 1
        | Some "textDocument/didOpen" ->
           (match document_path params with
            | Some path ->
               (match to_string_opt (member "text" (member "textDocument" params)) with
                | Some t -> Hashtbl.replace documents path t
                | None -> ());
               publish oc path
            | None -> ());
           loop ()
        | Some "textDocument/didChange" ->
           (match document_path params with
            | Some path ->
               (match member "contentChanges" params with
                | `List changes ->
                   (match List.rev changes with
                    | last :: _ -> (match to_string_opt (member "text" last) with
                                    | Some t -> Hashtbl.replace documents path t
                                    | None -> ())
                    | [] -> ())
                | _ -> ());
               publish oc path
            | None -> ());
           loop ()
        | Some "textDocument/didSave" ->
           (match document_path params with Some path -> publish oc path | None -> ());
           loop ()
        | Some "textDocument/didClose" ->
           (match document_path params with Some path -> Hashtbl.remove documents path | None -> ());
           loop ()
        | Some ("textDocument/hover" | "textDocument/definition" as m) ->
           let found =
             match document_path params with
             | Some path ->
                let pos = member "position" params in
                (match text_of path with
                 | Some text ->
                    (match word_at text (to_int (member "line" pos)) (to_int (member "character" pos)) with
                     | Some w -> resolve path w
                     | None -> None)
                 | None -> None)
             | None -> None
           in
           respond oc id
             (match found with
              | Some d -> if m = "textDocument/hover" then hover_json d else location_json d
              | None -> `Null);
           loop ()
        | Some _ when id <> `Null -> respond_error oc id (-32601) "method not found"; loop ()
        | _ -> loop ())
  in
  loop ()
