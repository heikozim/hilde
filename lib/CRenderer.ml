(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Common
open Escape
open CRepr
open Util

type indentation = Indentation of int

let zero_indent = Indentation 0

let indent (Indentation i) =
  Indentation (i+4)

type line = Line of indentation * string

let render_line (Line (Indentation i, s)) =
  (String.make i ' ') ^ s

let desc_text (d: desc): string =
  match d with
  | Desc text ->
     "/*\n  " ^ text ^ "\n*/"
  | DescAt (text, line, file) ->
     (* The directive is at column zero on purpose: a
        preprocessor directive that is indented is legal C, and every reader
        of generated C expects to find these at the margin.  The path is
        exactly as the caller wrote it on the command line -- the compiler
        does not know what it would be relative to. *)
     "#line " ^ (string_of_int line) ^ " \"" ^ file ^ "\"" ^ "\n"
     ^ "/*\n  " ^ text ^ "\n*/"


(* A decimal constant with no suffix has a SIGNED type in C: int, long or
   long long, whichever fits first, and if none of them fits, the standard
   says the program is ill-formed and the compilers do as they please.
   clang says so out loud -- "integer literal is too large to be represented
   in a signed integer type, interpreting as unsigned"
   (-Wimplicitly-unsigned-literal) -- and gcc says nothing at all, which is
   the worse of the two answers.

   So a value above LLONG_MAX gets the `u' suffix here, where the value is
   known, rather than at the place the type is known: the monomorphised
   expression carries the digits and not the type (lib/CodeGen.ml,
   MIntConstant), and the cast that follows the literal cannot repair a
   literal that was already ill-formed.  The largest Nat64,
   18446744073709551615, is such a value. *)
let int_literal (digits: string): string =
  let signed_max = "9223372036854775807" in
  let longer = (String.length digits) > (String.length signed_max) in
  let same_length_and_larger =
    ((String.length digits) = (String.length signed_max))
    && ((String.compare digits signed_max) > 0)
  in
  (* Only plain decimal digits are compared this way; anything else -- a
     sign, a suffix already there, a hexadecimal form -- is left alone. *)
  let plain_decimal =
    (String.length digits) > 0
    && (String.for_all (fun c -> c >= '0' && c <= '9') digits)
  in
  if plain_decimal && (longer || same_length_and_larger) then
    digits ^ "u"
  else if digits = "-9223372036854775808" then
    (* The smallest Int64.  C has no negative literals: this is the
       negation of 9223372036854775808, which fits no signed type, and gcc
       says "integer constant is so large that it is unsigned", in a
       pattern's comparison as in a plain `let'.  The value written as a
       sum of two that fit is the same number, of type long long. *)
    "(-9223372036854775807 - 1)"
  else
    digits

(* https://en.cppreference.com/w/c/keyword *)
let is_c_keyword name = Str.string_match (Str.regexp "alignas\\|alignof\\|auto\\|bool\\|break\\|case\\|char\\|const\\|constexpr\\|continue\\|default\\|do\\|double\\|else\\|enum\\|extern\\|false\\|float\\|for\\|goto\\|if\\|inline\\|int\\|long\\|nullptr\\|register\\|restrict\\|return\\|short\\|signed\\|sizeof\\|static\\|static_assert\\|struct\\|switch\\|thread_local\\|true\\|typedef\\|typeof\\|typeof_unqual\\|union\\|unsigned\\|void\\|volatile\\|while\\|_Alignas\\|_Alignof\\|_Atomic\\|_BitInt\\|_Bool\\|_Complex\\|_Decimal128\\|_Decimal32\\|_Decimal64\\|_Generic\\|_Imaginary\\|_Noreturn\\|_Static_assert\\|_Thread_local\\|_Pragma\\|asm\\|fortran") name 0

let avoid_ckw (v: string): string =
  if is_c_keyword v then ("hilde_ckw_" ^ v) else v

(* The words of C as a list, for a name that must be one of them whole.
   is_c_keyword above matches at the start of a name, so it also takes
   longName for long; that is harmless for a variable, which the renderer
   names alone, but a slot may also be named by C written by hand, an
   embedded body or a foreign function, which must find it under its own
   name. *)
let c_keywords = ["alignas"; "alignof"; "auto"; "bool"; "break"; "case"; "char"; "const"; "constexpr"; "continue"; "default"; "do"; "double"; "else"; "enum"; "extern"; "false"; "float"; "for"; "goto"; "if"; "inline"; "int"; "long"; "nullptr"; "register"; "restrict"; "return"; "short"; "signed"; "sizeof"; "static"; "static_assert"; "struct"; "switch"; "thread_local"; "true"; "typedef"; "typeof"; "typeof_unqual"; "union"; "unsigned"; "void"; "volatile"; "while"; "_Alignas"; "_Alignof"; "_Atomic"; "_BitInt"; "_Bool"; "_Complex"; "_Decimal128"; "_Decimal32"; "_Decimal64"; "_Generic"; "_Imaginary"; "_Noreturn"; "_Static_assert"; "_Thread_local"; "_Pragma"; "asm"; "fortran"]

(* A slot's name as C sees it: a slot named like a word of C, long or
   default, gets the same prefix as a variable would, every other name
   stays as it is.  Every place that writes a slot's name goes through
   here, so the definition and the uses agree.  The same holds for the
   names below, which the C library defines as macros: errno in errno.h,
   which every generated file includes, and stdin, stdout and stderr in
   stdio.h on OpenBSD. *)
let c_library_macros = ["errno"; "stdin"; "stdout"; "stderr"]

let slot_name (n: string): string =
  if List.mem n c_keywords || List.mem n c_library_macros then ("hilde_ckw_" ^ n) else n

module StringSet = Set.Make(String)

let unions (ss: StringSet.t list): StringSet.t =
  List.fold_left StringSet.union StringSet.empty ss

(* --- Which names the rendered C READS -------------------------------------

   C17 has no way to mark a parameter as deliberately unused, so the code
   generator marks them itself: a name that is declared and never read gets a
   `(void)name;' next to its declaration, which every C compiler counts as a
   use.  For that the renderer has to know what it is about to write, and
   that is what the three functions below answer.

   The distinction between reading and writing is the one gcc draws between
   -Wunused-variable and -Wunused-but-set-variable: a bare variable on the
   left of an assignment is written, not read.  Anything else on the left --
   a field, an index, a dereference -- does read the thing it starts from.

   Over-marking is harmless: `(void)x;' on a name that is used costs a
   statement and no warning.  Under-marking leaves the warning standing.
   Where these functions cannot see (the raw C text of an @embed, which can
   only reach its arguments), they therefore err towards marking. *)
let rec expr_reads (expr: c_expr): StringSet.t =
  match expr with
  | CBool _ | CInt _ | CFloat _ | CString _ | CSizeOf _ ->
     StringSet.empty
  | CVar name ->
     StringSet.singleton (avoid_ckw name)
  | CFuncall (name, args) ->
     StringSet.add (avoid_ckw name) (unions (List.map expr_reads args))
  | CFptrCall (fn, _, _, args) ->
     unions (expr_reads fn :: List.map expr_reads args)
  | CCast (inner, _) | CNegation inner | CAddressOf inner | CDeref inner ->
     expr_reads inner
  | CArithmetic (_, l, r) | CComparison (_, l, r)
  | CConjunction (l, r) | CDisjunction (l, r) | CIndex (l, r) ->
     StringSet.union (expr_reads l) (expr_reads r)
  | CIfExpression (c, t, f) ->
     unions [expr_reads c; expr_reads t; expr_reads f]
  | CStructInitializer args ->
     unions (List.map (fun (_, v) -> expr_reads v) args)
  | CStructAccessor (inner, _) | CPointerStructAccessor (inner, _)
  | CPath (inner, _) ->
     expr_reads inner
  | CEmbed (_, _, args) ->
     unions (List.map expr_reads args)

let rec stmt_reads (stmt: c_stmt): StringSet.t =
  match stmt with
  | CLet (_, _, None) ->
     StringSet.empty
  | CLet (_, _, Some value) ->
     expr_reads value
  | CAssign (CVar _, value) ->
     expr_reads value
  | CAssign (lvalue, value) ->
     StringSet.union (expr_reads lvalue) (expr_reads value)
  | CDiscarding value ->
     expr_reads value
  | CIf (c, t, f) ->
     unions [expr_reads c; stmt_reads t; stmt_reads f]
  | CSwitch (value, cases) ->
     unions (expr_reads value
             :: List.map (fun (CSwitchCase (v, b)) ->
                    StringSet.union (expr_reads v) (stmt_reads b)) cases)
  | CIntSwitch (value, arms, other) ->
     unions (expr_reads value
             :: stmt_reads other
             :: List.map (fun (labels, b) ->
                    unions (stmt_reads b :: List.map expr_reads labels)) arms)
  | CWhile (c, b) ->
     StringSet.union (expr_reads c) (stmt_reads b)
  | CFor (v, final, b) ->
     StringSet.add (avoid_ckw v)
       (StringSet.union (expr_reads final) (stmt_reads b))
  | CReturn value ->
     expr_reads value
  | CBlock ss | CExplicitBlock ss ->
     unions (List.map stmt_reads ss)
  | CLocalFunctionDeclaration _ ->
     StringSet.empty

let rec stmt_declares (stmt: c_stmt): StringSet.t =
  match stmt with
  | CLet (name, _, _) ->
     StringSet.singleton (avoid_ckw name)
  | CIf (_, t, f) ->
     StringSet.union (stmt_declares t) (stmt_declares f)
  | CSwitch (_, cases) ->
     unions (List.map (fun (CSwitchCase (_, b)) -> stmt_declares b) cases)
  | CIntSwitch (_, arms, other) ->
     unions (stmt_declares other :: List.map (fun (_, b) -> stmt_declares b) arms)
  | CWhile (_, b) | CFor (_, _, b) ->
     stmt_declares b
  | CBlock ss | CExplicitBlock ss ->
     unions (List.map stmt_declares ss)
  | CAssign _ | CDiscarding _ | CReturn _ | CLocalFunctionDeclaration _ ->
     StringSet.empty

(* Whether the statement leaves its function through a `return' on every path
   this renderer can see.  It is deliberately conservative: a switch counts
   only when every case returns, because no `default' label is ever written,
   and everything it cannot decide counts as "may fall through".  Being wrong
   in that direction costs one dead call to hilde_unreachable; being wrong in
   the other direction would leave an indeterminate return value behind. *)
let rec definitely_returns (stmt: c_stmt): bool =
  match stmt with
  | CReturn _ ->
     true
  | CBlock ss | CExplicitBlock ss ->
     List.exists definitely_returns ss
  | CIf (_, t, f) ->
     definitely_returns t && definitely_returns f
  | CSwitch _ ->
     (* Never, however many of its cases return.  A rendered switch ends in
        a default that calls hilde_case_unreachable, which does not return;
        the switch is still counted here as one that may end, so that what
        the generator writes after it stays as it was.  Covering every
        enumerator is not exhaustiveness to C. *)
     false
  | CIntSwitch _ ->
     (* Counted as one that may end, as the switch over a tag is: each arm
        ends in a break, and what follows the switch stays as it was. *)
     false
  | CLet _ | CAssign _ | CDiscarding _ | CWhile _ | CFor _
  | CLocalFunctionDeclaration _ ->
     false

let rec render_unit (CUnit (name, decls)): string =
  let rd d =
    String.concat "\n" (List.map render_line (render_decl zero_indent d))
  in
  "/* --- BEGIN translation unit for module '" ^ name ^ "' --- */\n"
  ^ (String.concat "\n\n" (List.map rd decls))
  ^ "\n/* --- END translation unit for module '" ^ name ^ "' --- */\n"

and render_decl i d =
  match d with
  | CMacro (desc, name, value) ->
     [
       Line (i, desc_text desc);
       Line (i, "#define " ^ name ^ " " ^ (e value))
     ]
  | CConstantDefinition (desc, name, ty, value) ->
     [
       Line (i, desc_text desc);
       Line (i, (render_type ty) ^ " " ^ (avoid_ckw name) ^ " = " ^ (e value) ^ ";")
     ]
  | CByteArrayDefinition (desc, name, bytes) ->
     (* The bytes as numbers from 0 to 255, sixteen to a line.  The array
        is of unsigned char because char is signed on some targets and
        unsigned on others; the place that reads it casts. *)
     let n = String.length bytes in
     let row (start: int): string =
       let len = min 16 (n - start) in
       let one k =
         let b = Char.code bytes.[start + k] in
         string_of_int b
       in
       (String.concat ", " (List.init len one)) ^ (if start + len < n then "," else "")
     in
     List.concat [
         [Line (i, desc_text desc);
          Line (i, "static const unsigned char " ^ name ^ "[" ^ (string_of_int n) ^ "] = {")];
         List.init ((n + 15) / 16) (fun r -> Line (indent i, row (r * 16)));
         [Line (i, "};")]
       ]
  | CStructForwardDeclaration (desc, name) ->
     [
       Line (i, desc_text desc);
       Line (i, "struct " ^ (avoid_ckw name) ^ ";");
       Line (i, "typedef struct " ^ (avoid_ckw name) ^ " " ^ (avoid_ckw name) ^ ";")
     ]
  | CTypeDefinition (desc, name, def) ->
     [
       Line (i, desc_text desc);
       Line (i, "typedef " ^ (render_type def) ^ " " ^ (avoid_ckw name) ^ ";")
     ]
  | CStructDefinition (desc, record) ->
     [
       Line (i, desc_text desc);
       Line (i, (render_struct record) ^ ";")
     ]
  | CNamedStructDefinition (desc, name, slots) ->
     [
       Line (i, desc_text desc);
       Line (i, "typedef struct " ^ (avoid_ckw name) ^ " {" ^ (render_slots slots) ^ "} " ^ (avoid_ckw name) ^ ";")
     ]
  | CEnumDefinition (desc, name, cases) ->
     List.concat [
         [Line (i, desc_text desc)];
         [Line (i, "typedef enum {")];
         [Line (indent i, comma_sep (List.map (fun case -> case) cases))];
         [Line (i, "} " ^ (avoid_ckw name) ^ ";")];
       ]
  | CFunctionDeclaration (desc, name, params, rt, linkage) ->
     let s = (render_linkage linkage)
             ^ (render_type rt)
             ^ " "
             ^ (avoid_ckw name)
             ^ "("
             ^ (params_or_void (List.map (fun (CValueParam (n, t)) -> (render_type t) ^ " " ^ (avoid_ckw n)) params))
             ^ ");"
     in
     [
       Line (i, desc_text desc);
       Line (i, s)
     ]
  | CFunctionDefinition (desc, name, params, rt, body) ->
     let s = (render_type rt)
             ^ " "
             ^ (avoid_ckw name)
             ^ "("
             ^ (params_or_void (List.map (fun (CValueParam (n, t)) -> (render_type t) ^ " " ^ (avoid_ckw n)) params))
             ^ ") {"
     in
     let reads = stmt_reads body in
     let unused (n: string): bool = not (StringSet.mem n reads) in
     let unused_params =
       List.filter unused
         (List.map (fun (CValueParam (n, _)) -> avoid_ckw n) params)
     and unused_locals = StringSet.filter unused (stmt_declares body) in
     let tail =
       if (not (definitely_returns body)) && (render_type rt) <> "void" then
         [Line (indent i, "hilde_unreachable(\"" ^ (avoid_ckw name) ^ "\");")]
       else
         []
     in
     List.concat [
         [Line (i, desc_text desc)];
         [Line (i, s)];
         List.map (fun n -> Line (indent i, "(void)" ^ n ^ ";")) unused_params;
         render_stmt unused_locals (indent i) body;
         tail;
         [Line (i, "}")];
       ]

and render_linkage = function
  | LinkageInternal -> ""
  | LinkageExternal -> "extern "

(* `unused' carries the names this function declares and never reads; each of
   them gets a `(void)name;' next to its declaration.  It is threaded rather
   than recomputed per statement because the question is about the whole
   function body, not about the statement in hand. *)
and render_stmt (unused: StringSet.t) (i: indentation) (stmt: c_stmt): line list =
  match stmt with
  | CLet (name, ty, value) ->
     let name' = avoid_ckw name in
     let decl =
       match value with
       | (Some value) ->
          (render_type ty) ^ " " ^ name' ^ " = " ^ (e value) ^ ";"
       | None ->
          (render_type ty) ^ " " ^ name' ^ ";"
     in
     if StringSet.mem name' unused then
       [Line (i, decl); Line (i, "(void)" ^ name' ^ ";")]
     else
       [Line (i, decl)]
  | CAssign (lvalue, value) ->
     let s = (e lvalue) ^ " = " ^ (e value) ^ ";" in
     [Line (i, s)]
  | CDiscarding value ->
     render_discarded i value
  | CIf (c, t, f) ->
     List.concat [
         [Line (i, "if (" ^ (e c) ^ ") {")];
         render_stmt unused (indent i) t;
         [Line (i, "} else {")];
         render_stmt unused (indent i) f;
         [Line (i, "}")]
       ]
  | CSwitch (value, cases) ->
     (* A case of Hilde names every case of its union, so no other tag can
        arrive.  The default says so to the C compiler: hilde_case_unreachable
        does not return, and without it gcc 14 at -O1 took a variable set in
        every case for one that may be unset after the switch. *)
     List.concat [
         [Line (i, "switch (" ^ (e value) ^ ") {")];
         List.concat (List.map (render_switch_case unused (indent i)) cases);
         [Line (indent i, "default:");
          Line (indent (indent i), "hilde_case_unreachable();");
          Line (i, "}")]
       ]
  | CIntSwitch (value, arms, other) ->
     (* A pattern case over an integer whose patterns are literals and
        ranges.  No value is the label of two arms, and every arm ends in a
        break, so there is no fall-through; the last when of the case is
        the default, which the check of the case has shown to be reached
        by every value no arm names. *)
     let arm (labels, b) =
       List.concat [
           List.map (fun l -> Line (indent i, "case " ^ (e l) ^ ":")) labels;
           render_stmt unused (indent (indent i)) b;
           [Line (indent (indent i), "break;")]
         ]
     in
     List.concat [
         [Line (i, "switch (" ^ (e value) ^ ") {")];
         List.concat (List.map arm arms);
         [Line (indent i, "default:")];
         render_stmt unused (indent (indent i)) other;
         [Line (indent (indent i), "break;");
          Line (i, "}")]
       ]
  | CWhile (c, b) ->
     List.concat [
         [Line (i, "while (" ^ (e c) ^ ") {")];
         [Line (indent i, "HILDE_PREEMPT_POINT();")];
         render_stmt unused (indent i) b;
         [Line (i, "}")]
       ]
  | CFor (v, final, b) ->
     let s = "; "
             ^ (avoid_ckw v)
             ^ " <= "
             ^ (e final)
             ^ "; "
             ^ (avoid_ckw v)
             ^ "++"
     in
     List.concat [
         [Line (i, "for (" ^ s ^ ") {")];
         [Line (indent i, "HILDE_PREEMPT_POINT();")];
         render_stmt unused (indent i) b;
         [Line (i, "}")]
       ]
  | CReturn v ->
     [Line (i, "return " ^ (e v) ^ ";")]
  | CBlock ss ->
     List.concat (List.map (render_stmt unused i) ss)
  | CLocalFunctionDeclaration (name, params, rt, linkage) ->
     let s = (render_linkage linkage)
             ^ (render_type rt)
             ^ " "
             ^ name
             ^ "("
             ^ (params_or_void (List.map (fun (CValueParam (n, t)) -> (render_type t) ^ " " ^ n) params))
             ^ ");"
     in
     [
       Line (i, s)
     ]
  | CExplicitBlock ss ->
     let i' = indent i in
     List.concat [
         [Line (i, "{")];
         (List.concat (List.map (render_stmt unused i') ss));
         [Line (i, "}")];
       ]

(* A discarded expression is a statement, so the cast that gives it a type in
   value position has nobody left to give it to.  Writing the cast anyway is
   what clang reports as "expression result unused" and gcc as "statement with
   no effect"; the expression inside is what is meant to run, and that is what
   is written.
   A discarded bare VARIABLE has no effect either, and it is written as
   `(void)x;' rather than as `x;'.  That keeps it a READ of x -- so the
   declaration behind it does not become unused in turn -- while saying to
   the C compiler that the value is meant to be thrown away.  Written as a
   bare `x;' it was one line of -Wunused-value over the frame. *)
and render_discarded (i: indentation) (value: c_expr): line list =
  match value with
  | CCast (inner, _) ->
     render_discarded i inner
  | CEmbed (_, expr, args) ->
     [Line (i, (embed_body expr args) ^ ";")]
  | CVar name ->
     [Line (i, "(void)" ^ (avoid_ckw name) ^ ";")]
  | _ ->
     [Line (i, (e value) ^ ";")]

and render_switch_case unused i (CSwitchCase (value, b)) =
  List.concat [
      [Line (i, "case " ^ (e value) ^ ":")];
      render_stmt unused (indent i) b;
      [Line (indent i, "break;")]
    ]

and render_type = function
  | CNamedType n ->
     n
  | CPointer t ->
     (render_type t) ^ "*"
  | CStructType s ->
     render_struct s
  | CUnionType slots ->
     "union "
     ^ "{ "
     ^ (render_slots slots)
     ^ "}"

and render_struct (CStruct (name, slots)) =
  let name' = Option.value name ~default:"" in
  "struct "
  ^ name'
  ^ " {"
  ^ (render_slots slots)
  ^ "}"

(* The members of a struct or union.  C17 has no struct without members,
   so a case of a union that carries no slots gets one byte nobody reads;
   gcc and clang accept the empty struct as an extension and say so under
   -Wpedantic. *)
and render_slots (slots: c_slot list): string =
  match slots with
  | [] -> "char hilde_empty;"
  | _ -> String.concat "" (List.map (fun (CSlot (n, t)) -> (render_type t) ^ " " ^ (slot_name n) ^ ";") slots)

and render_expr = function
  | (CBool b) -> render_bool b
  | (CInt i) -> int_literal i
  | (CFloat f) -> f
  | (CString s) -> "\"" ^ (unescape_string s) ^ "\""
  | (CVar s) -> (avoid_ckw s)
  | (CFuncall (n, a)) ->
     (avoid_ckw n) ^ (paren (comma_sep (List.map e a)))
  | CFptrCall (expr, rt, argtys, args) ->
     let rt: string = render_type rt
     and argtys: string = params_or_void (List.map render_type argtys)
     and expr: string = render_expr expr
     and args: string = String.concat ", " (List.map render_expr args)
     in
     (* An expression ends in no semicolon: the call may stand inside
        another, as an argument, and a semicolon there would not compile. *)
     ("((" ^ rt ^ "(*)(" ^ argtys ^ "))(" ^ expr ^ "))(" ^ args ^ ")")
  | (CCast (e, t)) ->
     let e' = render_expr e
     and t' = render_type t in
     paren ((paren t') ^ " " ^ e')
  | (CArithmetic (op, l, r)) ->
     paren ((e l) ^ " " ^ render_arith op ^ " " ^ (e r))
  | (CComparison (op, l, r)) ->
     paren ((e l) ^ " " ^ (render_comp op) ^ " " ^ (e r))
  | (CConjunction (l, r)) ->
     paren ((e l) ^ " && " ^ (e r))
  | (CDisjunction (l, r)) ->
     paren ((e l) ^ " || " ^ (e r))
  | (CNegation exp) ->
     "!" ^ (paren (e exp))
  | (CIfExpression (c, t, f)) ->
     paren ((e c) ^ " ? " ^ (e t) ^ " : " ^ (e f))
  | (CStructInitializer []) ->
     (* The value of a struct without slots, which render_slots gives one
        byte: an empty initializer is C23, not C17. *)
     "{ 0 }"
  | (CStructInitializer args) ->
     "{ " ^ (comma_sep (List.map (fun (n, v) -> "." ^ (slot_name n) ^ " = " ^ (e v)) args)) ^ " }"
  | (CStructAccessor (v, n)) ->
     (paren (e v)) ^ "." ^ (slot_name n)
  | (CPointerStructAccessor (v, n)) ->
     (paren (e v)) ^ "->" ^ (slot_name n)
  | CIndex (arr, idx) ->
     (e arr) ^ "[" ^ (e idx) ^ "]"
  | CAddressOf exp ->
     "&(" ^ (e exp) ^ ")"
  | CPath (head, elems) ->
     let f (elem: c_path_elem): string =
       match elem with
       | CPathSlot name -> "." ^ (slot_name name)
       | CPathPointer name -> "->" ^ (slot_name name)
     in
     (render_expr head) ^ (String.concat "" (List.map f elems))
  | CEmbed (Some ((CNamedType "hilde_bool_t") as ty), expr, args) ->
     (* A Bool is the byte 0 or 1.  A cast would keep 2 and turn 256 into 0,
        so any other value of the C text is compared with zero first. *)
     "((" ^ (render_type ty) ^ ")((" ^ (embed_body expr args) ^ ") != 0))"
  | CEmbed (Some ty, expr, args) ->
     "((" ^ (render_type ty) ^ ")(" ^ (embed_body expr args) ^ "))"
  | CEmbed (None, expr, args) ->
     "(" ^ (embed_body expr args) ^ ")"
  | CDeref expr ->
     "*" ^ (e expr)
  | CSizeOf ty ->
     "sizeof(" ^ (render_type ty) ^ ")"

(* The body of an embed, with the arguments substituted and without the cast
   the value position needs.  It is its own function because the discarding
   statement writes the body alone. *)
and embed_body (expr: string) (args: c_expr list): string =
  let strs = List.map render_expr args in
  (* the `expr` has a format like "derp $1 $2", so iterate over the list of
     arg swith an index, and replace the corresponding dollar sign marker if
     any *)
  let replace_index (text: string) (idx: int) (replacement: string): string =
    let marker = "$" ^ (string_of_int idx) in
    search_replace {
        text = text;
        search = marker;
        replacement = replacement
      }
  in
  let rec replace_all (text: string) (strs: string list) (idx: int): string =
    match strs with
    | first::rest ->
       let text' = replace_index text idx first in
       replace_all text' rest (idx + 1)
    | [] ->
       text
  in
  replace_all expr strs 1

and e expr = render_expr expr

and render_bool = function
  | false -> "false"
  | true -> "true"

and render_arith = function
  | Add -> "+"
  | Subtract -> "-"
  | Multiply -> "*"
  | Divide -> "/"

and render_comp = function
  | Equal -> "=="
  | NotEqual -> "!="
  | LessThan -> "<"
  | LessThanOrEqual -> "<="
  | GreaterThan -> ">"
  | GreaterThanOrEqual -> ">="

and paren s =
  "(" ^ s ^ ")"

and comma_sep ss =
  String.concat ", " ss

(* The parameter list of a function or of a function pointer type.  An
   empty list is written void: in C17 empty parentheses declare a function
   without a prototype, which -Wstrict-prototypes reports, and whose calls
   the compiler does not check. *)
and params_or_void ss =
  match ss with
  | [] -> "void"
  | _ -> comma_sep ss
