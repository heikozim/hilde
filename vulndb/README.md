# The vulnerability database of hilde guard

`hilde guard <module...> --vulndb=<path> --library-versions=<name>:<version>,...`
holds the C libraries a programme links against advisories in the OSV
format, and reports an advisory only when the programme reaches one of
the C functions it names.
The path is a file or a directory; in a directory every file ending in
`.json` is read, in the order of the names.  Nothing is fetched: the
check reads only what it is given.

| directory | what it holds |
|---|---|
| `osv/` | the advisories for the libraries of `docs/unsafe.md`; empty until the first real advisories are added |
| `fixtures/` | advisories made for the tests, each with `HILDE-FIXTURE` in its id and "not a real advisory" in its summary |

## An advisory

One OSV record, or a list of them, as in the fixtures:

- `id` and `summary`;
- `affected[].package.name`: the library as the programme links it, the
  name in `pragma Foreign_Library` -- `sqlite3`, `sqlcipher`, `crypto`,
  `tls`, `pcre2-8`, `argon2`, `z`, `pthread`;
- `affected[].ranges[].events`: `introduced` and `fixed` versions, numbers
  separated by dots, `"0"` for the first;
- `affected[].ecosystem_specific.imports[].symbols`: the C functions
  through which the vulnerability is reached, where Go's database keeps
  them for govulncheck.  An advisory that names none is counted and not
  reported.

A library's version is not read from the system: the programme's builder
gives it, as the one who knows what the programme is linked with.
