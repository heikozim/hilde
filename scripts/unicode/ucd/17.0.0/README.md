# The Unicode Character Database 17.0.0, the files Hilde's tables need

These files are the input of the four generators in `scripts/unicode`;
no generator reads a file outside this directory.

| file | first line of its header | read by |
|---|---|---|
| `UnicodeData.txt` | (the file has no header) | make-case-tables.py, make-property-tables.py, make-normalization-tables.py |
| `SpecialCasing.txt` | SpecialCasing-17.0.0.txt | make-case-tables.py |
| `CaseFolding.txt` | CaseFolding-17.0.0.txt | make-case-tables.py, make-property-tables.py |
| `Scripts.txt` | Scripts-17.0.0.txt | make-property-tables.py |
| `GraphemeBreakProperty.txt` | GraphemeBreakProperty-17.0.0.txt | make-grapheme-tables.py |
| `emoji-data.txt` | emoji-data.txt, Version: 17.0 | make-grapheme-tables.py |

## Where they come from

Copied byte for byte (`cmp` equal) from the package unicode-data of TeX
Live 2026 (`texmf-dist/tex/generic/unicode-data`).  `SHA256SUMS` holds the
SHA-256 of each file as copied; `scripts/check-unicode-data.py` holds
the files to it in the checks.  The files keep the bytes Unicode wrote,
not plain ASCII: their headers carry the copyright sign and
`emoji-data.txt` carries emoji in its comments.

## Licence

Each file's header reads "(C) 2025 Unicode, Inc." (with the copyright
and registered signs) and "For terms of use and license, see
https://www.unicode.org/terms_of_use.html".  The licence text those
terms name is not on any disk this work may read, and is not in this
directory yet: it is still to be taken in, together with `DerivedCoreProperties.txt` and
`CompositionExclusions.txt`, which the tables need as well.
