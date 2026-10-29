;
; Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
; See LICENSE file for details.
;
; SPDX-FileCopyrightText: 2026 Heiko Zimmermann
; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
;
; In Zed a later pattern wins over an earlier one, so the general
; patterns come first.  The capture names are the ones Zed's themes know.

(identifier) @variable

(parameter name: (identifier) @variable.parameter)
(named_argument name: (identifier) @variable.parameter)
(wildcard_pattern) @variable.special

(slot name: (identifier) @property)
(field_access field: (identifier) @property)
(pointer_access field: (identifier) @property)

(constant_declaration name: (identifier) @constant)

(pragma name: (identifier) @attribute)

(function_declaration name: (identifier) @function)
(method_declaration name: (identifier) @function)
(call function: (identifier) @function)

(module_name (identifier) @type)

(type_name (identifier) @type)
(generic_type name: (identifier) @type)
(type_parameter name: (identifier) @type)
(record_declaration name: (identifier) @type)
(union_declaration name: (identifier) @type)
(type_declaration name: (identifier) @type)
(typeclass_declaration name: (identifier) @type)
(instance_declaration name: (identifier) @type)
(raises_clause (identifier) @type)
(raise_statement kind: (identifier) @type)
(union_case name: (identifier) @variant)
(variant_pattern name: (identifier) @variant)
(when_clause name: (identifier) @variant)

(universe) @type
[ "Span" "Span!" ] @type

[ ";" "," "." ":" ] @punctuation.delimiter

[ "(" ")" "[" "]" "{" "}" ] @punctuation.bracket

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
  "if"
  "then"
  "else"
  "else if"
  "while"
  "for"
  "do"
  "from"
  "to"
  "return"
  "skip"
  "raise"
  "requires"
  "ensures"
  "invariant"
  "raises"
  "and"
  "or"
  "not"
] @keyword

[
  "@embed"
  "@bytes"
  "@template"
  "@query"
  "@execute"
] @preproc
(migrations_expression) @preproc

(nil) @constant
(boolean) @boolean
(integer) @number
(float) @number
(character) @string.special
(string) @string
(triple_string) @string

(docstring) @comment.doc
(comment) @comment
