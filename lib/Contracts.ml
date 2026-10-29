(*
   Part of the Hilde project.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The contract of a function: its requires and ensures clauses, made into
   ordinary statements before the checks of the compiler run, and the check
   after typing that a condition only reads. *)

open Identifier
open Common
open Span
open Cst
open Stages.Ast
open Stages.Combined
open Stages.Tast
open Type
open TypeSystem
open Id
open Env
open EnvTypes
open Escape
open Error
open ErrorText

(* --- Names ------------------------------------------------------------- *)

let site_param: identifier = make_ident Names.contract_site_param

let pervasive: module_name = make_mod_name "Hilde.Pervasive"

let pervasive_q (name: string): qident =
  make_qident (pervasive, make_ident name, make_ident name)

(* What a temporary made here stands for.  The check after typing finds a
   condition by the name of its temporary. *)
type temp_kind =
  | TempRequires
  | TempEnsures
  | TempOld
  | TempResult

type temp_info = {
    kind: temp_kind;
    clause_span: span;
    text: string;
  }

let temps: (string, temp_info) Hashtbl.t = Hashtbl.create 64

let counter: int ref = ref 0

(* The conditions made for the module being compiled that the check after
   typing has not seen yet.  One it never sees is an error of the compiler,
   not a condition that passed. *)
let pending: string list ref = ref []

let begin_module (): unit =
  pending := []

(* A fresh temporary.  Its name begins with an underscore, which no name a
   programme writes does, so it can neither hide nor be hidden. *)
let fresh_temp (info: temp_info): identifier =
  counter := !counter + 1;
  let name = "_hilde_contract_" ^ (string_of_int !counter) in
  Hashtbl.replace temps name info;
  (match info.kind with
   | TempResult -> ()
   | _ -> pending := name :: !pending);
  make_ident name

let is_result_temp (name: identifier): bool =
  match Hashtbl.find_opt temps (ident_string name) with
  | Some { kind = TempResult; _ } -> true
  | _ -> false

(* How a variable is named in a message: a temporary that holds the
   returned value is result. *)
let display_name (name: identifier): string =
  if is_result_temp name then "result" else ident_string name

let site_of_span (sp: span): string =
  let (Span.Span { filename; startp = Span.Position { line; _ }; _ }) = sp in
  filename ^ ":" ^ (string_of_int line)

(* --- The report of the clauses not proved ------------------------------- *)

(* hilde compile --contract-report: one line for every clause the compiler
   does not prove, which the C checks at run time -- every requires, at
   every call, and every ensures at each return where the prover could not
   show it.  The lines are gathered while the functions are rewritten and
   written by the command once the programme compiled.  A rewrite runs
   once for each definition, a generic one included, so a line stands once. *)
let report_lines: string list ref = ref []

let reset_report (): unit =
  report_lines := []

let note_unproved (line: string): unit =
  report_lines := line :: !report_lines

(* The lines in the order the clauses were met. *)
let report (): string list =
  List.rev !report_lines

(* --- Errors ------------------------------------------------------------ *)

module Errors = struct
  let repeated_in_body ~name ~interface_span ~has_interface_contract =
    hilde_raise (H 2051) DeclarationError [
        Text "The body of the public function ";
        Code (ident_string name);
        Text " holds a contract.";
        Break;
        Text "The contract of a public function stands in its interface only: ";
        Text (if has_interface_contract then "it is written at " else "its declaration is at ");
        Code (site_of_span interface_span);
        Text ".  Remove the requires, ensures and raises clauses from the body."
      ]

  let foreign_function ~name =
    hilde_raise (H 2052) DeclarationError [
        Text "The function ";
        Code (ident_string name);
        Text " is imported from C and has a contract.";
        Break;
        Text "A contract is checked by statements put into the body of its function, and a foreign function has none.  Write the contract on a Hilde function that calls it."
      ]

  (* The raises clause of a method stands at the typeclass's
     declaration and the instances inherit it, so the clause on an
     instance's method is refused instead of being read and dropped. *)
  let method_def_clause ~name =
    hilde_raise (H 2058) DeclarationError [
        Text "The method ";
        Code (ident_string name);
        Text " of an instance has a raises clause.";
        Break;
        Text "The raises clause of a method stands in the typeclass, where every instance and every caller reads it.  Remove the clause from the instance, and write it at the method's declaration in the typeclass."
      ]

  let captured ~fname ~var =
    hilde_raise (H 2053) DeclarationError [
        Text "The ensures of ";
        Code (ident_string fname);
        Text " names ";
        Code var;
        Text ", which the body of the function also declares.";
        Break;
        Text "An ensures sees the parameters, result and the names of modules; checked at a return, it would read the body's variable instead.  Rename the variable in the body."
      ]

  let ensures_on_never ~fname =
    hilde_raise (H 2062) DeclarationError [
        Text "The function ";
        Code (ident_string fname);
        Text " returns ";
        Code "Never";
        Text " and has an ensures.";
        Break;
        Text "An ensures speaks of the state at a return, and a function that returns Never does not return: the clause would hold of nothing.  Remove it; a requires stays allowed."
      ]

  let result_parameter ~fname =
    hilde_raise (H 2054) DeclarationError [
        Text "The function ";
        Code (ident_string fname);
        Text " has an ensures and a parameter named ";
        Code "result";
        Text ".";
        Break;
        Text "In an ensures, result is the value the function returns.  Rename the parameter."
      ]

  let old_misused ~what =
    hilde_raise (H 2055) DeclarationError [
        Text what;
        Break;
        Text "old(e) stands only in an ensures, takes one value, and does not nest: it is the value e had when the function was entered."
      ]
end

(* --- The oracle of calls ------------------------------------------------ *)

(* Whether the function named in an environment takes a call site: its last
   value parameter is the one a requires adds. *)
let env_function_takes_site (env: env) (name: qident): bool =
  match get_decl_by_name env (qident_to_sident name) with
  | Some (Function { value_params; _ }) ->
     (match List.rev value_params with
      | (ValueParameter (n, _)) :: _ -> equal_identifier n site_param
      | [] -> false)
  | _ ->
     false

(* The error kinds of a raises clause, in the order written.
   A clause of kind RaisesClause holds the kinds joined with " , " as
   its text; the kinds are read out of the text and kept as a list. *)
let raises_of_clauses (clauses: contract_clause list): string list =
  List.concat_map
    (fun (ContractClause { kind; text; _ }) ->
      if kind = RaisesClause then String.split_on_char ',' text |> List.map String.trim |> List.filter (fun s -> s <> "") else [])
    clauses

let has_requires (clauses: contract_clause list): bool =
  List.exists (fun (ContractClause { kind; _ }) -> kind = Requires) clauses

(* --- Walking the abstract syntax tree ------------------------------------ *)

let is_local_named (q: qident) (s: string): bool =
  String.equal (ident_string (local_name q)) s

let rec map_expr (f: aexpr -> aexpr option) (e: aexpr): aexpr =
  match f e with
  | Some e' -> e'
  | None ->
     let m = map_expr f in
     (match e with
      | NilConstant | BoolConstant _ | IntConstant _ | FloatConstant _
      | StringConstant _ | Variable _ | SizeOf _ | BorrowExpr _ | Reborrow _ ->
         e
      | FunctionCall (q, args) -> FunctionCall (q, map_args f args)
      | ArithmeticExpression (op, a, b) -> ArithmeticExpression (op, m a, m b)
      | Comparison (op, a, b) -> Comparison (op, m a, m b)
      | Conjunction (a, b) -> Conjunction (m a, m b)
      | Disjunction (a, b) -> Disjunction (m a, m b)
      | Negation a -> Negation (m a)
      | ArithNegation a -> ArithNegation (m a)
      | IfExpression (c, t, e) -> IfExpression (m c, m t, m e)
      | Path (q, elems) -> Path (q, List.map (map_elem f) elems)
      | RefPath (q, elems, mode) -> RefPath (q, List.map (map_elem f) elems, mode)
      | Embed (span, ty, s, args) -> Embed (span, ty, s, List.map m args)
      | Deref a -> Deref (m a)
      | Typecast (a, ty) -> Typecast (m a, ty)
      | Question (span, a) -> Question (span, m a))

and map_args f args =
  match args with
  | Positional l -> Positional (List.map (map_expr f) l)
  | Named l -> Named (List.map (fun (n, v) -> (n, map_expr f v)) l)

and map_elem f elem =
  match elem with
  | ArrayIndex e -> ArrayIndex (map_expr f e)
  | _ -> elem

(* Every name an expression reads a variable through: the heads of
   variables, paths, borrows and calls. *)
let rec free_names (e: aexpr): string list =
  let many l = List.concat_map free_names l in
  match e with
  | NilConstant | BoolConstant _ | IntConstant _ | FloatConstant _
  | StringConstant _ | SizeOf _ ->
     []
  | Variable q | BorrowExpr (_, q) | Reborrow q ->
     [ident_string (local_name q)]
  | FunctionCall (q, args) ->
     (ident_string (local_name q)) :: (args_names args)
  | ArithmeticExpression (_, a, b) | Comparison (_, a, b)
  | Conjunction (a, b) | Disjunction (a, b) ->
     many [a; b]
  | Negation a | ArithNegation a | Deref a | Typecast (a, _) | Question (_, a) ->
     free_names a
  | IfExpression (c, t, f) -> many [c; t; f]
  | Path (q, elems) | RefPath (q, elems, _) ->
     (ident_string (local_name q)) :: (List.concat_map elem_names elems)
  | Embed (_, _, _, args) -> many args

and args_names args =
  match args with
  | Positional l -> List.concat_map free_names l
  | Named l -> List.concat_map (fun (_, v) -> free_names v) l

and elem_names elem =
  match elem with
  | ArrayIndex e -> free_names e
  | _ -> []

let rec pattern_names (p: apattern): string list =
  match p with
  | PVar (_, n) -> [ident_string n]
  | PWild _ | PBool _ | PInt _ | PRange _ -> []
  | PVariant (_, _, ps) -> List.concat_map pattern_names ps

(* Every name the body of a function declares. *)
let rec declared_names (s: astmt): string list =
  match s with
  | ASkip _ | AAssign _ | AInitialAssign _ | ADiscarding _ | AReturn _ | ARaise _ ->
     []
  | ALet (_, _, n, _, body) -> (ident_string n) :: (declared_names body)
  | ADestructure (_, _, bindings, _, body) ->
     (List.map (fun (QBinding { rename; _ }) -> ident_string rename) bindings) @ (declared_names body)
  | AIf (_, _, a, b) | ABlock (_, a, b) -> (declared_names a) @ (declared_names b)
  | AWhen (_, _, b) | AWhile (_, _, b) -> declared_names b
  | ACase (_, _, whens) ->
     List.concat_map
       (fun (AbstractWhen (_, bindings, body)) ->
         (List.map (fun (QBinding { rename; _ }) -> ident_string rename) bindings) @ (declared_names body))
       whens
  | APatternCase (_, _, whens) ->
     List.concat_map
       (fun (PatternWhen (_, pats, body)) -> (List.concat_map pattern_names pats) @ (declared_names body))
       whens
  | AFor { name; body; _ } -> (ident_string name) :: (declared_names body)
  | ABorrow { rename; body; _ } -> (ident_string rename) :: (declared_names body)
  | ALetTmp (n, _) -> [ident_string n]

(* --- Rewriting a function ----------------------------------------------- *)

let block (span: span) (stmts: astmt list) (last: astmt): astmt =
  List.fold_right (fun s acc -> ABlock (span, s, acc)) stmts last

let string_constant (s: string): aexpr =
  StringConstant (escaped_of_raw s)

let local_variable (module_name: module_name) (n: identifier): aexpr =
  Variable (make_qident (module_name, n, n))

(* The site string of the static region: Span[Nat8, Static]. *)
let site_type: qtypespec =
  QSpan (QTypeSpecifier (pervasive_q "Nat8", []), QTypeSpecifier (pervasive_q "Static", []))

(* Replace old(e) in an ensures by a temporary bound at the entrance.
   Returns the condition and the bindings, in the order written. *)
let lift_olds (module_name: module_name) (ContractClause { span; text; _ }) (cond: aexpr): aexpr * (identifier * aexpr) list =
  let olds = ref [] in
  let rec contains_old (e: aexpr): bool =
    let found = ref false in
    let _ = map_expr (fun e ->
                match e with
                | FunctionCall (q, _) when is_local_named q "old" -> found := true; Some e
                | _ -> None) e
    in
    !found
  and replace (e: aexpr): aexpr option =
    match e with
    | FunctionCall (q, args) when is_local_named q "old" ->
       (match args with
        | Positional [inner] ->
           if contains_old inner then
             adorn_error_with_span span
               (fun _ -> Errors.old_misused ~what:"An old(e) stands inside another old.")
           else
             let tmp = fresh_temp { kind = TempOld; clause_span = span; text } in
             olds := (tmp, inner) :: !olds;
             Some (local_variable module_name tmp)
        | _ ->
           adorn_error_with_span span
             (fun _ -> Errors.old_misused ~what:"old takes exactly one value, written without a name."))
    | _ ->
       None
  in
  let cond' = map_expr replace cond in
  (cond', List.rev !olds)

let refuse_old_in_requires (ContractClause { span; _ }) (cond: aexpr): unit =
  let _ = map_expr (fun e ->
              match e with
              | FunctionCall (q, _) when is_local_named q "old" ->
                 adorn_error_with_span span
                   (fun _ -> Errors.old_misused ~what:"An old(e) stands in a requires.")
              | _ -> None) cond
  in
  ()

(* Replace result by the temporary that holds the returned value. *)
let substitute_result (module_name: module_name) (r: identifier) (cond: aexpr): aexpr =
  let rq = make_qident (module_name, r, r) in
  map_expr (fun e ->
      match e with
      | Variable q when is_local_named q "result" -> Some (Variable rq)
      | BorrowExpr (mode, q) when is_local_named q "result" -> Some (BorrowExpr (mode, rq))
      | Reborrow q when is_local_named q "result" -> Some (Reborrow rq)
      | Path (q, elems) when is_local_named q "result" -> Some (Path (rq, elems))
      | RefPath (q, elems, mode) when is_local_named q "result" -> Some (RefPath (rq, elems, mode))
      | _ -> None) cond

(* --- Proofs of simple cases -------------------------------------------- *)

(* An ensures is proved at a return when it holds for every value the
   parameters can have there: result is replaced by the returned expression,
   and the condition is judged true, false or unknown from three things --
   the ranges of the integer parameters, narrowed by the requires; the
   comparisons the requires states between them; and that an expression is
   equal to itself.  Only a parameter the body neither declares again nor
   assigns is known, so that a name in a condition means the same value at
   the entrance and at every return.  Where the proof succeeds the check
   loses its failure: the condition is still computed and discarded, so
   that the compiler types it and holds it to the reading rules. *)

type truth =
  | Holds
  | Fails
  | Unknown

type facts = {
    ranges: (string * (Z.t * Z.t)) list;
    (** The known integer parameters and the values each can have. *)
    relations: (comparison_operator * aexpr * aexpr) list;
    (** The comparisons of the requires whose names are all known. *)
    known: string list;
    (** The known parameters, integers or not. *)
  }

let power_of_two (n: int): Z.t = Z.shift_left Z.one n

(* The values an integer type holds; none for any other type, and none for
   Index and ByteSize, whose width is the system's. *)
let type_range (ty: qtypespec): (Z.t * Z.t) option =
  match ty with
  | QTypeSpecifier (q, []) ->
     let unsigned n = Some (Z.zero, Z.pred (power_of_two n))
     and signed n = Some (Z.neg (power_of_two (n - 1)), Z.pred (power_of_two (n - 1))) in
     (match ident_string (original_name q) with
      | "Nat8" -> unsigned 8
      | "Nat16" -> unsigned 16
      | "Nat32" -> unsigned 32
      | "Nat64" -> unsigned 64
      | "Int8" -> signed 8
      | "Int16" -> signed 16
      | "Int32" -> signed 32
      | "Int64" -> signed 64
      | _ -> None)
  | _ -> None

(* Every name the body assigns to. *)
let rec assigned_names (s: astmt): string list =
  let target (e: aexpr): string list =
    match e with
    | Variable q | Path (q, _) -> [ident_string (local_name q)]
    | _ -> []
  in
  match s with
  | AAssign (_, lhs, _) -> target lhs
  | AInitialAssign (q, _, _) -> [ident_string (local_name q)]
  | ALet (_, _, _, _, body) | ADestructure (_, _, _, _, body)
  | AWhen (_, _, body) | AWhile (_, _, body) ->
     assigned_names body
  | AIf (_, _, a, b) | ABlock (_, a, b) -> (assigned_names a) @ (assigned_names b)
  | ACase (_, _, whens) ->
     List.concat_map (fun (AbstractWhen (_, _, body)) -> assigned_names body) whens
  | APatternCase (_, _, whens) ->
     List.concat_map (fun (PatternWhen (_, _, body)) -> assigned_names body) whens
  | AFor { body; _ } | ABorrow { body; _ } -> assigned_names body
  | ASkip _ | ADiscarding _ | AReturn _ | ALetTmp _ | ARaise _ -> []

(* A condition the prover reads: constants, variables, the arithmetic
   operators and the comparisons, joined by and, or and not.  Anything
   else -- a call, a path, a borrow -- is left to the check. *)
let rec is_simple (e: aexpr): bool =
  match e with
  | BoolConstant _ | IntConstant _ | Variable _ -> true
  | ArithNegation a | Negation a -> is_simple a
  | ArithmeticExpression (_, a, b) | Comparison (_, a, b)
  | Conjunction (a, b) | Disjunction (a, b) ->
     (is_simple a) && (is_simple b)
  | _ -> false

(* An expression whose every name is a known parameter: it has the same
   value wherever it is evaluated in the function. *)
let rec is_known (f: facts) (e: aexpr): bool =
  match e with
  | IntConstant _ | BoolConstant _ -> true
  | Variable q -> List.mem (ident_string (local_name q)) f.known
  | ArithNegation a | Negation a -> is_known f a
  | ArithmeticExpression (_, a, b) | Comparison (_, a, b)
  | Conjunction (a, b) | Disjunction (a, b) ->
     (is_known f a) && (is_known f b)
  | _ -> false

(* The values an expression can have, or none when it is not made of known
   integers, integer constants and + - * /. *)
let rec interval (f: facts) (e: aexpr): (Z.t * Z.t) option =
  match e with
  | IntConstant s -> (match Z.of_string s with n -> Some (n, n) | exception _ -> None)
  | Variable q -> List.assoc_opt (ident_string (local_name q)) f.ranges
  | ArithNegation a -> Option.map (fun (lo, hi) -> (Z.neg hi, Z.neg lo)) (interval f a)
  | ArithmeticExpression (op, a, b) ->
     (match (interval f a, interval f b) with
      | (Some (al, ah), Some (bl, bh)) ->
         (match op with
          | Add -> Some (Z.add al bl, Z.add ah bh)
          | Subtract -> Some (Z.sub al bh, Z.sub ah bl)
          | Multiply ->
             let ps = [Z.mul al bl; Z.mul al bh; Z.mul ah bl; Z.mul ah bh] in
             Some (List.fold_left Z.min (List.hd ps) ps, List.fold_left Z.max (List.hd ps) ps)
          | Divide ->
             (* Only where neither is ever negative and the divisor never 0:
                there the quotient lies between the two corners. *)
             if Z.geq al Z.zero && Z.gt bl Z.zero then Some (Z.div al bh, Z.div ah bl) else None)
      | _ -> None)
  | _ -> None

(* A comparison written with < or <=, the operands turned round for > and
   >=. *)
let normal ((op, a, b): comparison_operator * aexpr * aexpr): comparison_operator * aexpr * aexpr =
  match op with
  | GreaterThan -> (LessThan, b, a)
  | GreaterThanOrEqual -> (LessThanOrEqual, b, a)
  | _ -> (op, a, b)

(* Whether the known comparison [fact] makes [goal] true. *)
let implies (fact: comparison_operator * aexpr * aexpr) (goal: comparison_operator * aexpr * aexpr): bool =
  let (fo, fa, fb) = normal fact
  and (go, ga, gb) = normal goal in
  let same = (fa = ga) && (fb = gb)
  and turned = (fa = gb) && (fb = ga) in
  match (fo, go) with
  | (LessThan, LessThan) | (LessThan, LessThanOrEqual) | (LessThanOrEqual, LessThanOrEqual) -> same
  | (LessThan, NotEqual) | (NotEqual, NotEqual) | (Equal, Equal) | (Equal, LessThanOrEqual) -> same || turned
  | _ -> false

let compare_intervals (op: comparison_operator) (a: Z.t * Z.t) (b: Z.t * Z.t): truth =
  let less_than (al, ah) (bl, bh) =
    if Z.lt ah bl then Holds else if Z.geq al bh then Fails else Unknown
  and at_most (al, ah) (bl, bh) =
    if Z.leq ah bl then Holds else if Z.gt al bh then Fails else Unknown
  and equal (al, ah) (bl, bh) =
    if Z.equal al ah && Z.equal bl bh && Z.equal al bl then Holds
    else if Z.lt ah bl || Z.lt bh al then Fails
    else Unknown
  in
  match op with
  | LessThan -> less_than a b
  | LessThanOrEqual -> at_most a b
  | GreaterThan -> less_than b a
  | GreaterThanOrEqual -> at_most b a
  | Equal -> equal a b
  | NotEqual -> (match equal a b with Holds -> Fails | Fails -> Holds | Unknown -> Unknown)

let rec truth (f: facts) (e: aexpr): truth =
  match e with
  | BoolConstant true -> Holds
  | BoolConstant false -> Fails
  | Conjunction (a, b) ->
     (match (truth f a, truth f b) with
      | (Holds, Holds) -> Holds
      | (Fails, _) | (_, Fails) -> Fails
      | _ -> Unknown)
  | Disjunction (a, b) ->
     (match (truth f a, truth f b) with
      | (Holds, _) | (_, Holds) -> Holds
      | (Fails, Fails) -> Fails
      | _ -> Unknown)
  | Negation a ->
     (match truth f a with Holds -> Fails | Fails -> Holds | Unknown -> Unknown)
  | Comparison (op, a, b) ->
     if (is_known f a) && (is_known f b) && a = b then
       (match op with
        | Equal | LessThanOrEqual | GreaterThanOrEqual -> Holds
        | NotEqual | LessThan | GreaterThan -> Fails)
     else if List.exists (fun fact -> implies fact (op, a, b)) f.relations then
       Holds
     else
       (match (interval f a, interval f b) with
        | (Some ia, Some ib) -> compare_intervals op ia ib
        | _ -> Unknown)
  | _ -> Unknown

(* The comparisons a condition is the conjunction of. *)
let rec conjuncts (e: aexpr): aexpr list =
  match e with
  | Conjunction (a, b) -> (conjuncts a) @ (conjuncts b)
  | _ -> [e]

let turned_round (op: comparison_operator): comparison_operator =
  match op with
  | LessThan -> GreaterThan
  | LessThanOrEqual -> GreaterThanOrEqual
  | GreaterThan -> LessThan
  | GreaterThanOrEqual -> LessThanOrEqual
  | Equal -> Equal
  | NotEqual -> NotEqual

(* What the parameters' types and the requires say at the entrance.  A
   conjunct p op c, with p a known integer parameter and c of one value,
   narrows the range of p; a comparison whose names are all known is kept
   as a relation. *)
let entrance_facts (params: qparam list) (body: astmt) (requires: aexpr list): facts =
  let changed = (declared_names body) @ (assigned_names body) in
  let known =
    List.filter_map
      (fun (QualifiedParameter (n, _)) ->
        let s = ident_string n in
        if List.mem s changed then None else Some s)
      params
  in
  let ranges =
    List.filter_map
      (fun (QualifiedParameter (n, ty)) ->
        let s = ident_string n in
        if List.mem s known then Option.map (fun r -> (s, r)) (type_range ty) else None)
      params
  in
  let tighten (f: facts) (name: string) (op: comparison_operator) ((cl, ch): Z.t * Z.t): facts =
    match List.assoc_opt name f.ranges with
    | Some (lo, hi) when Z.equal cl ch ->
       let (lo', hi') =
         match op with
         | LessThan -> (lo, Z.min hi (Z.pred cl))
         | LessThanOrEqual -> (lo, Z.min hi cl)
         | GreaterThan -> (Z.max lo (Z.succ cl), hi)
         | GreaterThanOrEqual -> (Z.max lo cl, hi)
         | Equal -> (Z.max lo cl, Z.min hi cl)
         | NotEqual -> (lo, hi)
       in
       { f with ranges = (name, (lo', hi')) :: (List.remove_assoc name f.ranges) }
    | _ -> f
  in
  let name_of (e: aexpr): string option =
    match e with
    | Variable q -> Some (ident_string (local_name q))
    | _ -> None
  in
  let narrow (f: facts) (c: aexpr): facts =
    match c with
    | Comparison (op, a, b) when is_simple c ->
       let f = if (is_known f a) && (is_known f b) then { f with relations = (op, a, b) :: f.relations } else f in
       (match (name_of a, interval f b) with
        | (Some p, Some cb) when List.mem_assoc p f.ranges -> tighten f p op cb
        | _ ->
           (match (name_of b, interval f a) with
            | (Some p, Some ca) when List.mem_assoc p f.ranges -> tighten f p (turned_round op) ca
            | _ -> f))
    | _ -> f
  in
  List.fold_left narrow { ranges; relations = []; known } (List.concat_map conjuncts requires)

(* Whether an ensures holds at a return of [returned].  An old of a known
   expression is that expression, since its names do not change; result is
   the returned expression, and, where that has a range, also a value of
   that range within the return type's, since a value that does not fit
   stopped the programme before it came back. *)
let proved_at_return (module_name: module_name) (f: facts) (olds: (identifier * aexpr) list)
      (rt: qtypespec) (returned: aexpr) (cond: aexpr): bool =
  let cond =
    map_expr (fun e ->
        match e with
        | Variable q ->
           (match List.find_opt (fun (t, _) -> equal_identifier t (local_name q)) olds with
            | Some (_, inner) when is_known f inner -> Some inner
            | _ -> None)
        | _ -> None) cond
  in
  let replace (by: aexpr) =
    map_expr (fun e ->
        match e with
        | Variable q when is_local_named q "result" -> Some by
        | _ -> None) cond
  in
  (is_simple cond) && (is_simple returned) &&
    ((truth f (replace returned) = Holds)
     || (match (type_range rt, interval f returned) with
         | (Some (tl, th), Some (lo, hi)) ->
            let n = make_ident "_hilde_returned" in
            let f' = { f with ranges = ("_hilde_returned", (Z.max tl lo, Z.min th hi)) :: f.ranges;
                              known = "_hilde_returned" :: f.known } in
            truth f' (replace (local_variable module_name n)) = Holds
         | _ -> false))

type prepared = {
    clause: contract_clause;
    cond: aexpr;
  }

(* The statement that checks one condition: the condition into a
   temporary, then the failure when it is false. *)
let check_statement (span: span) (tmp: identifier) (module_name: module_name) (cond: aexpr) (failure: aexpr): astmt =
  ABlock (span,
          ALetTmp (tmp, cond),
          AIf (span, local_variable module_name tmp, ASkip span, ADiscarding (span, failure)))

let rec rewrite_returns (rw: span -> aexpr -> astmt) (s: astmt): astmt =
  let r = rewrite_returns rw in
  match s with
  | AReturn (span, e) -> rw span e
  | ASkip _ | AAssign _ | AInitialAssign _ | ADiscarding _ | ALetTmp _ | ARaise _ -> s
  | ALet (span, m, n, t, body) -> ALet (span, m, n, t, r body)
  | ADestructure (span, m, bs, e, body) -> ADestructure (span, m, bs, e, r body)
  | AIf (span, c, a, b) -> AIf (span, c, r a, r b)
  | AWhen (span, c, b) -> AWhen (span, c, r b)
  | ACase (span, e, whens) ->
     ACase (span, e, List.map (fun (AbstractWhen (n, bs, body)) -> AbstractWhen (n, bs, r body)) whens)
  | APatternCase (span, e, whens) ->
     APatternCase (span, e, List.map (fun (PatternWhen (sp, ps, body)) -> PatternWhen (sp, ps, r body)) whens)
  | AWhile (span, c, b) -> AWhile (span, c, r b)
  | AFor f -> AFor { f with body = r f.body }
  | ABorrow b -> ABorrow { b with body = r b.body }
  | ABlock (span, a, b) -> ABlock (span, r a, r b)

(* A function with its contract made into statements.  cond_imports
   qualifies the names of the conditions: the interface's imports for a
   public function, the body's for any other.  Returns the parameters, with
   the call site added when there is a requires, and the body. *)
let rewrite_function
      ~(module_name: module_name)
      ~(name: identifier)
      ~(def_span: span)
      ~(cond_imports: Imports.import_map)
      ~(params: qparam list)
      ~(rt: qtypespec)
      ~(pragmas: pragma list)
      ~(clauses: contract_clause list)
      (body: astmt): qparam list * astmt =
  if clauses = [] then
    (params, body)
  else
    let _ =
      if List.exists (fun p -> match p with ForeignImportPragma _ -> true | _ -> false) pragmas then
        adorn_error_with_span def_span (fun _ -> Errors.foreign_function ~name)
    in
    let fname = (mod_name_string module_name) ^ "." ^ (ident_string name) in
    let prepare (clause: contract_clause): prepared =
      let (ContractClause { condition; _ }) = clause in
      { clause; cond = AbstractionPass.abs_expr cond_imports condition }
    in
    let requires = List.filter_map
                     (fun c -> let (ContractClause { kind; _ }) = c in
                               if kind = Requires then Some (prepare c) else None) clauses
    and ensures = List.filter_map
                    (fun c -> let (ContractClause { kind; _ }) = c in
                              if kind = Ensures then Some (prepare c) else None) clauses
    in
    List.iter (fun { clause; cond } -> refuse_old_in_requires clause cond) requires;
    let param_names = List.map (fun (QualifiedParameter (n, _)) -> ident_string n) params in
    let rt_is_never: bool =
      (match rt with
       | QTypeSpecifier (q, []) -> (ident_string (original_name q)) = "Never"
       | _ -> false)
    in
    if (ensures <> []) && rt_is_never then
      adorn_error_with_span def_span (fun _ -> Errors.ensures_on_never ~fname:name);
    if (ensures <> []) && (List.mem "result" param_names) then
      adorn_error_with_span def_span (fun _ -> Errors.result_parameter ~fname:name);
    (* The olds, lifted out of the ensures in the order written. *)
    let (ensures, olds) =
      List.fold_left
        (fun (acc, olds) { clause; cond } ->
          let (cond', o) = lift_olds module_name clause cond in
          (acc @ [{ clause; cond = cond' }], olds @ o))
        ([], []) ensures
    in
    (* An ensures reads only parameters, result and module names. *)
    let body_names = declared_names body in
    List.iter
      (fun { clause = ContractClause { span; _ }; cond } ->
        List.iter
          (fun n ->
            if (List.mem n body_names) && not (List.mem n param_names) then
              adorn_error_with_span span (fun _ -> Errors.captured ~fname:name ~var:n))
          (free_names cond))
      ensures;
    let requires_checks =
      List.map
        (fun { clause = ContractClause { span; text; _ }; cond } ->
          let tmp = fresh_temp { kind = TempRequires; clause_span = span; text } in
          note_unproved ((site_of_span span) ^ ": the requires " ^ text ^ " of " ^ fname
                         ^ " is checked at run time, at every call");
          let message =
            "Hilde: contract violated: the requires " ^ text ^ " of " ^ fname
            ^ " (" ^ (site_of_span span) ^ ") does not hold for the call at "
          in
          let failure =
            FunctionCall (pervasive_q "contractRequiresFailed",
                          Positional [string_constant message; local_variable module_name site_param])
          in
          check_statement span tmp module_name cond failure)
        requires
    in
    let old_bindings = List.map (fun (tmp, e) -> ALetTmp (tmp, e)) olds in
    let facts = entrance_facts params body (List.map (fun { cond; _ } -> cond) requires) in
    let body' =
      if ensures = [] then
        body
      else
        rewrite_returns
          (fun ret_span e ->
            let r = fresh_temp { kind = TempResult; clause_span = ret_span; text = "" } in
            let checks =
              List.map
                (fun { clause = ContractClause { span; text; _ }; cond } ->
                  let tmp = fresh_temp { kind = TempEnsures; clause_span = span; text } in
                  if proved_at_return module_name facts olds rt e cond then
                    (* Proved here: the condition is computed and discarded,
                       so that it is still typed and read by the rules, and
                       nothing fails. *)
                    ABlock (span,
                            ALetTmp (tmp, substitute_result module_name r cond),
                            ADiscarding (span, local_variable module_name tmp))
                  else
                    let () =
                      note_unproved ((site_of_span ret_span) ^ ": the ensures " ^ text ^ " of " ^ fname
                                     ^ " (" ^ (site_of_span span) ^ ") is not proved at this return and is"
                                     ^ " checked at run time")
                    in
                    let message =
                      "Hilde: contract violated: the ensures " ^ text ^ " of " ^ fname
                      ^ " (" ^ (site_of_span span) ^ ") does not hold on return; the function at "
                      ^ (site_of_span def_span) ^ " is at fault"
                    in
                    let failure = FunctionCall (pervasive_q "abort", Positional [string_constant message]) in
                    check_statement span tmp module_name (substitute_result module_name r cond) failure)
                ensures
            in
            block ret_span
              ((ALetTmp (r, Typecast (e, rt))) :: checks)
              (AReturn (ret_span, local_variable module_name r)))
          body
    in
    let params' =
      if requires = [] then params else params @ [QualifiedParameter (site_param, site_type)]
    in
    (params', block def_span (requires_checks @ old_bindings) body')

(* --- Invariants of records --------------------------------------------- *)

module InvariantErrors = struct
  let slots_public ~record ~why =
    hilde_raise (H 2057) DeclarationError [
        Text "The record ";
        Code (ident_string record);
        Text " has an invariant, and its slots can be reached outside its module: ";
        Text why;
        Text ".";
        Break;
        Text "An invariant is checked where a value leaves its module, which holds only when no other module can build the record or write its slots.  Declare the type opaque in the interface, type Name: Universe;, and the record in the body."
      ]
end

(* An invariant of a record whose slots its module alone reaches. *)
type invariant = {
    record: identifier;
    clause: contract_clause;
    checker: identifier;
  }

(* The functions made for invariants, by name, with the clause's span: the
   check after typing holds their conditions to the same rules. *)
let invariant_functions: (string, span) Hashtbl.t = Hashtbl.create 16

(* The condition with each bare slot name read through value. *)
let rec slots_through (slots: string list) (value: identifier) (e: cexpr): cexpr =
  let m = slots_through slots value in
  let is_slot n = List.mem (ident_string n) slots in
  match e with
  | CVariable (sp, n) when is_slot n -> CPath (sp, value, [CPointerSlotAccessor n])
  | CPath (sp, n, elems) when is_slot n -> CPath (sp, value, (CPointerSlotAccessor n) :: (List.map (slot_elem slots value) elems))
  | CPath (sp, n, elems) -> CPath (sp, n, List.map (slot_elem slots value) elems)
  | CBorrowExpr (sp, ReadBorrow, n) when is_slot n -> CRefPath (sp, value, [CPointerSlotAccessor n], ReadBorrow)
  | CRefPath (sp, n, elems, mode) when is_slot n -> CRefPath (sp, value, (CPointerSlotAccessor n) :: (List.map (slot_elem slots value) elems), mode)
  | CFuncall (sp, n, ConcretePositionalArgs l) -> CFuncall (sp, n, ConcretePositionalArgs (List.map m l))
  | CFuncall (sp, n, ConcreteNamedArgs l) -> CFuncall (sp, n, ConcreteNamedArgs (List.map (fun (k, v) -> (k, m v)) l))
  | CArith (sp, op, a, b) -> CArith (sp, op, m a, m b)
  | CComparison (sp, op, a, b) -> CComparison (sp, op, m a, m b)
  | CConjunction (sp, a, b) -> CConjunction (sp, m a, m b)
  | CDisjunction (sp, a, b) -> CDisjunction (sp, m a, m b)
  | CNegation (sp, a) -> CNegation (sp, m a)
  | CArithNegation (sp, a) -> CArithNegation (sp, m a)
  | CIfExpression (sp, a, b, c) -> CIfExpression (sp, m a, m b, m c)
  | CDeref (sp, a) -> CDeref (sp, m a)
  | CTypecast (sp, a, t) -> CTypecast (sp, m a, t)
  | CQuestion (sp, a) -> CQuestion (sp, m a)
  | CEmbed (sp, t, s, l) -> CEmbed (sp, t, s, List.map m l)
  | _ -> e

and slot_elem slots value elem =
  match elem with
  | CArrayIndex e -> CArrayIndex (slots_through slots value e)
  | _ -> elem

(* For each invariant of a record, a private function that says whether it
   holds for a value read through a reference:

       generic [<the record's type parameters>, Q: Region]
       function _hilde_invariant_<R>_<n>(_hilde_record: &[R[...], Q]): Bool is
           return <condition, slots read through _hilde_record>;
       end;
*)
let invariant_checker (ConcreteRecord (span, name, typarams, _, slots, _, clauses)): (invariant * concrete_def) list =
  let slot_names = List.map (fun (ConcreteSlot (n, _)) -> ident_string n) slots in
  let value = make_ident "_hilde_record" in
  let q = make_ident "_HildeQ" in
  let record_type =
    TypeSpecifier (name, List.map (fun (ConcreteTypeParam (n, _, _)) -> TypeSpecifier (n, [])) typarams)
  in
  List.mapi
    (fun i clause ->
      let (ContractClause { condition; span = cspan; _ }) = clause in
      let checker = make_ident ("_hilde_invariant_" ^ (ident_string name) ^ "_" ^ (string_of_int (i + 1))) in
      Hashtbl.replace invariant_functions (ident_string checker) cspan;
      let def =
        ConcreteFunctionDef (span, checker,
                             typarams @ [ConcreteTypeParam (q, RegionUniverse, [])],
                             [ConcreteParam (value, ConcreteReadRef (record_type, TypeSpecifier (q, [])))],
                             TypeSpecifier (make_ident "Bool", []),
                             CReturn (cspan, slots_through slot_names value condition),
                             Docstring "", [], [])
      in
      ({ record = name; clause; checker }, def))
    clauses

(* The name of the record of this module with invariants that a type is, if
   it is one. *)
let invariant_named (module_name: module_name) (records: string list) (t: qtypespec): identifier option =
  match t with
  | QTypeSpecifier (q, _)
       when (equal_module_name (source_module_name q) module_name)
            && (List.mem (ident_string (original_name q)) records) ->
     Some (original_name q)
  | _ -> None

(* The type a parameter has, when it is a write reference to a record of
   this module with invariants: the record's name. *)
let invariant_record (module_name: module_name) (records: string list) (ty: qtypespec): identifier option =
  match ty with
  | QWriteRef (t, _) -> invariant_named module_name records t
  | _ -> None

(* Where a record of this module with invariants stands in a result type:
   the type itself, the payload of an Option (its Some), or the payload of
   an Either (its Right, the success, as everywhere in the standard
   library).  Another type that holds the record -- a pair, a buffer of
   them -- is not looked into. *)
type result_shape =
  | ResultPlain
  | ResultInOption of qtypespec
  | ResultInEither of qtypespec * qtypespec

let invariant_result (module_name: module_name) (records: string list) (ty: qtypespec): (identifier * result_shape) option =
  let in_pervasive (q: qident) (name: string): bool =
    (equal_module_name (source_module_name q) pervasive) && (String.equal (ident_string (original_name q)) name)
  in
  match ty with
  | QTypeSpecifier (q, [inner]) when in_pervasive q "Option" ->
     (match invariant_named module_name records inner with
      | Some n -> Some (n, ResultInOption inner)
      | None -> None)
  | QTypeSpecifier (q, [left; inner]) when in_pervasive q "Either" ->
     (match invariant_named module_name records inner with
      | Some n -> Some (n, ResultInEither (left, inner))
      | None -> None)
  | _ ->
     (match invariant_named module_name records ty with
      | Some n -> Some (n, ResultPlain)
      | None -> None)

(* A public function with the checks of the invariants added at each
   return: for each parameter that is a write reference to such a record,
   and for a result that is one, or that holds one as the payload of an
   Option or the success of an Either.  For a payload the returned value is
   taken apart and put together again, the check between the two. *)
let add_invariant_checks
      ~(module_name: module_name)
      ~(name: identifier)
      ~(def_span: span)
      ~(invariants: invariant list)
      ~(params: qparam list)
      ~(rt: qtypespec)
      (body: astmt): astmt =
  if invariants = [] then body else
  let records = List.map (fun i -> ident_string i.record) invariants in
  let fname = (mod_name_string module_name) ^ "." ^ (ident_string name) in
  let param_targets =
    List.filter_map
      (fun (QualifiedParameter (n, t)) ->
        match invariant_record module_name records t with
        | Some r -> Some (r, n)
        | None -> None)
      params
  in
  let result_target = invariant_result module_name records rt in
  if param_targets = [] && result_target = None then body else
    rewrite_returns
      (fun ret_span e ->
        let r = fresh_temp { kind = TempResult; clause_span = ret_span; text = "" } in
        (* The checks of every invariant of record, for the value that
           the variable reads names (what says which one in the message). *)
        let checks_of (record: identifier) (what: string) (reads: identifier): astmt list =
          List.filter_map
            (fun inv ->
              if not (equal_identifier inv.record record) then None else
              let (ContractClause { span; text; _ }) = inv.clause in
              let tmp = fresh_temp { kind = TempResult; clause_span = span; text } in
              let message =
                "Hilde: contract violated: the invariant " ^ text ^ " of "
                ^ (mod_name_string module_name) ^ "." ^ (ident_string record)
                ^ " (" ^ (site_of_span span) ^ ") does not hold " ^ what ^ " on return from " ^ fname
                ^ "; the function at " ^ (site_of_span def_span) ^ " is at fault"
              in
              let call =
                FunctionCall (make_qident (module_name, inv.checker, inv.checker),
                              Positional [BorrowExpr (ReadBorrow, make_qident (module_name, reads, reads))])
              in
              let failure = FunctionCall (pervasive_q "abort", Positional [string_constant message]) in
              Some (check_statement span tmp module_name call failure))
            invariants
        in
        let param_checks =
          List.concat_map
            (fun (record, p) -> checks_of record ("for " ^ (ident_string p)) p)
            param_targets
        in
        let local = local_variable module_name in
        let build ctor field (v: identifier): aexpr =
          Typecast (FunctionCall (pervasive_q ctor, Named [(make_ident field, local v)]), rt)
        in
        match result_target with
        | None ->
           block ret_span ((ALetTmp (r, Typecast (e, rt))) :: param_checks) (AReturn (ret_span, local r))
        | Some (record, ResultPlain) ->
           block ret_span
             ((ALetTmp (r, Typecast (e, rt))) :: (param_checks @ (checks_of record "for its result" r)))
             (AReturn (ret_span, local r))
        | Some (record, ResultInOption inner) ->
           let p = fresh_temp { kind = TempResult; clause_span = ret_span; text = "" } in
           let some_arm =
             AbstractWhen (make_ident "Some",
                           [QBinding { name = make_ident "value"; ty = inner; rename = p }],
                           block ret_span (checks_of record "for its result" p)
                             (AReturn (ret_span, build "Some" "value" p)))
           in
           let none_arm =
             AbstractWhen (make_ident "None", [],
                           AReturn (ret_span, Typecast (FunctionCall (pervasive_q "None", Positional []), rt)))
           in
           block ret_span ((ALetTmp (r, Typecast (e, rt))) :: param_checks)
             (ACase (ret_span, local r, [some_arm; none_arm]))
        | Some (record, ResultInEither (left, inner)) ->
           let p = fresh_temp { kind = TempResult; clause_span = ret_span; text = "" } in
           let l = fresh_temp { kind = TempResult; clause_span = ret_span; text = "" } in
           let right_arm =
             AbstractWhen (make_ident "Right",
                           [QBinding { name = make_ident "right"; ty = inner; rename = p }],
                           block ret_span (checks_of record "for its result" p)
                             (AReturn (ret_span, build "Right" "right" p)))
           in
           let left_arm =
             AbstractWhen (make_ident "Left",
                           [QBinding { name = make_ident "left"; ty = left; rename = l }],
                           AReturn (ret_span, build "Left" "left" l))
           in
           block ret_span ((ALetTmp (r, Typecast (e, rt))) :: param_checks)
             (ACase (ret_span, local r, [right_arm; left_arm])))
      body

(* --- The check after typing: a condition only reads ------------------- *)

module Checks = struct
  let consumes ~span ~var =
    adorn_error_with_span span
      (fun _ ->
        hilde_raise (H 3096) TypeError [
            Text "This condition uses the linear value ";
            Code var;
            Text " itself, which would consume it.";
            Break;
            Text "A condition only reads: read a linear value through a reference, ";
            Code ("&" ^ var);
            Text "."
          ])

  (* The type is not named: the region of a borrow made in the condition
     is one the compiler numbered, and the number says nothing. *)
  let write_reference ~span =
    adorn_error_with_span span
      (fun _ ->
        hilde_raise (H 3097) TypeError [
            Text "This condition makes a reference to write through, with ";
            Code "&!";
            Text ", ";
            Code "&~";
            Text " or a writable span.";
            Break;
            Text "A condition only reads: take a read reference with & instead."
          ])

  let reaches ~span ~chain ~what =
    adorn_error_with_span span
      (fun _ ->
        hilde_raise (H 3098) TypeError [
            Text "This condition calls ";
            Code (String.concat " -> " chain);
            Text ", ";
            Text what;
            Text ".";
            Break;
            Text "A condition only reads: every function it calls, and every function those call, stays out of the binding modules and C, and asks for no reference to write through."
          ])

  let unknown_callee ~span ~what =
    adorn_error_with_span span
      (fun _ ->
        hilde_raise (H 3099) TypeError [
            Text "This condition calls ";
            Text what;
            Text ", so the function that runs is not known where the condition is checked.";
            Break;
            Text "A condition only reads, and the compiler has to see every function it calls to know that.  Call a function by its name."
          ])

  let old_not_free ~span ~ty =
    adorn_error_with_span span
      (fun _ ->
        hilde_raise (H 3100) TypeError [
            Text "old takes a value of the type ";
            Type ty;
            Text ", which is not in the Free universe.";
            Break;
            Text "old copies a value when the function is entered, and only a free value can be copied."
          ])
end

type purity =
  | Pure
  | Impure of string list * string

let is_write_type (ty: ty): bool =
  match ty with
  | WriteRef _ | SpanMut _ -> true
  | _ -> false

let is_linear (ty: ty): bool =
  match type_universe ty with
  | LinearUniverse | TypeUniverse -> true
  | _ -> false

let memo: (string, purity) Hashtbl.t = Hashtbl.create 64

(* Whether a function, and everything it calls, stays out of the binding
   modules and C and asks for no write reference.  A call cycle adds
   nothing, so a function being looked at counts as pure meanwhile.
   Hilde.Pervasive is the compiler's own module and its bodies are not
   walked; its parameters are. *)
let rec function_purity (env: env) (key: string) (label: string) (module_name: module_name) (params: value_parameter list) (external_name: string option) (body: tstmt option): purity =
  match Hashtbl.find_opt memo key with
  | Some p -> p
  | None ->
     Hashtbl.replace memo key Pure;
     let m = mod_name_string module_name in
     let result =
       if (String.length m > 9) && (String.sub m 0 9 = "Bindings.") then
         Impure ([label], "which is in the binding module " ^ m)
       else if external_name <> None then
         Impure ([label], "which is imported from C")
       else if List.exists (fun (ValueParameter (_, ty)) -> is_write_type ty) params then
         Impure ([label], "which asks for a reference to write through")
       else if m = "Hilde.Pervasive" then
         Pure
       else
         match body with
         | None -> Pure
         | Some b ->
            (match stmt_purity env b with
             | Pure -> Pure
             | Impure (chain, what) -> Impure (label :: chain, what))
     in
     Hashtbl.replace memo key result;
     result

and callee_purity (env: env) (e: texpr): purity option =
  match e with
  | TFuncall (id, name, _, _, _) ->
     (match get_decl_by_id env id with
      | Some (Function { mod_id; value_params; external_name; body; _ }) ->
         Some (function_purity env ("f" ^ (show_decl_id id)) (qident_debug_label name)
                 (module_name_from_id env mod_id) value_params external_name body)
      | _ -> Some Pure)
  | TMethodCall (ins_id, name, _, _, _, _) ->
     (match get_instance_method env ins_id with
      | Some (InsMethRec { instance_id; value_params; body; _ }) ->
         let mn =
           match get_decl_by_id env instance_id with
           | Some (Instance { mod_id; _ }) -> module_name_from_id env mod_id
           | _ -> pervasive
         in
         Some (function_purity env ("m" ^ (show_ins_meth_id ins_id)) (qident_debug_label name)
                 mn value_params None body)
      | None -> Some Pure)
  | TVarMethodCall { method_name; _ } ->
     Some (Impure ([qident_debug_label method_name], "a method of a type parameter, whose instance is not known here"))
  | TFptrCall (name, _, _) ->
     Some (Impure ([ident_string name], "a function pointer, whose function is not known here"))
  | _ ->
     None

and qident_debug_label (q: qident): string =
  (mod_name_string (source_module_name q)) ^ "." ^ (ident_string (original_name q))

and expr_purity (env: env) (e: texpr): purity =
  let first l =
    List.fold_left (fun acc x -> match acc with Pure -> Lazy.force x | _ -> acc) Pure l
  in
  let own = match callee_purity env e with Some p -> p | None -> Pure in
  match own with
  | Impure _ -> own
  | Pure ->
     (match e with
      | TEmbed _ -> Impure (["@embed"], "which is C written into the source")
      | _ -> first (List.map (fun c -> lazy (expr_purity env c)) (children e)))

and stmt_purity (env: env) (s: tstmt): purity =
  let first l =
    List.fold_left (fun acc x -> match acc with Pure -> Lazy.force x | _ -> acc) Pure l
  in
  let e x = lazy (expr_purity env x) and st x = lazy (stmt_purity env x) in
  match s with
  | TSkip _ | TUnreachable _ -> Pure
  | TLet (_, _, _, _, b) -> stmt_purity env b
  | TDestructure (_, _, _, v, b) -> first [e v; st b]
  | TAssign (_, a, b) -> first [e a; e b]
  | TAssignVar (_, _, v) | TInitialAssign (_, v) | TLetTmp (_, _, v) | TAssignTmp (_, v)
  | TDiscarding (_, v) | TReturn (_, v) -> expr_purity env v
  | TRaise _ -> Pure
  | TIf (_, c, a, b) -> first [e c; st a; st b]
  | TCase (_, v, whens, _) -> first ((e v) :: (List.map (fun (TypedWhen (_, _, b)) -> st b) whens))
  | TSwitch (_, v, arms, other) -> first ((e v) :: (List.map (fun (_, b) -> st b) arms) @ [st other])
  | TWhile (_, c, b) -> first [e c; st b]
  | TFor (_, _, a, b, body) -> first [e a; e b; st body]
  | TBorrow { body; _ } -> stmt_purity env body
  | TBlock (_, a, b) -> first [st a; st b]

and children (e: texpr): texpr list =
  match e with
  | TNilConstant | TBoolConstant _ | TIntConstant _ | TFloatConstant _ | TStringConstant _
  | TConstVar _ | TParamVar _ | TLocalVar _ | TFunVar _ | TTemporary _ | TSizeOf _ ->
     []
  | TFuncall (_, _, args, _, _) | TMethodCall (_, _, _, args, _, _) | TFptrCall (_, args, _)
  | TEmbed (_, _, args) ->
     args
  | TVarMethodCall { args; _ } -> args
  | TCast (a, _) | TNegation a | TDeref a | TSlotAccessor (a, _, _) | TPointerSlotAccessor (a, _, _) -> [a]
  | TComparison (_, a, b) | TConjunction (a, b) | TDisjunction (a, b)
  | TArrayIndex (a, b, _) | TSpanIndex (a, b, _) -> [a; b]
  | TIfExpression (a, b, c) -> [a; b; c]
  | TRecordConstructor (_, l) | TUnionConstructor (_, _, l) -> List.map snd l

(* The checks of one condition, in the order a reader would look. *)
let rec check_condition (env: env) (span: span) (e: texpr): unit =
  (* A write reference is linear too; it is named as what it is before a
     linear value is looked for. *)
  let ty = TastUtil.get_type e in
  if is_write_type ty then Checks.write_reference ~span;
  (match e with
   | TParamVar (n, ty) | TLocalVar (n, ty) | TTemporary (n, ty) ->
      if is_linear ty then Checks.consumes ~span ~var:(display_name n)
   | _ -> ());
  (* The arguments before the call, so that a condition that writes
     &!x or &~x is told so, rather than that the function it hands the
     reference to asks for one. *)
  List.iter (check_condition env span) (children e);
  (match e with
   | TVarMethodCall { method_name; _ } ->
      Checks.unknown_callee ~span ~what:("the method " ^ (qident_debug_label method_name) ^ " of a type parameter")
   | TFptrCall (name, _, _) ->
      Checks.unknown_callee ~span ~what:("through the function pointer " ^ (ident_string name))
   | TEmbed _ ->
      Checks.reaches ~span ~chain:["@embed"] ~what:"which is C written into the source"
   | _ ->
      (match callee_purity env e with
       | Some (Impure (chain, what)) -> Checks.reaches ~span ~chain ~what
       | _ -> ()))

let rec check_stmt (env: env) (s: tstmt): unit =
  let c = check_stmt env in
  match s with
  | TLetTmp (name, ty, e) ->
     pending := List.filter (fun p -> not (String.equal p (ident_string name))) !pending;
     (match Hashtbl.find_opt temps (ident_string name) with
      | Some { kind = TempRequires; clause_span; _ } | Some { kind = TempEnsures; clause_span; _ } ->
         check_condition env clause_span e
      | Some { kind = TempOld; clause_span; _ } ->
         check_condition env clause_span e;
         (match type_universe ty with
          | FreeUniverse -> ()
          | _ -> Checks.old_not_free ~span:clause_span ~ty)
      | _ -> ())
  | TSkip _ | TUnreachable _ | TAssign _ | TAssignVar _ | TInitialAssign _ | TAssignTmp _
  | TDiscarding _ | TReturn _ | TRaise _ ->
     ()
  | TLet (_, _, _, _, b) | TDestructure (_, _, _, _, b) | TWhile (_, _, b) | TFor (_, _, _, _, b) -> c b
  | TIf (_, _, a, b) | TBlock (_, a, b) -> c a; c b
  | TCase (_, _, whens, _) -> List.iter (fun (TypedWhen (_, _, b)) -> c b) whens
  | TSwitch (_, _, arms, other) -> List.iter (fun (_, b) -> c b) arms; c other
  | TBorrow { body; _ } -> c body

(* The returned conditions of a function made for an invariant. *)
let rec check_returns (env: env) (span: span) (s: tstmt): unit =
  let c = check_returns env span in
  match s with
  | TReturn (_, e) -> check_condition env span e
  | TLet (_, _, _, _, b) | TDestructure (_, _, _, _, b) | TWhile (_, _, b) | TFor (_, _, _, _, b) -> c b
  | TIf (_, _, a, b) | TBlock (_, a, b) -> c a; c b
  | TCase (_, _, whens, _) -> List.iter (fun (TypedWhen (_, _, b)) -> c b) whens
  | TSwitch (_, _, arms, other) -> List.iter (fun (_, b) -> c b) arms; c other
  | TBorrow { body; _ } -> c body
  | _ -> ()

let check_module (env: env) (TypedModule (_, decls)): unit =
  List.iter
    (fun d ->
      match d with
      | TFunction (_, _, name, _, _, _, body, _, _) ->
         (match Hashtbl.find_opt invariant_functions (ident_string name) with
          | Some span -> check_returns env span body
          | None -> ());
         check_stmt env body
      | _ -> ())
    decls;
  match !pending with
  | [] -> ()
  | missed ->
     internal_err ("contract conditions not seen after typing: " ^ (String.concat ", " missed))
