(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* `hilde query': the declarations of a module, with the
   compiler's types and the lines they are written on.  Each kind of
   declaration stands on a line this test names, and two instances of one
   typeclass tell apart whether instances are joined to their places in the
   right order -- swapped, the arguments would not match their lines. *)
open OUnit2
open Hilde_core.Identifier
open Hilde_core.Error
open Hilde_core.Compiler
open TestUtil
open Yojson.Basic.Util

let interface_code = String.concat "\n" [
    "module Q is";
    "    constant limit: Nat32;";
    "    record Point: Free is";
    "        x: Int32;";
    "        y: Int32;";
    "    end;";
    "    generic [R: Region]";
    "    function norm(p: &[Point, R]): Int32;";
    "    typeclass Sized(T: Free) is";
    "        method size(value: T): Int32;";
    "    end;";
    "    instance Sized(Int32);";
    "    instance Sized(Bool);";
    "    function fetch(n: Int32): Int32";
    "        raises NotFound, Denied;";
    "end module.";
    ""
  ]

let body_code = String.concat "\n" [
    "module body Q is";
    "    constant limit: Nat32 := 10;";
    "    generic [R: Region]";
    "    function norm(p: &[Point, R]): Int32 is";
    "        return p->x + p->y;";
    "    end;";
    "    function helper(): Unit is";
    "        return nil;";
    "    end;";
    "    instance Sized(Int32) is";
    "        method size(value: Int32): Int32 is";
    "            return 4;";
    "        end;";
    "    end;";
    "    instance Sized(Bool) is";
    "        method size(value: Bool): Int32 is";
    "            return 1;";
    "        end;";
    "    end;";
    "    function fetch(n: Int32): Int32 is";
    "        if n < 0 then";
    "            raise NotFound;";
    "        end if;";
    "        return n;";
    "    end;";
    "end module body.";
    ""
  ]

let source: module_source =
  TwoFileModuleSource {
      int_filename = "Q.hih";
      int_code = interface_code;
      body_filename = "Q.hiq";
      body_code = body_code
    }

let query (): Yojson.Basic.t =
  query_modules [source] (make_mod_name "Q")

let decls (): Yojson.Basic.t list =
  query () |> member "declarations" |> to_list

let named (name: string) (kind: string): Yojson.Basic.t =
  match List.filter (fun d -> member "name" d = `String name && member "kind" d = `String kind) (decls ()) with
  | [d] -> d
  | l -> assert_failure (Printf.sprintf "%d declarations %s of kind %s" (List.length l) name kind)

let line (d: Yojson.Basic.t): int =
  d |> member "span" |> member "startp" |> member "line" |> to_int

let file (d: Yojson.Basic.t): string =
  d |> member "span" |> member "filename" |> to_string

let test_header _ =
  let q = query () in
  eq 1 (q |> member "version" |> to_int);
  eq "Q" (q |> member "module" |> to_string)

(* The interface's declarations in its order, then the body's private
   ones: the order the combining pass keeps. *)
let test_names_in_order _ =
  eq ["limit"; "Point"; "norm"; "Sized"; "Sized"; "Sized"; "fetch"; "helper"]
    (List.map (fun d -> d |> member "name" |> to_string) (decls ()))

let test_constant _ =
  let d = named "limit" "constant" in
  eq "Nat32" (d |> member "type" |> to_string);
  eq "public" (d |> member "visibility" |> to_string)

let test_record _ =
  let d = named "Point" "record" in
  eq "Free" (d |> member "universe" |> to_string);
  eq [("x", "Int32"); ("y", "Int32")]
    (List.map (fun s -> (s |> member "name" |> to_string, s |> member "type" |> to_string))
       (d |> member "slots" |> to_list))

let test_function _ =
  let d = named "norm" "function" in
  eq "public" (d |> member "visibility" |> to_string);
  eq "Int32" (d |> member "returns" |> to_string);
  eq ["R"] (List.map (fun t -> t |> member "name" |> to_string) (d |> member "type_parameters" |> to_list));
  eq ["p"] (List.map (fun p -> p |> member "name" |> to_string) (d |> member "parameters" |> to_list))

(* The kinds of the raises clause, in the order written; a
   function without the clause says an empty list. *)
let test_raises _ =
  eq ["NotFound"; "Denied"]
    (List.map to_string (named "fetch" "function" |> member "raises" |> to_list));
  eq [] (named "norm" "function" |> member "raises" |> to_list)

let test_private_function _ =
  eq "private" (named "helper" "function" |> member "visibility" |> to_string)

let test_typeclass _ =
  let d = named "Sized" "typeclass" in
  eq ["size"] (List.map (fun m -> m |> member "name" |> to_string) (d |> member "methods" |> to_list))

(* The places: every declaration on the line it is written on -- a
   definition where it is defined, so `limit' in the body; a generic
   function from its `generic' line.  Before the parser was fixed the
   two instances stood on lines 9 and 14, the `end;' of the declaration
   before each. *)
let test_lines _ =
  eq [("limit", "Q.hiq", 2); ("Point", "Q.hih", 3); ("norm", "Q.hiq", 3);
      ("Sized", "Q.hih", 9); ("Sized", "Q.hiq", 10); ("Sized", "Q.hiq", 15);
      ("fetch", "Q.hiq", 20); ("helper", "Q.hiq", 7)]
    (List.map (fun d -> (d |> member "name" |> to_string, file d, line d)) (decls ()))

(* Each instance with ITS argument: joined by the order of a list, the two
   came out swapped -- Bool on line 10, Int32 on line 15. *)
let test_instances _ =
  let instances = List.filter (fun d -> member "kind" d = `String "instance") (decls ()) in
  eq [("Int32", 10); ("Bool", 15)]
    (List.map (fun d -> (d |> member "argument" |> to_string, line d)) instances)

let test_missing_module _ =
  try
    let _ = query_modules [source] (make_mod_name "Nowhere") in
    assert_failure "a module not on the command line was queried"
  with Hilde_error e ->
    let (HildeError { code; _ }) = e in
    eq "H1017" (code_string code)

let suite =
  "Query" >::: [
      "header" >:: test_header;
      "names in order" >:: test_names_in_order;
      "constant" >:: test_constant;
      "record" >:: test_record;
      "function" >:: test_function;
      "raises" >:: test_raises;
      "private function" >:: test_private_function;
      "typeclass" >:: test_typeclass;
      "lines" >:: test_lines;
      "instances" >:: test_instances;
      "missing module" >:: test_missing_module
    ]

let _ = run_test_tt_main suite
