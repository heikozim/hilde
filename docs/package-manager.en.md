# The package manager

A Hilde package is a directory with a manifest, `hilde.toml`, its modules below `src`, and the packages it
needs below `vendor/`, checked in. The package commands are carried out by `hilde-pkg`, which lies beside the
compiler; the compiler hands them to it, so they are all called as `hilde <command>`. Only `get` and `update`
use the network, through git. Every command takes `--json` and then prints one object:

```json
{"command": "verify", "ok": true, "count": 2, "summary": "...", "problems": []}
```

A problem has a code from H1501 to H1534 (docs/errors.en.md, section 13), a message and a suggestion. The
exit status is 0 when the command did what it was asked, 1 for a problem, 2 for a command line it does not
take.

## A new package

```sh
hilde new Acme.Json --git --packaging
hilde new module Acme.Json.Parse
```

`hilde new` writes `hilde.toml`, an empty `hilde.sum`, a changelog in Debian's form, the ISC licence with the
author git knows, `README.md`, `.gitignore` and `src/Json.hih`, `src/Json.hiq` and `src/Json.test.hiq`, each
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
`pragma Targets` of every module the package reaches. `update` raises each requirement to the newest tag of
its major, one by one: it fetches, runs `hilde test src` and `hilde guard`, and takes the raise back when one
of them fails or the package declares a capability more. It prints the lines of the changelogs between the
old and the new version and the text of a commit. It never raises a major.

## Capabilities

`hilde guard` inside a package tells for each package what its own modules do that it must declare:
`unsafe` for a module with `pragma Unsafe_Module`, `foreign` for a foreign function the programme reaches,
`embed` for an embed it reaches. A capability used and not named in `[package] capabilities` ends guard with
exit status 4.

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
