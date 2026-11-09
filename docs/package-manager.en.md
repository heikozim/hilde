# The package manager

A Hilde package is a directory with a manifest, `hilde.toml`, its modules below `src`, and the packages it
needs below `vendor/`, checked in. The package commands are carried out by `hilde-pkg`, which lies beside the
compiler; the compiler hands them to it, so they are all called as `hilde <command>`. Only `get` and `update`
use the network, through git, and `rust --vendor`, through cargo. Every command takes `--json` and then prints one object:

```json
{"command": "verify", "ok": true, "count": 2, "summary": "...", "problems": []}
```

A problem has a code from H1501 to H1543 (docs/errors.en.md, section 13), a message and a suggestion. The
exit status is 0 when the command did what it was asked, 1 for a problem, 2 for a command line it does not
take.

## A new package

```sh
hilde new Acme.Json --git --packaging
hilde new module Acme.Json.Parse
```

`hilde new` writes `hilde.toml`, an empty `hilde.sum`, a changelog in Debian's form, the ISC licence with the
author git knows, `README.md`, `AGENTS.md` with the commands and rules a coding agent needs, `llms.txt`
that points a model to them and to the language, `.gitignore` and `src/Json.hih`, `src/Json.hiq` and `src/Json.test.hiq`, each
source with an SPDX header. `--bin` makes a programme with a `main` function, `--git` a git repository,
`--packaging` the scripts `packaging/make_debian_package`, `make_openbsd_package`, `make_freebsd_package` and
`make_source_package`. `hilde new module` adds a module below `src` by the parts of its name after the
package's, `src/Parse.hih` here. Set `SOURCE_DATE_EPOCH` to date the changelog.

## hilde.toml

```toml
targets = ["linux", "openbsd"]

[package]
name = "Acme.App"
version = "v0.1.0"
signify-key = "RWS..."
capabilities = ["unsafe", "embed"]

[require]
"Acme.Json" = { git = "https://example.org/json.git", version = "v1.2.0" }

[c-source]
commit = true
dir = "c"

[policy]
require-signatures = true
```

The name is the module prefix of the package, its modules are named below it. A version is `vX.Y.Z`, and the
version in the `hilde.toml` of a release is its git tag. A requirement names the least version it needs and
where git finds it, and may pin the key its releases are signed with. Keys or tables a manifest does not have
are refused, so a misspelt key is found.

## Rust crates

```toml
[rust]
calamine = { version = "0.26.1", default-features = false, features = ["dates"] }
```

A package names the Rust crates it uses in the table `rust`: each by its name on crates.io, with one exact
version `X.Y.Z` and, when it asks for them, `default-features = false` and its `features`. A range, `^`, `~`,
`=` or `*` is refused (H1505), so every build and every host gets the same crate; a key a crate does not have,
such as `git` or `path`, is refused too (H1503). The package reaches the crates through its bridge modules,
one file each in `rust/bridge`, such as `rust/bridge/sheet.rs`.

The crates of the packages it requires join the build: `hilde rust` reads the `hilde.toml` of every package in
`vendor/` that `hilde.toml` requires, and theirs as well, and takes their tables `rust` and their bridge
modules in `vendor/<prefix>/rust/bridge` too. A package that is required and is not in `vendor/` is refused
(H1543). One crate name holds at one exact version for the whole build: when two of the manifests name one
crate with two versions, the build is refused (H1542); when the versions agree, the features of both are
turned on and the default features when either asks for them. A bridge module of a dependency is named with
its prefix in small letters before the name of its file, so that two packages never meet in the one library.

```sh
hilde rust --vendor
hilde rust
hilde rust --target=aarch64-unknown-linux-gnu --json
```

`hilde rust` writes one crate below `target/rust` and has cargo build it: a `staticlib` of the name
`hilde_rust_` and the prefix in small letters, `hilde_rust_acme_app` for `Acme.App`, with every bridge module
as a module of its own. A binary takes one Rust static library, or the standard library of Rust is linked
twice; when cargo leaves a second one beside it, the build is refused (H1538). The crate takes its
`rust-version` from the `rust-toolchain.toml` beside the compiler, which pins the Rust of every package, and
its profiles keep `panic = "unwind"`. A build is refused (H1536) when `CARGO_PROFILE_RELEASE_PANIC`,
`RUSTFLAGS` or a `.cargo/config.toml` of the package, of the directories above it or of the home of cargo
sets panic to abort, since `catch_unwind` then catches nothing; the guard crate refuses to compile under it
as well. Every `pub fn` and every `extern "C" fn` of a bridge must start with `hilde_bridge::guard`,
`guard_or` or `guard_code`, or be written with `hilde_bridge::export!` (H1537): a panic then becomes an error
code instead of ending the programme.

cargo runs with `--offline` and `--locked`, from `rust/Cargo.lock` and, for crates of crates.io, the sources in
`rust/vendor`; both are checked in (H1539). `--vendor` is the one step that fetches: it runs `cargo vendor` and
writes the lock file back to `rust/Cargo.lock`. cargo is `HILDE_CARGO` when it is set, else the one on PATH
(H1535). The library lands in `target/rust/build/release`, or below the triple named with `--target`, and
`target/rust/pkgconfig` gets its pkg-config file, with the native libraries rustc names. Every dependency
that brings Rust gets a file of its own there, named after its library, which links the one static library,
so that a module of the dependency names it with `pragma Foreign_Library` and is linked to the same library.
Inside such a package
`hilde build` and `hilde compile` run `hilde rust` first and find the library by that file, when a module of
the package names it with `pragma Foreign_Library(Name => "hilde_rust_acme_app")`, or when one of the
packages in `vendor/` brings Rust.

The pilot `pilot/calamine` is the worked example: the crate is named at 0.26.1 in its `hilde.toml`, the
bridge `rust/bridge/sheet.rs` exports a workbook as one opaque object, the header `bindings/fixtures/calamine.h`
goes through `scripts/gen-bindings.py` to `Bindings.C.Calamine`, and `Standard.Calamine` is the safe module
with contracts that the programme imports. Its crate is not vendored in this tree, so `pilot/calamine/run-fake.sh`
builds the layers against a plain C stand-in and runs them; with `rust/Cargo.lock` and `rust/vendor` in place,
`hilde rust` builds the real library instead.

## Getting packages

```sh
hilde get Acme.Json@v1.2.0 --git=https://example.org/json.git
hilde get
```

`get` fetches every package required, directly or through another, as git tags, and chooses the versions
by minimal version selection: each prefix gets the greatest version any selected package requires of it,
never a newer one. One prefix has one major; a new major is a new prefix, such as `Acme.Json2`. The trees go
to `vendor/<prefix>/` and their checksums to `hilde.sum`:

```text
Acme.Json v1.2.0 h1:0sun7IhfChLljPygSUAzTwodjRy1DIkk5dSyTgM3A1M= key:RWSgBGDjdJGlv/Ssv2UqfdZ9kfEYS1czgn4S5ReDnx9m1cPHwyT0GMWY
```

The checksum is Go's dirhash over the files of the tree, so a tree has one checksum whether it came from git,
from an archive or from `vendor/`. A release is signed when its tree has `signatures/vX.Y.Z.sig`; the key is
taken on first use and written into `hilde.sum`, and every later release of the prefix must be signed by it.
Nothing in `vendor/` or `hilde.sum` changes unless every package was fetched and checked.

Inside a package the compiler finds the modules of `src`, of every tree in `vendor/` and of the standard
library by itself: `hilde check`, `hilde test`, `hilde compile`, `hilde lsp` and `hilde guard` need no
`--modules`.

## Checking and updating

```sh
hilde verify
hilde update --check
hilde update
```

`verify` holds `vendor/` against `hilde.sum` without the network: every requirement has its line, every
tree is there with its checksum, no tree is left over, and every target of `hilde.toml` is allowed by the
`pragma Targets` of every module the package reaches. A package without `AGENTS.md` or `llms.txt`
is told so by a warning in the summary line; the exit stays the one of the sums. `update` raises each requirement to the newest tag of
its major, one by one: it fetches, runs `hilde test src` and `hilde guard`, and takes the raise back when one
of them fails or the package declares a capability more. It prints the lines of the changelogs between the
old and the new version and the text of a commit. It never raises a major.

## Capabilities

`hilde guard` inside a package tells for each package what its own modules do that it must declare:
`unsafe` for a module with `pragma Unsafe_Module`, `foreign` for a foreign function the programme reaches,
`embed` for an embed it reaches, and `ffi` for a module with `pragma Foreign_Library` or a `[rust]` table,
the crates of the package included. A capability used and not named in `[package] capabilities` ends guard with
exit status 4.

In a package with a `[rust]` table the guard also checks the crates: cargo audit over the `Cargo.lock` of
every package that brings Rust, and cargo deny over the crate of the build with a license policy the guard
writes itself (Apache-2.0, MIT, BSD-2-Clause, BSD-3-Clause, ISC, Zlib, Unicode; `openssl-sys` and GPL banned).
A vulnerability, a yanked crate, a banned crate or a forbidden license is one finding and ends guard with
exit status 5, with the version that fixes it printed when the advisory names one. A tool that is not
installed is a line that says so, never a pass; output the guard cannot read is a finding of its own.
`--rust-db=path` hands the advisory database to cargo audit as `--path`, so the check runs unattended and
offline. `--json` reports the whole guard as one object, with the report, the capabilities and the lines of
the crate checks as arrays of lines. This one is from a package whose audit found one vulnerability, and
the exit status of the command is 5:

```json
{
  "command": "guard",
  "report": [
    "hilde guard: the attack surface of the programme",
    "unsafe modules on the command line: 2",
    "  Acme.Helper (vendor/Acme.Helper/src/Helper.hiq)",
    "  Acme.Pair (src/Pair.hiq)",
    "foreign functions: 3, reachable: 3",
    "  reachable  Acme.Pair.addInRust -> acme_pair_add"
  ],
  "capabilities": [
    "capabilities of the packages: 2, undeclared: 0",
    "  Acme.Pair (hilde.toml): declares unsafe foreign ffi; uses unsafe foreign ffi"
  ],
  "rust": [
    "rust crates:",
    "  vulnerability: time 0.1.45, fixed in 0.2.23: RUSTSEC-FIXTURE-0001: a fixture advisory"
  ],
  "vulnerabilities_reached": 0,
  "capabilities_undeclared": 0,
  "rust_findings": 1,
  "ok": false
}
```

## Doc tests

The example in the docstring of an exported function, its lines set off by four blanks, runs as a test of
its own whenever `hilde test` runs inside a package, and elsewhere with `--doc`.

## A release

```sh
hilde export --make-key=release
hilde export --secret-key=release.sec
git add -A
git commit -m "release v1.3.0"
git tag v1.3.0
```

`export` needs a test file for every module, passing tests, and a test that calls every exported function.
It compares the interfaces with those of the newest tag and refuses a version lower than the change calls
for: a removed or changed declaration, a stricter requires or a weaker ensures is a major version, an added
declaration a minor one. It writes `llms.txt`, a manual page of each module into `man/man3`, the signature of
the tree into `signatures/`, and the archive with its signature into `dist/`. `--with-c` writes the generated
C of the system it runs on into `c/`. `hilde api-diff old new` shows the same comparison between two
directories, with the calls in `src` of what broke.

## Documentation and installing

```sh
hilde doc Standard.Text.trim
hilde doc --man Acme.Json > Acme.Json.3
hilde install --prefix=/usr/local --destdir=stage
```

`doc` prints a module or a declaration with its contracts and docstring, from `src`, `vendor/` and the
standard library, without the network. `install` writes only below the staging tree: a programme into `bin`,
a library's sources into `share/hilde`, the manual pages into `share/man` (on OpenBSD into `man`
unless the prefix is `/usr`), the licence and the changelog into `share/doc`. The scripts of `--packaging` wrap that tree into a package of the
system.
