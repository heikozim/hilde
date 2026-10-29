# tree-sitter-hilde

A [tree-sitter](https://tree-sitter.github.io/) grammar for Hilde, for
module bodies (`.hiq`) and module interfaces (`.hih`).  Zed uses it through
the extension in `editor/zed`; Neovim, Helix and other editors that read
tree-sitter grammars can use it as well.

The grammar is written after the compiler's lexer and parser,
`lib/Lexer.mll` and `lib/Parser.mly`.  Where the compiler keeps two forms
apart that an editor need not tell apart, the grammar is more lenient: a
module interface and a module body share one set of declarations, and a
declaration may end in a semicolon or carry a body.  As in the compiler, a
binary operator joins two atomic expressions, and a longer chain needs
brackets.

## Building

`src/parser.c` is generated from `grammar.js` and committed, because Zed
builds the parser from the repository without running the generator.
After a change to `grammar.js`:

```sh
cd editor/tree-sitter-hilde
tree-sitter generate --abi 14
printf '\n' >> src/grammar.json
printf '\n' >> src/node-types.json
./parse-all.sh
```

The generator writes the two JSON files without a final line feed, which
the repository requires.  ABI 14 keeps the parser loadable by editors that
do not read ABI 15 yet.  The committed parser was made with
tree-sitter-cli 0.25.3 in the image node:22-bookworm.

`parse-all.sh` parses every `.hih` and `.hiq` file under `standard/src` and
`examples` and prints the files whose tree holds an ERROR or MISSING node,
and the counts.

Where the grammar is more lenient than the compiler, a wrong file parses
without error.  One example: the closing `end module body.` of a module
body may also be written `end module.`.

## Highlighting

`queries/highlights.scm` uses the capture names of `tree-sitter highlight`,
where the first pattern that matches a node wins.  Zed keeps its own copy in
`editor/zed/languages/hilde/highlights.scm`, ordered the other way round,
because there the last pattern wins.
