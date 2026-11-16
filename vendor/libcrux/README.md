# libcrux ML-DSA, as OpenSSH carries it

`libcrux_internal.h` is the C of libcrux (Cryspen, MIT licence, `LICENSE-MIT`), generated from Rust whose
correctness and secret independence are proved with hax and F*. It holds ML-KEM-768 and ML-DSA-44, -65 and -87
of FIPS 203 and FIPS 204 in portable C, with SHA-3 and SHAKE of its own and no assembler. Hilde uses its ML-DSA.

The file is taken byte for byte from OpenSSH, which extracts it with `mlkem_mldsa.sh` and builds it into ssh:

| What | Value |
|---|---|
| Repository | https://github.com/openssh/openssh-portable |
| Commit of openssh-portable | 26b1363c7cbf5d01c730f45fc0b4abc5686beaf7 (2026-10-18) |
| File | `libcrux_internal.h`, `$OpenBSD: libcrux_internal.h,v 1.1 2026/06/14 03:59:34 djm Exp $` |
| libcrux revision named in the file | c46481ce3cd1cc8315e90db114581d8c992c3d7d |
| sha256 of the file | 4e5d912e00ac0f585f29d7735fc547d0b7d2ceb134129c1074d3bc4892f79290 |

`scripts/libcrux/fetch.sh` fetches the file again from that commit and holds it to the sha256 above;
`scripts/libcrux/check.sh`, which the checks run, holds the file here to the same sha256 and revision without a
network. The file is not changed here: Hilde's own C around it is `lib/mldsa.c`, after the pattern of OpenSSH's
`libcrux-mlkem-mldsa.c` (ISC licence, `LICENSE-ISC`). Being a copy kept byte for byte, the file is exempt from
the repository's rules on ASCII and comments; nothing else under `vendor/` is.

This is a stopgap. Once LibreSSL offers ML-DSA natively, Hilde's backend moves to libcrypto and this directory
is removed.
