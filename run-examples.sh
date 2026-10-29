#!/usr/bin/env bash
# Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Hilde is derived from the Austral project and extends it substantially.
# Modified by Heiko Zimmermann, 2026.

set -euxo pipefail

dune build

# The lines below are queued, not run at once: every compile and example
# line goes into the queue of its example directory, and the queues run at
# the same time, HILDE_JOBS of them (all processors without it).  The lines
# of one directory run one after the other in one job, because they build,
# run and clean the same directory.  Each job works in a directory of its
# own under _build/run-examples, where testbin, actual.txt and expected.txt
# keep their names, so the trace of a job reads as when the lines ran one
# after the other; the logs are printed in the order of the directories'
# first lines.
R=$PWD
JOBS=${HILDE_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1)}
Q=$R/_build/run-examples
rm -rf "$Q"
mkdir -p "$Q"
: > "$Q/order"

function enqueue() {
    local key
    key=$(printf '%s' "$2" | tr '/' '_')
    if [ ! -e "$Q/$key.cmds" ]; then
        echo "$key" >> "$Q/order"
    fi
    printf '%q ' "$@" >> "$Q/$key.cmds"
    echo >> "$Q/$key.cmds"
}

function compile() {
    enqueue run_compile "$@"
}

function example() {
    enqueue run_example "$@"
}

function example_stops() {
    enqueue run_example_stops "$@"
}

function run_compile() {
    ./hilde compile \
        ./standard/src/Buffer.hih,./standard/src/Buffer.hiq \
        ./standard/src/String.hih,./standard/src/String.hiq \
        ./standard/src/StringBuilder.hih,./standard/src/StringBuilder.hiq \
        ./standard/src/IO/IO.hih,./standard/src/IO/IO.hiq \
        ./standard/src/Bindings/Terminal.hih,./standard/src/Bindings/Terminal.hiq \
        ./standard/src/IO/Terminal.hih,./standard/src/IO/Terminal.hiq \
        $1/$2.hih,$1/$2.hiq \
        --entrypoint=Example.$2:main --output="$J/testbin"

    cd "$J"
    if [ $# -eq 4 ]
    then
        echo -n -e $4 | ./testbin > actual.txt
    else
        ./testbin > actual.txt
    fi

    echo -n -e "$3" > expected.txt
    diff actual.txt expected.txt
    rm testbin
    rm actual.txt
    rm expected.txt
    cd "$R"
}

compile examples/ffi FFI "aHello, world!\n"
compile examples/fib Fibonacci ""
compile examples/generic-record GenericRecord ""
compile examples/generic-union GenericUnion ""
compile examples/haversine Haversine ""
compile examples/hello-world HelloWorld "Hello, world!\n"
compile examples/identity Identity ""
compile examples/memory Memory ""
compile examples/named-argument NamedArgument ""
compile examples/record Record ""
compile examples/union Union ""
compile examples/greet Greet "Hello, Santa!\n" "Santa"
# The examples of docs/learning-hilde.md.
compile examples/learn-linear LearnLinear "12\n12\n12\n"
compile examples/learn-borrow LearnBorrow "3\n"
compile examples/learn-errors LearnErrors "5\nodd on the way\n"
compile examples/learn-text LearnText "Hello, Hilde!\nlength: 13\n"

# The examples of the large language features and modules.
# Each is built by its own
# Makefile, which is the one place its module list stands; the programme
# runs in the example's directory, and its standard output is held against
# the text here; its standard error must be empty.  Where the systems
# differ, the fourth argument is the text on OpenBSD and the fifth the text
# on FreeBSD, which has the third where there is no fifth.  The example is
# cleaned after its run, and its directory must then hold exactly the names
# it held before: nothing is left behind.  scripts/check-examples.py
# reads these lines: first it holds each example's README to the texts
# here, then check-runtime.sh has it run the same programmes under the
# sanitizers and valgrind.
python3 scripts/check-examples.py readmes
MAKE_TOOL=make
command -v gmake > /dev/null 2>&1 && MAKE_TOOL=gmake

# The file named by HILDE_EXAMPLES_NOT_RUN lists the examples a gate does
# not run on its system, one per line, the directory and the reason.  Such
# an example is printed as NOT RUN with its reason and is not built.
function not_run() {
    [ -n "${HILDE_EXAMPLES_NOT_RUN:-}" ] || return 1
    local dir reason
    while read -r dir reason; do
        if [ "$dir" = "$1" ]; then
            echo "NOT RUN $1 $2 $reason"
            return 0
        fi
    done < "$HILDE_EXAMPLES_NOT_RUN"
    return 1
}

function run_example() {
    if not_run "$1" "$2"; then
        return 0
    fi
    local expected=$3
    if [ $# -ge 4 ] && [ "$(uname -s)" = OpenBSD ]; then
        expected=$4
    fi
    if [ $# -ge 5 ] && [ "$(uname -s)" = FreeBSD ]; then
        expected=$5
    fi
    if [ $# -eq 6 ] && [ "$(uname -s)" = Darwin ]; then
        expected=$6
    fi
    local before
    before=$(ls -A "$1")
    $MAKE_TOOL -C "$1" > /dev/null
    (cd "$1" && "./$2" > "$J/actual.txt" 2> "$J/actual-err.txt")
    cd "$J"
    echo -n -e "$expected" > expected.txt
    diff actual.txt expected.txt
    diff actual-err.txt /dev/null
    cd "$R"
    $MAKE_TOOL -C "$1" clean > /dev/null
    [ "$(ls -A "$1")" = "$before" ]
    cd "$J"
    rm actual.txt actual-err.txt expected.txt
    cd "$R"
}

# A programme that must stop: its exit status is not 0, and both of its
# outputs are held.
function run_example_stops() {
    if not_run "$1" "$2"; then
        return 0
    fi
    local before
    before=$(ls -A "$1")
    $MAKE_TOOL -C "$1" > /dev/null
    local rc=0
    (cd "$1" && "./$2" > "$J/actual.txt" 2> "$J/actual-err.txt") || rc=$?
    [ "$rc" -ne 0 ]
    cd "$J"
    echo -n -e "$3" > expected.txt
    echo -n -e "$4" > expected-err.txt
    diff actual.txt expected.txt
    diff actual-err.txt expected-err.txt
    cd "$R"
    $MAKE_TOOL -C "$1" clean > /dev/null
    [ "$(ls -A "$1")" = "$before" ]
    cd "$J"
    rm actual.txt actual-err.txt expected.txt expected-err.txt
    cd "$R"
}

example examples/learn-contracts main "150\n30\n30\n"
example_stops examples/learn-contracts broken "70\n" "Hilde: contract violated: the requires (amount > 0) and (amount <= balance(&account)) of Example.LearnContracts.withdraw (LearnContracts.hih:38) does not hold for the call at LearnContractsBroken.hiq:25; the caller is at fault\n"
example examples/learn-regex main "Standard.Regex: 80:width 24:height depth=x\nStandard.Pcre:  80:width 24:height depth=x\nStandard.Pcre:  12\nStandard.Regex: the Greek letters from byte 4 to 10\nStandard.Regex: (?i) folds the sharp s: true\nU+03B1: Ll Greek\n"
example examples/learn-jit main "the JIT is built in: true\nwarnings: machine code\n  12:01\n  12:03\nwith a callout: the interpreter, because Standard.Pcre: feature is not supported by the JIT compiler\n  Warning\n  FATAL\n"
example examples/learn-match main "a small letter\na capital letter\na capital letter\na digit\nanother character\na key that is not a character\nno time at all\na tick of 250 ms\n"
example examples/learn-tasks main "5239625\n36552125\n99114625\n192927125\n333833500\n338350\n"
example examples/learn-template main "Order for ANN\n1. apples, 6 of them\n2. pears, 2 of them\n3. plums, 12 of them (the last line)\nShip today.\n"
example examples/learn-sqlite main "migrations applied: 1\ninsert: 1 row\ninsert: 1 row\ninsert: 1 row\n1 buy bread\n2 call Ann\n3 water the plants\n"
example examples/learn-sqlite cipher "migrations applied: 1\ninserted: 1\n1 the code of the safe\nthe file starts with the plain SQLite header: false\nthe file removed: true\n"
example examples/learn-poller main "poller:      epoll\nclient wrote: true\nserver watched: true\nserver ready: 1\nserver readable: true\nserver read: hello\nserver wrote: true\nclient watched: true\nclient ready: 1\nclient readable: true\nclient read: world\nserver closed: true\nclient closed: true\nlistener closed: true\n" "poller:      kqueue\nclient wrote: true\nserver watched: true\nserver ready: 1\nserver readable: true\nserver read: hello\nserver wrote: true\nclient watched: true\nclient ready: 1\nclient readable: true\nclient read: world\nserver closed: true\nclient closed: true\nlistener closed: true\n" "poller:      kqueue\nclient wrote: true\nserver watched: true\nserver ready: 1\nserver readable: true\nserver read: hello\nserver wrote: true\nclient watched: true\nclient ready: 1\nclient readable: true\nclient read: world\nserver closed: true\nclient closed: true\nlistener closed: true\n" "poller:      kqueue\nclient wrote: true\nserver watched: true\nserver ready: 1\nserver readable: true\nserver read: hello\nserver wrote: true\nclient watched: true\nclient ready: 1\nclient readable: true\nclient read: world\nserver closed: true\nclient closed: true\nlistener closed: true\n"
example examples/learn-sandbox main "pledge applied: false\nunveil applied: false\npledge and unveil are OpenBSD's; this system has neither\n" "pledge applied: true\nunveil applied: true\nreading /etc/hosts: refused\n" "pledge applied: false\nunveil applied: false\ncapsicum applied: true\nreading /etc/hosts: refused\n" "pledge applied: false\nunveil applied: false\nseatbelt applied: true\nreading /etc/hosts: refused\n"
example examples/learn-graph main "fewest roads: Aachen Cologne Frankfurt\nfewest kilometres: Aachen Bonn Frankfurt, 265 km\n"
example examples/learn-password main "a new hash starts with: \$argon2id\$v=19\$m=65536,t=3,p=4\$\nthe right password: matches\na wrong password: does not match\na stored Argon2id hash: matches\nan old bcrypt hash: matches, store a new hash\na broken string: not a hash this module can read\n" "a new hash starts with: \$argon2id\$v=19\$m=65536,t=3,p=4\$\nthe right password: matches\na wrong password: does not match\na stored Argon2id hash: matches\nan old bcrypt hash: matches, store a new hash\na broken string: not a hash this module can read\n" "a new hash starts with: \$argon2id\$v=19\$m=65536,t=3,p=4\$\nthe right password: matches\na wrong password: does not match\na stored Argon2id hash: matches\nan old bcrypt hash: matches, store a new hash\na broken string: not a hash this module can read\n" "a new hash starts with: \$argon2id\$v=19\$m=65536,t=3,p=4\$\nthe right password: matches\na wrong password: does not match\na stored Argon2id hash: matches\nan old bcrypt hash: the check failed\na broken string: not a hash this module can read\n"
example examples/learn-map main "sorted: apple apple apple fig pear pear plum\nin order: true\npear: found at 4\nkiwi: missing, it would go at 4\nkinds of fruit: 4\napple 3\nfig 1\npear 2\nplum 1\n"
example examples/learn-hashmap main "different words: 5\n  the 4\n  cat 2\n  saw 2\n  dog 2\n  and 1\nremoved saw, counted 2\nafter the removal, the last entry in its place:\n  the 4\n  cat 2\n  and 1\n  dog 2\nbird: 0\n"
example examples/learn-toml main "title: example\nhost: 0.0.0.0\nport: 8080\ntls: true\nstarted: 2026-09-28T01:00:00Z\nroutes: 2\nfirst route: /\nits root: /var/www\nsecond route goes to: 127.0.0.1\non port: 9000\nthe second key of server: port\na key that is not there: (none)\nrefused: something defined twice at line 2, column 1\nrefused: a bad number at line 2, column 8\n"
example examples/learn-encodings main "base64 of Hilde: SGlsZGU=\nand back: Hilde\nbase64 with a byte out of place: none\nhex: 6f6b21\nfrom hex: ok!\nodd hex: none\nurl: a%20b%26c=d\nback: a b&c=d\nwords: 3\njoined with |: red|green|blue\ntrimmed: [spaced]\nreplaced: 1 two 1\nparsed: -42\nequal in constant time: true\nbytes of cafe with an accent: 5\ncode points: 4\nwell-formed: true\nupper case, as hex: 434146c389\nupper case of the street: STRASSE\nfolded: strasse\nthe same as STRASSE without regard to case: true\ne with a combining acute, in NFC as hex: c3a9\ncode points: 2\ncharacters a reader sees: 1\nregional indicators D and E, code points: 2\ncharacters a reader sees: 1\n"
example examples/learn-values main "in the box: 7\nswapped out: 7\ntaken out: 11\nthe smallest Int8: -128\nthe largest Nat16: 65535\n(1, 2) equals (1, 2): true\n(1, 2) equals (2, 1): false\nfailure: load the configuration: open: no file named server.toml\nsteps in the chain: 2\nas an HTTP status: 404\n"
example examples/learn-data main "lines of the order: 2\nsum: 7.30\nwith tax, rounded: 8.69\nas JSON: {\"lines\":[{\"name\":\"coffee\",\"price\":4.20},{\"name\":\"tea, green\",\"price\":3.10}],\"total\":7.30,\"items\":2}\nthe second line: tea, green\nlines in the JSON: 2\nname: Corner Cafe\nopen: true\n"
example examples/learn-time main "the wall clock runs: true\na monotonic clock: true\nin UTC: 2026-09-28 01:00:00\nthe weekday, 1 for Monday: 1\nas RFC 3339: 2026-09-28T01:00:00Z\nwith a clock two hours east: 2026-09-28T03:00:00+02:00\nread back, seconds since 1970: 1790557200\nand nanoseconds: 500000000\nFebruary 30 is refused\nin Berlin: 2026-09-28 03:00:00\noffset in seconds: 7200\nsummer time: true\nabbreviation: CEST\n02:30 on 2026-03-29: skipped, the clocks go from 02:00 to 03:00\n"
example examples/learn-files main "base name: index.html\ndirectory: /srv/www/site\nextension: html\njoined: /srv/www/notes.txt\nabsolute: false\nnotes.txt holds: first line\na backup was made: true\nnotes.txt holds: second line\nnotes.txt.bak holds: first line\nthe same content again: unchanged\nthe directory of copies: 12\nthe watch saw a change: true\nall removed: true\n"
example examples/learn-archive main "CRC-32 of the text: 3996952829\nthe text: 48 bytes, packed: 29\nunpacked: hilde hilde hilde hilde hilde hilde hilde hilde\nunpacking plain text: not gzip\nentries added: true\nentries read: 3\n  directory site, 0 bytes\n  file site/index.html, 13 bytes\n    <p>hello</p>\n  file site/robots.txt, 14 bytes\n    User-agent: *\nread as plain tar: refused\n"
example examples/learn-log main "as text: time=2026-09-28T01:00:00.000Z level=INFO msg=\"request served\" path=/index.html status=200 cached=false\nas JSON: {\"time\":\"2026-09-28T01:00:00.000Z\",\"level\":\"INFO\",\"msg\":\"request served\",\"path\":\"/index.html\",\"status\":200,\"cached\":false}\nthe log takes debug: false\nthe log takes errors: true\nan error written: true\nthe entry of a request written: true\nclosed: true\nthe log file removed: true\nsent USR1 to itself: true\nUSR1 taken: true\ntaken again: false\nwatch stopped: true\nopen files, the soft limit within the hard: true\nthe usage of the process was read\nthe system is up: true\n"
example examples/learn-http main "header lines: 4\nthe first name: Host\nHost: example.org\nthe connection is to be upgraded: true\nas a CGI variable: HTTP_CONTENT_TYPE\na name with a byte out of place: none\npairs in the block: 1\nits name: SCRIPT_NAME\nits value: /index.hiq\nthe record: 32 bytes, a multiple of eight\nkind 4, request 1, content 23 bytes, the whole record 32\nthe end of the request: 16 bytes\n"
example examples/learn-network main "198.51.100.20: IPv6 false, private or reserved true\n8.8.8.8: IPv6 false, private or reserved false\n2001:db8::1: IPv6 true, private or reserved true\n300.1.1.1: no address\nanonymised: 198.51.100.0\nin 198.51.100.0/24: true\nexample.org is a host name: true\nbad_name is a host name: false\nlocalhost is 127.0.0.1: true\nhttps://example.org:8443/news?page=2#top: host example.org, port 8443, path /news?page=2\nhttps://[2001:db8::1]/: host 2001:db8::1, port 443, path /\nhttp://example.org/: refused\nheader lines are well formed: true\na header line with a line feed in its value: false\nTLS to 127.0.0.1 port 9: refused\nann@example.org is an address: true\nthe message's first line: Date: Mon, 28 Sep 2026 01:00:00 +0000\nits bytes: 207\nSFTP 2: no such file\nSFTP 3: permission denied\nSFTP -1: the server went away\n"
example examples/learn-server main "connections accepted: 1\nwhat the web server got back, its CR LF printed as LF:\nStatus: 200 OK\nContent-Type: text/plain\n\nhello, name=hilde\nlistener closed: true\na TCP port was chosen: true\nTCP listener closed: true\n"
example examples/learn-session main "Set-Cookie: theme=dark; Path=/; Secure; HttpOnly; SameSite=Strict\nSet-Cookie: theme=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Strict\nrefused\na new session, its token has the form of one: true\nthe cookie came back with the token: true\nthe session holds: user=ann\nthe form's token is valid: true\nthe same form from another site is taken: false\nafter the login the token is a new one:\n  the old token: no session\n  the new token: the session holds: user=ann\nafter the logout: no session\n"
example examples/learn-context main "the background: not done\nthe top of the chain is cancelled\nboth workers stopped after doing some work: true\nthe request's context: cancelled\na context of 50 ms, waited on for 10 s: past its deadline\n"
example examples/learn-pki main "www.example.org,example.org is a list of names: true\nexample.org,IP:192.0.2.1 is a list of names: false\nthe CA: Example Root\na CA: true\nthe server certificate: www.example.org\nissued by: Example Root\nfor the names: www.example.org,example.org\na CA itself: false\nthe chain verifies for example.org\nfor example.net it does not verify\nan ES256 signature in a JWS: 86 characters\n"
example examples/learn-signatures main "the secret in base32: GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ\nand back: 12345678901234567890\nfor the app: otpauth://totp/Example:ann@example.org?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example&algorithm=SHA1&digits=6&period=30\nthe code at 59 seconds: 94287082\ntaken a step later with a window of one: true\ntaken two steps later: false\nES256: the token verifies: true\nRS256: the token verifies: true\nML-DSA-65: the token verifies: true\nclaims of an ID token at 1000: the token has expired\n"
example examples/learn-html main "start p\ntext Fish & chips\nstart a\ntext menu\nend a\nstart script\ntext steal()\nend script\nend p\nthe link goes to https://example.org/\ntext: Fish & chipsmenu\nshown: <p>Fish &amp; chips<a href=\"https://example.org/\" rel=\"nofollow noopener\">menu</a></p>\nan attack: <a rel=\"nofollow noopener\">x</a>\nwith pictures: <p><img src=\"/cat.png\" alt=\"a cat\"></p>\nescaped: &lt;b&gt;&amp;&quot;&#39;\n"
example examples/learn-search main "search: coffee\n  the query of FTS5: \"coffee\"\n  /about: A house for <mark>coffee</mark> since 1904.\n  /menu: <mark>Coffee</mark>, tea and cakes. The <mark>coffee</mark> is roasted &lt;here&gt;.\n  /hours: The cafe opens at seven; <mark>coffee</mark> from eight.\nsearch: Coffee cake*\n  the query of FTS5: \"Coffee\" \"cake\"*\n  /menu: <mark>Coffee</mark>, tea and <mark>cakes</mark>. The <mark>coffee</mark> is roasted &lt;here&gt;.\nsearch: title:menu OR about\n  the query of FTS5: \"title\" \"menu\" \"OR\" \"about\"\nsearch: ?!\n  no words\n  nothing searched\ndocuments with coffee: 3\nmenu removed: true\nsearch: cakes\n  the query of FTS5: \"cakes\"\n"
example examples/learn-formats main "QR version 2, 25 modules on a side\n#######..#..#.#.#.#######\nthe PNG reads back as 132 by 132 pixels\nentry id: 7\nits text: Fish & chips\na document type is refused at byte 0\nescaped: &lt;a &amp; b&gt;\nthe YAML as JSON: {\"server\":{\"port\":8443,\"hosts\":[\"a.example.org\",\"b.example.org\"]},\"version\":\"1.2.3\"}\nan anchor is refused in line 1\none word for the remote shell: 'a b; rm -rf /'\nthe remote shell would print: a b; rm -rf /\n\n"
example examples/learn-crypto main "SHA-256 of abc: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad\nHMAC-SHA256: f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8\nsealed: 30 bytes, the text and a tag of 16\nopened: attack at dawn\nopened under another header: refused\npublic key: d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a\nthe signature holds: true\nfor another message: false\nrandom bytes: 32\n"
example examples/learn-testing main "        Assert: 2024 is a leap year ok\n        Assert: 2026 is not ok\n        Assert: 1900, a century, is not ok\n        Assert: 2000, divided by 400, is ok\n        Assert: every case of the rule reached ok\n"
example examples/learn-typeclass main "square: 9\nrectangle: 20\npair: 25\npair: 40\n"
example examples/learn-embed main "the motto, read when the programme was compiled: Simple things done well.\nits bytes: 25\n6 times 7, computed by C: 42\na pointer has 32 or 64 bits: true\n"
example examples/learn-records main "an interval from 9 to 5: refused, the low end is above the high end\nhours in the day: 7\nthe evening stretched by two: true\nstretched past the largest number: false\nthe evening ends at: 21\nhours now: 9\n"
example examples/learn-library main "sum of the readings: 680\nreadings above 100: 3\nan empty span sums to: 0\n300 is a reading: no\n42 is a reading: yes\n"
example examples/learn-arguments main "command line: -v run -l 9 a.txt b.txt\n  verbose: 1\n  run, level 9\n  mode: safe\n  dry run: 0\n  source: a.txt\n  source: b.txt\ncommand line: ls --json -v -v\n  verbose: 2\n  list, json: 1\ncommand line: run --mode=fast -n notes.txt\n  verbose: 0\n  run, level 6\n  mode: fast\n  dry run: 1\n  source: notes.txt\ncommand line: run --mode saf a.txt\nbackup: saf is not allowed for --mode, which takes fast, safe, did you mean safe?\nUsage: backup run [OPTIONS] <SOURCE>...\nTry backup run --help for more information.\ncommand line: run --level=12 a.txt\nbackup: 12 is out of range for --level, which takes 1 to 9\nUsage: backup run [OPTIONS] <SOURCE>...\nTry backup run --help for more information.\ncommand line: copy a.txt\nbackup: unknown subcommand copy\nUsage: backup [OPTIONS] [COMMAND]\nTry backup --help for more information.\ncommand line: run @backup.args c.txt\n  verbose: 1\n  run, level 3\n  mode: safe\n  dry run: 1\n  source: my notes.txt\n  source: c.txt\ncommand line: run @missing.args\nbackup: cannot read the argument file missing.args\nUsage: backup [OPTIONS] [COMMAND]\nTry backup --help for more information.\ncommand line: help run\nCopy the sources.\n\nUsage: backup run [OPTIONS] <SOURCE>...\n\nArguments:\n  <SOURCE>...  What to copy\n\nOptions:\n  -v, --verbose        Say more [repeatable]\n  -l, --level <LEVEL>  How hard to compress [range: 1 to 9] [default: 6]\n  -m, --mode <MODE>    How to copy [possible values: fast, safe] [default: safe]\n  -n, --dry-run        Copy nothing\n  -h, --help           Print help\n  -V, --version        Print version\ncommand line: --version\nbackup 1.0.0\nwords of this run: 0\n"
example examples/learn-htmx main "-- GET /todos from a browser:\nStatus: 200 OK\nContent-Type: text/html; charset=utf-8\nVary: HX-Request\n\n<!doctype html>\n<html><head><title>Todo</title><script src=\"/htmx.min.js\"></script></head>\n<body><h1>Todo</h1>\n<ul id=\"todos\" hx-get=\"/todos\" hx-trigger=\"todo-added from:body\">\n<li>buy tea</li>\n</ul>\n</body></html>\n-- POST /todos from htmx:\nStatus: 201 Created\nContent-Type: text/html; charset=utf-8\nVary: HX-Request\nHX-Trigger: todo-added\n\n\n-- GET /todos from htmx, after todo-added:\nStatus: 200 OK\nContent-Type: text/html; charset=utf-8\nVary: HX-Request\n\n<li>buy tea</li>\n<li>call &lt;Ann&gt;</li>\n\n"

# The queues run now.  A job that fails ends with its status in its .rc
# file; every job runs, and the script fails after the logs are printed.
function run_group() {
    J=$Q/$1.d
    mkdir -p "$J"
    while IFS= read -r line; do
        eval "$line"
    done < "$Q/$1.cmds"
}
while IFS= read -r key; do
    while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do
        sleep 0.2
    done
    # Not in a list of && or ||: there bash ignores set -e, also in the
    # subshell, and a failed line would not end its job.
    { set +e; ( set -e; run_group "$key" ) > "$Q/$key.log" 2>&1; echo $? > "$Q/$key.rc"; } &
done < "$Q/order"
wait
examples_bad=0
while IFS= read -r key; do
    cat "$Q/$key.log"
    rc=$(cat "$Q/$key.rc" 2>/dev/null || echo 9)
    if [ "$rc" != 0 ]; then
        echo "run-examples: the lines of $key ended with $rc"
        examples_bad=1
    fi
done < "$Q/order"
rm -rf "$Q"
[ "$examples_bad" = 0 ]

# The warning count of this run, both yardsticks (decision of the project
# lead, 2026-09-21). It reports numbers and never fails the run: the counts
# are not a verdict yet.
# The count needs an explicit base for its run directory; it refuses to guess
# one, so that nothing lands in /tmp unasked. A caller may name another.
COUNT_BASE="${COUNT_BASE:-$PWD/.count-warnings}"
sh scripts/count-warnings.sh --base "$COUNT_BASE" || true
