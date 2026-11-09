#!/bin/sh
# The Rust crates of a package, end to end: hilde rust and the compile that
# runs it first, over the fixture tests/rust-bridge/fixture, a package with
# two bridge modules of its own and one of a dependency in vendor, with no
# network.
#
#     sh scripts/check-rust-build.sh <work-directory>
#
# Run from the root of the tree, after make has built hilde and hilde-pkg.
# The work directory must not exist; it is made and removed.  The last line
# counts the steps that held, failed and were blocked; a step that does not
# hold is printed and the exit is 1.  Exit 9 when the check could not run.
#
# What it holds, with tests/rust-bridge/fake-cargo.sh as cargo:
#   build       one crate in target/rust, a staticlib with all three
#               bridges, the crate of the dependency pinned, panic =
#               "unwind", cargo run offline and locked in target/rust,
#               exactly one static library, its pkg-config file and the
#               one of the dependency, which links that library
#   compile     hilde compile in the package builds the library first and
#               links it; the programme calls all three bridges and goes on
#   dependency  two versions of one crate, H1542, and a dependency that is
#               not in vendor/, H1543
#   abort       panic = "abort" refused from a cargo configuration, from
#               CARGO_PROFILE_RELEASE_PANIC and from RUSTFLAGS, H1536, and a
#               compile stops with it
#   bridges     a function that does not start with the guard, H1537 with
#               its file and line, and a file that is no bridge name
#   offline     no rust/Cargo.lock, H1539; a crate without rust/vendor,
#               H1539; with it, the crate pinned with = and crates.io
#               replaced by rust/vendor
#   refusals    a version that is not exact, H1505; cargo failing, no
#               library and two libraries, H1538; no cargo, H1535; a target
#               that is none, H1541
#   target      --target puts the library and the pkg-config file below it
#   guard       the capabilities with ffi among them, a missing one ends
#               the guard with 4, and the checks of the crates with
#               stands-ins for cargo-audit and cargo-deny: clean, a
#               vulnerability with its fixed version, a yanked crate, a
#               banned crate, a forbidden license, output that is no JSON,
#               --rust-db passed on as --path, and the JSON of the guard
#   vendor      --vendor writes rust/Cargo.lock and does not run offline
#   json        --json gives one object with ok, count and the problems
# With a real cargo on PATH, in addition: the fixture built by cargo, its
# programme run, so that a panic in a bridge gives -1 across extern "C"
# instead of ending it; the tests of rust/hilde-bridge; and hilde-bridge
# refused under panic = "abort".  Without cargo each of these is printed
# BLOCKED and counted as blocked, not as held.  The same holds for a real
# cargo-audit and cargo-deny: the RustSec audit runs only when
# HILDE_RUSTSEC_DB names an advisory database, since fetching one needs
# the network a gate has not; without the tools or the database each is
# printed BLOCKED.
set -u
W=${1:-}
[ -n "$W" ] || { echo "ABORT: no work directory -- nothing ran"; exit 9; }
[ ! -e "$W" ] || { echo "ABORT: $W exists -- nothing ran"; exit 9; }
T=$(pwd)
H=$T/hilde
[ -x "$H" ] && [ -x "$T/hilde-pkg" ] || { echo "ABORT: hilde or hilde-pkg not built -- nothing ran"; exit 9; }
[ -d "$T/tests/rust-bridge/fixture" ] || { echo "ABORT: no tests/rust-bridge/fixture -- nothing ran"; exit 9; }
for t in cc ar pkg-config python3; do
	command -v "$t" > /dev/null 2>&1 || { echo "ABORT: $t not on PATH -- nothing ran"; exit 9; }
done
mkdir -p "$W" || exit 9
W=$(cd "$W" && pwd)
L=$W/log
good=0
bad=0
blocked=0
holds() {
	good=$((good + 1))
	echo "ok    $1"
}
fails() {
	bad=$((bad + 1))
	echo "FAIL  $1"
	[ -f "$L" ] && sed 's/^/      /' "$L" | head -n 20
}
blocks() {
	blocked=$((blocked + 1))
	echo "BLOCKED  $1"
}
# run <name> <want-exit> <command...>: the exit must be the one wanted.
run() {
	name=$1; want=$2; shift 2
	"$@" > "$L" 2>&1
	rc=$?
	if [ "$rc" = "$want" ]; then holds "$name (exit $rc)"; else fails "$name (exit $rc, want $want)"; fi
}
# has <name> <pattern> [file]: the file, the log of the last run when none
# is named, holds the pattern.
has() {
	if grep -q -E -e "$2" "${3:-$L}"; then holds "$1"; else fails "$1: no [$2]"; fi
}
# lacks <name> <pattern> [file]: the file does not hold the pattern.
lacks() {
	if grep -q -E -e "$2" "${3:-$L}"; then fails "$1: [$2] is there"; else holds "$1"; fi
}
# count <name> <want> <pattern> <file>: how many lines hold the pattern.
count() {
	n=$(grep -c -E -e "$3" "$4")
	if [ "$n" = "$2" ]; then holds "$1 ($n)"; else fails "$1: $n lines, want $2"; fi
}
# fresh <dir>: a copy of the fixture at dir, the working directory.
fresh() {
	cp -R "$T/tests/rust-bridge/fixture" "$1" && cd "$1" || exit 9
}

FAKE=$W/fake-cargo
cp "$T/tests/rust-bridge/fake-cargo.sh" "$FAKE" && chmod +x "$FAKE" || exit 9
export FAKE_CARGO_C="$T/tests/rust-bridge/fake-pair.c"
export FAKE_CARGO_LOG="$W/cargo.log"
export HILDE_CARGO="$FAKE"
unset CARGO_PROFILE_RELEASE_PANIC CARGO_PROFILE_DEV_PANIC RUSTFLAGS CARGO_ENCODED_RUSTFLAGS CARGO_BUILD_RUSTFLAGS CARGO_PROFILE_RELEASE_RUSTFLAGS

# build: three bridge modules, one staticlib.
fresh "$W/pair"
: > "$FAKE_CARGO_LOG"
run "hilde rust" 0 "$H" rust
has "it names the one staticlib and all three bridges" "^hilde rust: one staticlib target/rust/build/release/libhilde_rust_acme_pair.a with 3 bridge modules$"
count "one crate type, a staticlib" 1 '^crate-type = \["staticlib"\]$' target/rust/Cargo.toml
count "one library table" 1 '^\[lib\]$' target/rust/Cargo.toml
count "panic = unwind in both profiles" 2 '^panic = "unwind"$' target/rust/Cargo.toml
lacks "no profile aborts" 'abort' target/rust/Cargo.toml
has "the rust-version of rust-toolchain.toml" '^rust-version = "1\.88\.0"$' target/rust/Cargo.toml
has "the guard crate of this tree" "^hilde-bridge = \\{ path = \"$T/rust/hilde-bridge\" \\}$" target/rust/Cargo.toml
has "the crate of the dependency is pinned exactly" '^addone = \{ version = "=0\.1\.0" \}$' target/rust/Cargo.toml
count "all three bridges are modules of the one library" 3 '^pub mod (add|divide|acme_helper_one);$' target/rust/lib.rs
has "the bridge of the dependency is named by its file" '^#\[path = "\.\./\.\./vendor/Acme\.Helper/rust/bridge/one\.rs"\]$' target/rust/lib.rs
cmp -s "$T/rust-toolchain.toml" target/rust/rust-toolchain.toml && holds "the toolchain file is beside the crate" || fails "target/rust/rust-toolchain.toml is not the one of the tree"
cmp -s rust/Cargo.lock target/rust/Cargo.lock && holds "the lock file checked in is the one cargo reads" || fails "target/rust/Cargo.lock is not rust/Cargo.lock"
has "cargo runs offline by its configuration" '^offline = true$' target/rust/.cargo/config.toml
has "cargo ran in target/rust" "^cwd=$W/pair/target/rust$" "$FAKE_CARGO_LOG"
has "with --offline" '^arg=--offline$' "$FAKE_CARGO_LOG"
has "with --locked" '^arg=--locked$' "$FAKE_CARGO_LOG"
has "asking rustc for the native libraries" '^arg=native-static-libs$' "$FAKE_CARGO_LOG"
n=$(ls target/rust/build/release | grep -c '\.a$')
[ "$n" = 1 ] && holds "one static library in build/release" || fails "$n static libraries in build/release"
has "the pkg-config file links it and the native libraries" '^Libs: -L\$\{pcfiledir\}/\.\./build/release -lhilde_rust_acme_pair -lm$' target/rust/pkgconfig/hilde_rust_acme_pair.pc
PKG_CONFIG_PATH=$W/pair/target/rust/pkgconfig pkg-config --libs hilde_rust_acme_pair > "$L" 2>&1
has "pkg-config reads it" "^-L$W/pair/target/rust/pkgconfig/\\.\\./build/release -lhilde_rust_acme_pair -lm"
has "the pkg-config file of the dependency links the one staticlib" '^Libs: -L\$\{pcfiledir\}/\.\./build/release -lhilde_rust_acme_pair -lm$' target/rust/pkgconfig/hilde_rust_acme_helper.pc
PKG_CONFIG_PATH=$W/pair/target/rust/pkgconfig pkg-config --libs hilde_rust_acme_helper > "$L" 2>&1
has "pkg-config reads the one of the dependency" "^-L$W/pair/target/rust/pkgconfig/\\.\\./build/release -lhilde_rust_acme_pair -lm"
run "hilde rust --json" 0 "$H" rust --json
python3 -c 'import json,sys; d=json.loads(open(sys.argv[1]).read()); sys.exit(0 if d["command"]=="rust" and d["ok"] is True and d["count"]==3 and d["problems"]==[] else 1)' "$L" && holds "the JSON of rust counts three bridges" || fails "the JSON of rust"

# compile: the library is built first and linked.
: > "$FAKE_CARGO_LOG"
run "the programme compiles in the package" 0 "$H" compile src/Pair.hih,src/Pair.hiq --entrypoint=Acme.Pair:main --output=pair
has "the compile ran hilde rust first" '^arg=rustc$' "$FAKE_CARGO_LOG"
run "the programme runs" 0 ./pair
has "the first bridge adds" '^add 2 3 = 5$'
has "the second bridge divides" '^divide 8 2 = 4$'
has "a zero divisor gives -1" '^divide 7 0 panicked and gave -1$'
has "the bridge of the dependency adds" '^one 41 = 42$'
has "and the programme goes on" '^the programme goes on$'

# dependency: the crates of one build at one version, the dependency there.
cp hilde.toml "$W/pair.toml"
printf '\n[rust]\naddone = { version = "0.2.0" }\n' >> hilde.toml
run "two versions of one crate" 1 "$H" rust
has "is H1542" "H1542: the Rust crate addone has the version 0\.2\.0 in one hilde\.toml of the build and the version 0\.1\.0 in another"
cp "$W/pair.toml" hilde.toml
mv vendor/Acme.Helper "$W/helper"
run "a dependency not in vendor" 1 "$H" rust
has "is H1543" "H1543: the dependency Acme\.Helper of hilde\.toml is not in vendor/"
mv "$W/helper" vendor/Acme.Helper

# abort: every way to ask for panic = "abort" is refused.
mkdir -p .cargo && printf '[profile.release]\npanic = "abort"\n' > .cargo/config.toml
run "panic = abort in .cargo/config.toml" 1 "$H" rust
has "is H1536" "H1536"
has "naming the file" "the cargo configuration ./.cargo/config.toml sets panic to abort"
rm -f pair
run "a compile stops with it" 1 "$H" compile src/Pair.hih,src/Pair.hiq --entrypoint=Acme.Pair:main --output=pair
[ ! -e pair ] && holds "and writes no programme" || fails "a programme was written"
rm -r .cargo
run "CARGO_PROFILE_RELEASE_PANIC=abort" 1 env CARGO_PROFILE_RELEASE_PANIC=abort "$H" rust
has "is H1536" "H1536: the environment variable CARGO_PROFILE_RELEASE_PANIC"
run "RUSTFLAGS with -C panic=abort" 1 env RUSTFLAGS="-C panic=abort" "$H" rust
has "is H1536" "H1536: the environment variable RUSTFLAGS"
run "RUSTFLAGS without panic" 0 env RUSTFLAGS="-C opt-level=2" "$H" rust

# bridges: a function without the guard, a file that is no bridge.
printf '// a bridge that forgets the guard\n\npub fn acme_pair_bad(a: i32) -> i32 {\n    a\n}\n' > rust/bridge/bad.rs
run "a bridge function without the guard" 1 "$H" rust
has "is H1537 with its line and file" "H1537: the function at line 3 of rust/bridge/bad.rs does not run its body under hilde_bridge::guard"
rm rust/bridge/bad.rs
printf '\n' > rust/bridge/Bad.rs
run "a file that is no bridge name" 1 "$H" rust
has "is H1537" "H1537: rust/bridge holds Bad.rs, which is no bridge module"
rm rust/bridge/Bad.rs

# offline: the lock file and the vendored sources are needed.
mv rust/Cargo.lock "$W/lock"
run "no rust/Cargo.lock" 1 "$H" rust
has "is H1539" "H1539: there is no rust/Cargo.lock"
mv "$W/lock" rust/Cargo.lock
cp hilde.toml "$W/keep.toml"
printf '\n[rust]\ncalamine = { version = "0.26.1", default-features = false, features = ["dates"] }\n' >> hilde.toml
mv rust/vendor "$W/vendor"
run "a crate without rust/vendor" 1 "$H" rust
has "is H1539" "H1539: there is no rust/vendor"
mv "$W/vendor" rust/vendor
run "a crate with rust/vendor" 0 "$H" rust
has "the crate is pinned exactly" '^calamine = \{ version = "=0\.26\.1", default-features = false, features = \["dates"\] \}$' target/rust/Cargo.toml
has "crates.io is replaced" '^replace-with = "vendored-sources"$' target/rust/.cargo/config.toml
has "by rust/vendor" '^directory = "\.\./\.\./rust/vendor"$' target/rust/.cargo/config.toml

# refusals.
cp "$W/keep.toml" hilde.toml
printf '\n[rust]\ncalamine = { version = "^0.26.1" }\n' >> hilde.toml
run "a version that is not exact" 1 "$H" rust
has "is H1505 naming crate and version" 'H1505: the Rust crate calamine in hilde.toml has the version "\^0\.26\.1", which is not one exact version X\.Y\.Z'
cp "$W/keep.toml" hilde.toml
printf '\n[rust]\ncalamine = { version = "0.26.1", git = "https://example.org/calamine.git" }\n' >> hilde.toml
run "a key a crate does not have" 1 "$H" rust
has "is H1503" 'H1503: hilde.toml has the key git in rust\."calamine"'
cp "$W/keep.toml" hilde.toml
run "cargo fails" 1 env FAKE_CARGO_MODE=fail "$H" rust
has "is H1538 with what cargo said" "error\\[E0425\\]"
rm -rf target/rust/build
run "cargo writes no library" 1 env FAKE_CARGO_MODE=nolib "$H" rust
has "is H1538" "H1538: cargo ended and wrote no libhilde_rust_acme_pair.a"
run "cargo writes two libraries" 1 env FAKE_CARGO_MODE=twolibs "$H" rust
has "is H1538" "H1538: target/rust/build/release holds another static library"
rm -rf target/rust/build
run "no cargo" 1 env HILDE_CARGO= PATH=/nonexistent "$H" rust
has "is H1535" "H1535"
run "a target that is none" 1 "$H" rust --target=../x
has "is H1541" "H1541"

# target: the library and its pkg-config file below the triple.
run "--target" 0 "$H" rust --target=x86_64-unknown-linux-gnu
[ -f target/rust/build/x86_64-unknown-linux-gnu/release/libhilde_rust_acme_pair.a ] && holds "the library is below the triple" || fails "no library below the triple"
has "the pkg-config file below the triple points there" '^Libs: -L\$\{pcfiledir\}/\.\./\.\./build/x86_64-unknown-linux-gnu/release ' target/rust/pkgconfig/x86_64-unknown-linux-gnu/hilde_rust_acme_pair.pc

# guard: the capabilities with ffi among them, and the checks of the
# crates with the stands-ins for cargo-audit and cargo-deny.
fresh "$W/pair-guard"
FAKE_AUDIT=$W/fake-cargo-audit
cp "$T/tests/rust-bridge/fake-cargo-audit.sh" "$FAKE_AUDIT" && chmod +x "$FAKE_AUDIT" || exit 9
FAKE_DENY=$W/fake-cargo-deny
cp "$T/tests/rust-bridge/fake-cargo-deny.sh" "$FAKE_DENY" && chmod +x "$FAKE_DENY" || exit 9
AUDIT_LOG=$W/audit.log
DENY_LOG=$W/deny.log
export HILDE_CARGO_AUDIT="$FAKE_AUDIT" FAKE_CARGO_AUDIT_LOG="$AUDIT_LOG"
export HILDE_CARGO_DENY="$FAKE_DENY" FAKE_CARGO_DENY_LOG="$DENY_LOG"
run "the guard holds with the capabilities declared" 0 "$H" guard src/Pair.hih,src/Pair.hiq
has "the dependency names ffi for its crates" "Acme\.Helper .*declares unsafe foreign ffi; uses unsafe foreign ffi"
has "the root package uses what its modules need" "Acme\.Pair .*declares unsafe foreign ffi; uses unsafe foreign ffi"
has "no lock file in the dependency, the audit says so" "Acme\.Helper: no rust/Cargo\.lock: the audit did not run"
has "no crate built yet, cargo-deny says so" "cargo-deny: hilde rust has built no crate in target/rust yet: the check did not run"
cp hilde.toml "$W/guard.toml"
grep -v '^capabilities' hilde.toml > "$W/nocaps.toml"
{ cat "$W/nocaps.toml"; printf 'capabilities = ["unsafe", "foreign"]\n'; } > hilde.toml
run "a capability that is missing" 4 "$H" guard src/Pair.hih,src/Pair.hiq
has "ffi is undeclared" "undeclared: Acme\.Pair uses ffi, which .*hilde\.toml does not name in \[package\] capabilities"
cp "$W/guard.toml" hilde.toml
printf '\n[rust]\naddone = { version = "0.1.0" }\n' >> hilde.toml
run "hilde rust for the crate of the root package" 0 "$H" rust
: > "$DENY_LOG"
run "the guard over the built crate" 0 "$H" guard src/Pair.hih,src/Pair.hiq
has "cargo-deny ran with its configuration" "^arg=--config$" "$DENY_LOG"
has "the configuration is in target/rust" "^arg=$W/pair-guard/target/rust/deny\.toml$" "$DENY_LOG"
has "over the crate cargo built" "^arg=$W/pair-guard/target/rust/Cargo\.toml$" "$DENY_LOG"
has "the audit still waits for the lock of the dependency" "Acme\.Helper: no rust/Cargo\.lock: the audit did not run"
mkdir -p vendor/Acme.Helper/rust && cp rust/Cargo.lock vendor/Acme.Helper/rust/Cargo.lock
: > "$AUDIT_LOG"
run "the guard over the audited crate" 0 "$H" guard src/Pair.hih,src/Pair.hiq
has "cargo-audit ran over the lock of the dependency" "^arg=$W/pair-guard/vendor/Acme\.Helper/rust/Cargo\.lock$" "$AUDIT_LOG"
has "as JSON" "^arg=--json$" "$AUDIT_LOG"
run "a vulnerability" 5 env FAKE_CARGO_AUDIT_MODE=vulnerable "$H" guard src/Pair.hih,src/Pair.hiq
has "with the version that fixes it" "vulnerability: time 0\.1\.45, fixed in 0\.2\.23: RUSTSEC-FIXTURE-0001: a fixture advisory"
run "a yanked crate" 5 env FAKE_CARGO_AUDIT_MODE=yanked "$H" guard src/Pair.hih,src/Pair.hiq
has "named with its version" "yanked: memoffset 0\.5\.3"
run "a banned crate" 5 env FAKE_CARGO_DENY_MODE=banned "$H" guard src/Pair.hih,src/Pair.hiq
has "with what cargo-deny said" "banned: crate 'openssl-sys 0\.9\.100' is banned"
run "a license that is not allowed" 5 env FAKE_CARGO_DENY_MODE=license "$H" guard src/Pair.hih,src/Pair.hiq
has "with what cargo-deny said" "license: The 'GPL-3\.0-only' license is not allowed"
run "an audit that speaks no JSON" 5 env FAKE_CARGO_AUDIT_MODE=garbage "$H" guard src/Pair.hih,src/Pair.hiq
has "is never silently green" "tool: this is no json at all"
run "a deny that speaks no JSON" 5 env FAKE_CARGO_DENY_MODE=garbage "$H" guard src/Pair.hih,src/Pair.hiq
has "is never silently green" "tool: this is no json at all"
mkdir -p "$W/rustsec-db"
run "the audit from a database given on the command line" 0 "$H" guard src/Pair.hih,src/Pair.hiq --rust-db="$W/rustsec-db"
has "passed on as --path" "^arg=--path$" "$AUDIT_LOG"
has "the database named" "^arg=$W/rustsec-db$" "$AUDIT_LOG"
run "the guard as JSON" 0 "$H" guard src/Pair.hih,src/Pair.hiq --json
python3 -c 'import json,sys; d=json.loads(open(sys.argv[1]).read()); sys.exit(0 if d["command"]=="guard" and d["ok"] is True and d["rust_findings"]==0 and d["capabilities_undeclared"]==0 and d["rust"]!=[] else 1)' "$L" && holds "the JSON of the guard counts the crates" || fails "the JSON of the guard"
run "the JSON of a guard with findings" 5 env FAKE_CARGO_AUDIT_MODE=vulnerable "$H" guard src/Pair.hih,src/Pair.hiq --json
python3 -c 'import json,sys; d=json.loads(open(sys.argv[1]).read()); sys.exit(0 if d["ok"] is False and d["rust_findings"]>=1 and any("vulnerability" in l for l in d["rust"]) else 1)' "$L" && holds "the JSON names the finding" || fails "the JSON of a guard with findings"
run "the guard without cargo-audit" 0 env HILDE_CARGO_AUDIT= "$H" guard src/Pair.hih,src/Pair.hiq
has "says that the check did not run" "cargo-audit is not installed: the check did not run"

# vendor: the one step that fetches.
fresh "$W/pair-vendor"
rm rust/Cargo.lock
printf '\n[rust]\ncalamine = { version = "0.26.1" }\n' >> hilde.toml
run "hilde rust --vendor" 0 "$H" rust --vendor
[ -f rust/Cargo.lock ] && holds "rust/Cargo.lock is written" || fails "no rust/Cargo.lock"
[ -d rust/vendor ] && holds "rust/vendor is made" || fails "no rust/vendor"
lacks "the vendor step is not offline" '^offline = true$' target/rust/.cargo/config.toml
run "and the build after it" 0 "$H" rust
has "is offline again" '^offline = true$' target/rust/.cargo/config.toml

# A real cargo: the fixture built by Rust, the panic seen across extern "C".
if command -v cargo > /dev/null 2>&1; then
	unset HILDE_CARGO
	fresh "$W/pair-real"
	run "hilde rust with cargo" 0 "$H" rust
	run "the programme of the fixture compiles" 0 "$H" compile src/Pair.hih,src/Pair.hiq --entrypoint=Acme.Pair:main --output=pair
	run "and runs to its end" 0 ./pair
	has "the panic in the bridge gave -1" '^divide 7 0 panicked and gave -1$'
	has "the bridge of the dependency added" '^one 41 = 42$'
	has "and the programme went on" '^the programme goes on$'
	has "Rust said what panicked" 'acme_pair_divide: division by zero'
	cd "$T" || exit 9
	run "the tests of hilde-bridge" 0 cargo test --offline --manifest-path rust/hilde-bridge/Cargo.toml --target-dir "$W/bridge-target"
	run "hilde-bridge under panic = abort" 101 cargo build --offline --release --manifest-path rust/hilde-bridge/Cargo.toml --target-dir "$W/bridge-abort" --config 'profile.release.panic="abort"'
	has "is refused by the crate itself" 'hilde-bridge needs panic = "unwind"'
else
	blocks "real cargo: cargo is not on PATH, so the fixture was not built by Rust and its panic was not run across extern \"C\""
	blocks "real cargo: the tests of rust/hilde-bridge (cargo test) did not run"
	blocks "real cargo: hilde-bridge was not built under panic = \"abort\" to see it refused"
fi

# The real cargo checks, on the copy the guard section left behind.
if command -v cargo-audit > /dev/null 2>&1; then
	if [ -n "${HILDE_RUSTSEC_DB:-}" ] && [ -d "$HILDE_RUSTSEC_DB" ]; then
		cd "$W/pair-guard" || exit 9
		cargo-audit audit --file rust/Cargo.lock --json --path "$HILDE_RUSTSEC_DB" > "$L" 2>&1
		rc=$?
		case $rc in
			0 | 1) holds "real cargo-audit over the lock of the fixture (exit $rc)";;
			*) fails "real cargo-audit over the lock of the fixture (exit $rc)";;
		esac
	else
		blocks "real cargo-audit: HILDE_RUSTSEC_DB names no advisory database, so the audit did not run; fetching one needs the network"
	fi
else
	blocks "real cargo-audit: the tool is not on PATH, so the advisory check of the guard did not run against the RustSec database"
fi
if command -v cargo-deny > /dev/null 2>&1; then
	cd "$W/pair-guard" || exit 9
	run "real cargo-deny over the built crate" 0 cargo-deny check licenses bans --offline --format json --config target/rust/deny.toml --manifest-path target/rust/Cargo.toml
else
	blocks "real cargo-deny: the tool is not on PATH, so the license and ban check of the guard did not run"
fi

# The pilot's C stand-in: the generated binding, the safe layer with its
# contracts and the programme, built and run without Rust.  The crate
# itself is not built here; that needs rust/Cargo.lock and rust/vendor,
# which the pilot does not carry yet.
if command -v cc > /dev/null 2>&1; then
	cd "$T" || exit 9
	if sh pilot/calamine/run-fake.sh > "$L" 2>&1; then
		holds "the pilot runs against the C stand-in ($(tail -n 1 "$L"))"
	else
		fails "the pilot did not run against the C stand-in"
		cat "$L"
	fi
	cd "$T" || exit 9
else
	blocks "the pilot: cc is not on PATH, so the C stand-in was not built"
fi

cd "$T" || exit 9
rm -rf "$W"
echo "check-rust-build: $good held, $bad failed, $blocked blocked"
[ "$bad" = 0 ] || exit 1
exit 0
