(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Util
open Error
open ErrorText
open Sexplib
open Std

type escaped_string = EscapedString of string
[@@deriving (show, sexp)]

let is_hex c =
  (('0' <= c) && (c <= '9')) || (('a' <= c) && (c <= 'f')) || (('A' <= c) && (c <= 'F'))

let hex_value c =
  if ('0' <= c) && (c <= '9') then Char.code c - 48
  else if ('a' <= c) && (c <= 'f') then Char.code c - 87
  else Char.code c - 55

let utf8_of_code_point cp =
  let b x = Char.chr x in
  if cp < 0x80 then [b cp]
  else if cp < 0x800 then [b (0xC0 lor (cp lsr 6)); b (0x80 lor (cp land 0x3F))]
  else if cp < 0x10000 then
    [b (0xE0 lor (cp lsr 12)); b (0x80 lor ((cp lsr 6) land 0x3F)); b (0x80 lor (cp land 0x3F))]
  else
    [b (0xF0 lor (cp lsr 18)); b (0x80 lor ((cp lsr 12) land 0x3F));
     b (0x80 lor ((cp lsr 6) land 0x3F)); b (0x80 lor (cp land 0x3F))]

let bad_unicode_escape () =
  hilde_raise (H 6058) ParseError [
      Text "A ";
      Code "\\u{...}";
      Text " escape takes one to six hexadecimal digits of a code point up to ";
      Code "10FFFF";
      Text ", and no surrogate (";
      Code "D800";
      Text " to ";
      Code "DFFF";
      Text ")."
    ]

let rec escape_string s =
  EscapedString (string_implode (escape_list (string_explode s)))

and escape_list lst =
  match lst with
  | ('\\' :: 'n' :: rest) -> '\n' :: (escape_list rest)
  | ('\\' :: 'r' :: rest) -> '\r' :: (escape_list rest)
  | ('\\' :: 't' :: rest) -> '\t' :: (escape_list rest)
  | ('\\' :: '\'' :: rest) -> '\'' :: (escape_list rest)
  | ('\\' :: '"' :: rest) -> '"' :: (escape_list rest)
  | ('\\' :: '\\' :: rest) -> '\\' :: (escape_list rest)
  | ('\\' :: 'u' :: '{' :: rest) -> unicode_escape rest
  | ('\\' :: ' ' :: rest) -> consume_whitespace (' ' :: rest)
  | ('\\' :: '\n' :: rest) -> consume_whitespace (' ' :: rest)
  | ('\\' :: '\r' :: rest) -> consume_whitespace (' ' :: rest)
  | ('\\' :: '\t' :: rest) -> consume_whitespace (' ' :: rest)
  | (head :: rest) -> head :: (escape_list rest)
  | nil -> nil

(* After the backslash that ends a continuation the rest of the string is
   read on, escapes and further continuations included.  It was returned as
   it stood, so that a second continuation and every escape after the first
   one stayed in the string as written (measured: two
   continuations gave 21 bytes for 6, "\t" after one gave two bytes). *)
and consume_whitespace lst =
  match lst with
  | (' '  :: rest) -> consume_whitespace rest
  | ('\n' :: rest) -> consume_whitespace rest
  | ('\r' :: rest) -> consume_whitespace rest
  | ('\t' :: rest) -> consume_whitespace rest
  | ('\\' :: rest) -> escape_list rest
  | _ -> err (H 6018) "Bad whitespace escape sequence"

(* \u{X} with one to six hexadecimal digits: the code point X written as
   UTF-8, as the escape of Rust and JavaScript.  Before it was read, the
   six characters stayed in the string as they were written. *)
and unicode_escape lst =
  let rec digits acc n lst =
    match lst with
    | '}' :: rest when n > 0 -> (acc, rest)
    | c :: rest when n < 6 && is_hex c -> digits ((acc * 16) + hex_value c) (n + 1) rest
    | _ -> bad_unicode_escape ()
  in
  let (cp, rest) = digits 0 0 lst in
  if (cp > 0x10FFFF) || ((cp >= 0xD800) && (cp <= 0xDFFF)) then
    bad_unicode_escape ()
  else
    (utf8_of_code_point cp) @ (escape_list rest)

let escaped_to_string (EscapedString s) =
  s

(* The bytes of a file are already the bytes that are
   meant: nothing in them is an escape sequence to be processed, and a
   backslash in a PNG is a backslash.  `escape_string' would read one as the
   start of an escape and eat the byte after it. *)
let escaped_of_raw (s: string): escaped_string =
  EscapedString s

let rec unescape_string (EscapedString s) =
  String.concat "" (List.map unescape_char (string_explode s))

and unescape_char = function
  | '\n' -> "\\n"
  | '\r' -> "\\r"
  | '\t' -> "\\t"
  | '\'' -> "\\\'"
  | '\\' -> "\\\\"
  | '"' -> "\\\""
  | c ->
     (* `@bytes' puts arbitrary file contents into a C string
        literal, where a NUL and every byte above 126 have to be written as
        an escape.  OCTAL and not hex: a hex escape in C is greedy and runs
        on into the next character when that happens to be a hex digit,
        while `\\ooo' is at most three digits and stops.  Text literals are
        unaffected -- every byte of one is already in 32..126 or handled
        above. *)
     let code: int = Char.code c in
     if (code < 32) || (code > 126) then
       Printf.sprintf "\\%03o" code
     else
       String.make 1 c
