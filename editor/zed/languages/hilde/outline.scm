;
; Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
; See LICENSE file for details.
;
; SPDX-FileCopyrightText: 2026 Heiko Zimmermann
; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
;

(module_declaration
  "module" @context
  "body"? @context
  name: (module_name) @name) @item

(constant_declaration "constant" @context name: (identifier) @name) @item
(type_declaration "type" @context name: (identifier) @name) @item
(record_declaration "record" @context name: (identifier) @name) @item
(union_declaration "union" @context name: (identifier) @name) @item
(union_case "case" @context name: (identifier) @name) @item
(function_declaration "function" @context name: (identifier) @name) @item
(typeclass_declaration "typeclass" @context name: (identifier) @name) @item
(instance_declaration "instance" @context name: (identifier) @name) @item
(method_declaration "method" @context name: (identifier) @name) @item
