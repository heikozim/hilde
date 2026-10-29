# wasm-cloudflare

A worker of Cloudflare that answers a POST with the words of its text and the text in capitals, as
JSON, through the library of `../wasm-browser/TextStats.hiq`.  At most 65536 bytes are taken; every
other method is refused with 405.

## Build and deploy

```sh
./hilde build --target-type=wasm examples/wasm-browser/TextStats.hiq --output=examples/wasm-cloudflare/text-stats.wasm
cd examples/wasm-cloudflare && wrangler deploy
```

`worker.mjs` imports the module as wrangler bundles it and answers through `handler.mjs`, which node
runs as well:

```sh
node examples/wasm-cloudflare/test.mjs examples/wasm-cloudflare/text-stats.wasm
```

## What comes out

```text
200 {"words":4,"upper":"HILDE AT THE EDGE"}
405 POST the text
413 at most 65536 bytes
```

`scripts/check-wasm-examples.sh` holds the output of `test.mjs` against `expected-stdout.txt`, with
the module built by zig and by clang.  The deployment itself is not part of the checks.
