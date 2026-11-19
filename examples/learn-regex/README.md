# learn-regex

## What it shows

Hilde has two engines for regular expressions, and the module name says
which one works:

- `Standard.Regex` is written in Hilde and takes the syntax of RE2.  It
  runs in time proportional to the text.  It has no lookaround and no back
  references; a pattern written as a literal that it cannot take is
  refused by the compiler before the programme runs.
- `Standard.Pcre` calls the PCRE2 library and takes its larger syntax,
  lookahead among it, with a limit on the work one search may do.

The programme rewrites `name=number` into `number:name` with the same
pattern and the same rewrite in both engines, then finds a number
followed by ` px` with a lookahead that only PCRE2 has.

Then Unicode: `\p{Greek}+` finds the Greek letters in a text, `(?i)`
matches a small sharp s against the capital one, U+1E9E, by Unicode's
simple case folding, and `Standard.UnicodeProperties`, where
`Standard.Regex` reads its classes, gives the general category and the
script of one code point.  The source is plain ASCII, so the Greek and
German texts are written as the hexadecimal of their UTF-8.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-regex
make
./main
```

The PCRE2 library has to be installed.

## What comes out

```
Standard.Regex: 80:width 24:height depth=x
Standard.Pcre:  80:width 24:height depth=x
Standard.Pcre:  12
Standard.Regex: the Greek letters from byte 4 to 10
Standard.Regex: (?i) folds the sharp s: true
U+03B1: Ll Greek
```

`depth=x` stays as it is: `x` is not a number.  The Greek letters are
bytes 4 to 10, two bytes each.
