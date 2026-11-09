# wasm-cli

The lines, words and bytes of the standard input, as `wc` counts them, built as a command module for
wasm32-wasi and run in wasmtime.  The same source is built as a binary and gives the same output: it
holds nothing for one target only.

## Build and run

From the root of the tree, with zig or with clang, lld and wasi-libc installed:

```sh
./hilde build --modules=standard/src:bindings/generated examples/wasm-cli/WordCount.hih,examples/wasm-cli/WordCount.hiq --entrypoint=Example.WordCount:main --target=wasm --output=wordcount.wasm
wasmtime run wordcount.wasm < examples/wasm-cli/input.txt
```

`HILDE_WASM_CC=clang` or `zig` chooses the compiler; without it hilde takes zig when it is there.

## What comes out

```text
3 13 80
```

`scripts/check-wasm-examples.sh` builds it with both compilers and as a binary and holds the output
against `expected-stdout.txt`.
