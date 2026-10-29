(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The checks of a typed module that the type Never asks for, and the check
   that every function ends.

   A function ends on every path in a return, a raise, a call of a function
   that returns Never, or a while whose condition is the literal true.  A
   function that returns Never has no return at all.  Never is the type of a
   result only: no parameter, variable, slot, constant, conversion or type
   argument has it, and a call that does not come back is not passed on as
   an argument or an operand. *)

open Identifier
open Type
open Stages.Tast
open Error
open Span

module Errors = struct
  let missing_return ~name ~declaration =
    hilde_raise (H 2031) DeclarationError [
      Text "The ";
      Text declaration;
      Text " ";
      Code (ident_string name);
      Text " does not end in a return statement."
    ]

  let return_in_never () =
    hilde_raise (H 2060) DeclarationError [
      Text "A return stands in a function that returns ";
      Code "Never";
      Text ".";
      Break;
      Text "A function that returns Never does not come back: it ends in a call of a function that returns Never, in a raise or in a loop that never ends."
    ]

  let never_does_not_end ~name =
    hilde_raise (H 2061) DeclarationError [
      Text "The function ";
      Code (ident_string name);
      Text " returns ";
      Code "Never";
      Text " but a path through it comes to its end.";
      Break;
      Text "Every path ends in a call of a function that returns Never, in a raise or in a while whose condition is true."
    ]

  let never_holds ~what =
    hilde_raise (H 3109) TypeError [
      Code "Never";
      Text " cannot be the type of ";
      Text what;
      Text ": it has no value.";
      Break;
      Text "Only the return type of a function or a method may be Never."
    ]

  let never_operand () =
    hilde_raise (H 3110) TypeError [
      Text "A call that does not come back stands where its value would be passed on.";
      Break;
      Text "Its result is Never; call it as a statement of its own."
    ]
end

let is_never (ty: ty): bool =
  match ty with
  | Never -> true
  | _ -> false

let rec contains_never (ty: ty): bool =
  match ty with
  | Never -> true
  | Unit | Boolean | Integer _ | SingleFloat | DoubleFloat | RegionTy _ | TyVar _ | MonoTy _ -> false
  | NamedType (_, args, _) -> List.exists contains_never args
  | ReadRef (t, r) | WriteRef (t, r) | Span (t, r) | SpanMut (t, r) -> contains_never t || contains_never r
  | Address t | Pointer t -> contains_never t
  | FnPtr (args, rt) -> List.exists contains_never args || contains_never rt

(* Whether an expression does not come back.  Only a call or an embed can;
   a constant is never asked for its type, which a string constant has only
   from where it stands. *)
let rec expr_never (e: texpr): bool =
  match e with
  | TFuncall (_, _, _, ty, _) | TMethodCall (_, _, _, _, ty, _) | TFptrCall (_, _, ty) | TEmbed (ty, _, _) ->
     is_never ty
  | TVarMethodCall { rt; _ } ->
     is_never rt
  | TIfExpression (_, t, f) ->
     expr_never t && expr_never f
  | _ ->
     false

let check_holds (what: string) (ty: ty): unit =
  if contains_never ty then Errors.never_holds ~what

(* A return type may be Never itself; Never inside it is a type argument. *)
let check_result (ty: ty): unit =
  if not (is_never ty) then check_holds "a type argument" ty

let rec operand (e: texpr): unit =
  if expr_never e then Errors.never_operand ();
  value e

(* An expression whose own result may be Never, with its parts checked as
   operands. *)
and value (e: texpr): unit =
  match e with
  | TNilConstant | TBoolConstant _ | TIntConstant _ | TFloatConstant _ | TStringConstant _
  | TConstVar _ | TParamVar _ | TLocalVar _ | TTemporary _ ->
     ()
  | TFunVar (_, ty, _) ->
     check_holds "a function pointer" ty
  | TFuncall (_, _, args, _, _) ->
     List.iter operand args
  | TMethodCall (_, _, _, args, _, _) ->
     List.iter operand args
  | TVarMethodCall { args; _ } ->
     List.iter operand args
  | TFptrCall (_, args, _) ->
     List.iter operand args
  | TCast (e, ty) ->
     check_holds "a conversion" ty;
     operand e
  | TComparison (_, a, b) | TConjunction (a, b) | TDisjunction (a, b) ->
     operand a;
     operand b
  | TNegation e ->
     operand e
  | TIfExpression (c, t, f) ->
     operand c;
     value t;
     value f
  | TRecordConstructor (_, fields) ->
     List.iter (fun (_, v) -> operand v) fields
  | TUnionConstructor (_, _, fields) ->
     List.iter (fun (_, v) -> operand v) fields
  | TSlotAccessor (e, _, _) | TPointerSlotAccessor (e, _, _) ->
     operand e
  | TArrayIndex (a, b, _) | TSpanIndex (a, b, _) ->
     operand a;
     operand b
  | TEmbed (_, _, args) ->
     List.iter operand args
  | TDeref e ->
     operand e
  | TSizeOf ty ->
     check_holds "a size" ty

let check_binding (TypedBinding { ty; _ }) =
  check_holds "a variable" ty

let rec walk (s: tstmt): unit =
  match s with
  | TSkip _ | TRaise _ | TUnreachable _ ->
     ()
  | TLet (span, _, _, ty, body) ->
     adorn_error_with_span span (fun _ -> check_holds "a variable" ty);
     walk body
  | TDestructure (span, _, bindings, e, body) ->
     adorn_error_with_span span (fun _ -> List.iter check_binding bindings; operand e);
     walk body
  | TAssign (span, lhs, rhs) ->
     adorn_error_with_span span (fun _ -> operand lhs; value rhs)
  | TAssignVar (span, _, rhs) ->
     adorn_error_with_span span (fun _ -> value rhs)
  | TInitialAssign (_, rhs) ->
     value rhs
  | TIf (span, c, t, f) ->
     adorn_error_with_span span (fun _ -> operand c);
     walk t;
     walk f
  | TCase (span, e, whens, _) ->
     adorn_error_with_span span (fun _ -> operand e);
     List.iter (fun (TypedWhen (_, bindings, body)) ->
         adorn_error_with_span span (fun _ -> List.iter check_binding bindings);
         walk body) whens
  | TWhile (span, c, body) ->
     adorn_error_with_span span (fun _ -> operand c);
     walk body
  | TFor (span, _, a, b, body) ->
     adorn_error_with_span span (fun _ -> operand a; operand b);
     walk body
  | TBorrow { body; _ } ->
     walk body
  | TBlock (_, a, b) ->
     walk a;
     walk b
  | TDiscarding (span, e) ->
     adorn_error_with_span span (fun _ -> value e)
  | TReturn (span, e) ->
     adorn_error_with_span span (fun _ -> value e)
  | TLetTmp (_, _, e) ->
     value e
  | TAssignTmp (_, e) ->
     value e
  | TSwitch (span, e, arms, other) ->
     adorn_error_with_span span (fun _ -> operand e);
     List.iter (fun (_, body) -> walk body) arms;
     walk other

let is_true (e: texpr): bool =
  match e with
  | TBoolConstant true -> true
  | _ -> false

(* Whether every assignment to the temporary t in the statement gives it
   true: the condition of a while, lifted into a temporary, that stays true. *)
let rec stays_true (t: identifier) (s: tstmt): bool =
  match s with
  | TAssignTmp (t', e) when equal_identifier t t' -> is_true e
  | TSkip _ | TAssign _ | TAssignVar _ | TInitialAssign _ | TLetTmp _ | TAssignTmp _
  | TDiscarding _ | TReturn _ | TRaise _ | TUnreachable _ ->
     true
  | TLet (_, _, _, _, body) | TDestructure (_, _, _, _, body) | TFor (_, _, _, _, body)
  | TWhile (_, _, body) ->
     stays_true t body
  | TBorrow { body; _ } ->
     stays_true t body
  | TIf (_, _, a, b) | TBlock (_, a, b) ->
     stays_true t a && stays_true t b
  | TCase (_, _, whens, _) ->
     List.for_all (fun (TypedWhen (_, _, body)) -> stays_true t body) whens
  | TSwitch (_, _, arms, other) ->
     List.for_all (fun (_, body) -> stays_true t body) arms && stays_true t other

(* Whether every path through the statement ends: in a return, a raise, a
   call that does not come back, or a loop that never ends. *)
let rec ends (s: tstmt): bool =
  match s with
  | TSkip _ | TAssign _ | TAssignVar _ | TInitialAssign _ | TLetTmp _ | TAssignTmp _ ->
     false
  | TLet (_, _, _, _, body) | TDestructure (_, _, _, _, body) | TFor (_, _, _, _, body) ->
     ends body
  | TBorrow { body; _ } ->
     ends body
  | TIf (_, _, t, f) ->
     ends t && ends f
  | TCase (_, _, whens, _) ->
     List.for_all (fun (TypedWhen (_, _, body)) -> ends body) whens
  | TSwitch (_, _, arms, other) ->
     List.for_all (fun (_, body) -> ends body) arms && ends other
  | TWhile (_, c, body) ->
     is_true c || ends body
  | TBlock (_, TLetTmp (t, _, c), TWhile (_, TTemporary (t', _), body))
       when equal_identifier t t' && is_true c && stays_true t body ->
     (* while true, its condition lifted into a temporary. *)
     true
  | TBlock (_, a, b) ->
     ends a || ends b
  | TDiscarding (_, e) ->
     expr_never e
  | TReturn _ | TRaise _ | TUnreachable _ ->
     true

(* The span a message about a whole body is given: its first statement. *)
let rec body_span (s: tstmt): span option =
  match s with
  | TSkip sp | TLet (sp, _, _, _, _) | TDestructure (sp, _, _, _, _) | TAssign (sp, _, _)
  | TAssignVar (sp, _, _) | TIf (sp, _, _, _) | TCase (sp, _, _, _) | TWhile (sp, _, _)
  | TFor (sp, _, _, _, _) | TDiscarding (sp, _) | TReturn (sp, _) | TRaise (sp, _)
  | TUnreachable sp | TSwitch (sp, _, _, _) ->
     Some sp
  | TBorrow { span; _ } ->
     Some span
  | TBlock (sp, _, _) ->
     Some sp
  | TInitialAssign _ | TLetTmp _ | TAssignTmp _ ->
     None

let at_body (body: tstmt) (f: unit -> unit): unit =
  match body_span body with
  | Some sp -> adorn_error_with_span sp f
  | None -> f ()

let check_body ~(declaration: string) (name: identifier) (rt: ty) (body: tstmt): unit =
  walk body;
  at_body body (fun _ ->
      if is_never rt then
        (if not (ends body) then Errors.never_does_not_end ~name)
      else if not (ends body) then
        Errors.missing_return ~name ~declaration)

let check_params (params: value_parameter list): unit =
  List.iter (fun (ValueParameter (_, ty)) -> check_holds "a parameter" ty) params

let check_decl (decl: typed_decl): unit =
  match decl with
  | TConstant (_, _, _, ty, e, _) ->
     check_holds "a constant" ty;
     value e
  | TRecord (_, _, _, _, _, slots, _) ->
     List.iter (fun (TypedSlot (_, ty)) -> check_holds "a slot" ty) slots
  | TUnion (_, _, _, _, _, cases, _) ->
     List.iter (fun (Stages.Linked.LCase (_, _, slots)) ->
         List.iter (fun (TypedSlot (_, ty)) -> check_holds "a slot" ty) slots) cases
  | TFunction (_, _, name, _, params, rt, body, _, _) ->
     check_params params;
     check_result rt;
     check_body ~declaration:"function" name rt body
  | TForeignFunction (_, _, _, params, rt, _, _) ->
     check_params params;
     check_holds "the result of a function written in C" rt
  | TTypeClass (_, _, _, _, methods, _) ->
     List.iter (fun (TypedMethodDecl (_, _, params, rt)) -> check_params params; check_result rt) methods
  | TInstance (_, _, _, _, ty, methods, _) ->
     check_holds "a type argument" ty;
     List.iter (fun (TypedMethodDef (_, name, params, rt, body)) ->
         check_params params;
         check_result rt;
         check_body ~declaration:"method" name rt body) methods

let check_module (TypedModule (_, decls)): unit =
  Reporter.with_frame "Never check"
    (fun _ -> List.iter check_decl decls)
