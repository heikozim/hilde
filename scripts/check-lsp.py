#!/usr/bin/env python3
# Part of the Hilde project, under the Apache License v2.0 with LLVM
# Exceptions.  See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""A session with hilde lsp, from the root of a tree with ./hilde built.

A document is opened with a type error, then changed to compile; the
diagnostics of both are checked, then hover and go to definition on a
function of the standard library, whose contract the hover must show, and
on one of the document, then a second, unformatted document is opened and
its formatting is asked for, whose answer must be the text of hilde fmt,
and a document the formatter refuses is asked for its formatting and must
get no edit, then a document without an error and one whose error carries
only a hint are asked for their code actions and must get none, the second
with its diagnostics unchanged by the request, and one whose error carries
the one fix must get it as one quickfix, the reserved word of H0008 and the
parentheses of H0009 over 2 * 3 + 1; hilde check --fix writes those
parentheses into the file, which then checks clean, and leaves the hint of
1 + 2 * 3 alone; then shutdown and exit.
Every step prints one line with ok or FAIL; the last line counts them.  Exit
0 when all hold, 1 when one does not, 9 when the server could not be started.

    python3 scripts/check-lsp.py
"""
import json
import os
import shutil
import subprocess
import sys

WORK = os.path.join("_build", "check-lsp")
BAD = """import Standard.Htmx (redirectHeader);

module body Doc is
    function count(): Int32 is
        return true;
    end;
end module body.
"""
GOOD = """import Standard.Htmx (redirectHeader);
import Standard.String (String, destroyString);

module body Doc is
    function count(): Int32 is
        return 1;
    end;

    function main(): ExitCode is
        let line: String := redirectHeader("/done");
        destroyString(line);
        printLn(count());
        return ExitSuccess();
    end;
end module body.
"""
UNFORMATTED = """module body Plain is
  function count():Int32 is
        return 1;
      end;
end module body.
"""
REFUSED = """module body Broken is
  function count(): Int32 is
    return "unterminated;
  end;
end module body.
"""
HINTED = """module body Guarded is
    function count(): Int32 is
        let total: Int32 := 1 + 2 * 3;
        printLn(total);
        return 0;
    end;
end module body.
"""
RESERVED = """module body Ranged is
    function first(from: Index): Index is
        return 1;
    end;
end module body.
"""
GROUPED = """module body Grouped is
    function count(): Int32 is
        let total: Int32 := 2 * 3 + 1;
        return total;
    end;
end module body.
"""
GROUPED_FIXED = GROUPED.replace("2 * 3 + 1", "(2 * 3) + 1")


def send(p, msg):
    body = json.dumps(msg).encode()
    p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
    p.stdin.flush()


def receive(p):
    length = None
    while True:
        line = p.stdout.readline()
        if not line:
            return None
        line = line.strip()
        if not line:
            if length is not None:
                break
            continue
        if line.lower().startswith(b"content-length:"):
            length = int(line.split(b":", 1)[1])
    return json.loads(p.stdout.read(length))


def until(p, pred):
    while True:
        m = receive(p)
        if m is None or pred(m):
            return m


def main():
    try:
        return session()
    except (BrokenPipeError, OSError, ValueError) as e:
        print("FAIL the server ended the session: %s" % e)
        print("check-lsp steps=1 ok=0 failed=1")
        return 1


def session():
    if not os.access("./hilde", os.X_OK):
        print("ABORT: ./hilde is not there -- nothing ran")
        return 9
    if os.path.exists(WORK):
        shutil.rmtree(WORK)
    os.makedirs(WORK)
    doc = os.path.abspath(os.path.join(WORK, "Doc.hiq"))
    with open(doc, "w") as f:
        f.write(BAD)
    uri = "file://" + doc
    try:
        p = subprocess.Popen(["./hilde", "lsp"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    except OSError as e:
        print("ABORT: %s -- nothing ran" % e)
        return 9
    results = []

    def check(name, ok, detail=""):
        results.append(ok)
        print("%s %s%s" % ("ok  " if ok else "FAIL", name, (": " + detail) if detail and not ok else ""))

    send(p, {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"capabilities": {}}})
    r = until(p, lambda m: m.get("id") == 1)
    caps = (r or {}).get("result", {}).get("capabilities", {})
    check("initialize: hover and definition", caps.get("hoverProvider") is True and caps.get("definitionProvider") is True, str(r))
    check("initialize: formatting", caps.get("documentFormattingProvider") is True, str(caps))
    check("initialize: code actions", caps.get("codeActionProvider") is True, str(caps))
    send(p, {"jsonrpc": "2.0", "method": "initialized", "params": {}})
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didOpen",
             "params": {"textDocument": {"uri": uri, "languageId": "hilde", "version": 1, "text": BAD}}})
    d = until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    diags = (d or {}).get("params", {}).get("diagnostics", [])
    check("didOpen: one diagnostic H3060 on line 4",
          len(diags) == 1 and diags[0].get("code") == "H3060" and diags[0]["range"]["start"]["line"] == 4, str(d))
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didChange",
             "params": {"textDocument": {"uri": uri, "version": 2}, "contentChanges": [{"text": GOOD}]}})
    d = until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    check("didChange: the error is gone", d is not None and d["params"]["diagnostics"] == [], str(d))
    # redirectHeader on line 9, character 30.
    send(p, {"jsonrpc": "2.0", "id": 2, "method": "textDocument/hover",
             "params": {"textDocument": {"uri": uri}, "position": {"line": 9, "character": 30}}})
    h = until(p, lambda m: m.get("id") == 2)
    value = ((h or {}).get("result") or {}).get("contents", {}).get("value", "")
    check("hover: type and contract of redirectHeader",
          "function redirectHeader(url: Span[Nat8, R]): String" in value
          and "requires (spanLength(url) > 0) and isFieldValue(url)" in value, value[:300])
    send(p, {"jsonrpc": "2.0", "id": 3, "method": "textDocument/definition",
             "params": {"textDocument": {"uri": uri}, "position": {"line": 9, "character": 30}}})
    g = until(p, lambda m: m.get("id") == 3)
    loc = (g or {}).get("result") or {}
    check("definition: in standard/src/Htmx.hih",
          loc.get("uri", "").endswith("/standard/src/Htmx.hih") and loc.get("range", {}).get("start", {}).get("line", -1) > 0, str(g))
    # count on line 11, character 16.
    send(p, {"jsonrpc": "2.0", "id": 4, "method": "textDocument/hover",
             "params": {"textDocument": {"uri": uri}, "position": {"line": 11, "character": 17}}})
    h = until(p, lambda m: m.get("id") == 4)
    value = ((h or {}).get("result") or {}).get("contents", {}).get("value", "")
    check("hover: a function of the document", "function count(): Int32" in value, value[:200])
    send(p, {"jsonrpc": "2.0", "id": 5, "method": "textDocument/hover",
             "params": {"textDocument": {"uri": uri}, "position": {"line": 2, "character": 0}}})
    h = until(p, lambda m: m.get("id") == 5)
    check("hover: nothing on a blank line", h is not None and h.get("result") is None, str(h))
    # A second, unformatted document, opened and then formatted.
    plain = os.path.abspath(os.path.join(WORK, "Plain.hiq"))
    with open(plain, "w") as f:
        f.write(UNFORMATTED)
    plain_uri = "file://" + plain
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didOpen",
             "params": {"textDocument": {"uri": plain_uri, "languageId": "hilde", "version": 1, "text": UNFORMATTED}}})
    until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    copy = os.path.join(WORK, "Plain.fmt.hiq")
    with open(copy, "w") as f:
        f.write(UNFORMATTED)
    expected = subprocess.run(["./hilde", "fmt", copy], capture_output=True, text=True)
    with open(copy) as f:
        formatted = f.read()
    check("fmt: the reference text is not the source", expected.returncode == 0 and formatted != UNFORMATTED,
          expected.stderr[:200])
    send(p, {"jsonrpc": "2.0", "id": 6, "method": "textDocument/formatting",
             "params": {"textDocument": {"uri": plain_uri}, "options": {"tabSize": 2, "insertSpaces": True}}})
    e = until(p, lambda m: m.get("id") == 6)
    edits = (e or {}).get("result")
    check("formatting: one edit over the whole document",
          isinstance(edits, list) and len(edits) == 1
          and edits[0]["range"]["start"] == {"line": 0, "character": 0}
          and edits[0]["range"]["end"] == {"line": UNFORMATTED.count("\n"), "character": 0}, str(e)[:300])
    check("formatting: the text of hilde fmt",
          isinstance(edits, list) and len(edits) == 1 and edits[0].get("newText") == formatted,
          repr(edits[0].get("newText") if isinstance(edits, list) and edits else edits)[:300])
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didClose",
             "params": {"textDocument": {"uri": plain_uri}}})
    # A document the formatter refuses, because a string runs to its end.
    broken = os.path.abspath(os.path.join(WORK, "Broken.hiq"))
    with open(broken, "w") as f:
        f.write(REFUSED)
    broken_uri = "file://" + broken
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didOpen",
             "params": {"textDocument": {"uri": broken_uri, "languageId": "hilde", "version": 1, "text": REFUSED}}})
    until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    send(p, {"jsonrpc": "2.0", "id": 7, "method": "textDocument/formatting",
             "params": {"textDocument": {"uri": broken_uri}, "options": {}}})
    e = until(p, lambda m: m.get("id") == 7)
    check("formatting: a refused document gets no edit",
          e is not None and e.get("result") == [] and "error" not in e, str(e)[:300])
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didClose",
             "params": {"textDocument": {"uri": broken_uri}}})
    # Code actions.  The document that compiles holds no error, so it gets
    # none; a document whose error carries only a hint gets none either,
    # because the server answers a quickfix only for the one fix an error
    # marks as machine applicable.
    send(p, {"jsonrpc": "2.0", "id": 8, "method": "textDocument/codeAction",
             "params": {"textDocument": {"uri": uri},
                        "range": {"start": {"line": 0, "character": 0},
                                  "end": {"line": 0, "character": 0}},
                        "context": {"diagnostics": []}}})
    e = until(p, lambda m: m.get("id") == 8)
    check("codeAction: a document without an error gets none",
          e is not None and e.get("result") == [] and "error" not in e, str(e)[:300])
    hinted = os.path.abspath(os.path.join(WORK, "Hinted.hiq"))
    with open(hinted, "w") as f:
        f.write(HINTED)
    hinted_uri = "file://" + hinted
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didOpen",
             "params": {"textDocument": {"uri": hinted_uri, "languageId": "hilde", "version": 1, "text": HINTED}}})
    d = until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    diags = (d or {}).get("params", {}).get("diagnostics", [])
    check("didOpen: one diagnostic H0009 on the mixed operators",
          len(diags) == 1 and diags[0].get("code") == "H0009" and diags[0]["range"]["start"]["line"] == 2, str(d))
    where = diags[0]["range"] if diags else {"start": {"line": 0, "character": 0},
                                             "end": {"line": 0, "character": 0}}
    send(p, {"jsonrpc": "2.0", "id": 9, "method": "textDocument/codeAction",
             "params": {"textDocument": {"uri": hinted_uri}, "range": where,
                        "context": {"diagnostics": diags}}})
    e = until(p, lambda m: m.get("id") == 9)
    check("codeAction: an error whose fix is only a hint gets none",
          e is not None and e.get("result") == [] and "error" not in e, str(e)[:300])
    # A request for code actions leaves the document as it is: the
    # diagnostics after it are the ones the open published.
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didSave",
             "params": {"textDocument": {"uri": hinted_uri}}})
    d = until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    check("codeAction: the request leaves the diagnostics unchanged",
          d is not None and d["params"]["diagnostics"] == diags, str(d)[:300])
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didClose",
             "params": {"textDocument": {"uri": hinted_uri}}})
    # The positive side: a reserved word that stands once, as a parameter,
    # carries its free name as the one fix, and the server answers it as one
    # quickfix that writes the free name over the word.
    reserved = os.path.abspath(os.path.join(WORK, "Ranged.hiq"))
    with open(reserved, "w") as f:
        f.write(RESERVED)
    reserved_uri = "file://" + reserved
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didOpen",
             "params": {"textDocument": {"uri": reserved_uri, "languageId": "hilde", "version": 1, "text": RESERVED}}})
    d = until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    diags = (d or {}).get("params", {}).get("diagnostics", [])
    check("didOpen: one diagnostic H0008 on the reserved word",
          len(diags) == 1 and diags[0].get("code") == "H0008" and diags[0]["range"]["start"]["line"] == 1, str(d))
    where = diags[0]["range"] if diags else {"start": {"line": 0, "character": 0},
                                             "end": {"line": 0, "character": 0}}
    send(p, {"jsonrpc": "2.0", "id": 11, "method": "textDocument/codeAction",
             "params": {"textDocument": {"uri": reserved_uri}, "range": where,
                        "context": {"diagnostics": diags}}})
    e = until(p, lambda m: m.get("id") == 11)
    actions = (e or {}).get("result") or []
    edits = actions[0].get("edit", {}).get("changes", {}).get(reserved_uri, []) if len(actions) == 1 else []
    check("codeAction: the one fix of an error gets one quickfix",
          len(actions) == 1 and actions[0].get("kind") == "quickfix"
          and len(edits) == 1 and edits[0].get("newText") == "since"
          and edits[0]["range"] == where, str(e)[:300])
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didClose",
             "params": {"textDocument": {"uri": reserved_uri}}})
    # H0009 where the operator before binds tighter, 2 * 3 + 1: the
    # parentheses around 2 * 3 are the one fix, an edit that inserts only
    # the two parentheses, and the server answers it as one quickfix.
    grouped = os.path.abspath(os.path.join(WORK, "Grouped.hiq"))
    with open(grouped, "w") as f:
        f.write(GROUPED)
    grouped_uri = "file://" + grouped
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didOpen",
             "params": {"textDocument": {"uri": grouped_uri, "languageId": "hilde", "version": 1, "text": GROUPED}}})
    d = until(p, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    diags = (d or {}).get("params", {}).get("diagnostics", [])
    check("didOpen: one diagnostic H0009 on 2 * 3 + 1",
          len(diags) == 1 and diags[0].get("code") == "H0009" and diags[0]["range"]["start"]["line"] == 2, str(d))
    where = diags[0]["range"] if diags else {"start": {"line": 0, "character": 0},
                                             "end": {"line": 0, "character": 0}}
    send(p, {"jsonrpc": "2.0", "id": 12, "method": "textDocument/codeAction",
             "params": {"textDocument": {"uri": grouped_uri}, "range": where,
                        "context": {"diagnostics": diags}}})
    e = until(p, lambda m: m.get("id") == 12)
    actions = (e or {}).get("result") or []
    edits = actions[0].get("edit", {}).get("changes", {}).get(grouped_uri, []) if len(actions) == 1 else []
    column = GROUPED.splitlines()[2].index("2 * 3")
    check("codeAction: the parentheses of 2 * 3 + 1 are one quickfix over 2 * 3",
          len(actions) == 1 and actions[0].get("kind") == "quickfix"
          and len(edits) == 1 and edits[0].get("newText") == "(2 * 3)"
          and edits[0]["range"] == {"start": {"line": 2, "character": column},
                                    "end": {"line": 2, "character": column + 5}}, str(e)[:300])
    send(p, {"jsonrpc": "2.0", "method": "textDocument/didClose",
             "params": {"textDocument": {"uri": grouped_uri}}})
    # hilde check --fix writes the same parentheses into the file and the
    # module then checks without an error; the hint of 1 + 2 * 3 is left
    # as it stands, and the check still fails.
    fixed = subprocess.run(["./hilde", "check", grouped, "--fix"], capture_output=True)
    with open(grouped) as f:
        after = f.read()
    again = subprocess.run(["./hilde", "check", grouped], capture_output=True)
    check("check --fix writes (2 * 3) + 1 and the module then checks clean",
          after == GROUPED_FIXED and again.returncode == 0,
          "fix exit %d, check exit %d, text %r" % (fixed.returncode, again.returncode, after[:200]))
    with open(hinted, "w") as f:
        f.write(HINTED)
    left = subprocess.run(["./hilde", "check", hinted, "--fix"], capture_output=True)
    with open(hinted) as f:
        kept = f.read()
    check("check --fix leaves 1 + 2 * 3 as it stands and fails",
          kept == HINTED and left.returncode != 0, "exit %d" % left.returncode)
    send(p, {"jsonrpc": "2.0", "id": 10, "method": "shutdown"})
    s = until(p, lambda m: m.get("id") == 10)
    check("shutdown", s is not None and "result" in s and s["result"] is None, str(s))
    send(p, {"jsonrpc": "2.0", "method": "exit"})
    try:
        code = p.wait(timeout=10)
    except subprocess.TimeoutExpired:
        p.kill()
        code = None
    check("exit 0 after shutdown", code == 0, str(code))
    shutil.rmtree(WORK)
    good = sum(1 for r in results if r)
    print("check-lsp steps=%d ok=%d failed=%d" % (len(results), good, len(results) - good))
    return 0 if good == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
