#!/bin/sh
# The package commands, end to end: packages made with hilde new, released
# as tags of local git repositories, required, selected, vendored, verified
# and refused, with no network.
#
#     sh scripts/check-pkg.sh <work-directory>
#
# Run from the root of the tree, after make has built hilde and hilde-pkg.
# The work directory must not exist; it is made and removed.  The last line
# counts the steps that held; a step that does not hold is printed and the
# exit is 1.  Exit 9 when the check could not run.
#
# What it holds:
#   new         hilde new makes a package that hilde check and hilde test
#               take, a programme that runs, and refuses a name twice.
#   select      Acme.App requires Acme.Text v1.0.0 and Acme.Io v1.0.0, which
#               requires Acme.Text v1.1.0: minimal version selection picks
#               v1.1.0, not the newer v1.2.0 the repository also has.
#   vendor      the compiler finds the vendored modules by itself inside the
#               package: hilde test of a module that imports one passes.
#   verify      exit 0 on the fetched trees; a changed byte, a stray tree and
#               a missing hilde.sum line each give exit 1 with their code.
#   refusals    a missing tag (H1509, naming the tags nearest to it), a
#               wrong URL (H1508), a second major (H1516), and nothing in
#               vendor/ changed by a refused get.
#   json        --json gives one object with ok and the problems.
set -u
W=${1:-}
[ -n "$W" ] || { echo "ABORT: no work directory -- nothing ran"; exit 9; }
[ ! -e "$W" ] || { echo "ABORT: $W exists -- nothing ran"; exit 9; }
H=$(pwd)/hilde
[ -x "$H" ] && [ -x "$(pwd)/hilde-pkg" ] || { echo "ABORT: hilde or hilde-pkg not built -- nothing ran"; exit 9; }
command -v git > /dev/null 2>&1 || { echo "ABORT: git not on PATH -- nothing ran"; exit 9; }
command -v python3 > /dev/null 2>&1 || { echo "ABORT: python3 not on PATH -- nothing ran"; exit 9; }
command -v mandoc > /dev/null 2>&1 || { echo "ABORT: mandoc not on PATH -- nothing ran"; exit 9; }
mkdir -p "$W" || exit 9
W=$(cd "$W" && pwd)
L=$W/log
good=0
bad=0
holds() {
	good=$((good + 1))
	echo "ok    $1"
}
fails() {
	bad=$((bad + 1))
	echo "FAIL  $1"
	[ -f "$L" ] && sed 's/^/      /' "$L" | head -n 20
}
# run <name> <want-exit> <command...>: the exit must be the one wanted.
run() {
	name=$1; want=$2; shift 2
	"$@" > "$L" 2>&1
	rc=$?
	if [ "$rc" = "$want" ]; then holds "$name (exit $rc)"; else fails "$name (exit $rc, want $want)"; fi
}
# has <name> <pattern>: the log of the last run holds the pattern.
has() {
	if grep -q -E -e "$2" "$L"; then holds "$1"; else fails "$1: no [$2]"; fi
}
# setver <vX.Y.Z>: the version of hilde.toml in the working directory.
setver() {
	sed "s/^version = \".*\"$/version = \"$1\"/" hilde.toml > hilde.toml.new && mv hilde.toml.new hilde.toml
}
G="git -c user.name=check -c user.email=check@example.org -c init.defaultBranch=main"
export SOURCE_DATE_EPOCH=1793000000

# The four outputs of every application: version, version --full, info and
# sandbox, each held to its form, and each form checked once against an
# output it must not take.
P=$(pwd)/hilde-pkg
run "hilde-pkg --version" 0 "$P" --version
one='^hilde 1\.[0-9]+\.[0-9]+, Copyright \(C\) [0-9]{4} .+$'
[ "$(grep -c "" "$L")" = 1 ] && has "the version is one line of its form" "$one" || fails "the version is not one line"
run "hilde-pkg --version --full" 0 "$P" --version --full
grep -q -E "$one" "$L" && fails "the form of one line takes the full version" || holds "the form of one line refuses the full version"
has "the full version names the version at column 13" "^version     1\.[0-9]+\.[0-9]+$"
tail -n 1 "$L" | grep -q '^copyright   Copyright (C) ' && holds "the copyright is the last line" || fails "the copyright is not the last line"
run "hilde-pkg info" 0 "$P" info
has "info names the programme" "^name        hilde-pkg$"
has "info names the system" "^system      "
grep -q '^name        hilde$' "$L" && fails "info names another programme" || holds "info names no other programme"
run "hilde-pkg sandbox" 0 "$P" sandbox
has "sandbox says what is applied" "^hilde-pkg: no mechanism applied"
has "and counts its paths" "^paths: 0$"
run "hilde-pkg -s" 0 "$P" -s
n=$(grep -c '^paths: ' "$L")
[ "$n" = 1 ] && holds "one count of paths" || fails "$n counts of paths"
run "hilde-pkg without a command" 2 "$P"

# new: a library, a programme, a module, a name twice.
cd "$W" || exit 9
run "new Acme.Text" 0 "$H" new Acme.Text
run "new Acme.Text again" 1 "$H" new Acme.Text
has "a name twice is H1521" "H1521"
run "new Tool --bin" 0 "$H" new Tool --bin
cd "$W/Acme.Text" || exit 9
run "the new package checks" 0 "$H" check src/Text.hih,src/Text.hiq
run "the new package tests" 0 "$H" test src
has "its test and the doc test of double ran" "2 tests, 0 failed"
run "new module" 0 "$H" new module Acme.Text.Parse.Words
[ -f src/Parse/Words.hih ] && holds "the module is src/Parse/Words.hih" || fails "no src/Parse/Words.hih"
run "the package with the module tests" 0 "$H" test src
has "both tests and the doc test ran" "3 tests, 0 failed"
# Doc tests: the example of double runs as a test; an example that breaks
# the requires of double fails; outside a package only with --doc.
run "test --json" 0 "$H" test src --json
python3 -c 'import json,sys; d=json.loads(open(sys.argv[1]).read().strip().splitlines()[-1]); sys.exit(0 if d["command"]=="test" and d["ok"] is True and d["tests"]==3 and d["doc_tests"] is True else 1)' "$L" && holds "the JSON of test counts the doc test" || fails "the JSON of test"
cp src/Text.hih "$W/keep-doc.hih"
sed 's/let n: Int64 := double(21);/let n: Int64 := double(2000000000);/' "$W/keep-doc.hih" > src/Text.hih
run "a doc test that breaks a requires" 1 "$H" test src
has "the doc test fails" "FAIL  Acme.Text.DocTest"
cp "$W/keep-doc.hih" src/Text.hih
run "fmt --check --json" 0 "$H" fmt --check --json src
python3 -c 'import json,sys; d=json.loads(open(sys.argv[1]).read().strip().splitlines()[-1]); sys.exit(0 if d["command"]=="fmt" and d["files"]>=4 and "ok" in d else 1)' "$L" && holds "the JSON of fmt" || fails "the JSON of fmt"
run "guard --json" 0 "$H" guard src/Text.hih,src/Text.hiq --json
python3 -c 'import json,sys; d=json.loads(open(sys.argv[1]).read()); sys.exit(0 if d["command"]=="guard" and d["ok"] is True and len(d["report"])>3 else 1)' "$L" && holds "the JSON of guard" || fails "the JSON of guard"
cd "$W/Tool" || exit 9
run "the programme compiles" 0 "$H" compile src/Tool.hih,src/Tool.hiq --entrypoint=Tool:main --output=tool
run "the programme runs" 0 ./tool
has "it prints 42" "^42$"
# zig is taken only at the version of scripts/zig-version.txt.
printf '#!/bin/sh\necho 0.16.0\n' > "$W/fakezig" && chmod +x "$W/fakezig"
run "a zig of another version" 255 env HILDE_WASM_CC=zig HILDE_ZIG="$W/fakezig" "$H" compile src/Tool.hih,src/Tool.hiq --entrypoint=Tool:main --target=wasm --output=tool.wasm
has "it is passed over and named" "fakezig is version 0.16.0"
has "and what zig is needed for" "needed only for --target=wasm"

# Releases: Acme.Text v1.0.0, v1.1.0 and v1.2.0.
cd "$W/Acme.Text" || exit 9
setver v1.0.0
$G init -q . && $G add -A && $G commit -q -m one && $G tag v1.0.0 || { echo "ABORT: git setup"; exit 9; }
echo "-- second" >> src/Text.hiq
setver v1.1.0
$G commit -q -am two && $G tag v1.1.0 || exit 9
echo "-- third" >> src/Text.hiq
setver v1.2.0
$G commit -q -am three && $G tag v1.2.0 || exit 9
# Acme.Io v1.0.0 requires Acme.Text v1.1.0.
cd "$W" || exit 9
run "new Acme.Io" 0 "$H" new Acme.Io
cd "$W/Acme.Io" || exit 9
run "Acme.Io requires Acme.Text v1.1.0" 0 "$H" get Acme.Text@v1.1.0 --git="$W/Acme.Text"
setver v1.0.0
$G init -q . && $G add -A && $G commit -q -m one && $G tag v1.0.0 || exit 9

# select: the app requires Acme.Text v1.0.0 and Acme.Io v1.0.0.
cd "$W" || exit 9
run "new Acme.App" 0 "$H" new Acme.App
cd "$W/Acme.App" || exit 9
run "get Acme.Text@v1.0.0" 0 "$H" get Acme.Text@v1.0.0 --git="$W/Acme.Text"
grep -q "^Acme.Text v1.0.0 h1:" hilde.sum && holds "hilde.sum names v1.0.0" || fails "hilde.sum: $(cat hilde.sum)"
run "get Acme.Io@v1.0.0" 0 "$H" get Acme.Io@v1.0.0 --git="$W/Acme.Io"
has "two packages vendored" "2 packages in vendor/"
grep -q "^Acme.Text v1.1.0 h1:" hilde.sum && holds "minimal version selection takes v1.1.0" || fails "hilde.sum: $(cat hilde.sum)"
n=$(grep -c "" hilde.sum)
[ "$n" = 2 ] && holds "hilde.sum has 2 lines" || fails "hilde.sum has $n lines"
grep -q 'version = "v1.0.0"' hilde.toml && holds "hilde.toml keeps the version asked for" || fails "hilde.toml: $(cat hilde.toml)"
[ -d vendor/Acme.Text/src ] && [ -d vendor/Acme.Io/src ] && holds "vendor/ holds both trees" || fails "vendor/ is not complete"
[ ! -e vendor/Acme.Text/.git ] && holds "no .git in vendor/" || fails "vendor/Acme.Text/.git is there"
[ ! -e .hilde-cache ] && holds "the cache is removed" || fails ".hilde-cache is left"

# vendor: a test of the app that imports Acme.Text.
printf '%s\n' 'import Standard.Testing (' '    assertTrue' ');' 'import Acme.Text (' '    double' ');' '' 'module body Acme.App.Uses.Test is' '    function testDouble(): Unit is' '        assertTrue(double(4) = 8, "a vendored function");' '        return nil;' '    end;' 'end module body.' > src/Uses.test.hiq
run "hilde test finds vendor/ by itself" 0 "$H" test src
has "the test of a vendored import ran" "3 tests, 0 failed"

# verify.
run "verify" 0 "$H" verify
has "two trees held" "2 trees in vendor/ hold"
cp vendor/Acme.Text/src/Text.hiq "$W/keep.hiq"
echo "-- changed" >> vendor/Acme.Text/src/Text.hiq
run "verify after a change" 1 "$H" verify
has "a changed tree is H1515" "H1515"
cp "$W/keep.hiq" vendor/Acme.Text/src/Text.hiq
run "verify after the change is undone" 0 "$H" verify
mkdir -p vendor/Acme.Stray/src && echo x > vendor/Acme.Stray/src/X.hih
run "verify with a stray tree" 1 "$H" verify
has "a stray tree is H1515" "Acme.Stray is not named"
rm -r vendor/Acme.Stray
cp hilde.sum "$W/keep.sum"
grep -v "^Acme.Io " "$W/keep.sum" > hilde.sum
run "verify without a line" 1 "$H" verify
has "a requirement without its line is H1514" "H1514"
cp "$W/keep.sum" hilde.sum
run "verify again" 0 "$H" verify

# refusals.
run "a missing tag" 1 "$H" get Acme.Text@v1.5.0
has "a missing tag is H1509" "H1509"
has "the nearest tags are named" "v1.2.0"
run "a wrong URL" 1 "$H" get Acme.Gone@v1.0.0 --git="$W/no-such-repository"
has "a wrong URL is H1508" "H1508"
cd "$W/Acme.Text" || exit 9
setver v2.0.0
$G commit -q -am four && $G tag v2.0.0 || exit 9
cd "$W/Acme.App" || exit 9
run "a second major" 1 "$H" get Acme.Text@v2.0.0
has "a second major is H1516" "H1516"
run "verify after the refusals" 0 "$H" verify
grep -q 'version = "v1.0.0"' hilde.toml && holds "a refused get leaves hilde.toml" || fails "hilde.toml changed: $(cat hilde.toml)"

# update: Acme.Text has v1.2.0 within its major; Acme.Io v1.1.0 requires
# Acme.Text v2.0.0, a second major, so its raise is taken back.
cd "$W/Acme.Io" || exit 9
run "Acme.Io v1.1.0 requires Acme.Text v2.0.0" 0 "$H" get Acme.Text@v2.0.0
setver v1.1.0
$G add -A && $G commit -q -m two && $G tag v1.1.0 || exit 9
cd "$W/Acme.App" || exit 9
run "update --check" 0 "$H" update --check
has "update --check names the raise of Acme.Text" "Acme.Text v1.0.0 -> v1.2.0"
has "and of Acme.Io" "Acme.Io v1.0.0 -> v1.1.0"
grep -q 'version = "v1.0.0"' hilde.toml && holds "update --check changes nothing" || fails "hilde.toml: $(cat hilde.toml)"
run "update" 0 "$H" update
has "the raise of Acme.Text is kept" "^    Acme.Text v1.0.0 -> v1.2.0$"
has "the raise of Acme.Io is taken back" "Acme.Io v1.0.0 -> v1.1.0, taken back"
grep -q '"Acme.Text" = { git = "[^"]*", version = "v1.2.0" }' hilde.toml && holds "hilde.toml requires Acme.Text v1.2.0" || fails "hilde.toml: $(cat hilde.toml)"
grep -q '"Acme.Io" = { git = "[^"]*", version = "v1.0.0" }' hilde.toml && holds "hilde.toml keeps Acme.Io v1.0.0" || fails "hilde.toml: $(cat hilde.toml)"
run "verify after update" 0 "$H" verify
# api-diff over two directories.
mkdir -p "$W/api/old" "$W/api/new"
cp src/App.hih "$W/api/old/App.hih"
cp src/App.hih "$W/api/new/App.hih"
run "api-diff of the same interface" 0 "$H" api-diff "$W/api/old" "$W/api/new"
has "the same interface is patch" "^hilde api-diff: patch$"
grep -v '^end module\.$' "$W/api/old/App.hih" > "$W/api/new/App.hih"
printf '    function more(): Int64;\nend module.\n' >> "$W/api/new/App.hih"
run "api-diff of an added function" 0 "$H" api-diff "$W/api/old" "$W/api/new"
has "an added function is minor" "^hilde api-diff: minor$"

# export: signed releases of Acme.Text, whose newest tag is v2.0.0 now.
cd "$W/Acme.Text" || exit 9
run "make a key" 0 "$H" export --make-key="$W/text"
[ -f "$W/text.pub" ] && [ -f "$W/text.sec" ] && holds "the key pair is written" || fails "no key pair"
run "a second key over the first" 1 "$H" export --make-key="$W/text"
key=$(sed -n 2p "$W/text.pub")
printf 'signify-key = "%s"\n' "$key" >> hilde.toml
setver v1.3.0
run "export of a version older than the newest tag" 1 "$H" export --secret-key="$W/text.sec"
has "an old version is H1534" "H1534"
cp src/Text.hih "$W/keep.hih"
sed 's/requires (n > -1000000000) and (n < 1000000000)/requires (n > -1000) and (n < 1000)/' "$W/keep.hih" > src/Text.hih
cmp -s "$W/keep.hih" src/Text.hih && fails "the requires was not made stricter" || holds "the requires is made stricter"
setver v2.1.0
run "export of a break as a minor version" 1 "$H" export --secret-key="$W/text.sec"
has "a break under a minor version is H1530" "H1530"
cp "$W/keep.hih" src/Text.hih
run "export without a key" 1 "$H" export
has "no key is H1513" "H1513"
run "export v2.1.0" 0 "$H" export --secret-key="$W/text.sec"
has "the release is a patch over v2.0.0" "v2.1.0, a patch release after v2.0.0"
for f in llms.txt man/man3/Acme.Text.3 man/man3/Acme.Text.Parse.Words.3 signatures/v2.1.0.sig dist/acme-text-2.1.0.tar.gz dist/acme-text-2.1.0.tar.gz.sig; do
	[ -f "$f" ] && holds "export wrote $f" || fails "export did not write $f"
done
mandoc -T lint -I os=Hilde man/man3/*.3 > "$L" 2>&1
[ -s "$L" ] && fails "mandoc -T lint of the pages export wrote" || holds "mandoc -T lint: 0 messages for the pages export wrote"
# The lint names an operating system of its own: without it mandoc on
# OpenBSD takes the rules of OpenBSD's own source tree, which ask for an RCS
# id and an Mdocdate a page of a package does not carry.  The control: with
# os=OpenBSD on every host the same page has those two messages.
mandoc -T lint -I os=OpenBSD man/man3/Acme.Text.3 > "$L" 2>&1
k=$(grep -c -E "Mdocdate missing|RCS id missing" "$L")
[ "$k" = 2 ] && holds "control: the lint as OpenBSD asks for the RCS id and the Mdocdate" || fails "control: the lint as OpenBSD gave $k of the 2 messages"
tar -tzf dist/acme-text-2.1.0.tar.gz > "$L" 2>&1
has "the archive holds the tree" "^acme-text-2.1.0/src/Text.hiq$"
has "and the signature of the tree" "^acme-text-2.1.0/signatures/v2.1.0.sig$"
$G add -A && $G commit -q -m release && $G tag v2.1.0 || exit 9
cd "$W" || exit 9
run "new Acme.Signed" 0 "$H" new Acme.Signed
cd "$W/Acme.Signed" || exit 9
run "get a signed release" 0 "$H" get Acme.Text@v2.1.0 --git="$W/Acme.Text"
grep -q "^Acme.Text v2.1.0 h1:[^ ]* key:$key$" hilde.sum && holds "hilde.sum takes the key on first use" || fails "hilde.sum: $(cat hilde.sum)"
run "verify the signed release" 0 "$H" verify
cd "$W/Acme.Text" || exit 9
echo "-- unsigned" >> src/Text.hiq
setver v2.1.1
$G commit -q -am unsigned && $G tag v2.1.1 || exit 9
cd "$W/Acme.Signed" || exit 9
run "get an unsigned release after a signed one" 1 "$H" get Acme.Text@v2.1.1
has "an unsigned release after a signed one is H1512" "H1512"
cd "$W/Acme.Text" || exit 9
cp signatures/v2.1.0.sig signatures/v2.1.2.sig
echo "-- forged" >> src/Text.hiq
setver v2.1.2
$G add -A && $G commit -q -m forged && $G tag v2.1.2 || exit 9
cd "$W/Acme.Signed" || exit 9
run "get a release whose signature does not hold" 1 "$H" get Acme.Text@v2.1.2
has "a signature that does not hold is H1512" "does not hold"
grep -q "^Acme.Text v2.1.0 " hilde.sum && holds "the refused gets leave hilde.sum" || fails "hilde.sum: $(cat hilde.sum)"

# capabilities: Acme.Raw is an unsafe module with an embed.
cd "$W" || exit 9
run "new Acme.Raw" 0 "$H" new Acme.Raw
cd "$W/Acme.Raw" || exit 9
printf '%s\n' '"""' 'Seven, from C.' '' '- One number.' '"""' 'module Acme.Raw is' '    """' '    Seven.' '    """' '    function seven(): Int64' '        ensures result = 7;' 'end module.' > src/Raw.hih
printf '%s\n' 'pragma Unsafe_Module;' 'module body Acme.Raw is' '    function seven(): Int64 is' '        return @embed(Int64, "7");' '    end;' 'end module body.' > src/Raw.hiq
printf '%s\n' 'import Standard.Testing (' '    assertTrue' ');' 'import Acme.Raw (' '    seven' ');' '' 'module body Acme.Raw.Test is' '    function testSeven(): Unit is' '        assertTrue(seven() = 7, "seven");' '        return nil;' '    end;' 'end module body.' > src/Raw.test.hiq
run "guard of undeclared capabilities" 4 "$H" guard src/Raw.hih,src/Raw.hiq
has "unsafe is undeclared" "undeclared: Acme.Raw uses unsafe"
has "embed is undeclared" "undeclared: Acme.Raw uses embed"
printf 'capabilities = ["unsafe", "embed"]\n' >> hilde.toml
run "guard of declared capabilities" 0 "$H" guard src/Raw.hih,src/Raw.hiq
has "both declared and used" "Acme.Raw .*declares unsafe embed; uses unsafe embed"
printf 'capabilities = ["ffi"]\n' > "$W/bad.toml"
setver v1.0.0
$G init -q . && $G add -A && $G commit -q -m one && $G tag v1.0.0 || exit 9
printf 'capabilities = ["unsafe", "embed", "foreign"]\n' > "$W/caps"
grep -v '^capabilities' hilde.toml > hilde.toml.new && mv hilde.toml.new hilde.toml
cat "$W/caps" >> hilde.toml
setver v1.1.0
$G commit -q -am more && $G tag v1.1.0 || exit 9
cd "$W" || exit 9
run "new Acme.UsesRaw" 0 "$H" new Acme.UsesRaw
cd "$W/Acme.UsesRaw" || exit 9
run "get Acme.Raw v1.0.0" 0 "$H" get Acme.Raw@v1.0.0 --git="$W/Acme.Raw"
run "guard of a package whose dependency declares its capabilities" 0 "$H" guard src/UsesRaw.hih,src/UsesRaw.hiq
has "the dependency is held to its declaration" "Acme.Raw .*declares unsafe embed"
run "update to a release that declares a capability more" 0 "$H" update
has "a capability more is taken back" "Acme.Raw v1.0.0 -> v1.1.0, taken back"
grep -q "^Acme.Raw v1.0.0 " hilde.sum && holds "hilde.sum keeps Acme.Raw v1.0.0" || fails "hilde.sum: $(cat hilde.sum)"
cd "$W/Acme.Raw" || exit 9
cp "$W/bad.toml" "$W/bad-caps"
grep -v '^capabilities' hilde.toml > hilde.toml.new && mv hilde.toml.new hilde.toml
cat "$W/bad-caps" >> hilde.toml
run "a capability that is none" 1 "$H" verify
has "a capability that is none is H1505" "H1505"

# targets: a module that reaches Standard.Signify cannot be built for wasm.
cd "$W" || exit 9
run "new Acme.Keys" 0 "$H" new Acme.Keys
cd "$W/Acme.Keys" || exit 9
printf '%s\n' 'import Standard.Signify (' '    publicKeyLineLength' ');' 'module body Acme.Keys is' '    function double(n: Int64): Int64 is' '        let size: Index := publicKeyLineLength();' '        return n * 2;' '    end;' 'end module body.' > src/Keys.hiq
{ printf 'targets = ["linux", "wasm"]\n\n'; cat hilde.toml; } > hilde.toml.new && mv hilde.toml.new hilde.toml
run "verify of a target a module leaves out" 1 "$H" verify
has "a target left out is H1523" "H1523"
has "the module that leaves it out is named" "the target wasm.*Standard.Signify"
{ printf 'targets = ["linux"]\n\n'; grep -v '^targets' hilde.toml; } > hilde.toml.new && mv hilde.toml.new hilde.toml
run "verify of targets every module allows" 0 "$H" verify

# install: a programme and a library into staging trees.
cd "$W/Tool" || exit 9
run "install without --destdir" 1 "$H" install
has "no staging tree is H1505" "H1505"
run "install the programme" 0 "$H" install --prefix=/usr/local --destdir="$W/stage-tool"
[ -x "$W/stage-tool/usr/local/bin/tool" ] && holds "the programme is in bin" || fails "no stage-tool/usr/local/bin/tool"
run "the installed programme runs" 0 "$W/stage-tool/usr/local/bin/tool"
has "and prints 42" "^42$"
[ -f "$W/stage-tool/usr/local/share/doc/tool/LICENSE" ] && holds "the licence is in share/doc" || fails "no licence in share/doc/tool"
cd "$W/Acme.Text" || exit 9
run "install the library" 0 "$H" install --prefix=/usr --destdir="$W/stage-text"
[ -f "$W/stage-text/usr/share/hilde/Acme.Text/src/Text.hih" ] && holds "the sources are in share/hilde" || fails "no sources in share/hilde"
[ -f "$W/stage-text/usr/share/man/man3/Acme.Text.3" ] && holds "the manual page is in share/man/man3" || fails "no man3 page"
run "install the library below /usr/local" 0 "$H" install --prefix=/usr/local --destdir="$W/stage-local"
case $(uname -s) in
OpenBSD) want=usr/local/man/man3/Acme.Text.3;;
*) want=usr/local/share/man/man3/Acme.Text.3;;
esac
[ -f "$W/stage-local/$want" ] && holds "below /usr/local the manual page is in $want" || fails "no $want"
[ ! -e "$W/stage-text/usr/share/hilde/Acme.Text/.git" ] && holds "no .git in the installed tree" || fails ".git installed"
cd "$W/Acme.App" || exit 9

# json.
run "verify --json" 0 "$H" verify --json
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d["command"]=="verify" and d["ok"] is True and d["count"]==2 and d["problems"]==[] else 1)' "$L" && holds "the JSON of verify" || fails "the JSON of verify"
run "a missing tag --json" 1 "$H" get Acme.Text@v1.5.0 --json
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); p=d["problems"]; sys.exit(0 if d["ok"] is False and len(p)==1 and p[0]["code"]=="H1509" and p[0]["suggestion"] else 1)' "$L" && holds "the JSON of a refusal" || fails "the JSON of a refusal"

# The manual page of every module of the standard library, through hilde doc,
# with no message of mandoc -T lint.
cd "$W" || exit 9
mkdir -p "$W/man" || exit 9
pages=0; lint=0
for m in $(sed -n 's/^module \([A-Za-z0-9.]*\) is$/\1/p' "$(dirname "$H")"/standard/src/*.hih "$(dirname "$H")"/standard/src/*/*.hih | sort -u); do
	"$H" doc --man "$m" > "$W/man/$m.3" 2> "$L" || { fails "hilde doc --man $m"; continue; }
	pages=$((pages + 1))
	mandoc -T lint -I os=Hilde "$W/man/$m.3" > "$W/man/$m.lint" 2>&1
	k=$(grep -c "" "$W/man/$m.lint")
	lint=$((lint + k))
done
[ "$pages" -gt 100 ] && [ "$lint" = 0 ] && holds "mandoc -T lint: 0 messages for $pages pages of the standard library" || fails "mandoc -T lint: $lint messages for $pages pages of the standard library"

cd "$W/.." || exit 9
rm -r "$W"
test -e "$W" && fails "the work directory is left" || holds "the work directory is removed"
echo "check-pkg good=$good bad=$bad"
[ "$bad" = 0 ] && [ "$good" -gt 0 ] || exit 1
exit 0
