# wasm-browser

A library for wasm32-wasi, `TextStats.hiq`, called from a web page.  It exports two functions with
`pragma Foreign_Export`: `stats_words`, the words of a text, and `stats_upper`, which writes the text
with its letters a to z made capitals into a second buffer.  `hilde-wasm.js` loads the module, answers
the few calls of WASI it makes, and moves text in and out of its memory with `hilde_wasm_alloc` and
`hilde_wasm_free`.

## Build and run

```sh
./hilde build --target-type=wasm examples/wasm-browser/TextStats.hiq --output=examples/wasm-browser/text-stats.wasm
```

Serve `examples/wasm-browser` with any web server and open `index.html`; the page counts and changes
the text as it is typed.  The same loader runs in node:

```sh
node examples/wasm-browser/test.mjs examples/wasm-browser/text-stats.wasm
```

## What comes out

```text
5 20 [HILDE RUNS IN THE BROWSER.]
0 0 []
2 8 [  TWO   WORDS  ]
```

`scripts/check-wasm-examples.sh` builds the module with zig and with clang and holds the output of
`test.mjs` against `expected-stdout.txt`.
