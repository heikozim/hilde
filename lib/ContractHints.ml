(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* hilde check --missing-contracts: hints at the contracts a function's body
   lets the compiler derive, and the public functions that have none.

   A hint is not an error: it changes neither the check nor its exit.  Every
   hint names one clause, written as it would stand in the contract, so that
   a reader or a tool can add it as it is.  The derivations are few and
   cheap, each read off one expression of the body:

   - a division, or rem, by a parameter: requires p /= 0;
   - a span parameter indexed by a parameter: requires i < spanLength(s);
   - a subtraction of natural numbers whose left side is a parameter and
     whose right side is a parameter or a constant: requires a >= b;
   - every return returns the same literal: ensures result = c;
   - a parameter passed to a function whose requires speaks of it: that
     requires, the names of the callee's parameters replaced by the
     caller's.

   A hint is left out when the function already says it: the clause stands
   in the contract, the requires and the parameters' types prove it, or the
   body tests the parameter in a comparison of its own.  A function whose
   docstring or source holds the words No contract gets no hint at all. *)

open Identifier
open Common
open Span
open Cst
open Stages.Ast
open Stages.Combined
open Error
open ErrorText

(* Whether hints are gathered at all.  Only the check with the switch sets
   it; every other command combines its modules as before. *)
let enabled: bool ref = ref false

(* A function as the combining pass saw it, before its contract was made
   into statements. *)
type recorded = {
    module_name: module_name;
    name: identifier;
    public: bool;
    (* A public function of a module with an interface: its contract
       stands in the interface. *)
    interfaced: bool;
    at: span;
    (* Where the contract is written: the declaration in the interface for
       a public function, the definition otherwise. *)
    def_span: span;
    params: qparam list;
    requires: aexpr list;
    ensures: aexpr list;
    docstring: string;
    body: astmt;
  }

let table: (string, recorded) Hashtbl.t = Hashtbl.create 256

(* The keys in the order the functions were met, for an order of hints
   that does not depend on the hash table. *)
let order: string list ref = ref []

let key_of (mn: module_name) (name: identifier): string =
  (mod_name_string mn) ^ "." ^ (ident_string name)

let pervasive: module_name = make_mod_name "Hilde.Pervasive"

let record
      ~(module_name: module_name)
      ~(name: identifier)
      ~(public: bool)
      ~(interfaced: bool)
      ~(at: span)
      ~(def_span: span)
      ~(cond_imports: Imports.import_map)
      ~(params: qparam list)
      ~(clauses: contract_clause list)
      ~(docstring: docstring)
      (body: astmt): unit =
  if !enabled then begin
    let conds (k: contract_kind): aexpr list =
      List.filter_map
        (fun (ContractClause { kind; condition; _ }) ->
          if kind = k then Some (AbstractionPass.abs_expr cond_imports condition) else None)
        clauses
    in
    let (Docstring d) = docstring in
    let key = key_of module_name name in
    if not (Hashtbl.mem table key) then order := key :: !order;
    Hashtbl.replace table key {
        module_name; name; public; interfaced; at; def_span; params;
        requires = conds Requires; ensures = conds Ensures; docstring = d; body
      }
  end

(* --- Printing a condition as source text --------------------------------- *)

let operator_text (op: comparison_operator): string =
  match op with
  | Equal -> "="
  | NotEqual -> "/="
  | LessThan -> "<"
  | LessThanOrEqual -> "<="
  | GreaterThan -> ">"
  | GreaterThanOrEqual -> ">="

let arithmetic_text (op: arithmetic_operator): string =
  match op with
  | Add -> "+"
  | Subtract -> "-"
  | Multiply -> "*"
  | Divide -> "/"
  | Remainder -> "%"

(* The source text of an expression, with parentheses around every operand
   that is an operation, since Hilde has no precedence.  None for a form
   this printer does not write; a hint that would need one is left out. *)
let rec text (e: aexpr): string option =
  let all (l: aexpr list): string list option =
    List.fold_right
      (fun x acc -> match (text x, acc) with (Some s, Some r) -> Some (s :: r) | _ -> None)
      l (Some [])
  in
  let operand (x: aexpr): string option =
    match x with
    | ArithmeticExpression _ | Comparison _ | Conjunction _ | Disjunction _ | Negation _ ->
       Option.map (fun s -> "(" ^ s ^ ")") (text x)
    | _ -> text x
  in
  let binary (a: aexpr) (op: string) (b: aexpr): string option =
    match (operand a, operand b) with
    | (Some x, Some y) -> Some (x ^ " " ^ op ^ " " ^ y)
    | _ -> None
  in
  match e with
  | BoolConstant b -> Some (if b then "true" else "false")
  | IntConstant s -> Some s
  | NilConstant -> Some "nil"
  | Variable q -> Some (ident_string (local_name q))
  | BorrowExpr (ReadBorrow, q) -> Some ("&" ^ (ident_string (local_name q)))
  | BorrowExpr (WriteBorrow, q) -> Some ("&!" ^ (ident_string (local_name q)))
  | FunctionCall (q, Positional args) ->
     Option.map (fun l -> (ident_string (local_name q)) ^ "(" ^ (String.concat ", " l) ^ ")") (all args)
  | FunctionCall (q, Named args) ->
     Option.map
       (fun l ->
         let pairs = List.map2 (fun (n, _) v -> (ident_string n) ^ " => " ^ v) args l in
         (ident_string (local_name q)) ^ "(" ^ (String.concat ", " pairs) ^ ")")
       (all (List.map snd args))
  | ArithmeticExpression (op, a, b) -> binary a (arithmetic_text op) b
  | Comparison (op, a, b) -> binary a (operator_text op) b
  | Conjunction (a, b) -> binary a "and" b
  | Disjunction (a, b) -> binary a "or" b
  | Negation a -> Option.map (fun s -> "not " ^ s) (operand a)
  | ArithNegation (IntConstant s) -> Some ("-" ^ s)
  | Path (q, elems) ->
     let elem (p: path_elem): string option =
       match p with
       | SlotAccessor s -> Some ("." ^ (ident_string s))
       | PointerSlotAccessor s -> Some ("->" ^ (ident_string s))
       | ArrayIndex i -> Option.map (fun s -> "[" ^ s ^ "]") (text i)
     in
     List.fold_left
       (fun acc p -> match (acc, elem p) with (Some a, Some b) -> Some (a ^ b) | _ -> None)
       (Some (ident_string (local_name q))) elems
  | _ -> None

(* The texts a comparison has written either way round: a /= 0 and
   0 /= a, i < n and n > i.  Any other condition has its one text. *)
let spellings (e: aexpr): string list =
  let turned (op: comparison_operator): comparison_operator =
    match op with
    | LessThan -> GreaterThan
    | LessThanOrEqual -> GreaterThanOrEqual
    | GreaterThan -> LessThan
    | GreaterThanOrEqual -> LessThanOrEqual
    | Equal -> Equal
    | NotEqual -> NotEqual
  in
  let one = Option.to_list (text e) in
  match e with
  | Comparison (op, a, b) -> one @ (Option.to_list (text (Comparison (turned op, b, a))))
  | _ -> one

(* --- Reading the body ------------------------------------------------------ *)

(* Every expression the statement holds at its top, in the order written. *)
let rec stmt_exprs (s: astmt): aexpr list =
  match s with
  | ASkip _ | ARaise _ -> []
  | ALet (_, _, _, _, b) -> stmt_exprs b
  | ADestructure (_, _, _, e, b) -> e :: (stmt_exprs b)
  | AAssign (_, a, b) -> [a; b]
  | AInitialAssign (_, _, e) -> [e]
  | AIf (_, c, a, b) -> c :: ((stmt_exprs a) @ (stmt_exprs b))
  | AWhen (_, e, b) | AWhile (_, e, b) -> e :: (stmt_exprs b)
  | ACase (_, e, whens) ->
     e :: (List.concat_map (fun (AbstractWhen (_, _, b)) -> stmt_exprs b) whens)
  | APatternCase (_, e, whens) ->
     e :: (List.concat_map (fun (PatternWhen (_, _, b)) -> stmt_exprs b) whens)
  | AFor { initial; final; body; _ } -> initial :: final :: (stmt_exprs body)
  | ABorrow { body; _ } -> stmt_exprs body
  | ABlock (_, a, b) -> (stmt_exprs a) @ (stmt_exprs b)
  | ADiscarding (_, e) | AReturn (_, e) | ALetTmp (_, e) -> [e]

(* The conditions of the ifs and whiles of the statement. *)
let rec stmt_conditions (s: astmt): aexpr list =
  match s with
  | AIf (_, c, a, b) -> c :: ((stmt_conditions a) @ (stmt_conditions b))
  | AWhile (_, c, b) -> c :: (stmt_conditions b)
  | ALet (_, _, _, _, b) | ADestructure (_, _, _, _, b) | AWhen (_, _, b) -> stmt_conditions b
  | ACase (_, _, whens) ->
     List.concat_map (fun (AbstractWhen (_, _, b)) -> stmt_conditions b) whens
  | APatternCase (_, _, whens) ->
     List.concat_map (fun (PatternWhen (_, _, b)) -> stmt_conditions b) whens
  | AFor { body; _ } | ABorrow { body; _ } -> stmt_conditions body
  | ABlock (_, a, b) -> (stmt_conditions a) @ (stmt_conditions b)
  | ASkip _ | ARaise _ | AAssign _ | AInitialAssign _ | ADiscarding _ | AReturn _ | ALetTmp _ -> []

(* The expressions returned, in the order written. *)
let rec returns (s: astmt): aexpr list =
  match s with
  | AReturn (_, e) -> [e]
  | ALet (_, _, _, _, b) | ADestructure (_, _, _, _, b) | AWhen (_, _, b) | AWhile (_, _, b) -> returns b
  | AIf (_, _, a, b) | ABlock (_, a, b) -> (returns a) @ (returns b)
  | ACase (_, _, whens) -> List.concat_map (fun (AbstractWhen (_, _, b)) -> returns b) whens
  | APatternCase (_, _, whens) -> List.concat_map (fun (PatternWhen (_, _, b)) -> returns b) whens
  | AFor { body; _ } | ABorrow { body; _ } -> returns body
  | ASkip _ | ARaise _ | AAssign _ | AInitialAssign _ | ADiscarding _ | ALetTmp _ -> []

(* The expression and every expression inside it, outermost first. *)
let rec subexprs (e: aexpr): aexpr list =
  let many l = List.concat_map subexprs l in
  let args (a: abstract_arglist): aexpr list =
    match a with
    | Positional l -> l
    | Named l -> List.map snd l
  in
  let elems (l: path_elem list): aexpr list =
    List.filter_map (fun p -> match p with ArrayIndex i -> Some i | _ -> None) l
  in
  e :: (match e with
        | NilConstant | BoolConstant _ | IntConstant _ | FloatConstant _ | StringConstant _
        | Variable _ | SizeOf _ | BorrowExpr _ | Reborrow _ ->
           []
        | FunctionCall (_, a) -> many (args a)
        | ArithmeticExpression (_, a, b) | Comparison (_, a, b)
        | Conjunction (a, b) | Disjunction (a, b) ->
           many [a; b]
        | Negation a | ArithNegation a | Deref a | Typecast (a, _) | Question (_, a) -> subexprs a
        | IfExpression (c, t, f) -> many [c; t; f]
        | Path (_, l) | RefPath (_, l, _) -> many (elems l)
        | Embed (_, _, _, l) -> many l)

(* --- Types ------------------------------------------------------------------ *)

let type_name (ty: qtypespec): string option =
  match ty with
  | QTypeSpecifier (q, []) -> Some (ident_string (original_name q))
  | _ -> None

let unsigned_types: string list = ["Nat8"; "Nat16"; "Nat32"; "Nat64"; "Index"; "ByteSize"]

let integer_types: string list = unsigned_types @ ["Int8"; "Int16"; "Int32"; "Int64"]

let has_type (names: string list) (ty: qtypespec): bool =
  match type_name ty with
  | Some n -> List.mem n names
  | None -> false

let is_span (ty: qtypespec): bool =
  match ty with
  | QSpan _ | QSpanWrite _ -> true
  | _ -> false

(* --- The hints -------------------------------------------------------------- *)

type hint = {
    code: error_code;
    clause: string;
    (* The clause as it is written: requires c, or ensures c. *)
    reason: err_text;
  }

(* A code and the text of its reason.  The kind stands beside the code so
   that the registry of codes reads it as it reads a raise. *)
let coded (code: error_code) (_: error_kind) (reason: err_text): error_code * err_text =
  (code, reason)

let fname_text (r: recorded): string = ident_string r.name

let derive (r: recorded): hint list =
  let changed = (Contracts.declared_names r.body) @ (Contracts.assigned_names r.body) in
  let param_type (s: string): qtypespec option =
    List.find_map
      (fun (QualifiedParameter (n, ty)) -> if ident_string n = s then Some ty else None)
      r.params
  in
  (* A parameter whose value is the one the caller passed wherever the
     body reads it. *)
  let usable (q: qident): qtypespec option =
    let s = ident_string (local_name q) in
    if List.mem s changed then None else param_type s
  in
  (* The names the body compares or tests on its own: a hint about them
     would ignore the body's own handling. *)
  let tested: string list =
    let compared =
      List.concat_map
        (fun e ->
          List.concat_map
            (fun x -> match x with Comparison _ -> Contracts.free_names x | _ -> [])
            (subexprs e))
        (stmt_exprs r.body)
    in
    compared @ (List.concat_map Contracts.free_names (stmt_conditions r.body))
  in
  let free (q: qident): bool = not (List.mem (ident_string (local_name q)) tested) in
  let facts = Contracts.entrance_facts r.params r.body r.requires in
  let stated (conds: aexpr list): string list =
    List.concat_map spellings (List.concat_map Contracts.conjuncts conds)
  in
  let stated_requires = stated r.requires
  and stated_ensures = stated r.ensures in
  (* Whether the function already says a requires. *)
  let said (cond: aexpr): bool =
    (Contracts.truth facts cond = Contracts.Holds)
    || List.exists (fun s -> List.mem s stated_requires) (spellings cond)
  in
  let requires_hint ((code, reason): error_code * err_text) (cond: aexpr): hint option =
    if said cond then None
    else Option.map (fun t -> { code; clause = "requires " ^ t; reason }) (text cond)
  in
  let fn = fname_text r in
  let integer (q: qident): bool =
    match usable q with Some ty -> has_type integer_types ty | None -> false
  in
  (* A remainder by a parameter, written with the operator or with rem. *)
  let remainder_by (e: aexpr): (qident * aexpr) option =
    match e with
    | ArithmeticExpression (Remainder, _, (Variable q as d)) -> Some (q, d)
    | FunctionCall (f, Positional [_; (Variable q as d)]) when ident_string (original_name f) = "rem" -> Some (q, d)
    | _ -> None
  in
  let one (e: aexpr): hint list =
    match (e, remainder_by e) with
    | (_, Some (q, d)) when (free q) && (integer q) ->
       let reason =
         coded (H 2202) ContractHint [
             Text "The function "; Code fn; Text " takes the remainder by its parameter ";
             Code (ident_string (local_name q)); Text ", which may be 0."]
       in
       Option.to_list (requires_hint reason (Comparison (NotEqual, d, IntConstant "0")))
    | (_, Some _) -> []
    | (e, None) ->
    match e with
    | ArithmeticExpression (Divide, _, (Variable q as d)) when (free q) && (integer q) ->
       let reason =
         coded (H 2201) ContractHint [
             Text "The function "; Code fn; Text " divides by its parameter ";
             Code (ident_string (local_name q)); Text ", which may be 0."]
       in
       Option.to_list (requires_hint reason (Comparison (NotEqual, d, IntConstant "0")))
    | Path (h, (ArrayIndex (Variable i as ix)) :: _) | RefPath (h, (ArrayIndex (Variable i as ix)) :: _, _)
         when (free i) && (free h)
              && (match usable h with Some ty -> is_span ty | None -> false)
              && (usable i <> None) ->
       let length = FunctionCall (make_qident (pervasive, make_ident "spanLength", make_ident "spanLength"),
                                  Positional [Variable h]) in
       let reason =
         coded (H 2203) ContractHint [
             Text "The function "; Code fn; Text " reads the span "; Code (ident_string (local_name h));
             Text " at its parameter "; Code (ident_string (local_name i));
             Text ", which may lie past its end."]
       in
       Option.to_list (requires_hint reason (Comparison (LessThan, ix, length)))
    | ArithmeticExpression (Subtract, (Variable a as left), right)
         when (free a) && (match usable a with Some ty -> has_type unsigned_types ty | None -> false)
              && (match right with
                  | Variable b -> (free b) && (usable b <> None)
                  | IntConstant c -> c <> "0"
                  | _ -> false) ->
       let reason =
         coded (H 2204) ContractHint [
             Text "The function "; Code fn; Text " subtracts from its parameter ";
             Code (ident_string (local_name a));
             Text " of a natural type, which falls below 0 when the parameter is the smaller."]
       in
       Option.to_list (requires_hint reason (Comparison (GreaterThanOrEqual, left, right)))
    | _ -> []
  in
  let local = List.concat_map one (List.concat_map subexprs (stmt_exprs r.body)) in
  (* Of the bounds a >= c with a constant c that one parameter gets, only
     the largest is a hint: it says all the others. *)
  let bound (h: hint): (string * Z.t) option =
    match String.split_on_char ' ' h.clause with
    | ["requires"; p; ">="; c] when h.code = H 2204 ->
       (match Z.of_string c with n -> Some (p, n) | exception _ -> None)
    | _ -> None
  in
  let local =
    List.filter
      (fun h ->
        match bound h with
        | Some (p, n) ->
           not (List.exists
                  (fun o -> match bound o with Some (p', n') -> p' = p && Z.gt n' n | None -> false)
                  local)
        | None -> true)
      local
  in
  (* Every return returns the same literal. *)
  let constant: hint list =
    let literal (e: aexpr): aexpr option =
      match e with
      | IntConstant _ | BoolConstant _ -> Some e
      | Typecast ((IntConstant _ as c), _) -> Some c
      | _ -> None
    in
    match List.map literal (returns r.body) with
    | (Some c) :: rest when List.for_all (fun x -> x = Some c) rest ->
       let cond = Comparison (Equal, Variable (make_qident (r.module_name, make_ident "result", make_ident "result")), c) in
       if List.exists (fun s -> List.mem s stated_ensures) (spellings cond) then []
       else
         (match text cond with
          | Some t ->
             let (code, reason) =
               coded (H 2205) ContractHint [
                   Text "Every return of the function "; Code fn; Text " returns ";
                   Code (Option.value (text c) ~default:""); Text "."]
             in
             [{ code; clause = "ensures " ^ t; reason }]
          | None -> [])
    | _ -> []
  in
  local @ constant

(* The requires of the functions the body calls, said again with the
   caller's parameters, where the caller passes its own parameter. *)
let lifted (r: recorded): hint list =
  let changed = (Contracts.declared_names r.body) @ (Contracts.assigned_names r.body) in
  let caller_param (e: aexpr): qident option =
    match e with
    | Variable q ->
       let s = ident_string (local_name q) in
       if (not (List.mem s changed))
          && List.exists (fun (QualifiedParameter (n, _)) -> ident_string n = s) r.params
       then Some q else None
    | _ -> None
  in
  let tested: string list =
    List.concat_map
      (fun e ->
        List.concat_map
          (fun x -> match x with Comparison _ -> Contracts.free_names x | _ -> [])
          (subexprs e))
      (stmt_exprs r.body)
    @ (List.concat_map Contracts.free_names (stmt_conditions r.body))
  in
  let facts = Contracts.entrance_facts r.params r.body r.requires in
  let stated = List.concat_map spellings (List.concat_map Contracts.conjuncts r.requires) in
  let one (e: aexpr): hint list =
    match e with
    | FunctionCall (f, args) ->
       let key = key_of (source_module_name f) (original_name f) in
       (match Hashtbl.find_opt table key with
        | Some callee when callee.requires <> [] && key <> key_of r.module_name r.name ->
           let names = List.map (fun (QualifiedParameter (n, _)) -> ident_string n) callee.params in
           let passed: (string * aexpr) list =
             (* A call of a function with a requires carries the call site
                as its last argument; the name it has is in no parameter
                list, so it pairs with nothing. *)
             match args with
             | Positional l when List.length l = (List.length names) + 1 ->
                List.combine names (List.filteri (fun i _ -> i < List.length names) l)
             | Positional _ -> []
             | Named l -> List.map (fun (n, v) -> (ident_string n, v)) l
           in
           let same_module = equal_module_name callee.module_name r.module_name in
           (* A name of the condition the caller can write too: a function
              of the pervasive module, or any name when both are in one
              module. *)
           let reachable (q: qident): bool =
             same_module || equal_module_name (source_module_name q) pervasive
           in
           let ok = ref true and mapped = ref [] in
           let subst (x: aexpr): aexpr option =
             let swap (q: qident) (mk: qident -> aexpr): aexpr option =
               let s = ident_string (local_name q) in
               if List.mem s names then
                 (match Option.bind (List.assoc_opt s passed) caller_param with
                  | Some q' -> mapped := q' :: !mapped; Some (mk q')
                  | None -> ok := false; None)
               else if reachable q then None
               else (ok := false; None)
             in
             match x with
             | Variable q -> swap q (fun q' -> Variable q')
             | BorrowExpr (m, q) -> swap q (fun q' -> BorrowExpr (m, q'))
             | Path (q, elems) ->
                let s = ident_string (local_name q) in
                if List.mem s names then
                  (match Option.bind (List.assoc_opt s passed) caller_param with
                   | Some q' -> mapped := q' :: !mapped; Some (Path (q', elems))
                   | None -> ok := false; None)
                else None
             | FunctionCall (g, _) -> if not (reachable g) then ok := false; None
             | _ -> None
           in
           List.filter_map
             (fun cond ->
               ok := true;
               mapped := [];
               let cond' = Contracts.map_expr subst cond in
               let lifts = !ok && !mapped <> []
                           && not (List.exists
                                     (fun q -> List.mem (ident_string (local_name q)) tested) !mapped)
                           && Contracts.truth facts cond' <> Contracts.Holds
                           && not (List.exists (fun s -> List.mem s stated) (spellings cond'))
               in
               if not lifts then None
               else
                 match (text cond', text cond) with
                 | (Some t, Some original) ->
                    let (code, reason) =
                      coded (H 2206) ContractHint [
                          Text "The function "; Code (fname_text r); Text " passes its parameter ";
                                     Code (String.concat ", " (List.sort_uniq compare
                                                                 (List.map (fun q -> ident_string (local_name q)) !mapped)));
                                     Text " to "; Code (key_of callee.module_name callee.name);
                                     Text ", whose contract requires "; Code original;
                                     Text ", and states nothing about it."]
                    in
                    Some { code; clause = "requires " ^ t; reason }
                 | _ -> None)
             (List.concat_map Contracts.conjuncts callee.requires)
        | _ -> [])
    | _ -> []
  in
  List.concat_map one (List.concat_map subexprs (stmt_exprs r.body))

(* The source text of the lines of a span, or the empty string. *)
let span_source (source_of: string -> string option) (Span { filename; startp; endp }: span): string =
  match source_of filename with
  | None -> ""
  | Some code ->
     let (Position { line = l0; _ }) = startp and (Position { line = l1; _ }) = endp in
     let lines = String.split_on_char '\n' code in
     String.concat "\n" (List.filteri (fun i _ -> i + 1 >= l0 && i + 1 <= l1) lines)

let contains (hay: string) (needle: string): bool =
  let n = String.length needle and m = String.length hay in
  let rec go i = i + n <= m && (String.sub hay i n = needle || go (i + 1)) in
  n > 0 && go 0

(* For a slot, the run of -- comment lines above its group of slots.  A slot
   takes no docstring, so the reason of a group of slots stands in one
   comment above the group; the way up passes over blank lines, generic
   lines and the other slots of the group, and stops at anything else.  For
   a declaration that is no slot it is empty. *)
let comment_above (source_of: string -> string option) (Span { filename; startp; _ }: span): string =
  match source_of filename with
  | None -> ""
  | Some code ->
     let (Position { line; _ }) = startp in
     let lines = Array.of_list (String.split_on_char '\n' code) in
     let at (i: int): string = if i >= 0 && i < Array.length lines then String.trim lines.(i) else "" in
     let starts (p: string) (s: string): bool =
       String.length s >= String.length p && String.sub s 0 (String.length p) = p
     in
     (* The line above i that is not a generic line. *)
     let rec above (i: int): int = if starts "generic" (at (i - 1)) then above (i - 1) else i - 1 in
     let slot (i: int): bool = at (above i) = "pragma Slot;" in
     let rec up (i: int) (acc: string list): string list =
       if i < 0 then acc
       else
         let l = at i in
         if starts "--" l then up (i - 1) (l :: acc)
         else if acc <> [] then acc
         else if l = "" || starts "generic" l || l = "pragma Slot;" then up (i - 1) acc
         else if (starts "function" l || starts "method" l) && slot i then up (i - 1) acc
         else acc
     in
     let first = line - 1 in
     if slot first then String.concat "\n" (up (first - 1) []) else ""

let waived (source_of: string -> string option) (r: recorded): bool =
  let w = "No contract" in
  (contains r.docstring w) || (contains (span_source source_of r.at) w)
  || (contains (span_source source_of r.def_span) w)
  || (contains (comment_above source_of r.at) w)

(* The modules the rule of mandatory contracts leaves out: the state of an
   arena lives in the runtime, which checks it, and each function of
   Decimal checks its limit itself. *)
let exempt: string list = ["Standard.Arena"; "Standard.Decimal"]

let as_error (r: recorded) (h: hint): hilde_error =
  let where = if r.public && r.interfaced then " in its interface" else "" in
  make_hint h.code r.module_name r.at
    (h.reason
     @ [Break;
        Text ("Add the clause " ^ h.clause ^ " to the contract of ");
        Code (fname_text r); Text where;
        Text ", after the return type, or write a line No contract: and the reason in its docstring.";
        Suggest { replacement = h.clause; at = None; certain = false }])

let no_contract (r: recorded): hilde_error =
  let (code, text) =
    coded (H 2207) ContractHint [
        Text "The public function "; Code (fname_text r); Text " has no contract.";
        Break;
        Text "Write its requires and ensures in its interface, after the return type, or a line No contract: and the reason in its docstring."]
  in
  make_hint code r.module_name r.at text

(* The hints of the functions whose definition stands in one of [files],
   in the order of the source: those derived from the body first, then a
   public function without a contract. *)
let hints ~(source_of: string -> string option) ~(files: string list): hilde_error list =
  let in_files (r: recorded): bool =
    let (Span { filename; _ }) = r.def_span in
    List.mem filename files
  in
  let rs = List.filter_map (fun k -> Hashtbl.find_opt table k) (List.rev !order) in
  let rs = List.filter (fun r -> (in_files r) && not (waived source_of r)) rs in
  List.concat_map
    (fun r ->
      let derived = (derive r) @ (lifted r) in
      let seen = Hashtbl.create 8 in
      let derived =
        List.filter
          (fun h -> if Hashtbl.mem seen h.clause then false else (Hashtbl.add seen h.clause (); true))
          derived
      in
      let missing =
        if r.public && r.interfaced && r.requires = [] && r.ensures = []
           && not (List.mem (mod_name_string r.module_name) exempt)
        then [no_contract r] else []
      in
      (List.map (as_error r) derived) @ missing)
    rs

let reset (): unit =
  Hashtbl.reset table;
  order := []
