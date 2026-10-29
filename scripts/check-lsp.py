#!/usr/bin/env python3
# Part of the Hilde project, under the Apache License v2.0 with LLVM
# Exceptions.  See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""A session with hilde lsp, from the root of a tree with ./hilde built.

A document is opened with a type error, then changed to compile; the
diagnostics of both are checked, then hover and go to definition on a
function of the standard library, whose contract the hover must show, and
on one of the document, then shutdown and exit.  Every step prints one line
with ok or FAIL; the last line counts them.  Exit 0 when all hold, 1 when
one does not, 9 when the server could not be started.

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
    send(p, {"jsonrpc": "2.0", "id": 6, "method": "shutdown"})
    s = until(p, lambda m: m.get("id") == 6)
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
