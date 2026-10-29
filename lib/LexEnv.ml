(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open Common
open Type
open Error
open ErrorText

type var_source =
  | VarConstant
  | VarParam
  | VarLocal of mutability

type lexenv_inner = LexEnv of (identifier * ty * var_source) list

type lexenv = lexenv_inner ref

let empty_lexenv _ =
  ref (LexEnv [])

let get_var (l: lexenv) (name: identifier): (ty * var_source) option =
  let (LexEnv inner) = !l in
  Option.map (fun (_, t, s) -> (t, s)) (List.find_opt (fun (n, _, _) -> n = name) inner)

let push_var l name ty source =
  let (LexEnv inner) = !l in
  match get_var l name with
  | (Some _) ->
     (* Most often a binding of a case or a destructuring that takes the
        name of a variable bound before it in the same function. *)
     hilde_raise (H 6020) GenericError [
         Text "The name ";
         Code (ident_string name);
         Text " is bound already in this function. A name stays bound until the end of the block it was bound in, also after its value is consumed, so a second binding needs a name of its own, as in ";
         Code ("value as other" ^ (String.capitalize_ascii (ident_string name)));
         Text "."
       ]
  | None ->
     let inner' = LexEnv ((name, ty, source) :: inner) in
     l := inner';
     l

let rec push_vars env l =
  match l with
  | (n,t,s)::rest ->
     push_vars (push_var env n t s) rest
  | [] ->
     env

let remove_var (l: lexenv) (name: identifier): unit =
  let (LexEnv inner) = !l in
  let filtered =
    List.filter (fun (n, _, _) -> not (equal_identifier name n)) inner
  in
  l := LexEnv filtered;
  ()

let rec remove_vars l names =
  match names with
  | [] ->
     ()
  | first::rest ->
     let _ = remove_var l first in
     remove_vars l rest
