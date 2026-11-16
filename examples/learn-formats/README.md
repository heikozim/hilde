# learn-formats

## What it shows

The formats a web framework reads and writes besides HTML and JSON, and
commands on other hosts.

- `Standard.Qr` makes the QR code of a URL at level medium, version 2 with
  25 modules on a side, and prints its top row; `qrToImage` draws it with
  four pixels a module and the quiet zone, and `Standard.Png` writes the
  image as a PNG file and reads it back.
- `Standard.Xml` reads a feed and finds an attribute and the text of an
  element, with the reference `&amp;` decoded; a document type, where an
  external entity would read a file, is refused at its first byte.
  `escapeXml` escapes text for XML.
- `Standard.Yaml` reads a configuration into JSON text; `1.2.3` is a
  string, not a number.  An anchor is refused with its line.
- `Standard.Ssh` quotes a word for the remote shell so that the space and
  the semicolon inside it stay text.  `/bin/sh` stands in for the remote
  shell, run by `runCommand` within five seconds, and prints the word as
  it was; ssh itself is not run, as the example must not need a host.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-formats
make
./main
```

## What comes out

```
QR version 2, 25 modules on a side
#######..#..#.#.#.#######
the PNG reads back as 132 by 132 pixels
entry id: 7
its text: Fish & chips
a document type is refused at byte 0
escaped: &lt;a &amp; b&gt;
the YAML as JSON: {"server":{"port":8443,"hosts":["a.example.org","b.example.org"]},"version":"1.2.3"}
an anchor is refused in line 1
one word for the remote shell: 'a b; rm -rf /'
the remote shell would print: a b; rm -rf /

```
