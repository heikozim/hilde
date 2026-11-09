# Hilde for Zed

A Zed extension for Hilde: syntax highlighting, bracket matching,
indentation and the outline of a module, for `.hiq` and `.hih` files.  It
uses the tree-sitter grammar in `editor/tree-sitter-hilde`.

## Installing

In Zed, run the command `zed: install dev extension` and choose this
directory, `editor/zed`.  Zed clones the repository named under
`[grammars.hilde]` in `extension.toml` at the commit `rev` and builds the
parser from `editor/tree-sitter-hilde/src/parser.c`.

That commit has to be reachable from the repository URL.  Before it is
pushed, point the grammar at the local clone instead, for example:

```toml
[grammars.hilde]
repository = "file:///path/to/your/clone/of/hilde"
rev = "<the commit that holds the grammar>"
path = "editor/tree-sitter-hilde"
```

## Changing the grammar

After a change to the grammar, generate the parser as described in
`editor/tree-sitter-hilde/README.md`, commit it, and set `rev` to that
commit.  A rebase changes the commit, so `rev` is set again after one.

The pattern `hilde` in the top-level `.gitignore`, meant for the compiler
binary, also matches the directory `languages/hilde`; a new file there is
added with `git add -f`.

`languages/hilde/highlights.scm` is ordered for Zed, where the last
matching pattern wins; `editor/tree-sitter-hilde/queries/highlights.scm` is
ordered the other way round for `tree-sitter highlight`.
