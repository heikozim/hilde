(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Identifier
open Span
open Type
open TypeSystem
open Stages.Tast

type finding = {
    span: span;
    name: string;
    parameter: bool;
    func: string;
    code: string;
    text: string;
  }

(* An expression reads the name when it holds it at least once; the count
   is the one the linearity check makes, and its type is opaque, so it is
   held against the count of an expression that holds no name. *)
let in_expr (name: identifier) (e: texpr): bool =
  LinearityCheck.count name e <> LinearityCheck.count name TNilConstant

(* Whether a statement reads the name anywhere.  A borrow of it reads it;
   an assignment to it does not. *)
let rec reads (name: identifier) (s: tstmt): bool =
  let r = reads name and e = in_expr name in
  match s with
  | TSkip _ | TRaise _ | TUnreachable _ -> false
  | TLet (_, _, _, _, body) -> r body
  | TDestructure (_, _, _, value, body) -> e value || r body
  | TAssign (_, lhs, rhs) -> e lhs || e rhs
  | TAssignVar (_, _, value) -> e value
  | TInitialAssign (_, value) -> e value
  | TIf (_, c, t, f) -> e c || r t || r f
  | TCase (_, scrutinee, whens, _) ->
     e scrutinee || List.exists (fun (TypedWhen (_, _, body)) -> r body) whens
  | TWhile (_, c, body) -> e c || r body
  | TFor (_, _, lo, hi, body) -> e lo || e hi || r body
  | TBorrow { original; body; _ } -> equal_identifier original name || r body
  | TBlock (_, a, b) -> r a || r b
  | TDiscarding (_, value) -> e value
  | TReturn (_, value) -> e value
  | TLetTmp (_, _, value) -> e value
  | TAssignTmp (_, value) -> e value
  | TSwitch (_, scrutinee, arms, rest) ->
     e scrutinee || List.exists (fun (_, body) -> r body) arms || r rest

(* The place of the first statement that carries one, for a parameter,
   which has no place of its own in the typed tree. *)
let rec first_span (s: tstmt): span option =
  match s with
  | TSkip span | TUnreachable span | TRaise (span, _) -> Some span
  | TLet (span, _, _, _, _) | TDestructure (span, _, _, _, _) | TAssign (span, _, _)
  | TAssignVar (span, _, _) | TIf (span, _, _, _) | TCase (span, _, _, _)
  | TWhile (span, _, _) | TFor (span, _, _, _, _) | TDiscarding (span, _)
  | TReturn (span, _) | TSwitch (span, _, _, _) -> Some span
  | TBorrow { span; _ } -> Some span
  | TBlock (span, a, _) ->
     (match first_span a with
      | Some s -> Some s
      | None -> Some span)
  | TInitialAssign _ | TLetTmp _ | TAssignTmp _ -> None

(* A name the compiler made, not the programmer: it begins with an
   underscore, which a programme cannot write. *)
let generated (name: identifier): bool =
  let s = ident_string name in
  s = "" || s.[0] = '_'

let is_free (ty: ty): bool =
  match type_universe ty with
  | FreeUniverse -> true
  | _ -> false

let generated_file (Span.Span { filename; _ }): bool =
  let marker = "bindings/generated/" in
  let n = String.length marker and m = String.length filename in
  let rec at i = i + n <= m && (String.sub filename i n = marker || at (i + 1)) in
  filename = "" || at 0

(* The let bindings of a body that the rest of their scope never reads. *)
let rec unread_lets (func: string) (s: tstmt): finding list =
  let go = unread_lets func in
  match s with
  | TLet (span, _, name, ty, body) ->
     let here =
       if is_free ty && not (generated name) && not (reads name body) then
         [{ span; name = ident_string name; parameter = false; func; code = "N002";
          text = Printf.sprintf "the binding %s in %s is never read" (ident_string name) func }]
       else []
     in
     here @ go body
  | TDestructure (_, _, _, _, body) -> go body
  | TIf (_, _, t, f) -> go t @ go f
  | TCase (_, _, whens, _) -> List.concat_map (fun (TypedWhen (_, _, body)) -> go body) whens
  | TWhile (_, _, body) | TFor (_, _, _, _, body) -> go body
  | TBorrow { body; _ } -> go body
  | TBlock (_, a, b) -> go a @ go b
  | TSwitch (_, _, arms, rest) -> List.concat_map (fun (_, body) -> go body) arms @ go rest
  | TSkip _ | TRaise _ | TUnreachable _ | TAssign _ | TAssignVar _ | TInitialAssign _
  | TDiscarding _ | TReturn _ | TLetTmp _ | TAssignTmp _ -> []

let of_function (name: identifier) (params: value_parameter list) (body: tstmt): finding list =
  let func = ident_string name in
  match first_span body with
  | None -> []
  | Some at ->
     let params =
       List.filter_map (fun (ValueParameter (p, ty)) ->
           if is_free ty && not (generated p) && not (reads p body) then
             Some { span = at; name = ident_string p; parameter = true; func; code = "N002";
                    text = Printf.sprintf "the parameter %s of %s is never read" (ident_string p) func }
           else None) params
     in
     List.filter (fun f -> not (generated_file f.span)) (params @ unread_lets func body)

let findings (TypedModule (_, decls)): finding list =
  List.concat_map (fun d ->
      match d with
      | TFunction (_, _, name, _, params, _, body, _, _) -> of_function name params body
      | _ -> []) decls

let message (f: finding): string = f.code ^ ": " ^ f.text

let store: finding list ref = ref []

let reset (): unit = store := []

let record (found: finding list): unit = store := !store @ found

let recorded (): finding list = !store
