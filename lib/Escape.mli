(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

(* A string where escape characters have been processed into the characters they
   represent. *)
type escaped_string
[@@deriving (show, sexp)]

(* Given a string with escape characters, process the escape characters and
   return a escaped string. *)
val escape_string : string -> escaped_string

(* Take a string of BYTES that carries no escape sequences -- the contents of
   a file -- and call it escaped, because there is nothing left to process. *)
val escaped_of_raw : string -> escaped_string

(* Return a escaped string as a regular string *)
val escaped_to_string : escaped_string -> string

(* Replace unrepresentable characters in a escaped string (e.g. newlines) with
   escape characters in C/C++ format. *)
val unescape_string : escaped_string -> string
