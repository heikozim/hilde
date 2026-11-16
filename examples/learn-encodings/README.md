# learn-encodings

## What it shows

Text in its encodings.

- `Standard.Base64` and `Standard.Text` turn bytes into Base64,
  hexadecimal and URL encoding and back.
- `Standard.Utf8` counts the code points of a text and checks that its
  bytes are UTF-8.
- `Standard.Unicode` changes case by the tables of Unicode, beyond ASCII.
- `Standard.Normalization` brings a text to a normal form: an e and a
  combining acute become the e with an acute in NFC.
- `Standard.Grapheme` counts the characters a reader sees: an e with a
  combining acute is one, and so is a flag of two regional indicators.

Every function that can meet bad input answers None; none of them stops
the programme.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-encodings
make
./main
```

## What comes out

```
base64 of Hilde: SGlsZGU=
and back: Hilde
base64 with a byte out of place: none
hex: 6f6b21
from hex: ok!
odd hex: none
url: a%20b%26c=d
back: a b&c=d
words: 3
joined with |: red|green|blue
trimmed: [spaced]
replaced: 1 two 1
parsed: -42
equal in constant time: true
bytes of cafe with an accent: 5
code points: 4
well-formed: true
upper case, as hex: 434146c389
upper case of the street: STRASSE
folded: strasse
the same as STRASSE without regard to case: true
e with a combining acute, in NFC as hex: c3a9
code points: 2
characters a reader sees: 1
regional indicators D and E, code points: 2
characters a reader sees: 1
```
