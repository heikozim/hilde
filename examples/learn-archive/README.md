# learn-archive

## What it shows

Archives and compression, in memory.

- `Standard.Gzip` packs bytes with DEFLATE and checks them with CRC-32 when
  it unpacks them.
- `Standard.Archive` writes a tar archive compressed with gzip and reads it
  back entry by entry, within a budget that limits what an archive from
  outside may ask for.

Nothing is written to disk.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-archive
make
./main
```

## What comes out

```
CRC-32 of the text: 3996952829
the text: 48 bytes, packed: 29
unpacked: hilde hilde hilde hilde hilde hilde hilde hilde
unpacking plain text: not gzip
entries added: true
entries read: 3
  directory site, 0 bytes
  file site/index.html, 13 bytes
    <p>hello</p>
  file site/robots.txt, 14 bytes
    User-agent: *
read as plain tar: refused
```
