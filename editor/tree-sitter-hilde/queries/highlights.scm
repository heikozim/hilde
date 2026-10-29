;
; Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
; See LICENSE file for details.
;
; SPDX-FileCopyrightText: 2026 Heiko Zimmermann
; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
;

(comment) @comment
(docstring) @comment.doc

(string) @string
(triple_string) @string
(character) @character
(integer) @number
(float) @number
(boolean) @boolean
(nil) @constant.builtin

[
  "module"
  "body"
  "is"
  "end"
  "import"
  "as"
  "constant"
  "type"
  "function"
  "generic"
  "record"
  "union"
  "case"
  "of"
  "when"
  "typeclass"
  "instance"
  "method"
  "let"
  "var"
  "borrow"
  "pragma"
  "sizeof"
] @keyword

[
  "if"
  "then"
  "else"
  "else if"
  "while"
  "for"
  "do"
  "from"
  "to"
] @keyword.control

[
  "return"
  "skip"
  "raise"
] @keyword.return

[
  "requires"
  "ensures"
  "invariant"
  "raises"
] @keyword.contract

[
  "@embed"
  "@bytes"
  "@template"
  "@query"
  "@execute"
] @keyword.directive
(migrations_expression) @keyword.directive

[
  "and"
  "or"
  "not"
] @keyword.operator

[
  "="
  "/="
  "<"
  "<="
  ">"
  ">="
  "+"
  "-"
  "*"
  "/"
  ":="
  "=>"
  "->"
  "!"
  "?"
  "&"
  "&!"
  "&~"
  "&("
  "&!("
  ".."
  "|"
] @operator

[ "(" ")" "[" "]" "{" "}" ] @punctuation.bracket

[ ";" "," "." ":" ] @punctuation.delimiter

(universe) @type.builtin
[ "Span" "Span!" ] @type.builtin

(type_name (identifier) @type)
(generic_type name: (identifier) @type)
(type_parameter name: (identifier) @type)
(record_declaration name: (identifier) @type)
(union_declaration name: (identifier) @type)
(type_declaration name: (identifier) @type)
(typeclass_declaration name: (identifier) @type)
(instance_declaration name: (identifier) @type)
(union_case name: (identifier) @constructor)
(variant_pattern name: (identifier) @constructor)
(when_clause name: (identifier) @constructor)
(raises_clause (identifier) @type)
(raise_statement kind: (identifier) @type)

(module_name (identifier) @module)

(function_declaration name: (identifier) @function)
(method_declaration name: (identifier) @function.method)
(call function: (identifier) @function.call)

(pragma name: (identifier) @attribute)

(constant_declaration name: (identifier) @constant)

(parameter name: (identifier) @variable.parameter)
(named_argument name: (identifier) @variable.parameter)

(slot name: (identifier) @property)
(field_access field: (identifier) @property)
(pointer_access field: (identifier) @property)

(wildcard_pattern) @variable.builtin

(identifier) @variable
