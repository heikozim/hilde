(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Imports
open Cst
module Ast = Stages.Ast
open Ast
open Escape
open Qualifier
open Span
open Common
open Error

(* `@bytes("path")'.

   The path is relative to the MODULE -- the file the span names -- and it
   may not leave that module's directory: an absolute path is refused and so
   is any `..' component.  That is stricter than "inside the project tree",
   and it is the stricter rule on purpose, because it can be checked without
   knowing where the tree begins.  The compiler is never told that, and a
   check that depends on something the compiler is not told is a check that
   is wrong on somebody else's machine. *)
let embedded_file_path (span: span) (path: string): string =
  let Span { filename; _ } = span in
  let refuse (why: string): 'a =
    adorn_error_with_span span
      (fun () -> err (H 6001) ("@bytes(\"" ^ path ^ "\"): " ^ why))
  in
  if path = "" then
    refuse "the path is empty"
  else if not (Filename.is_relative path) then
    refuse "the path is absolute, and a module may only embed a file beside itself"
  else
    let parts: string list = String.split_on_char '/' path in
    if List.exists (fun (p: string) -> p = "..") parts then
      refuse "the path leaves the module's own directory, which is not allowed"
    else
      Filename.concat (Filename.dirname filename) path

let read_embedded_file (span: span) (path: string): string =
  let full: string = embedded_file_path span path in
  try
    let stream = open_in_bin full in
    let size: int = in_channel_length stream in
    let contents: string = really_input_string stream size in
    close_in stream;
    contents
  with Sys_error message ->
    adorn_error_with_span span
      (fun () -> err (H 6002) ("@bytes(\"" ^ path ^ "\"): cannot read it: " ^ message))

(* Whether a function takes the call site of its callers, because
   it has a requires.  The combining pass sets it while it combines a module;
   outside that, no function does. *)
let contract_callee: (Identifier.qident -> bool) ref = ref (fun _ -> false)

(* The call site, "file:line" of the call, as the last argument. *)
let add_call_site (span: span) (args: abstract_arglist): abstract_arglist =
  let Span { filename; startp = Position { line; _ }; _ } = span in
  let site = StringConstant (escaped_of_raw (filename ^ ":" ^ (string_of_int line))) in
  match args with
  | Positional l -> Positional (l @ [site])
  | Named l -> Named (l @ [(Identifier.make_ident Names.contract_site_param, site)])

let sql_target (t: query_target): Sql.target =
  match t with
  | QueryBorrow name -> Sql.TBorrow name
  | QueryReborrow name -> Sql.TReborrow name

let rec abs_stmt im stmt =
  match stmt with
  | CSkip span ->
     ASkip span
  | CLet _ ->
     internal_err "Let statement not in a list context"
  | CDestructure _ ->
     internal_err "Destructure statement not in a list context"
  | CAssign (span, lvalue, value) ->
     AAssign (span, abs_expr im lvalue, abs_expr im value)
  | CIf (span, c, t, f) ->
     let c = abs_expr im c
     and t = abs_stmt im t
     and f = abs_stmt im f
     in
     (match f with
      | ASkip _ ->
         (* If the else branch is just a skip statement, we rewrite this into a
            `when` (i.e. an `if` without an `else`). This is because in the pass
            where we check all functions have a return value we need else-less
            whens. *)
         AWhen (span, c, t)
      | _ ->
         AIf (span, c, t, f))
  | CCase (span, e, cases) ->
     abs_case im span e cases
  | CWhile (span, c, b) ->
     AWhile (span, abs_expr im c, abs_stmt im b)
  | CFor (span, n, i, f, b) ->
     AFor {
         span = span;
         name = n;
         initial = abs_expr im i;
         final = abs_expr im f;
         body = abs_stmt im b
       }
  | CBorrow { span; original; rename; region; body; mode; _ } ->
     ABorrow { span; original; rename; region; body=abs_stmt im body; mode }
  | CBlock (_, l) ->
     let_reshape im l
  | CDiscarding (span, e) ->
     ADiscarding (span, abs_expr im e)
  | CTemplate (span, name, options, data, out) ->
     Jinja.expand im span name options data out
  | CQuery { span; target; sql; args; row; row_ty; body; error; handler } ->
     Sql.expand_query im span (sql_target target) sql (List.map (abs_expr im) args)
       row row_ty (abs_stmt im body) error (abs_stmt im handler)
  | CReturn (span, e) ->
     AReturn (span, abs_expr im e)
  (* The kind rides the statement; the check reads it there and
     the code generator writes the runtime stop.  No call is built, so a
     raise stays distinguishable from a written abort. *)
  | CRaise (span, kind) ->
     ARaise (span, Identifier.ident_string kind)

and try_folding (e: aexpr): aexpr =
  match try_folding' e with
  | Some bi ->
     IntConstant (Z.to_string bi)
  | None ->
     e

and try_folding' (e: aexpr): Z.t option =
  let parse_bigint (s: string): Z.t =
    try
      Z.of_string s
    with
    | Invalid_argument _ ->
       internal_err ("Failed to parse '" ^ s ^ "' as a big int. This is a bug in the parser.")
  in
  match e with
  | IntConstant i ->
     Some (parse_bigint i)
  | ArithNegation e -> begin
     match (try_folding' e) with
     | Some v -> Some (Z.neg v)
     | None -> None
    end
  | ArithmeticExpression (op, lhs, rhs) -> begin
      match (try_folding' lhs) with
      | Some lhs -> begin
          match (try_folding' rhs) with
          | Some rhs -> begin
              Some (apply_op op lhs rhs)
            end
          | None -> None
        end
      | None -> None
    end
  | _ ->
     None

and apply_op (op: arithmetic_operator) (lhs: Z.t) (rhs: Z.t): Z.t =
  let f =
    match op with
    | Add -> Z.add
    | Subtract -> Z.sub
    | Multiply -> Z.mul
    | Divide -> Z.div
  in
  f lhs rhs

and abs_expr im expr =
  match expr with
  | CNilConstant _ -> NilConstant
  | CBoolConstant (_, b) -> BoolConstant b
  | CIntConstant (_, i) -> IntConstant i
  | CFloatConstant (_, f) -> FloatConstant f
  | CStringConstant (span, s) -> StringConstant (adorn_error_with_span span (fun _ -> escape_string s))
  | CEmbedFile (span, path) -> StringConstant (escaped_of_raw (read_embedded_file span path))
  | CVariable (_, i) -> Variable (qualify_identifier im i)
  | CFuncall (span, name, args) ->
     let q = qualify_identifier im name in
     let args' = abs_arglist im args in
     if !contract_callee q then
       FunctionCall (q, add_call_site span args')
     else
       FunctionCall (q, args')
  | CArith (_, op, lhs, rhs) ->
     let e: aexpr = ArithmeticExpression (op, abs_expr im lhs, abs_expr im rhs) in
     try_folding e
  | CComparison (_, op, lhs, rhs) ->
     Comparison (op, abs_expr im lhs, abs_expr im rhs)
  | CConjunction (_, lhs, rhs) ->
     Conjunction (abs_expr im lhs, abs_expr im rhs)
  | CDisjunction (_, lhs, rhs) ->
     Disjunction (abs_expr im lhs, abs_expr im rhs)
  | CNegation (_, e) ->
     Negation (abs_expr im e)
  | CArithNegation (_, e) ->
     try_folding (ArithNegation (abs_expr im e))
  | CIfExpression (_, c, t, f) ->
     IfExpression (abs_expr im c, abs_expr im t, abs_expr im f)
  | CPath (_, head, es) ->
     Path (qualify_identifier im head, List.map (abs_path_elem im) es)
  | CRefPath (_, head, es, mode) ->
     RefPath (qualify_identifier im head, List.map (abs_path_elem im) es, mode)
  | CEmbed (span, ty, expr, args) ->
     Embed (span, qualify_typespec im ty, expr, List.map (abs_expr im) args)
  | CDeref (_, e) ->
     Deref (abs_expr im e)
  | CTypecast (_, e, ty) ->
     Typecast (abs_expr im e, qualify_typespec im ty)
  | CSizeOf (_, ty) ->
     SizeOf (qualify_typespec im ty)
  | CBorrowExpr (_, mode, var) ->
     BorrowExpr (mode, qualify_identifier im var)
  | CReborrow (_, name) ->
     Reborrow (qualify_identifier im name)
  | CExecute (span, target, sql, args) ->
     Sql.expand_execute im span (sql_target target) sql (List.map (abs_expr im) args)
  | CMigrations span ->
     Sql.expand_migrations im span
  | CQuestion (span, e) ->
     Question (span, abs_expr im e)

(* A case whose every when is the old form
   -- a variant with named, typed bindings, or a bare variant name -- is the
   old statement and is abstracted exactly as before.  One pattern when
   makes the whole case a pattern case. *)
and abs_case im span e cases =
  if List.for_all is_old_when cases then
    ACase (span, abs_expr im e, List.map (abs_old_when im) cases)
  else
    adorn_error_with_span span
      (fun _ -> APatternCase (span, abs_expr im e, List.map (abs_pattern_when im) cases))

and is_old_when (w: concrete_when): bool =
  match w with
  | ConcreteWhen _ -> true
  | ConcretePatternWhen (_, [CPName (_, name)], _) -> is_variant_name name
  | ConcretePatternWhen _ -> false

(* A name that begins with an upper-case letter is a variant, any other
   is a variable. *)
and is_variant_name (name: Identifier.identifier): bool =
  let s = Identifier.ident_string name in
  (String.length s > 0) && (s.[0] >= 'A') && (s.[0] <= 'Z')

and abs_old_when im (w: concrete_when): abstract_when =
  match w with
  | ConcreteWhen (name, bindings, body) ->
     AbstractWhen (name,
                   List.map (fun (ConcreteBinding { name; ty; rename; }) -> QBinding { name; ty = qualify_typespec im ty; rename }) bindings,
                   abs_stmt im body)
  | ConcretePatternWhen (_, [CPName (_, name)], body) ->
     AbstractWhen (name, [], abs_stmt im body)
  | ConcretePatternWhen _ ->
     internal_err "abs_old_when: a pattern when is not an old when"

and abs_pattern_when im (w: concrete_when): pattern_when =
  match w with
  | ConcreteWhen (name, [], body) ->
     (* `when X() do': the variant without sub-patterns. *)
     PatternWhen (empty_span, [PVariant (empty_span, name, [])], abs_stmt im body)
  | ConcreteWhen (name, _, _) ->
     hilde_raise (H 3071) TypeError [
         Text "The when of ";
         Code (Identifier.ident_string name);
         Text " binds its slots by name and type, but this case uses patterns in another when.";
         Break;
         Text "A case either binds by name in every when, or uses patterns in every when: write the slots of ";
         Code (Identifier.ident_string name);
         Text " as patterns, one per slot in the order the union declares them."
       ]
  | ConcretePatternWhen (span, pats, body) ->
     adorn_error_with_span span
       (fun _ -> PatternWhen (span, List.map abs_pattern pats, abs_stmt im body))

and abs_pattern (p: concrete_pattern): apattern =
  match p with
  | CPWild span -> PWild span
  | CPBool (span, b) -> PBool (span, b)
  | CPInt (span, v) -> PInt (span, v)
  | CPRange (span, lo, hi) -> PRange (span, lo, hi)
  | CPFloat (span, f) ->
     adorn_error_with_span span
       (fun _ ->
         hilde_raise (H 3080) TypeError [
             Text "The float literal ";
             Code f;
             Text " cannot be a pattern.";
             Break;
             Text "A pattern compares for equality, and two floats that print alike need not be equal.  Only integer and Bool literals are patterns; bind the value to a variable and compare it in the body."
           ])
  | CPString (span, _) ->
     adorn_error_with_span span
       (fun _ ->
         hilde_raise (H 3081) TypeError [
             Text "A string literal cannot be a pattern.";
             Break;
             Text "Only integer and Bool literals are patterns; bind the value to a variable and compare it in the body."
           ])
  | CPName (span, name) ->
     if is_variant_name name then
       PVariant (span, name, [])
     else
       PVar (span, name)
  | CPVariant (span, name, args) ->
     if is_variant_name name then
       PVariant (span, name, List.map abs_pattern args)
     else
       adorn_error_with_span span
         (fun _ ->
           hilde_raise (H 3087) TypeError [
               Code (Identifier.ident_string name);
               Text " takes sub-patterns, but its name begins with a lower-case letter, which makes it a variable.";
               Break;
               Text "Only a variant takes sub-patterns, and a variant's name begins with an upper-case letter."
             ])

and abs_arglist im args =
  match args with
  | ConcretePositionalArgs l ->
     Positional (List.map (abs_expr im) l)
  | ConcreteNamedArgs l ->
     Named (List.map (fun (n, v) -> (n, abs_expr im v)) l)

and abs_path_elem im elem =
  match elem with
  | CSlotAccessor i ->
     SlotAccessor i
  | CPointerSlotAccessor i ->
     PointerSlotAccessor i
  | CArrayIndex ie ->
     ArrayIndex (abs_expr im ie)

(* Given a list of statements, find the first let statement, if any, and put the
   remainder of the list under its body. Then call let_reshape on that
   remainder. *)
and let_reshape (im: import_map) (l: cstmt list): astmt =
  match l with
  | first::rest ->
     (match first with
      | CLet (span, mut, n, t, v) ->
         ALet (span, mut, n, qualify_typespec im t,
               ABlock (empty_span, AInitialAssign (qualify_identifier im n, qualify_typespec im t, Typecast (abs_expr im v, qualify_typespec im t)), let_reshape im rest))
      | CDestructure (span, mut, bs, e) ->
         let bs' = List.map (fun (ConcreteBinding {name; ty; rename; }) -> QBinding { name; ty = qualify_typespec im ty; rename; }) bs
         and e' = abs_expr im e
         and b = let_reshape im rest
         in
         ADestructure (span, mut, bs', e', b)
      | s ->
         (if rest = [] then
            abs_stmt im s
          else
            ABlock (empty_span, abs_stmt im s, let_reshape im rest)))
  | [] ->
     ASkip empty_span
