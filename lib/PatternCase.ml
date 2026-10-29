(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The patterns of a case.

   Three things live here, none of which needs the type checker's
   recursion: typing a pattern against the type of the place it stands at;
   deciding whether the whens of a case leave a value out or can never be
   chosen (L. Maranget, "Warnings for pattern matching", JFP 17(3), 2007);
   and writing the statements a pattern case becomes.  Those statements
   are ordinary ones -- a borrow, a case over a reference, comparisons, an
   if chain, a case by value -- and the type checker checks them as it
   checks any other, which is how the linearity check covers every new
   form.
*)
open Identifier
open Type
open TypeSystem
open Span
open Common
open Error
open ErrorText

module A = Stages.Ast
module D = Stages.AstDB

(* A pattern with its place's type applied.  TAny is a variable (Some) or
   `_' (None); TInt is an interval with both ends included, a literal being
   one whose ends are equal; TBoxed is a pattern that looks through a box. *)
type tpat =
  | TAny of identifier option
  | TInt of Z.t * Z.t
  | TBool of bool
  | TCon of identifier * tpat list
  | TBoxed of tpat

(* A variable a pattern binds, with its type and where it stands. *)
type binding = identifier * ty * span

(* What the type checker tells this module about a type: the variants of a
   union visible here, each with its slots' names and types in the order
   the union declares them, the type arguments applied; None for any type
   that is not a union. *)
type lookup = {
    union_of: ty -> (identifier * (identifier * ty) list) list option;
  }

(* ------------------------------------------------------------------ *)
(* Types                                                              *)
(* ------------------------------------------------------------------ *)

(* `Standard.Box.Box[T]' is the one indirection a pattern looks
   through. *)
let is_box (ty: ty): ty option =
  match ty with
  | NamedType (name, [inner], _) ->
     if ((mod_name_string (source_module_name name)) = "Standard.Box")
        && ((ident_string (original_name name)) = "Box") then
       Some inner
     else
       None
  | _ ->
     None

let is_union (lk: lookup) (ty: ty): bool =
  match lk.union_of ty with
  | Some _ -> true
  | None -> false

let int_range (ty: ty): Z.t * Z.t =
  match ty with
  | Integer (s, w) -> TypeMatch.int_bounds s w
  | _ -> internal_err "PatternCase.int_range: not an integer type"

let range_text (ty: ty): string =
  let (lo, hi) = int_range ty in
  (Z.to_string lo) ^ " .. " ^ (Z.to_string hi)

let variants_text (cases: (identifier * (identifier * ty) list) list): string =
  String.concat ", " (List.map (fun (n, _) -> ident_string n) cases)

let pattern_span (p: A.apattern): span =
  match p with
  | A.PVar (span, _) -> span
  | A.PWild span -> span
  | A.PBool (span, _) -> span
  | A.PInt (span, _) -> span
  | A.PRange (span, _, _) -> span
  | A.PVariant (span, _, _) -> span

(* What a pattern case decides on. *)
let check_scrutinee (lk: lookup) (ty: ty): unit =
  match ty with
  | ReadRef _ | WriteRef _ ->
     hilde_raise (H 3072) TypeError [
         Text "A case with patterns takes a value, but this one is given a reference of type ";
         Type ty;
         Text ".";
         Break;
         Text "Matching through a reference is not built; pass the value, or use the case that binds by name, which works on references."
       ]
  | Boolean | Integer _ ->
     ()
  | _ ->
     if is_union lk ty then
       ()
     else
       hilde_raise (H 3090) TypeError [
           Text "A case with patterns decides on a union, an integer or a Bool, but this value has the type ";
           Type ty;
           Text "."
         ]

(* ------------------------------------------------------------------ *)
(* Typing a pattern                                                    *)
(* ------------------------------------------------------------------ *)

let parse_int (span: span) (ty: ty) (text: string): Z.t =
  let n = TypeMatch.parse_bigint text in
  let (lo, hi) = int_range ty in
  if (Z.leq lo n) && (Z.leq n hi) then
    n
  else
    adorn_error_with_span span
      (fun _ ->
        hilde_raise (H 3078) TypeError [
            Text "The literal ";
            Code (Z.to_string n);
            Text " is outside ";
            Type ty;
            Text ", whose values are ";
            Code (range_text ty);
            Text ".";
            Break;
            Text "A pattern never truncates or wraps a literal."
          ])

(* The pattern at a place of type [ty].  [top] is true for the patterns of
   the whens themselves, where a catch-all over a union is refused. *)
let rec type_pattern (lk: lookup) (top: bool) (ty: ty) (p: A.apattern): tpat * binding list =
  match p with
  | A.PVar (span, name) ->
     if top && (is_union lk ty) then
       adorn_error_with_span span
         (fun _ ->
           hilde_raise (H 3073) TypeError [
               Text "The variable ";
               Code (ident_string name);
               Text " would match every value of the union ";
               Type ty;
               Text ", and a case over a union has no catch-all.";
               Break;
               Text "List the variants; the compiler says which one is missing."
             ])
     else
       (TAny (Some name), [(name, ty, span)])
  | A.PWild span ->
     if top && (is_union lk ty) then
       adorn_error_with_span span
         (fun _ ->
           hilde_raise (H 3091) TypeError [
               Code "_";
               Text " would match every value of the union ";
               Type ty;
               Text ", and a case over a union has no catch-all.";
               Break;
               Text "List the variants; the compiler says which one is missing."
             ])
     else if (type_universe ty) <> FreeUniverse then
       adorn_error_with_span span
         (fun _ ->
           hilde_raise (H 3082) TypeError [
               Code "_";
               Text " stands where the value has the type ";
               Type ty;
               Text ", which is not in the Free universe.";
               Break;
               Text "It would drop that value without anyone consuming it.  Bind it to a variable and consume it in the body."
             ])
     else
       (TAny None, [])
  | A.PBool (span, b) ->
     (match is_box ty with
      | Some inner ->
         let (q, bs) = type_pattern lk false inner p in
         (TBoxed q, bs)
      | None ->
         if ty = Boolean then
           (TBool b, [])
         else
           adorn_error_with_span span
             (fun _ ->
               hilde_raise (H 3077) TypeError [
                   Code (string_of_bool b);
                   Text " is a Bool pattern, but the value here has the type ";
                   Type ty;
                   Text "."
                 ]))
  | A.PInt (span, text) ->
     (match is_box ty with
      | Some inner ->
         let (q, bs) = type_pattern lk false inner p in
         (TBoxed q, bs)
      | None ->
         (match ty with
          | Integer _ ->
             let n = parse_int span ty text in
             (TInt (n, n), [])
          | _ ->
             adorn_error_with_span span
               (fun _ ->
                 hilde_raise (H 3076) TypeError [
                     Text "The integer pattern ";
                     Code text;
                     Text " stands where the value has the type ";
                     Type ty;
                     Text ", which is not an integer type."
                   ])))
  | A.PRange (span, lo_text, hi_text) ->
     (match is_box ty with
      | Some inner ->
         let (q, bs) = type_pattern lk false inner p in
         (TBoxed q, bs)
      | None ->
         (match ty with
          | Integer _ ->
             let lo = parse_int span ty lo_text
             and hi = parse_int span ty hi_text in
             if Z.gt lo hi then
               adorn_error_with_span span
                 (fun _ ->
                   hilde_raise (H 3079) TypeError [
                       Text "The range ";
                       Code ((Z.to_string lo) ^ " .. " ^ (Z.to_string hi));
                       Text " is empty: its lower bound is above its upper bound.";
                       Break;
                       Text "A range lists its lower bound first, and both bounds belong to it."
                     ])
             else
               (TInt (lo, hi), [])
          | _ ->
             adorn_error_with_span span
               (fun _ ->
                 hilde_raise (H 3092) TypeError [
                     Text "The range ";
                     Code (lo_text ^ " .. " ^ hi_text);
                     Text " stands where the value has the type ";
                     Type ty;
                     Text ", which is not an integer type."
                   ])))
  | A.PVariant (span, name, args) ->
     (match is_box ty with
      | Some inner ->
         let (q, bs) = type_pattern lk false inner p in
         (TBoxed q, bs)
      | None ->
         (match lk.union_of ty with
          | None ->
             adorn_error_with_span span
               (fun _ ->
                 hilde_raise (H 3089) TypeError [
                     Code (ident_string name);
                     Text " is a variant pattern, but the value here has the type ";
                     Type ty;
                     Text ", which is not a union."
                   ])
          | Some cases ->
             (match List.find_opt (fun (n, _) -> equal_identifier n name) cases with
              | None ->
                 adorn_error_with_span span
                   (fun _ ->
                     hilde_raise (H 3088) TypeError [
                         Code (ident_string name);
                         Text " is not a variant of ";
                         Type ty;
                         Text ".  Its variants are ";
                         Code (variants_text cases);
                         Text "."
                       ])
              | Some (_, slots) ->
                 if (List.length slots) <> (List.length args) then
                   adorn_error_with_span span
                     (fun _ ->
                       hilde_raise (H 3083) TypeError [
                           Text "The variant ";
                           Code (ident_string name);
                           Text (" has " ^ (string_of_int (List.length slots)) ^ " slot(s), and the pattern gives "
                                 ^ (string_of_int (List.length args)) ^ " sub-pattern(s).");
                           Break;
                           Text "A variant pattern gives one sub-pattern for every slot, in the order the union declares them, so that no slot is left out unseen."
                         ])
                 else
                   let typed = List.map2 (fun (_, sty) a -> type_pattern lk false sty a) slots args in
                   (TCon (name, List.map fst typed), List.concat (List.map snd typed)))))

(* A variable once per alternative, and the same variables with the same
   types in every alternative of a when. *)
let check_alternatives (alts: (span * tpat * binding list) list): unit =
  let check_duplicates (bs: binding list) =
    let rec go (seen: identifier list) (rest: binding list) =
      match rest with
      | [] -> ()
      | (name, _, span) :: more ->
         if List.exists (equal_identifier name) seen then
           adorn_error_with_span span
             (fun _ ->
               hilde_raise (H 3086) TypeError [
                   Text "The variable ";
                   Code (ident_string name);
                   Text " is bound twice in one pattern.";
                   Break;
                   Text "A pattern binds each variable once; to compare two parts, bind both and compare them in the body."
                 ])
         else
           go (name :: seen) more
    in
    go [] bs
  in
  List.iter (fun (_, _, bs) -> check_duplicates bs) alts;
  match alts with
  | [] -> ()
  | (_, _, first) :: rest ->
     let find (name: identifier) (bs: binding list): binding option =
       List.find_opt (fun (n, _, _) -> equal_identifier n name) bs
     in
     List.iter (fun (aspan, _, bs) ->
         let missing (name: identifier) (where: span) =
           adorn_error_with_span where
             (fun _ ->
               hilde_raise (H 3084) TypeError [
                   Text "The alternatives of this when bind different variables: ";
                   Code (ident_string name);
                   Text " is bound in one alternative and not in another.";
                   Break;
                   Text "The body runs after any of them, so every alternative binds the same variables."
                 ])
         in
         List.iter (fun (name, ty, _) ->
             match find name bs with
             | None ->
                missing name aspan
             | Some (_, ty', span') ->
                if not (equal_ty ty ty') then
                  adorn_error_with_span span'
                    (fun _ ->
                      hilde_raise (H 3085) TypeError [
                          Text "The variable ";
                          Code (ident_string name);
                          Text " has the type ";
                          Type ty;
                          Text " in one alternative and ";
                          Type ty';
                          Text " in another.";
                          Break;
                          Text "The body runs after any of them, so a variable has one type in every alternative."
                        ])
                else
                  ())
           first;
         List.iter (fun (name, _, span) ->
             match find name first with
             | None -> missing name span
             | Some _ -> ())
           bs)
       rest

(* ------------------------------------------------------------------ *)
(* Exhaustiveness and reachability                                     *)
(* ------------------------------------------------------------------ *)

(* The heads of a column: what a pattern is at its top. *)
type ctor =
  | KVariant of identifier
  | KBool of bool
  | KInt of Z.t * Z.t
  | KBox

let head (p: tpat): ctor option =
  match p with
  | TAny _ -> None
  | TInt (lo, hi) -> Some (KInt (lo, hi))
  | TBool b -> Some (KBool b)
  | TCon (n, _) -> Some (KVariant n)
  | TBoxed _ -> Some KBox

let arg_types (lk: lookup) (ty: ty) (c: ctor): ty list =
  match c with
  | KVariant n ->
     (match lk.union_of ty with
      | Some cases ->
         (match List.find_opt (fun (m, _) -> equal_identifier m n) cases with
          | Some (_, slots) -> List.map snd slots
          | None -> internal_err "PatternCase.arg_types: no such variant")
      | None -> internal_err "PatternCase.arg_types: not a union")
  | KBox ->
     (match is_box ty with
      | Some inner -> [inner]
      | None -> internal_err "PatternCase.arg_types: not a box")
  | KBool _ | KInt _ ->
     []

let rec wilds (n: int): tpat list =
  if n <= 0 then [] else (TAny None) :: (wilds (n - 1))

(* A row of the matrix specialised by a constructor of arity [a].  Integer
   constructors are elementary segments: every interval of the column
   contains a segment or is disjoint from it, because the segments are cut
   at every interval's ends (see [segments]). *)
let specialize_row (c: ctor) (a: int) (row: tpat list): tpat list option =
  match row with
  | [] -> internal_err "PatternCase.specialize_row: empty row"
  | p :: rest ->
     (match (p, c) with
      | (TAny _, _) -> Some ((wilds a) @ rest)
      | (TCon (n, args), KVariant m) -> if equal_identifier n m then Some (args @ rest) else None
      | (TBool b, KBool b') -> if b = b' then Some rest else None
      | (TInt (lo, hi), KInt (slo, shi)) -> if (Z.leq lo slo) && (Z.leq shi hi) then Some rest else None
      | (TBoxed q, KBox) -> Some (q :: rest)
      | _ -> None)

let specialize (c: ctor) (a: int) (rows: tpat list list): tpat list list =
  List.filter_map (specialize_row c a) rows

let default_matrix (rows: tpat list list): tpat list list =
  List.filter_map (fun row ->
      match row with
      | (TAny _) :: rest -> Some rest
      | _ -> None)
    rows

let column_heads (rows: tpat list list): ctor list =
  List.filter_map (fun row ->
      match row with
      | p :: _ -> head p
      | [] -> None)
    rows

let intervals (heads: ctor list): (Z.t * Z.t) list =
  List.filter_map (fun c -> match c with KInt (lo, hi) -> Some (lo, hi) | _ -> None) heads

(* The type's range cut at both ends of every interval: segments that are
   each either inside an interval or outside it. *)
let segments ((tlo, thi): Z.t * Z.t) (ivs: (Z.t * Z.t) list): (Z.t * Z.t) list =
  let cuts = List.concat_map (fun (lo, hi) -> [lo; Z.succ hi]) ivs in
  let cuts = List.filter (fun c -> (Z.gt c tlo) && (Z.leq c thi)) cuts in
  let cuts = List.sort_uniq Z.compare cuts in
  let rec build (starts: Z.t list): (Z.t * Z.t) list =
    match starts with
    | [s] -> [(s, thi)]
    | s :: ((n :: _) as rest) -> (s, Z.pred n) :: (build rest)
    | [] -> []
  in
  build (tlo :: cuts)

let covered (ivs: (Z.t * Z.t) list) ((slo, shi): Z.t * Z.t): bool =
  List.exists (fun (lo, hi) -> (Z.leq lo slo) && (Z.leq shi hi)) ivs

(* Every constructor of the column's type, whether the heads name them
   all, and one they leave out. *)
let signature (lk: lookup) (ty: ty) (heads: ctor list): ctor list * bool * ctor option =
  let has (c: ctor): bool = List.exists (fun h -> h = c) heads in
  match is_box ty with
  | Some _ ->
     ([KBox], has KBox, if has KBox then None else Some KBox)
  | None ->
     (match ty with
      | Boolean ->
         let all = [KBool true; KBool false] in
         let missing = List.find_opt (fun c -> not (has c)) all in
         (all, missing = None, missing)
      | Integer _ ->
         let ivs = intervals heads in
         let segs = segments (int_range ty) ivs in
         let open_segs = List.filter (fun s -> not (covered ivs s)) segs in
         (List.map (fun (lo, hi) -> KInt (lo, hi)) segs,
          open_segs = [],
          (match open_segs with
           | (lo, _) :: _ -> Some (KInt (lo, lo))
           | [] -> None))
      | _ ->
         (match lk.union_of ty with
          | Some cases ->
             let all = List.map (fun (n, _) -> KVariant n) cases in
             let present (c: ctor): bool =
               match c with
               | KVariant n -> List.exists (fun h -> match h with KVariant m -> equal_identifier n m | _ -> false) heads
               | _ -> false
             in
             let missing = List.find_opt (fun c -> not (present c)) all in
             (all, missing = None, missing)
          | None ->
             ([], false, None)))

let rec split_at (n: int) (l: 'a list): 'a list * 'a list =
  if n <= 0 then ([], l)
  else
    match l with
    | x :: rest -> let (a, b) = split_at (n - 1) rest in (x :: a, b)
    | [] -> internal_err "PatternCase.split_at: list too short"

let rebuild (c: ctor) (a: int) (w: tpat list): tpat list =
  let (args, rest) = split_at a w in
  let p =
    match c with
    | KVariant n -> TCon (n, args)
    | KBool b -> TBool b
    | KInt (lo, _) -> TInt (lo, lo)
    | KBox -> TBoxed (List.hd args)
  in
  p :: rest

let rec first_some (f: 'a -> 'b option) (l: 'a list): 'b option =
  match l with
  | [] -> None
  | x :: rest ->
     (match f x with
      | Some y -> Some y
      | None -> first_some f rest)

(* Maranget's U(P, q), computing a witness: Some w when a value vector w
   that q matches is matched by no row of P, None when there is none. *)
let rec useful (lk: lookup) (tys: ty list) (rows: tpat list list) (q: tpat list): tpat list option =
  match (tys, q) with
  | ([], []) ->
     if rows = [] then Some [] else None
  | (ty :: tys', q1 :: qs) ->
     let heads = column_heads rows in
     let try_ctor (c: ctor) (qargs: tpat list): tpat list option =
       let targs = arg_types lk ty c in
       let a = List.length targs in
       match useful lk (targs @ tys') (specialize c a rows) (qargs @ qs) with
       | Some w -> Some (rebuild c a w)
       | None -> None
     in
     (match q1 with
      | TInt (lo, hi) ->
         let segs = segments (int_range ty) ((lo, hi) :: (intervals heads)) in
         let inside = List.filter (fun (slo, shi) -> (Z.leq lo slo) && (Z.leq shi hi)) segs in
         first_some (fun (slo, shi) -> try_ctor (KInt (slo, shi)) []) inside
      | TBool b -> try_ctor (KBool b) []
      | TCon (n, args) -> try_ctor (KVariant n) args
      | TBoxed p -> try_ctor KBox [p]
      | TAny _ ->
         let (all, complete, missing) = signature lk ty heads in
         if complete then
           first_some (fun c -> try_ctor c (wilds (List.length (arg_types lk ty c)))) all
         else
           (match useful lk tys' (default_matrix rows) qs with
            | None -> None
            | Some w ->
               (match missing with
                | Some c when heads <> [] ->
                   let a = List.length (arg_types lk ty c) in
                   Some (rebuild c a ((wilds a) @ w))
                | _ ->
                   Some ((TAny None) :: w))))
  | _ ->
     internal_err "PatternCase.useful: the vector and the types differ in length"

let rec show_pattern (p: tpat): string =
  match p with
  | TAny _ -> "_"
  | TInt (lo, hi) ->
     if Z.equal lo hi then Z.to_string lo
     else (Z.to_string lo) ^ " .. " ^ (Z.to_string hi)
  | TBool b -> string_of_bool b
  | TCon (n, []) -> ident_string n
  | TCon (n, args) -> (ident_string n) ^ "(" ^ (String.concat ", " (List.map show_pattern args)) ^ ")"
  | TBoxed q -> show_pattern q

(* [whens] is every when with its alternatives, in the order they are
   written. *)
let check_case (lk: lookup) (ty: ty) (whens: (span * tpat) list list): unit =
  let before: tpat list list ref = ref [] in
  List.iter (fun alts ->
      List.iter (fun (aspan, p) ->
          (match useful lk [ty] (List.rev !before) [p] with
           | None ->
              adorn_error_with_span aspan
                (fun _ ->
                  hilde_raise (H 3074) TypeError [
                      Text "The pattern ";
                      Code (show_pattern p);
                      Text " can never be chosen: every value it matches is matched by a pattern before it.";
                      Break;
                      Text "Remove it, or move it before the pattern that covers it."
                    ])
           | Some _ ->
              ());
          before := [p] :: !before)
        alts)
    whens;
  match useful lk [ty] (List.rev !before) [TAny None] with
  | None -> ()
  | Some [w] ->
     hilde_raise (H 3075) TypeError [
         Text "The case does not cover every value of ";
         Type ty;
         Text ": for example ";
         Code (show_pattern w);
         Text " matches no when.";
         Break;
         Text "Add a when for it.  A case has no else; over an integer a variable or ";
         Code "_";
         Text " finishes it."
       ]
  | Some _ ->
     internal_err "PatternCase.check_case: a witness of the wrong length"

(* ------------------------------------------------------------------ *)
(* The statements a pattern case becomes                              *)
(* ------------------------------------------------------------------ *)

let local (mn: module_name) (name: identifier): D.aexpr =
  D.Variable (make_qident (mn, name, name))

let box_function (name: string): qident =
  make_qident (make_mod_name "Standard.Box", make_ident name, make_ident name)

let int_literal (n: Z.t): D.aexpr =
  D.IntConstant (Z.to_string n)

(* An if whose condition is first put in a temporary, as the lift pass
   does for every if of a programme.  Written with the comparison in place,
   the C came out as `if ((a == b))', and clang's -Wparentheses-equality
   counted 226 warnings over the gate's programmes -- the Linux gate over
   tree 21975642 was red on exactly that step, 2026-09-25. *)
let lifted_if (span: span) (c: D.aexpr) (t: D.astmt) (f: D.astmt): D.astmt =
  let tmp = fresh_ident () in
  D.ABlock (span, D.LetTmp (tmp, c), D.AIf (span, D.Temporary tmp, t, f))

let union_cases (lk: lookup) (ty: ty): (identifier * (identifier * ty) list) list =
  match lk.union_of ty with
  | Some cases -> cases
  | None -> internal_err "PatternCase.union_cases: not a union"

(* The deciding phase.  [r] is a read reference to the value of type [ty];
   [success] runs when [p] matches it.  Nothing is moved or freed. *)
let rec test (mn: module_name) (lk: lookup) (span: span) (ty: ty) (p: tpat) (r: D.aexpr) (success: D.astmt): D.astmt =
  match p with
  | TAny _ ->
     success
  | TBool b ->
     let c = if b then D.Deref r else D.Negation (D.Deref r) in
     lifted_if span c success (D.ASkip span)
  | TInt (lo, hi) ->
     let (tlo, thi) = int_range ty in
     let conds =
       if Z.equal lo hi then
         [D.Comparison (Equal, D.Deref r, int_literal lo)]
       else
         (* A bound at the end of the type is left out: it always holds,
            and a C compiler says so about `x >= 0' on an unsigned x. *)
         (if Z.equal lo tlo then [] else [D.Comparison (GreaterThanOrEqual, D.Deref r, int_literal lo)])
         @ (if Z.equal hi thi then [] else [D.Comparison (LessThanOrEqual, D.Deref r, int_literal hi)])
     in
     (match conds with
      | [] -> success
      | [c] -> lifted_if span c success (D.ASkip span)
      | [a; b] -> lifted_if span (D.Conjunction (a, b)) success (D.ASkip span)
      | _ -> internal_err "PatternCase.test: more than two bounds")
  | TBoxed q ->
     (match is_box ty with
      | Some inner ->
         test mn lk span inner q (D.FunctionCall (box_function "unboxReadRef", D.Positional [r])) success
      | None ->
         internal_err "PatternCase.test: a boxed pattern on a type that is not a box")
  | TCon (name, args) ->
     let whens =
       List.map (fun (cname, slots) ->
           let names = List.map (fun _ -> fresh_ident ()) slots in
           let bindings = List.combine (List.map fst slots) names in
           if equal_identifier cname name then
             let parts = List.combine (List.combine (List.map snd slots) args) names in
             let body =
               List.fold_right (fun ((sty, arg), nm) acc -> test mn lk span sty arg (local mn nm) acc)
                 parts success
             in
             D.AbstractWhenSlots (cname, bindings, body)
           else
             D.AbstractWhenSlots (cname, bindings, D.ASkip span))
         (union_cases lk ty)
     in
     D.ACase (span, r, whens)

(* The taking-apart phase, for the one alternative that the deciding phase
   chose.  [v] is the value of type [ty], which this consumes; [body] runs
   with the alternative's variables bound. *)
let rec take (mn: module_name) (lk: lookup) (span: span) (ty: ty) (p: tpat) (v: D.aexpr) (body: D.astmt): D.astmt =
  match p with
  | TAny (Some name) ->
     D.ALetInfer (span, name, v, body)
  | TAny None | TInt _ | TBool _ ->
     (* Free by construction: `_' only on a Free type (decision 8),
        literals only on integers and Bool. *)
     body
  | TBoxed q ->
     (match is_box ty with
      | Some inner ->
         let u = fresh_ident () in
         D.ALetInfer (span, u, D.FunctionCall (box_function "unbox", D.Positional [v]),
                      take mn lk span inner q (local mn u) body)
      | None ->
         internal_err "PatternCase.take: a boxed pattern on a type that is not a box")
  | TCon (name, args) ->
     let whens =
       List.map (fun (cname, slots) ->
           if equal_identifier cname name then
             (* A slot whose pattern is a variable is bound under the
                variable's own name; any other gets a fresh one. *)
             let named =
               List.map2 (fun (sname, sty) arg ->
                   match arg with
                   | TAny (Some x) -> ((sname, x), None)
                   | _ -> let nm = fresh_ident () in ((sname, nm), Some (sty, arg, nm)))
                 slots args
             in
             let inner =
               List.fold_right (fun (_, more) acc ->
                   match more with
                   | None -> acc
                   | Some (sty, arg, nm) -> take mn lk span sty arg (local mn nm) acc)
                 named body
             in
             D.AbstractWhenSlots (cname, List.map fst named, inner)
           else
             D.AbstractWhenSlots (cname, List.map (fun (sname, _) -> (sname, fresh_ident ())) slots, D.AUnreachable span))
         (union_cases lk ty)
     in
     D.ACase (span, v, whens)

(* The body of a when with n alternatives is typed n times, once in the
   branch of each (decision 11).  A temporary an earlier pass made inside
   the body (LetTmp) stays in the lexical environment once it is typed, so
   the second copy would declare it again.  Every copy after the first gets
   fresh names for the temporaries it defines; everything else in it is
   scoped and is typed afresh as it is.  Without the fresh names the
   second copy is refused with H6020. *)
let refresh_temporaries (body: D.astmt): D.astmt =
  let table: (identifier * identifier) list ref = ref [] in
  let rec collect (s: D.astmt): unit =
    match s with
    | D.LetTmp (id, _) -> table := (id, fresh_ident ()) :: !table
    | D.ALet (_, _, _, _, b) | D.ADestructure (_, _, _, _, b) | D.AWhen (_, _, b)
    | D.AWhile (_, _, b) | D.ALetInfer (_, _, _, b) -> collect b
    | D.AIf (_, _, a, b) | D.ABlock (_, a, b) -> collect a; collect b
    | D.ACase (_, _, ws) ->
       List.iter (fun w -> match w with D.AbstractWhen (_, _, b) | D.AbstractWhenSlots (_, _, b) -> collect b) ws
    | D.APatternCase (_, _, ws) -> List.iter (fun (D.PatternWhen (_, _, b)) -> collect b) ws
    | D.AFor { body; _ } -> collect body
    | D.ABorrow { body; _ } -> collect body
    | D.ASkip _ | D.AAssign _ | D.AAssignVar _ | D.AInitialAssign _ | D.ADiscarding _
    | D.AReturn _ | D.AssignTmp _ | D.AUnreachable _ | D.ARaise _ -> ()
  in
  collect body;
  let rn (id: identifier): identifier =
    match List.find_opt (fun (a, _) -> equal_identifier a id) !table with
    | Some (_, b) -> b
    | None -> id
  in
  let rec ex (x: D.aexpr): D.aexpr =
    match x with
    | D.Temporary id -> D.Temporary (rn id)
    (* A temporary made before this pass may be read as a variable, as the
       statements a contract is made into read theirs.  Its name
       begins with an underscore, so no variable of the programme is taken
       along. *)
    | D.Variable q when not (equal_identifier (rn (local_name q)) (local_name q)) ->
       let renamed = rn (local_name q) in
       D.Variable (make_qident (source_module_name q, renamed, renamed))
    | D.FunctionCall (q, D.Positional l) -> D.FunctionCall (q, D.Positional (List.map ex l))
    | D.FunctionCall (q, D.Named l) -> D.FunctionCall (q, D.Named (List.map (fun (n, v) -> (n, ex v)) l))
    | D.ArithmeticExpression (op, a, b) -> D.ArithmeticExpression (op, ex a, ex b)
    | D.Comparison (op, a, b) -> D.Comparison (op, ex a, ex b)
    | D.Conjunction (a, b) -> D.Conjunction (ex a, ex b)
    | D.Disjunction (a, b) -> D.Disjunction (ex a, ex b)
    | D.Negation a -> D.Negation (ex a)
    | D.ArithNegation a -> D.ArithNegation (ex a)
    | D.IfExpression (a, b, c) -> D.IfExpression (ex a, ex b, ex c)
    | D.Embed (sp, t, s, l) -> D.Embed (sp, t, s, List.map ex l)
    | D.Deref a -> D.Deref (ex a)
    | D.Typecast (a, t) -> D.Typecast (ex a, t)
    | D.Question (sp, a) -> D.Question (sp, ex a)
    | D.SlotAccessor (a, id) -> D.SlotAccessor (ex a, id)
    | D.PointerSlotAccessor (a, id) -> D.PointerSlotAccessor (ex a, id)
    | D.ArrayIndex (a, b) -> D.ArrayIndex (ex a, ex b)
    | D.RefTransform (m, a) -> D.RefTransform (m, ex a)
    | D.NilConstant | D.BoolConstant _ | D.IntConstant _ | D.FloatConstant _
    | D.StringConstant _ | D.Variable _ | D.SizeOf _ -> x
  and st (s: D.astmt): D.astmt =
    match s with
    | D.ASkip _ | D.AUnreachable _ -> s
    | D.ALet (sp, m, id, t, b) -> D.ALet (sp, m, id, t, st b)
    | D.ADestructure (sp, m, bs, v, b) -> D.ADestructure (sp, m, bs, ex v, st b)
    | D.AAssign (sp, a, b) -> D.AAssign (sp, ex a, ex b)
    | D.AAssignVar (sp, q, v) -> D.AAssignVar (sp, q, ex v)
    | D.AInitialAssign (q, t, v) -> D.AInitialAssign (q, t, ex v)
    | D.AIf (sp, c, a, b) -> D.AIf (sp, ex c, st a, st b)
    | D.AWhen (sp, c, b) -> D.AWhen (sp, ex c, st b)
    | D.ACase (sp, v, ws) ->
       D.ACase (sp, ex v,
                List.map (fun w ->
                    match w with
                    | D.AbstractWhen (n, bs, b) -> D.AbstractWhen (n, bs, st b)
                    | D.AbstractWhenSlots (n, ps, b) -> D.AbstractWhenSlots (n, ps, st b))
                  ws)
    | D.APatternCase (sp, v, ws) ->
       D.APatternCase (sp, ex v, List.map (fun (D.PatternWhen (wsp, ps, b)) -> D.PatternWhen (wsp, ps, st b)) ws)
    | D.AWhile (sp, c, b) -> D.AWhile (sp, ex c, st b)
    | D.AFor { span; name; initial; final; body } ->
       D.AFor { span; name; initial = ex initial; final = ex final; body = st body }
    | D.ABorrow { span; original; rename; region; body; mode } ->
       D.ABorrow { span; original = rn original; rename; region; body = st body; mode }
    | D.ABlock (sp, a, b) -> D.ABlock (sp, st a, st b)
    | D.ADiscarding (sp, v) -> D.ADiscarding (sp, ex v)
    | D.AReturn (sp, v) -> D.AReturn (sp, ex v)
    | D.ARaise (sp, kind) -> D.ARaise (sp, kind)
    | D.LetTmp (id, v) -> D.LetTmp (rn id, ex v)
    | D.AssignTmp (id, v) -> D.AssignTmp (rn id, ex v)
    | D.ALetInfer (sp, id, v, b) -> D.ALetInfer (sp, id, ex v, st b)
  in
  st body

(* The most values the arms of one switch may name together.  A range is
   written as one label per value, so a wider case stays an if chain. *)
let max_switch_labels: int = 1024

(* The labels of a switch for a case over an integer, when one fits: there
   are two whens or more, every when but the last has only literals and
   ranges, and those name at most max_switch_labels values.  Each arm gets
   the values of its patterns that no arm before it names, in order; the
   last when becomes the default.  None when the case does not fit. *)
let switch_labels (ty: ty) (whens: tpat list list): Z.t list list option =
  let interval (p: tpat): (Z.t * Z.t) option =
    match p with
    | TInt (lo, hi) -> Some (lo, hi)
    | _ -> None
  in
  match (ty, List.rev whens) with
  | (Integer _, _ :: (_ :: _ as rev_arms)) ->
     let arms = List.map (List.map interval) (List.rev rev_arms) in
     if List.exists (List.exists Option.is_none) arms then
       None
     else
       let arms = List.map (List.filter_map Fun.id) arms in
       let size =
         List.fold_left (fun acc arm ->
             List.fold_left (fun acc (lo, hi) -> Z.add acc (Z.succ (Z.sub hi lo))) acc arm)
           Z.zero arms
       in
       if Z.gt size (Z.of_int max_switch_labels) then
         None
       else
         let seen: (string, unit) Hashtbl.t = Hashtbl.create 64 in
         let rec values (lo: Z.t) (hi: Z.t): Z.t list =
           if Z.gt lo hi then
             []
           else if Hashtbl.mem seen (Z.to_string lo) then
             values (Z.succ lo) hi
           else
             (Hashtbl.add seen (Z.to_string lo) ();
              lo :: values (Z.succ lo) hi)
         in
         let labels = List.map (List.concat_map (fun (lo, hi) -> values lo hi)) arms in
         (* An arm whose values all stand in arms before it cannot be
            chosen, and the check of the case has refused it already. *)
         if List.mem [] labels then None else Some labels
  | _ ->
     None

(* The whole statement.  [scrutinee] is the temporary the lift pass put the
   value in; [clauses] is every alternative of every when, in order, each
   with the body of its when. *)
let generate (mn: module_name) (lk: lookup) (span: span) (ty: ty) (scrutinee: identifier) (clauses: (tpat * D.astmt) list): D.astmt =
  let row = fresh_ident ()
  and r = fresh_ident ()
  and region = fresh_ident () in
  let numbered = List.mapi (fun i c -> (i + 1, c)) clauses in
  let tests =
    List.fold_right (fun (k, (p, _)) acc ->
        let t =
          lifted_if span
            (D.Comparison (Equal, D.Temporary row, D.IntConstant "0"))
            (test mn lk span ty p (local mn r) (D.AssignTmp (row, D.IntConstant (string_of_int k))))
            (D.ASkip span)
        in
        D.ABlock (span, t, acc))
      numbered (D.ASkip span)
  in
  let deciding =
    D.ABorrow {
        span = span;
        original = scrutinee;
        rename = r;
        region = region;
        body = tests;
        mode = Read
      }
  in
  let rec chain (l: (int * (tpat * D.astmt)) list): D.astmt =
    match l with
    | [] -> internal_err "PatternCase.generate: a case without whens"
    | [(_, (p, body))] ->
       take mn lk span ty p (D.Temporary scrutinee) body
    | (k, (p, body)) :: rest ->
       lifted_if span
         (D.Comparison (Equal, D.Temporary row, D.IntConstant (string_of_int k)))
         (take mn lk span ty p (D.Temporary scrutinee) body)
         (chain rest)
  in
  D.ABlock (span,
            D.LetTmp (row, D.IntConstant "0"),
            D.ABlock (span, deciding, chain numbered))
