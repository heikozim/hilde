<!-- Derived from Austral; modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>. -->
# hilde.vim

File detection and syntax highlighting for Hilde, for files ending in
`.hiq` (module body) and `.hih` (module interface).

Install by putting this directory on the runtime path, for example with
`set runtimepath+=/path/to/hilde/editor/hilde.vim` in the vimrc, or by
copying its `ftdetect`, `ftplugin` and `syntax` directories into
`~/.vim`.

The syntax groups follow the compiler's lexer, `lib/Lexer.mll`.

Neovim users can use the tree-sitter grammar in `editor/tree-sitter-hilde`
instead.
