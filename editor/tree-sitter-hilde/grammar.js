//
// Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE file for details.
//
// SPDX-FileCopyrightText: 2026 Heiko Zimmermann
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Tree-sitter grammar for Hilde, written after lib/Lexer.mll and
// lib/Parser.mly.  It follows the compiler's grammar where an editor
// needs the structure, and is more lenient where that keeps the grammar
// small: a module interface and a module body share one set of
// declarations, and a declaration may end in a semicolon or carry a body.

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const commaSep = (rule) => optional(commaSep1(rule));
const commaSep1 = (rule) => seq(rule, repeat(seq(',', rule)));

const IDENTIFIER = /[a-zA-Z][a-zA-Z0-9_]*/;

module.exports = grammar({
  name: 'hilde',

  word: ($) => $.identifier,

  extras: ($) => [/\s/, $.comment],

  conflicts: ($) => [
    // A docstring after the slots of a union case documents the next slot
    // or the next case; the token after it decides.
    [$.union_case],
  ],

  rules: {
    source_file: ($) => seq(
      optional(alias($.triple_string, $.docstring)),
      repeat($.pragma),
      repeat($.import_declaration),
      $.module_declaration,
    ),

    // Modules and imports

    module_declaration: ($) => seq(
      'module',
      optional('body'),
      field('name', $.module_name),
      'is',
      repeat($._declaration),
      'end',
      'module',
      optional('body'),
      '.',
    ),

    module_name: ($) => seq($.identifier, repeat(seq('.', $.identifier))),

    import_declaration: ($) => seq(
      'import',
      field('module', $.module_name),
      '(',
      commaSep($.import_symbol),
      ')',
      ';',
    ),

    import_symbol: ($) => seq(
      field('name', $.identifier),
      optional(seq('as', field('alias', $.identifier))),
    ),

    pragma: ($) => seq(
      'pragma',
      field('name', $.identifier),
      optional(field('arguments', $.arguments)),
      ';',
    ),

    // Declarations

    _declaration: ($) => seq(
      optional(alias($.triple_string, $.docstring)),
      repeat($.pragma),
      choice(
        $.constant_declaration,
        $.type_declaration,
        $.record_declaration,
        $.union_declaration,
        $.function_declaration,
        $.typeclass_declaration,
        $.instance_declaration,
      ),
    ),

    constant_declaration: ($) => seq(
      'constant',
      field('name', $.identifier),
      ':',
      field('type', $._type),
      optional(seq(':=', field('value', $._expression))),
      ';',
    ),

    type_declaration: ($) => seq(
      'type',
      field('name', $.identifier),
      optional($.type_parameters),
      ':',
      $.universe,
      ';',
    ),

    record_declaration: ($) => seq(
      'record',
      field('name', $.identifier),
      optional($.type_parameters),
      ':',
      $.universe,
      'is',
      repeat(choice($.slot, $.invariant_clause)),
      'end',
      ';',
    ),

    slot: ($) => seq(
      optional(alias($.triple_string, $.docstring)),
      field('name', $.identifier),
      ':',
      field('type', $._type),
      ';',
    ),

    invariant_clause: ($) => seq('invariant', $._expression, ';'),

    union_declaration: ($) => seq(
      'union',
      field('name', $.identifier),
      optional($.type_parameters),
      ':',
      $.universe,
      'is',
      repeat(choice(alias($.triple_string, $.docstring), $.union_case)),
      'end',
      ';',
    ),

    union_case: ($) => seq(
      'case',
      field('name', $.identifier),
      choice(
        ';',
        seq('is', repeat($.slot)),
      ),
    ),

    function_declaration: ($) => seq(
      optional($.generic_clause),
      'function',
      field('name', $.identifier),
      field('parameters', $.parameters),
      ':',
      field('return_type', $._type),
      repeat($._contract_clause),
      choice(
        ';',
        seq('is', optional(field('body', $.block)), 'end', ';'),
      ),
    ),

    parameters: ($) => seq('(', commaSep($.parameter), ')'),

    parameter: ($) => seq(
      field('name', $.identifier),
      ':',
      field('type', $._type),
    ),

    _contract_clause: ($) => choice(
      $.requires_clause,
      $.ensures_clause,
      $.raises_clause,
    ),

    requires_clause: ($) => seq('requires', $._expression),

    ensures_clause: ($) => seq('ensures', $._expression),

    raises_clause: ($) => seq('raises', commaSep1($.identifier)),

    generic_clause: ($) => seq('generic', $.type_parameters),

    type_parameters: ($) => seq('[', commaSep($.type_parameter), ']'),

    type_parameter: ($) => seq(
      field('name', $.identifier),
      ':',
      $.universe,
      optional(seq('(', commaSep($.identifier), ')')),
    ),

    universe: (_) => choice('Free', 'Linear', 'Type', 'Region'),

    typeclass_declaration: ($) => seq(
      'typeclass',
      field('name', $.identifier),
      '(',
      $.type_parameter,
      ')',
      'is',
      repeat($.method_declaration),
      'end',
      ';',
    ),

    instance_declaration: ($) => seq(
      optional($.generic_clause),
      'instance',
      field('name', $.identifier),
      '(',
      field('type', $._type),
      ')',
      choice(
        ';',
        seq('is', repeat($.method_declaration), 'end', ';'),
      ),
    ),

    method_declaration: ($) => seq(
      optional(alias($.triple_string, $.docstring)),
      optional($.generic_clause),
      'method',
      field('name', $.identifier),
      field('parameters', $.parameters),
      ':',
      field('return_type', $._type),
      repeat($.raises_clause),
      choice(
        ';',
        seq('is', field('body', $.block), 'end', ';'),
      ),
    ),

    // Types

    _type: ($) => choice(
      $.type_name,
      $.generic_type,
      $.reference_type,
      $.span_type,
    ),

    type_name: ($) => $.identifier,

    generic_type: ($) => seq(
      field('name', $.identifier),
      '[',
      commaSep($._type),
      ']',
    ),

    reference_type: ($) => seq(
      choice('&', '&!'),
      '[',
      field('type', $._type),
      ',',
      field('region', $._type),
      ']',
    ),

    span_type: ($) => seq(
      choice('Span', 'Span!'),
      '[',
      field('type', $._type),
      ',',
      field('region', $._type),
      ']',
    ),

    // Statements

    block: ($) => repeat1($._statement),

    _statement: ($) => choice(
      $.if_statement,
      $.let_statement,
      $.destructure_statement,
      $.assignment_statement,
      $.expression_statement,
      $.case_statement,
      $.while_statement,
      $.for_statement,
      $.borrow_statement,
      $.return_statement,
      $.raise_statement,
      $.template_statement,
      $.query_statement,
      $.skip_statement,
    ),

    if_statement: ($) => seq(
      'if',
      field('condition', $._expression),
      'then',
      field('consequence', $.block),
      repeat($.else_if_clause),
      optional($.else_clause),
      'end',
      'if',
      ';',
    ),

    // The compiler's lexer reads else and if as one token when only blanks
    // stand between them; across a line break they are an else whose block
    // starts with an if.
    else_if_clause: ($) => seq(
      alias(token(seq('else', /[ \t]+/, 'if')), 'else if'),
      field('condition', $._expression),
      'then',
      field('consequence', $.block),
    ),

    else_clause: ($) => seq('else', $.block),

    let_statement: ($) => seq(
      choice('let', 'var'),
      field('name', $.identifier),
      ':',
      field('type', $._type),
      ':=',
      field('value', $._expression),
      ';',
    ),

    destructure_statement: ($) => seq(
      choice('let', 'var'),
      '{',
      commaSep($.binding),
      '}',
      ':=',
      field('value', $._expression),
      ';',
    ),

    binding: ($) => seq(
      field('name', $.identifier),
      optional(seq('as', field('rename', $.identifier))),
      ':',
      field('type', $._type),
    ),

    assignment_statement: ($) => seq(
      field('left', choice($.identifier, $.path)),
      ':=',
      field('right', $._expression),
      ';',
    ),

    expression_statement: ($) => seq($._expression, ';'),

    case_statement: ($) => seq(
      'case',
      field('value', $._expression),
      'of',
      repeat($.when_clause),
      'end',
      'case',
      ';',
    ),

    when_clause: ($) => seq(
      'when',
      choice(
        seq(
          field('name', $.identifier),
          '(',
          commaSep($.binding),
          ')',
        ),
        seq($._pattern, repeat(seq('|', $._pattern))),
      ),
      'do',
      field('body', $.block),
    ),

    while_statement: ($) => seq(
      'while',
      field('condition', $._expression),
      'do',
      field('body', $.block),
      'end',
      'while',
      ';',
    ),

    for_statement: ($) => seq(
      'for',
      field('variable', $.identifier),
      'from',
      field('start', $._expression),
      'to',
      field('end', $._expression),
      'do',
      field('body', $.block),
      'end',
      'for',
      ';',
    ),

    borrow_statement: ($) => seq(
      'borrow',
      field('name', $.identifier),
      ':',
      choice('&', '&!'),
      '[',
      field('type', $._type),
      ',',
      field('region', $.identifier),
      ']',
      ':=',
      choice('&', '&!', '&~'),
      field('original', $.identifier),
      'do',
      field('body', $.block),
      'end',
      'borrow',
      ';',
    ),

    return_statement: ($) => seq('return', $._expression, ';'),

    raise_statement: ($) => seq('raise', field('kind', $.identifier), ';'),

    skip_statement: (_) => seq('skip', ';'),

    template_statement: ($) => seq(
      '@template',
      '(',
      field('path', $.string),
      ',',
      field('data', $.identifier),
      ',',
      field('output', $.identifier),
      optional(seq(',', field('options', $.string))),
      ')',
      ';',
    ),

    query_statement: ($) => seq(
      '@query',
      '(',
      $._query_target,
      ',',
      field('sql', $.string),
      repeat(seq(',', $._expression)),
      ')',
      'for',
      field('row', $.identifier),
      ':',
      field('row_type', $._type),
      'do',
      field('body', $.block),
      'else',
      field('error', $.identifier),
      'do',
      field('handler', $.block),
      'end',
      'for',
      ';',
    ),

    _query_target: ($) => seq(choice('&!', '&~'), $.identifier),

    // Patterns

    _pattern: ($) => choice(
      $.wildcard_pattern,
      $.boolean,
      $._integer_literal,
      $.range_pattern,
      $.float,
      $.string,
      $.triple_string,
      $.identifier,
      $.variant_pattern,
    ),

    wildcard_pattern: (_) => '_',

    range_pattern: ($) => seq(
      field('low', $._integer_literal),
      '..',
      field('high', $._integer_literal),
    ),

    variant_pattern: ($) => seq(
      field('name', $.identifier),
      '(',
      commaSep1($._pattern),
      ')',
    ),

    // Expressions.  As in the compiler, a binary operator joins two atomic
    // expressions, and longer chains need brackets.

    _expression: ($) => choice(
      $._atomic_expression,
      $.binary_expression,
      $.unary_expression,
      $.if_expression,
      $.cast_expression,
    ),

    _atomic_expression: ($) => choice(
      $.nil,
      $.boolean,
      $._integer_literal,
      $.float,
      $.string,
      $.triple_string,
      $.path,
      $.ref_path,
      $.identifier,
      $.call,
      $.parenthesized_expression,
      $.embed_expression,
      $.bytes_expression,
      $.execute_expression,
      $.migrations_expression,
      $.sizeof_expression,
      $.borrow_expression,
      $.deref_expression,
      $.try_expression,
    ),

    nil: (_) => 'nil',

    boolean: (_) => choice('true', 'false'),

    _integer_literal: ($) => choice($.integer, $.character),

    // The sign is part of the constant, as in the compiler's lexer.
    integer: (_) => token(choice(
      /[+-]?[0-9][0-9']*/,
      /#x[0-9a-fA-F][0-9a-fA-F']*/,
      /#b[01][01']*/,
      /#o[0-7][0-7']*/,
    )),

    // A digit after the point is required, so that 0..127 reads as a range.
    float: (_) => token(
      /[+-]?[0-9][0-9']*\.[0-9][0-9']*([eE][+-]?[0-9][0-9']*)?/,
    ),

    character: (_) => token(/'([ -\[\]-~]|\\[nrt\\])'/),

    string: (_) => token(seq('"', repeat(choice(/[^"\\]/, /\\(.|\r?\n)/)), '"')),

    triple_string: (_) => token(seq(
      '"""',
      repeat(choice(/[^"\\]/, /\\"""/, '\\', /"[^"]/, /""[^"]/)),
      '"""',
    )),

    path: ($) => seq(
      field('root', $.identifier),
      repeat1(choice($.field_access, $.pointer_access, $.index)),
    ),

    field_access: ($) => seq('.', field('field', $.identifier)),

    pointer_access: ($) => seq('->', field('field', $.identifier)),

    index: ($) => seq('[', $._expression, ']'),

    ref_path: ($) => seq(choice('&(', '&!('), $.path, ')'),

    call: ($) => seq(
      field('function', $.identifier),
      field('arguments', $.arguments),
    ),

    arguments: ($) => seq(
      '(',
      optional(choice(
        commaSep1($._expression),
        commaSep1($.named_argument),
      )),
      ')',
    ),

    named_argument: ($) => seq(
      field('name', $.identifier),
      '=>',
      field('value', $._expression),
    ),

    parenthesized_expression: ($) => seq('(', $._expression, ')'),

    embed_expression: ($) => seq(
      '@embed',
      '(',
      field('type', $._type),
      ',',
      field('code', $.string),
      repeat(seq(',', $._expression)),
      ')',
    ),

    bytes_expression: ($) => seq('@bytes', '(', field('path', $.string), ')'),

    execute_expression: ($) => seq(
      '@execute',
      '(',
      $._query_target,
      ',',
      field('sql', $.string),
      repeat(seq(',', $._expression)),
      ')',
    ),

    migrations_expression: (_) => '@migrations',

    sizeof_expression: ($) => seq('sizeof', '(', $._type, ')'),

    borrow_expression: ($) => seq(choice('&', '&!', '&~'), $.identifier),

    // The postfix operator binds tighter than the prefix one: !e? is !(e?).
    deref_expression: ($) => prec(1, seq('!', $._atomic_expression)),

    try_expression: ($) => prec(2, seq($._atomic_expression, '?')),

    binary_expression: ($) => seq(
      field('left', $._atomic_expression),
      field('operator', choice(
        '=', '/=', '<', '<=', '>', '>=',
        'and', 'or',
        '+', '-', '*', '/',
      )),
      field('right', $._atomic_expression),
    ),

    unary_expression: ($) => seq(
      field('operator', choice('not', '-')),
      field('operand', $._atomic_expression),
    ),

    if_expression: ($) => seq(
      'if',
      field('condition', $._expression),
      'then',
      field('consequence', $._expression),
      'else',
      field('alternative', $._expression),
    ),

    cast_expression: ($) => seq(
      field('value', $._atomic_expression),
      ':',
      field('type', $._type),
    ),

    identifier: (_) => IDENTIFIER,

    comment: (_) => token(seq('--', /[^\r\n]*/)),
  },
});
