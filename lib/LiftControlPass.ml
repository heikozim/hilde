(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open Stages
open Span

(* A lifted temporary -- the value of an assignment, the condition of an
   `if' or a `while', the scrutinee of a `case', the bounds of a `for' --
   is typed in a block that carries the span of its statement.  Until
   2026-09-24 that block had the empty span: a type error in a scrutinee
   was then reported at whatever statement came before it, or at no place
   at all when none did. *)
let rec lift (stmt: Ast.astmt): AstLC.astmt =
  match stmt with
  | Ast.ASkip span ->
     AstLC.ASkip span
  | Ast.ALet (span, m, id, qt, s) ->
     AstLC.ALet (span, m, id, qt, lift s)
  | Ast.ADestructure (span, m, qbl, e, s) ->
     AstLC.ADestructure (span, m, qbl, transform e, lift s)
  | Ast.AAssign (span, lv, e) ->
     let tmp: identifier = fresh_ident () in
     let e = transform e in
     let lv = transform lv in
     AstLC.ABlock (
         span,
         AstLC.LetTmp (
             tmp,
             e
           ),
         AstLC.AAssign (span, lv, Temporary tmp)
       )
  | Ast.AInitialAssign (name, typespec, expr) ->
     AstLC.AInitialAssign (name, typespec, transform expr)
  | Ast.AIf (span, e, s1, s2) ->
     let tmp: identifier = fresh_ident () in
     let e = transform e in
     AstLC.ABlock (
         span,
         AstLC.LetTmp (
             tmp,
             e
           ),
         AstLC.AIf (
             span,
             Temporary tmp,
             lift s1,
             lift s2
           )
       )
  | Ast.AWhen (span, e, s) ->
     let tmp: identifier = fresh_ident () in
     let e = transform e in
     AstLC.ABlock (
         span,
         AstLC.LetTmp (
             tmp,
             e
           ),
         AstLC.AWhen (
             span,
             Temporary tmp,
             lift s
           )
       )
  | Ast.ACase (span, e, awl) ->
     let tmp: identifier = fresh_ident () in
     let e = transform e in
     AstLC.ABlock (
         span,
         AstLC.LetTmp (
             tmp,
             e
           ),
         AstLC.ACase (
             span,
             Temporary tmp,
             List.map transform_abstract_when awl
           )
       )
  | Ast.APatternCase (span, e, pwl) ->
     (* Lifted as the scrutinee of a case is.  The
        type checker takes the temporary as the value it decides on. *)
     let tmp: identifier = fresh_ident () in
     let e = transform e in
     AstLC.ABlock (
         span,
         AstLC.LetTmp (
             tmp,
             e
           ),
         AstLC.APatternCase (
             span,
             Temporary tmp,
             List.map (fun (Ast.PatternWhen (wspan, pats, s)) -> AstLC.PatternWhen (wspan, pats, lift s)) pwl
           )
       )
  | Ast.AWhile (span, e, s) ->
     let tmp: identifier = fresh_ident () in
     let e = transform e in
     AstLC.ABlock (
         span,
         AstLC.LetTmp (
             tmp,
             e
           ),
         AstLC.AWhile (
             span,
             Temporary tmp,
             AstLC.ABlock (
                 empty_span,
                 lift s,
                 AssignTmp (tmp, e)
               )
           )
       )
  | Ast.AFor {span; name; initial; final; body} ->
     let tmp_initial: identifier = fresh_ident () in
     let tmp_final: identifier = fresh_ident () in
     let idx =
       Ast.QTypeSpecifier (
           make_qident (
               make_mod_name "Hilde.Pervasive",
               make_ident "Index",
               make_ident "Index"
             ),
           []
         )
     in
     AstLC.ABlock (
         span,
         AstLC.LetTmp (
             tmp_initial,
             Typecast (transform initial, idx)
           ),
         AstLC.ABlock (
             span,
             AstLC.LetTmp (
                 tmp_final,
                 Typecast (transform final, idx)
               ),
             AstLC.AFor {
                 span;
                 name;
                 initial=Temporary tmp_initial;
                 final=Temporary tmp_final;
                 body=lift body
               }
           )
       )
  | Ast.ABorrow {span; original; rename; region; body; mode} ->
     AstLC.ABorrow {span; original; rename; region; body=lift body; mode}
  | Ast.ABlock (span, s1, s2) ->
     AstLC.ABlock (span, lift s1, lift s2)
  | Ast.ADiscarding (span, e) ->
     AstLC.ADiscarding (span, transform e)
  | Ast.ALetTmp (name, e) ->
     AstLC.LetTmp (name, transform e)
  | Ast.AReturn (span, e) ->
     AstLC.AReturn (span, transform e)
  | Ast.ARaise (span, kind) ->
     AstLC.ARaise (span, kind)

and transform (expr: Ast.aexpr): AstLC.aexpr =
  match expr with
  | Ast.NilConstant ->
    AstLC.NilConstant
  | Ast.BoolConstant b ->
    AstLC.BoolConstant b
  | Ast.IntConstant s ->
    AstLC.IntConstant s
  | Ast.FloatConstant s ->
    AstLC.FloatConstant s
  | Ast.StringConstant es ->
    AstLC.StringConstant es
  | Ast.Variable q ->
    AstLC.Variable q
  | Ast.FunctionCall (q, al) ->
    AstLC.FunctionCall (q, transform_arglist al)
  | Ast.ArithmeticExpression (ao, e1, e2) ->
    AstLC.ArithmeticExpression (ao, transform e1, transform e2)
  | Ast.Comparison (co, e1, e2) ->
    AstLC.Comparison (co, transform e1, transform e2)
  | Ast.Conjunction (e1, e2) ->
    AstLC.Conjunction (transform e1, transform e2)
  | Ast.Disjunction (e1, e2) ->
    AstLC.Disjunction (transform e1, transform e2)
  | Ast.Negation e ->
    AstLC.Negation (transform e)
  | Ast.ArithNegation e ->
    AstLC.ArithNegation (transform e)
  | Ast.IfExpression (e1, e2, e3) ->
    AstLC.IfExpression (transform e1, transform e2, transform e3)
  | Ast.Path (head, pel) ->
    AstLC.Path (head, transform_path pel)
  | Ast.RefPath (head, rpel, mode) ->
    AstLC.RefPath (head, transform_path rpel, mode)
  | Ast.Embed (span, qt, s, el) ->
    AstLC.Embed (span, qt, s, List.map transform el)
  | Ast.Deref e ->
    AstLC.Deref (transform e)
  | Ast.Typecast (e, qt) ->
    AstLC.Typecast (transform e, qt)
  | Ast.SizeOf qt ->
    AstLC.SizeOf qt
  | Ast.BorrowExpr (bm, q) ->
    AstLC.BorrowExpr (bm, q)
  | Ast.Reborrow q ->
    AstLC.Reborrow q
  | Ast.Question (span, e) ->
    AstLC.Question (span, transform e)

and transform_abstract_when aw =
  match aw with
  | Ast.AbstractWhen (id, qbl, s) -> AstLC.AbstractWhen (id, qbl, lift s)

and transform_arglist al =
  match al with
  | Ast.Positional el -> AstLC.Positional (List.map transform el)
  | Ast.Named idel -> AstLC.Named (List.map (fun (id, e) -> (id, transform e)) idel)

and transform_path (elems: Ast.path_elem list): AstLC.path_elem list =
  List.map transform_elem elems

and transform_elem (elem: Ast.path_elem): AstLC.path_elem =
  match elem with
  | Ast.SlotAccessor name ->
    AstLC.SlotAccessor name
  | Ast.PointerSlotAccessor name ->
    AstLC.PointerSlotAccessor name
  | Ast.ArrayIndex expr ->
    AstLC.ArrayIndex (transform expr)
