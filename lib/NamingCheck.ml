(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Identifier
open Span
open Type
open Stages.Tast

let is_snake (s: string): bool =
  not (String.exists (fun c -> c >= 'A' && c <= 'Z') s)

let is_camel (s: string): bool =
  let n = String.length s in
  let rec ok i =
    if i >= n then true
    else if s.[i] = '_' && i + 1 < n && not (s.[i + 1] >= '0' && s.[i + 1] <= '9') then false
    else ok (i + 1)
  in
  n > 0 && not (s.[0] >= 'A' && s.[0] <= 'Z') && ok 0

(* A name the compiler made: it begins with an underscore. *)
let generated (s: string): bool = s = "" || s.[0] = '_'

let finding (span: span) (name: string) (parameter: bool) (func: string) (text: string): UnusedCheck.finding =
  { span; name; parameter; func; code = "N001"; text }

(* The names a body binds that are not snake_case, in the order of the
   source. *)
let rec bound (func: string) (s: tstmt): UnusedCheck.finding list =
  let go = bound func in
  let check span name what =
    let n = ident_string name in
    if generated n || is_snake n then []
    else [finding span n false func (Printf.sprintf "the %s %s in %s is not snake_case" what n func)]
  in
  match s with
  | TLet (span, _, name, _, body) -> check span name "variable" @ go body
  | TDestructure (span, _, bindings, _, body) ->
     List.concat_map (fun (TypedBinding { rename; _ }) -> check span rename "variable") bindings @ go body
  | TFor (span, name, _, _, body) -> check span name "variable" @ go body
  | TBorrow { span; rename; body; _ } -> check span rename "variable" @ go body
  | TCase (span, _, whens, _) ->
     List.concat_map (fun (TypedWhen (_, bindings, body)) ->
         List.concat_map (fun (TypedBinding { rename; _ }) -> check span rename "variable") bindings
         @ go body) whens
  | TIf (_, _, t, f) -> go t @ go f
  | TWhile (_, _, body) -> go body
  | TBlock (_, a, b) -> go a @ go b
  | TSwitch (_, _, arms, rest) -> List.concat_map (fun (_, body) -> go body) arms @ go rest
  | TSkip _ | TRaise _ | TUnreachable _ | TAssign _ | TAssignVar _ | TInitialAssign _
  | TDiscarding _ | TReturn _ | TLetTmp _ | TAssignTmp _ -> []

let of_body (name: identifier) (is_function: bool) (params: value_parameter list) (body: tstmt): UnusedCheck.finding list =
  let func = ident_string name in
  match UnusedCheck.first_span body with
  | None -> []
  | Some at ->
     let own =
       if is_function && not (generated func) && not (is_camel func) then
         [finding at func false func (Printf.sprintf "the function %s is not camelCase" func)]
       else []
     in
     let params =
       List.filter_map (fun (ValueParameter (p, _)) ->
           let n = ident_string p in
           if generated n || is_snake n then None
           else Some (finding at n true func (Printf.sprintf "the parameter %s of %s is not snake_case" n func)))
         params
     in
     List.filter (fun (f: UnusedCheck.finding) -> not (UnusedCheck.generated_file f.span))
       (own @ params @ bound func body)

let findings (TypedModule (_, decls)): UnusedCheck.finding list =
  List.concat_map (fun d ->
      match d with
      | TFunction (_, _, name, _, params, _, body, _, _) -> of_body name true params body
      | TInstance (_, _, _, _, _, methods, _) ->
         List.concat_map (fun (TypedMethodDef (_, name, params, _, body)) -> of_body name false params body) methods
      | _ -> []) decls
