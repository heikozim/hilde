# learn-arguments

## What it shows

Reading a command line with `Standard.Arguments`, after the model of
clap's builder.  A command is declared first: its options, its positional
arguments and its subcommands.  Every declaration hands back a key, and
the programme asks for a value by its key, so a name misspelt in the
programme is a variable the compiler does not know.

- `backup` has two subcommands, `run` and `list`; `list` is also called
  `ls`.  `-v` or `--verbose` is declared once, global, and counted before
  and after the subcommand.
- `run` takes `--level`, a whole number from 1 to 9 with the default 6,
  `--mode`, one of `fast` and `safe`, the flag `--dry-run` and one or more
  sources.
- A line the command refuses gives an error value, never a stop: its
  message names the problem, suggests a word that is nearly right, and
  shows the usage line of the subcommand concerned.
- `run @backup.args c.txt` reads words from a file, as gcc does with @file: the
  programme writes the file `backup.args`, `expandArgumentFiles` puts its words where
  the word that names it stood, a quote groups (`"my notes.txt"`), and a file that is
  not there is an error with a message, never a stop.
- `help run` and `--version` give texts written from the declarations.

The programme builds its command lines itself, so that its output is the
same on every run.  At the end it counts the words it was started with:
none, when it is started as below.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-arguments
make
./main
```

## What comes out

```
command line: -v run -l 9 a.txt b.txt
  verbose: 1
  run, level 9
  mode: safe
  dry run: 0
  source: a.txt
  source: b.txt
command line: ls --json -v -v
  verbose: 2
  list, json: 1
command line: run --mode=fast -n notes.txt
  verbose: 0
  run, level 6
  mode: fast
  dry run: 1
  source: notes.txt
command line: run --mode saf a.txt
backup: saf is not allowed for --mode, which takes fast, safe, did you mean safe?
Usage: backup run [OPTIONS] <SOURCE>...
Try backup run --help for more information.
command line: run --level=12 a.txt
backup: 12 is out of range for --level, which takes 1 to 9
Usage: backup run [OPTIONS] <SOURCE>...
Try backup run --help for more information.
command line: copy a.txt
backup: unknown subcommand copy
Usage: backup [OPTIONS] [COMMAND]
Try backup --help for more information.
command line: run @backup.args c.txt
  verbose: 1
  run, level 3
  mode: safe
  dry run: 1
  source: my notes.txt
  source: c.txt
command line: run @missing.args
backup: cannot read the argument file missing.args
Usage: backup [OPTIONS] [COMMAND]
Try backup --help for more information.
command line: help run
Copy the sources.

Usage: backup run [OPTIONS] <SOURCE>...

Arguments:
  <SOURCE>...  What to copy

Options:
  -v, --verbose        Say more [repeatable]
  -l, --level <LEVEL>  How hard to compress [range: 1 to 9] [default: 6]
  -m, --mode <MODE>    How to copy [possible values: fast, safe] [default: safe]
  -n, --dry-run        Copy nothing
  -h, --help           Print help
  -V, --version        Print version
command line: --version
backup 1.0.0
words of this run: 0
```
