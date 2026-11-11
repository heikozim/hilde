# learn-files

## What it shows

Files and their names.

- `Standard.Path` takes a path apart and puts one together.
- `Standard.AtomicFile` writes a file so that a reader sees the old
  content or the new one, never half of it.
- `Standard.FileHelpers` copies files and measures a directory.
- `Standard.Watch` sees a file change.

Everything the programme makes it removes again, so its directory holds
afterwards what it held before.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-files
make
./main
```

## What comes out

```
base name: index.html
directory: /srv/www/site
extension: html
joined: /srv/www/notes.txt
absolute: false
notes.txt holds: first line
a backup was made: true
notes.txt holds: second line
notes.txt.bak holds: first line
the same content again: unchanged
the directory of copies: 12
the watch saw a change: true
all removed: true
```
