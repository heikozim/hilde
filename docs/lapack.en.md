# The BLIS and LAPACK backend

Mirco, the science layer of Hilde, computes its matrix work in pure Hilde by default
(`Standard.ArrayCompute`).  This is the optional C backend:
BLIS provides the BLAS layer, and the LAPACK routines come from the C translation that OpenBLAS ships as
lapack-netlib and builds without a Fortran compiler.  Nothing in the standard library imports it, and nothing
Fortran is compiled: the backend is chosen by importing the binding module, and a programme then links
`libmircoblis`, the one static library the package MircoBlis builds.

## The package MircoBlis

The package stands in `mirco-blis/` and carries the C sources checked in under `c/`, declared with the
`[c-source]` table of its `hilde.toml`.  Nothing of it is Standard; a programme that imports
`Bindings.Lapack` (directly, or the safe module built on it once it exists) selects the backend and links the
library.  Every other programme builds and links exactly as before.

- `c/blis/` is BLIS 2.1, without the `blastest` suite and without a top-level `f2c`; the `f2c` beside the BLAS
  layer inside `frame` stays, for the BLAS interface is built from it.
- `c/lapack/` is the C translation of lapack-netlib in OpenBLAS 0.3.34: the 126 files listed in
  `c/lapack/FILES.txt` that the bound routines need.
- The licences travel with the package in `mirco-blis/licenses/`, byte for byte the files the sources carry,
  and `mirco-blis/NOTICE` records where each tree came from and the SHA-256 of the two upstream archives.

## Building the library

`tools/build-c.sh` builds both trees into one static library, `libmircoblis.a`, and writes the pkg-config file
that hands the compiler its flags:

```sh
sh mirco-blis/tools/build-c.sh
export PKG_CONFIG_PATH=$PWD/mirco-blis/_c/pkgconfig
```

- BLIS is built by its own configure for the family of the machine, static and single threaded; the LAPACK
  files are compiled with the C compiler alone, with no Fortran compiler and no Fortran runtime.
- The LAPACK routines are linked against the BLAS layer of BLIS, not against OpenBLAS's own BLAS.
- The build refuses to finish while one of the routines the bindings call is missing from the library, and it
  compiles the LAPACK files with the plain flags of the build, nothing silenced.
- When the build succeeds it runs the test of the bindings against the library it built
  (`mirco-blis/test/Routines.test.hiq`), which calls every bound routine and holds the answers against values
  computed by hand.  The build is set up so the checked-in sources in `c/` are never touched by configure or
  make; everything lands below `mirco-blis/_c/`.

## The bound routines

`Bindings.Lapack` (`docs/unsafe.md`) binds the routines the decompositions need, each one call, matrices in
column-major order, info written into the span the caller hands over:

| routine | gives |
| --- | --- |
| `dgesv` | the solution of a linear system (solve) |
| `dgetrf` | the LU factorization with partial pivoting |
| `dpotrf` | the Cholesky factorization |
| `dgeqrf`, `dorgqr` | the QR factorization and the orthogonal matrix Q |
| `dsyevd` | the symmetric eigenproblem |
| `dgesdd` | the singular value decomposition |
| `dgelsd` | the least squares solution with the rank |
| `dgemm` | the matrix product, the BLAS layer of BLIS |

The body of every binding holds each span to the size the routine touches before the call and gives -1000
without calling when a dimension is below 1 or a span is shorter; a work query (`lwork -1`) needs its one
element.  A work array of one element with `lwork -1` is the query of the best size.

## Licences and provenance

BLIS is BSD 3-Clause, the C translation of lapack-netlib carries the modified BSD licence of LAPACK beside
the BSD 3-Clause licence of OpenBLAS; all three stand in `mirco-blis/licenses/`.  The trees were taken over
from the reference import that fetched the two upstream archives on 2026-10-27 and held them against the
pinned SHA-256; `mirco-blis/c/README.md` tells the verification and `mirco-blis/tools/import-c.sh` re-imports
both trees fresh from the archives, holding them against the same pins.

## BLIS and LAPACK as system packages

For OpenBSD 8.0 the reference import measured (in the guest openbsd-hilde, 2026-10-27): there is no package
`blis` and no package `openblas`; the only lapack port is `lapack-3.12.1p0` of netlib, built from Fortran.
For FreeBSD nothing is measured yet.  The sources checked into the package are therefore the way on every
system: a system package cannot replace them where it does not exist, and one build keeps the results of the
backend alike.
