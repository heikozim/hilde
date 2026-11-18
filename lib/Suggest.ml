(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The name a mistyped one was most likely meant to be. *)

(* The number of single-byte insertions, deletions and replacements that
   turn a into b. *)
let distance (a: string) (b: string): int =
  let n = String.length a and m = String.length b in
  let row = Array.init (m + 1) (fun j -> j) in
  for i = 1 to n do
    let diagonal = ref row.(0) in
    row.(0) <- i;
    for j = 1 to m do
      let above = row.(j) in
      let cost = if a.[i - 1] = b.[j - 1] then 0 else 1 in
      row.(j) <- min (min (above + 1) (row.(j - 1) + 1)) (!diagonal + cost);
      diagonal := above
    done
  done;
  row.(m)

(* The candidate nearest to name, when it is near enough and no other is as
   near: at most a third of the length of name apart, and at least one.  A
   tie names nothing, since a guess between two would mislead. *)
let closest (name: string) (candidates: string list): string option =
  let limit = max 1 (String.length name / 3) in
  let scored = List.filter_map (fun c ->
      let d = distance name c in
      if d > 0 && d <= limit then Some (d, c) else None) candidates in
  match List.sort compare scored with
  | (d, c) :: rest ->
     (match rest with
      | (d', _) :: _ when d' = d -> None
      | _ -> Some c)
  | [] -> None
