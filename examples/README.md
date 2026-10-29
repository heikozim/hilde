<!-- Modified by Heiko Zimmermann for Hilde, 2026. -->
# Hilde Examples

This directory contains examples of Hilde programs. To build all examples, run `make` in this directory. An executable called `main` will be built in each directory. To build an individual example, `cd` into that directory and run `make`.

## The examples of the language features and the standard library

Each of these directories shows one large feature of the language or one
module of the standard library in a small, complete programme.  Each has a
`README.md` that says what it shows, how to build it and what comes out.

| Directory | What it shows |
|---|---|
| `learn-contracts` | `requires` and `ensures` on an account, and a second programme that breaks a contract and stops |
| `learn-regex` | one pattern with `Standard.Regex` (RE2 syntax) and with `Standard.Pcre`; a Unicode class, case folding beyond ASCII and `Standard.UnicodeProperties` |
| `learn-jit` | `Standard.PcreJit`, a pattern of PCRE2 as machine code and one that falls back to the interpreter |
| `learn-match` | patterns in `case` two levels deep, alternatives with `\|` and ranges |
| `learn-tasks` | four tasks in a scope and a fifth with an arena of its own, the same output on every run |
| `sperli-sum` | the sum of a table of 3,000,000 rows over the ranks of a Sperli job, in Hilde and in Go |
| `sperli-bench` | latency and bandwidth between two ranks of a Sperli job over TLS 1.3 |
| `learn-template` | `Standard.Template`, templates in Jinja2 syntax |
| `learn-sqlite` | `Standard.Sqlite`, and `Standard.SqlCipher` with a fixed example key |
| `learn-poller` | a server and its client over a Unix socket, waited for with `Standard.Poller` |
| `learn-sandbox` | `pledge` and `unveil` on OpenBSD through `Standard.Sandbox` |
| `learn-graph` | `Standard.Graph`, the shortest ways through a small map |
| `learn-password` | `Standard.Password`, Argon2id hashes and an old bcrypt hash |
| `learn-map` | `Standard.Sort` and `Standard.Map`, a stock of fruit sorted, searched and counted |
| `learn-hashmap` | `Standard.HashMap` and `Standard.Hash`, the words of a sentence counted, one removed, one looked up |
| `learn-toml` | `Standard.Toml`, a server's configuration read and asked by paths, two refused with their line and column |
| `learn-encodings` | `Standard.Base64`, `Standard.Text`, `Standard.Utf8` and `Standard.Unicode`, bytes turned into text and back, code points counted, case changed |
| `learn-values` | `Standard.Box`, `Standard.Bounded`, `Standard.Equality` and `Standard.Failure`, small values and an instance of one's own |
| `learn-data` | `Standard.Csv`, `Standard.Decimal`, `Standard.Json` and `Standard.Ini`, one order in three formats and its sum in decimals |
| `learn-time` | `Standard.Time` and `Standard.Calendar`, dates in UTC and in a zone, RFC 3339, the hour summer time skips |
| `learn-files` | `Standard.Path`, `Standard.AtomicFile`, `Standard.FileHelpers` and `Standard.Watch`, files written, copied, measured and watched |
| `learn-archive` | `Standard.Gzip` and `Standard.Archive`, bytes packed and checked, a tar archive written and read within a budget |
| `learn-log` | `Standard.Log`, `Standard.Signal` and `Standard.Resource`, entries with levels and fields, a signal caught, the limits of the process |
| `learn-http` | `Standard.Http` and `Standard.Fcgi`, the header lines of a request and the records of FastCGI, in memory |
| `learn-network` | `Standard.Ip`, `Standard.Resolve`, `Standard.HttpClient`, `Standard.Tls`, `Standard.Smtp` and `Standard.Sftp`, as far as they work without a network |
| `learn-server` | `Standard.FcgiServer`, a FastCGI responder serving one request a task sent over a Unix socket, and a TCP listener of `Standard.File` |
| `learn-session` | `Standard.Cookie`, `Standard.Session` and `Standard.Csrf`, a session in SQLite made, loaded through its cookie, rotated at the login and removed at the logout, and the token of a form |
| `learn-context` | `Standard.Context`, a cancel at the top of a chain that stops two workers lent the context below it, and a deadline that ends a wait |
| `wasm-cli` | `hilde build --target=wasm`, the lines, words and bytes of the input, run in wasmtime and built as a binary from the same source |
| `wasm-browser` | a library for wasm32-wasi called from a page through `hilde-wasm.js`, which also runs in node |
| `wasm-cloudflare` | the same library in a worker of Cloudflare, answering a POST with JSON |
| `learn-pki` | `Standard.X509` and `Standard.Acme`, a CA, a server certificate from a request, a chain verified for its name and refused for another, and an ES256 signature as ACME sends it |
| `learn-signatures` | `Standard.Base32`, `Standard.Otp` and `Standard.Jws`, the secret of an authenticator app, its URI and a TOTP code checked in a window, tokens signed with ECDSA, RSA and ML-DSA, and the claims of an ID token |
| `learn-html` | `Standard.Html`, the tokens of HTML a visitor wrote, its text, the HTML a page may show of it under the basic policy and under a policy of its own, and escaping |
| `learn-search` | `Standard.Search`, full-text search with SQLite FTS5: pages indexed, ranked hits with escaped snippets, what a visitor types made words, a count and a page removed |
| `learn-formats` | `Standard.Qr`, `Standard.Png`, `Standard.Xml`, `Standard.Yaml` and `Standard.Ssh`: a QR code drawn as a PNG and read back, a feed read and a document type refused, a configuration as JSON and an anchor refused, a word quoted for a remote shell |
| `learn-crypto` | `Standard.Libcrypto`, a digest, an HMAC, a message sealed and opened, an Ed25519 signature, random bytes |
| `learn-testing` | `Standard.Testing`, the assertions a test file uses, in a plain programme |
| `learn-typeclass` | a type class of one's own, with an instance for two records and a generic instance for a pair |
| `learn-embed` | `@bytes`, a file put into the programme when it is compiled, and `@embed`, a C expression in an unsafe module |
| `learn-records` | an opaque type with an invariant, a write reference to a part with `&!(...)`, and the borrow statement |
| `learn-library` | the library mode, a Hilde module built as a static library and called from C |
| `learn-arguments` | `Standard.Arguments`, a command with subcommands declared, command lines parsed or refused, help and version |
| `learn-htmx` | `Standard.Htmx` with `Standard.Template`, a page for a browser and its list alone for htmx, both rendered from Jinja templates, and an answer with HX-Trigger |

`learn-linear`, `learn-borrow`, `learn-errors` and `learn-text` are the
programmes of `docs/learning-hilde.md`.

## How the checks hold them

`run-examples.sh` in the root of the repository builds every example and
compares what it prints with the text written there, on Linux and on
OpenBSD; where the two systems differ, the line holds both texts.  An
example's standard error must be empty, and after its run the directory
must hold what it held before.  The checks also compile every example to C
and count the C compiler's warnings (`scripts/count-warnings.sh`), and on
Linux run it under AddressSanitizer and valgrind
(`scripts/check-examples.py`).  No example reaches beyond the
machine it runs on or writes outside its own directory.

A new language feature or a new public module of the standard library comes
with an example here, in the same change, held to the same rules as the ones
there:

- One directory with the programme, a `Makefile` that builds it and is the
  one place its module list stands, with a target `c` that writes the same
  programme as C, and a target `clean` that removes all it built.
- A `README.md` in plain language: what it shows, how to build it, what
  comes out.
- A line in `run-examples.sh` with its exact output, on Linux and OpenBSD;
  its standard error is empty.
- Real, complete Hilde that compiles without a warning under the normal
  yardstick (`cc -std=c17 -Wall -Wextra`) and loses no memory under
  AddressSanitizer and valgrind.
- No network, no file outside its own directory, and nothing left behind
  after its run.
