;
; Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
; See LICENSE file for details.
;
; SPDX-FileCopyrightText: 2026 Heiko Zimmermann
; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
;
; A construct that ends with end is indented up to its end.

(module_declaration "end" @end) @indent
(record_declaration "end" @end) @indent
(union_declaration "end" @end) @indent
(function_declaration "end" @end) @indent
(typeclass_declaration "end" @end) @indent
(instance_declaration "end" @end) @indent
(method_declaration "end" @end) @indent
(if_statement "end" @end) @indent
(case_statement "end" @end) @indent
(while_statement "end" @end) @indent
(for_statement "end" @end) @indent
(borrow_statement "end" @end) @indent
(query_statement "end" @end) @indent
(when_clause) @indent

(_ "(" ")" @end) @indent
(_ "[" "]" @end) @indent
(_ "{" "}" @end) @indent
