<!-- Modified by Heiko Zimmermann for Hilde, 2026. -->
# Change Log

All notable changes to the "hilde" extension will be documented in this file.

## 1.1.0

- The grammar follows the compiler's lexer: var, requires, ensures,
  invariant, raises, raise, the operators ?, &~, &(, &!(, .. and |, the
  types Span and Span!, and the directives @bytes, @template, @query,
  @execute and @migrations.
- The grammar marks tokens and no longer tracks blocks, so a construct it
  does not know cannot spoil the colours of the rest of the file.
- Lines are indented after is, then, do, else and of, and outdented at end
  and else.
- Snippets for contracts, the case with patterns and the module header.

## 1.0.0

- Initial release.
