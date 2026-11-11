(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* hilde rename: which names of a source change and which stay, and that a
   collision is reported. *)
open OUnit2
open Hilde_core
open TestUtil

let source: string = String.concat "\n" [
    "import M (otherConst, someFunc);";
    "module body T is";
    "    constant maxSize: Index := 4;";
    "    -- maxSize bounds someFunc and stringText stays.";
    "    function doWork(firstArg: Index, hmacSha3_512: Index): Index is";
    "        let localName: Index := firstArg + maxSize;";
    "        let {slotName: Index} := pair;";
    "        let r: R := Rec(slotField => localName);";
    "        let s: Index := doWork(firstArg => r.slotField, hmacSha3_512 => slotName);";
    "        printLn(\"localName\");";
    "        return someFunc(s);";
    "    end;";
    "end module body."
  ]

let expected: string = String.concat "\n" [
    "import M (otherConst, someFunc);";
    "module body T is";
    "    constant max_size: Index := 4;";
    "    -- max_size bounds someFunc and stringText stays.";
    "    function doWork(first_arg: Index, hmac_sha3_512: Index): Index is";
    "        let local_name: Index := first_arg + max_size;";
    "        let {slotName as slot_name: Index} := pair;";
    "        let r: R := Rec(slotField => local_name);";
    "        let s: Index := doWork(first_arg => r.slotField, hmac_sha3_512 => slot_name);";
    "        printLn(\"localName\");";
    "        return someFunc(s);";
    "    end;";
    "end module body."
  ]

let test_text _ =
  let (out, collisions) = Rename.rename_text source in
  eq expected out;
  eq 0 (List.length collisions)

let test_snake _ =
  eq "foo_bar" (Rename.snake "fooBar");
  eq "sha3_256" (Rename.snake "sha3_256");
  eq "hmac_sha3_512" (Rename.snake "hmacSha3_512");
  eq "parse_html_text" (Rename.snake "parseHTMLText");
  eq "x" (Rename.snake "x")

let test_collision _ =
  let src = "module body T is\n function f(fooBar: Index, foo_bar: Index): Index is\n return 0;\n end;\nend module body.\n" in
  let (_, collisions) = Rename.rename_text src in
  eq true (List.length collisions > 0)

let test_keyword _ =
  let src = "module body T is\n function f(Of: Index): Index is\n return 0;\n end;\nend module body.\n" in
  let (_, collisions) = Rename.rename_text src in
  eq true (List.length collisions > 0)

(* An import of a constant of a module the run only reads: the module
   carries the new form already, the importer the old one, and the constant
   of the import and of its use change while the module stays. *)
let test_module_root _ =
  let module_src: string = String.concat "\n" [
      "module Standard.File is";
      "    constant kind_regular: FileKind;";
      "end";
    ] in
  let source: string = String.concat "\n" [
      "import Standard.File (FileDescriptor, kindRegular);";
      "module body T is";
      "    function isRegular(fd: FileDescriptor): Bool is";
      "        return sameKind(fd, kindRegular);";
      "    end;";
      "end module body.";
    ] in
  let expected: string = String.concat "\n" [
      "import Standard.File (FileDescriptor, kind_regular);";
      "module body T is";
      "    function isRegular(fd: FileDescriptor): Bool is";
      "        return sameKind(fd, kind_regular);";
      "    end;";
      "end module body.";
    ] in
  let tables = Rename.fresh_tables () in
  (match Rename.lex module_src with
   | Some toks -> Rename.scan_tables tables "standard/src/File.hih" toks
   | None -> assert_failure "the module does not lex");
  match Rename.lex source with
  | None -> assert_failure "the source does not lex"
  | Some toks ->
     let r = Rename.process tables "use.hiq" toks in
     eq expected (Rename.apply_edits tables source toks r);
     eq 0 (List.length r.collisions)

(* A slot of a case and a constant may carry one name.  In a pattern the name
   before as is the slot, which keeps its name; only the variable behind as is
   a binding of the run.  The constant is renamed at its declaration and at its
   uses, and the constructor call keeps its slot name. *)
let shared: string = String.concat "\n" [
    "module body T is";
    "    union Check: Free is";
    "        case Verified is";
    "            keyId: Int32;";
    "        case NotSigned;";
    "    end;";
    "";
    "    constant keyId: Int32 := 3;";
    "";
    "    function makeCheck(): Check is";
    "        return Verified(keyId => keyId);";
    "    end;";
    "";
    "    function caseOf(check: Check): Int32 is";
    "        case check of";
    "            when Verified(keyId as named: Int32) do";
    "                return keyId;";
    "            when NotSigned do";
    "                return 1;";
    "        end case;";
    "    end;";
    "end module body."
  ]

let shared_expected: string = String.concat "\n" [
    "module body T is";
    "    union Check: Free is";
    "        case Verified is";
    "            keyId: Int32;";
    "        case NotSigned;";
    "    end;";
    "";
    "    constant key_id: Int32 := 3;";
    "";
    "    function makeCheck(): Check is";
    "        return Verified(keyId => key_id);";
    "    end;";
    "";
    "    function caseOf(check: Check): Int32 is";
    "        case check of";
    "            when Verified(keyId as named: Int32) do";
    "                return key_id;";
    "            when NotSigned do";
    "                return 1;";
    "        end case;";
    "    end;";
    "end module body."
  ]

let test_shared_name _ =
  let (out, collisions) = Rename.rename_text shared in
  eq shared_expected out;
  eq 0 (List.length collisions)

(* What hilde check answers for the source: "clean", or the code of its first
   error.  A pattern names the slots of its union, and the compiler compares
   them by name, so a renamed slot is a type error. *)
let checked (src: string): string =
  let source =
    Compiler.BodyModuleSource { body_filename = "T.hiq"; body_code = src }
  in
  try
    ignore (Compiler.check_multiple Compiler.empty_compiler [source]);
    "clean"
  with
  | Hilde_core.Error.Hilde_error (Hilde_core.Error.HildeError { code; _ }) ->
     Hilde_core.Error.code_string code

let test_shared_name_compiles _ =
  let (out, _) = Rename.rename_text shared in
  eq "clean" (checked out)

(* The same rule in a destructuring: the slot before as stays, the variable
   behind it and the constant are renamed. *)
let test_shared_name_destructuring _ =
  let src = String.concat "\n" [
      "module body T is";
      "    constant slotField: Int32 := 3;";
      "";
      "    function take(pair: Pair): Int32 is";
      "        let {slotField as localName: Int32} := pair;";
      "        return localName + slotField;";
      "    end;";
      "end module body."
    ] in
  let want = String.concat "\n" [
      "module body T is";
      "    constant slot_field: Int32 := 3;";
      "";
      "    function take(pair: Pair): Int32 is";
      "        let {slotField as local_name: Int32} := pair;";
      "        return local_name + slot_field;";
      "    end;";
      "end module body."
    ] in
  let (out, collisions) = Rename.rename_text src in
  eq want out;
  eq 0 (List.length collisions)

(* The control: with the slot renamed in the pattern the same text does not
   compile, so the test above is not empty. *)
let test_shared_name_control _ =
  let wrong = String.concat "\n" [
      "module body T is";
      "    union Check: Free is";
      "        case Verified is";
      "            keyId: Int32;";
      "        case NotSigned;";
      "    end;";
      "";
      "    function caseOf(check: Check): Int32 is";
      "        case check of";
      "            when Verified(key_id as named: Int32) do";
      "                return 1;";
      "            when NotSigned do";
      "                return 1;";
      "        end case;";
      "    end;";
      "end module body."
    ]
  in
  eq "H3025" (checked wrong)

(* The example of a docstring is renamed with the code: its own variables
   by what it declares, the names of the file by the file's pairs, and the
   prose around it word by word.  A docstring line at the text's depth is
   prose, not an example. *)
let doc_source: string = String.concat "\n" [
    "\"\"\"";
    "Counts things.";
    "";
    "- isRange in the prose follows nothing it does not declare.";
    "";
    "    let isRange: Bool := check(maxSize);";
    "";
    "    let firstEnd: Index := isRange;";
    "\"\"\"";
    "module T is";
    "    constant maxSize: Index;";
    "end module."
  ]

let doc_expected: string = String.concat "\n" [
    "\"\"\"";
    "Counts things.";
    "";
    "- isRange in the prose follows nothing it does not declare.";
    "";
    "    let is_range: Bool := check(max_size);";
    "";
    "    let first_end: Index := is_range;";
    "\"\"\"";
    "module T is";
    "    constant max_size: Index;";
    "end module."
  ]

let test_docstring_example _ =
  let (out, collisions) = Rename.rename_text doc_source in
  eq doc_expected out;
  eq 0 (List.length collisions)

(* The plan names the positions of the example relative to it, under the
   number of the example. *)
let test_docstring_plan _ =
  let (plan, _) = Rename.plan_of_text "t.hih" doc_source in
  let in_example =
    List.filter (fun (q: Rename.planned) -> q.p_block = Some 0) plan in
  eq 3 (List.length in_example);
  eq true (List.exists (fun (q: Rename.planned) ->
      q.p_old = "isRange" && q.p_line = 1 && q.p_col = 9 && q.p_decl) in_example)

(* An example and the docstring it lies in. *)
let test_docstring_blocks _ =
  let src = "\"\"\"\nText.\n\n    let a: Index := 1;\n    let b: Index := a;\n\nMore text.\n\"\"\"\n" in
  match Rename.lex src with
  | None -> eq true false
  | Some toks ->
     let blocks = Rename.docstring_blocks src toks in
     eq 1 (List.length blocks);
     let (s, e) = List.hd blocks in
     eq "    let a: Index := 1;\n    let b: Index := a;\n" (String.sub src s (e - s))

let suite =
  "Rename" >::: [
      "an example in a docstring" >:: test_docstring_example;
      "the plan of a docstring example" >:: test_docstring_plan;
      "the examples of a docstring" >:: test_docstring_blocks;
      "a source" >:: test_text;
      "snake case" >:: test_snake;
      "collision" >:: test_collision;
      "a keyword is no name" >:: test_keyword;
      "a constant of a module root" >:: test_module_root;
      "a slot and a constant of one name" >:: test_shared_name;
      "the renamed text compiles" >:: test_shared_name_compiles;
      "a slot in a destructuring" >:: test_shared_name_destructuring;
      "a renamed slot does not compile" >:: test_shared_name_control
    ]

let _ = run_test_tt_main suite
