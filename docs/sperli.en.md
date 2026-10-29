# Sperli: ranks that send each other messages

Sperli (Simple Parallel Execution over Remote Links Interface) is the cluster layer of Hilde: a job of `n` ranks,
each a process on a listed host, that send and receive messages with a tag. It has the semantics of message passing
(rank, size, send and receive with a tag) and none of the interface of MPI. The bytes on the wire are in
`docs/sperli-protocol.md`; the refusals are the codes H1601 to H1625 of `docs/errors.en.md`. This page describes
point-to-point messages, the collectives, the checkpoints and the launcher; the C library follows the checkpoints.

## Security

Security is not an option and has no switch.

- Every connection is TLS 1.3 with a certificate on both sides. There is no plain mode, not on localhost.
- The launcher makes one CA, one Ed25519 certificate for each rank and one pair of keys of `Standard.CompositeSig`
  (ML-DSA-44 and Ed25519 together) for each job. No other cryptography is used.
- A rank shows a join token in its hello: the job, rank, size, incarnation, host and expiry, signed by the launcher.
  The peer checks the signature first, then the job, then the rank, size, incarnation and host, then the expiry.
- The hosts the environment variable `SPERLI_REFUSED_HOSTS` lists (separated by commas, blanks or line ends), the
  reserved names `host-a.invalid` and `host-b.invalid`, and any name below one of them, never run a rank, even if
  the host list names them. `--deny-hosts FILE` adds names; it never removes these.
- A frame header is checked before a byte of its payload is read. A payload is at most 16 MiB. A frame of an older
  incarnation is dropped.

## hilde run

```
hilde run -n 3 --hosts hosts.txt ./app arguments
```

`hilde run` is carried out by `hilde-launcher`, which `make` builds beside `hilde`. The programme is the path of an
executable that is the same on every host. The options:

| Option | Meaning |
|---|---|
| `-n N` | the number of ranks, 1 to 4096; required |
| `--hosts FILE` | the host list; required |
| `--deny-hosts FILE` | names to refuse besides those of `SPERLI_REFUSED_HOSTS` and the reserved ones, one a line |
| `--checkpoint-dir DIR`, `--checkpoint-every SECONDS`, `--restart-max K`, `--resume JOB` | `--checkpoint-dir` and `--restart-max` make the launcher start a failed job again; the other two are read and kept |

A host list has one host a line and an optional port: `node1`, `node2 47001`. A line that starts with `#` is a
comment. Rank `i` runs on line `i`; there must be at least `N` lines. A rank on `localhost` or an address of `127.`
is started directly and gets a free port; any other rank is started over ssh at port 62222 (`ssh -p 62222 -o
BatchMode=yes host program arguments`, each word quoted) and listens at the port of its line, or at 47000 and its
rank. The ranks' output is shown, rank by rank, when they have ended: `[rank 1] text`. The exit status is 0 when
every rank ended with 0.

## A rank

A rank reads its job from the first line of its standard input and joins:

```
let line: String := readLine(&!input);
case readJobText(asSpan(&line)) of
    when Right(right as job: Job) do
        case init(job) of
            when Right(right as opened: Comm) do
                var comm: Comm := opened;
                let sent: Int32 := send(&!comm, 1, 7, message);
                case recv(&!comm, 1, 7) of
                    when Right(right as text: String) do
                        destroyString(text);
                    when Left(left as code: Int32) do
                        skip;
                end case;
                finish(comm);
            when Left(left as code: Int32) do
                skip;
        end case;
    when Left(left as code: Int32) do
        skip;
end case;
```

- `send` consumes the buffer. It returns 0 or a code. Tags are 0 to 2147483647.
- `recv` returns the next message from a rank with a tag; a message of another tag from the same rank is kept for its
  own `recv`. Messages of one rank and one tag arrive in the order sent.
- `startSend` and `startRecv` give open operations, linear values that `finishSend` and `finishRecv` end.
- The collectives are the same calls in the same order on every rank (see below).
- A rank that waits for a message is lost to its peer after 5000 ms without a frame. `setSilence` raises the limit for
  a rank that computes for longer, and `heartbeat` sends a heartbeat to every peer.
- `abortJob` tells every peer the job is over; `finish` says bye and closes.
- Signing and checking a token needs a stack of several hundred kilobytes. A rank that joins inside a task opens the
  scope with `openScopeWithStack(8388608)`; the main thread has enough.

## Collectives

```
let code: Int32 := barrier(&!comm);
case allreduce(&!comm, int64Type(), sumReduction(), numbers) of
    when Right(right as total: String) do
        destroyString(total);
    when Left(left as code: Int32) do
        skip;
end case;
```

| Call | Result |
|---|---|
| `barrier(comm)` | 0 when every rank has called it |
| `bcast(comm, root, data)` | the data of `root` on every rank |
| `reduce(comm, root, type, operation, data)` | the reduction over all ranks at `root`; the empty string elsewhere |
| `allreduce(comm, type, operation, data)` | the reduction on every rank |
| `gather(comm, root, data)` | the blocks of all ranks in rank order at `root`; the empty string elsewhere |
| `scatter(comm, root, data)` | block i of the data of `root` on rank i |

- Data is a `String` that the call consumes; the result is a new `String`. The data of a rank that does not supply any
  (`bcast`, `scatter` on a rank other than the root) is ignored and may be empty.
- An array is a string of elements of `type`: bytes, int32, int64, uint32, uint64, float32 or float64, least
  significant byte first. `operation` is sum, min, max, prod, land, lor, lxor, band, bor or bxor; whole numbers wrap
  around, and the reduction runs in rank order. `docs/sperli-protocol.md` has the table of what fits what.
- A call may carry at most 16777200 bytes of data. Larger data is split by the caller.
- A wrong call that every rank sees alike (a root outside the job, a reduction that does not fit the type, data that is
  no whole number of elements) returns H1618 on every rank and the job goes on. A scatter whose data is no whole
  number of blocks, a frame that does not match its call and contributions of different length end the job: the rank
  that sees it returns the code and tells every other rank, which return H1612.
- The waiting rank is lost to its peer after the silence limit like in `recv`. A rank that is slow in a collective
  makes the others wait for it, so a job with long computations between collectives raises the limit with `setSilence`.
- The collectives are a star around the root, so a result does not depend on timing.

## Checkpoints

```
useCheckpoints(&!comm, "ckpt");
let code: Int32 := checkpoint(&!comm, &state);
case resume(&!comm) of
    when Right(right as back: String) do
        destroyString(back);
    when Left(left as code: Int32) do
        skip;
end case;
```

- `useCheckpoints` names the directory. Every rank calls `checkpoint` in the same order as the collectives. A state is
  a value of a type with an instance of `Checkpointable` (`encodeState`, `decodeState`; `String` has one);
  `checkpointBytes` takes the bytes directly. A type that holds a connection, a file or an open send or receive has
  no instance, so the compiler refuses the call; a send or receive that is still open fails the call with H1624.
- A rank writes `<dir>/<job>/<epoch>/rank-<n>.ckpt` (header `SPCK`, version, job, epoch, rank, size, length and
  SHA-256, then the state) to a temporary name, syncs it, renames it and sends its SHA-256 to rank 0. It also sends
  the file to rank `(n + 1) mod size`, which keeps it as `rank-<n>.ckpt.buddy`.
- When rank 0 has every SHA-256 it writes `COMMIT`, which lists them and carries a CompositeSig signature of the job
  key, and sends it to the others. An epoch without a valid signed COMMIT does not count. Only the epoch just written
  and the one before stay.
- When a rank is lost, the others end with H1611 or H1612 and the exit status 75. With `--checkpoint-dir` the launcher
  starts the job again, at most `--restart-max` times; a lost rank goes to the next unused host of the list. The
  rank calls `resume`: the newest epoch whose COMMIT verifies is taken, the signature and every SHA-256 are checked
  against the file headers and the COMMIT, and a missing or damaged file is fetched from the buddy. Version 1
  resumes only a job of the size it was written with (H1623). A refusal is a code: H1619 to H1622.

## The C library

`libsperli` is the C interface of Sperli, for a programme that is not written in Hilde, such as the Go package. It is
a static library and a header per target:

```
sh scripts/libsperli/build.sh
```

writes `libsperli/c/<target>/libsperli.a` and `libsperli/c/<target>/sperli.h`, with `<target>` one of `linux`,
`openbsd`, `freebsd` and `darwin`, the system the script runs on. A programme links the library with
`-lpthread -ltls -lcrypto` and includes `sperli.h`, which has the full text of every function.

| Function | Call |
|---|---|
| `sperli_init` | joins the job that a description names; gives the handle |
| `sperli_rank`, `sperli_size` | the own rank, the number of ranks |
| `sperli_send`, `sperli_recv` | one message to or from a rank with a tag |
| `sperli_barrier`, `sperli_bcast`, `sperli_reduce`, `sperli_allreduce`, `sperli_gather`, `sperli_scatter` | the collectives |
| `sperli_result` | copies out the data a call kept |
| `sperli_checkpoint_directory`, `sperli_checkpoint`, `sperli_resume` | the checkpoints |
| `sperli_finish` | leaves the job |
| `sperli_describe` | a sentence for a code |

- TLS 1.3 with a certificate on both sides is always on; the library has no option for anything else.
- Every function checks all of its arguments first and answers with a code: a null pointer, a length, a rank, a tag,
  an element type, a reduction, a count, a handle, a path, a call while another runs. A wrong argument never ends the
  process and changes nothing in the job. Only a broken promise of the library itself, an `ensures`, ends it with
  `abort(3)`.
- A code is 0, a negative number for a mistake of the caller, or 1601 to 1625 for a refusal in the job, the number of
  the H code. The numbers are stable. The negative codes:

| Code | Name | Meaning |
|---|---|---|
| -1 | `SPERLI_E_NULL_POINTER` | a pointer is NULL where bytes or a result are needed |
| -2 | `SPERLI_E_BAD_LENGTH` | a length is zero where data is needed, or above its limit |
| -3 | `SPERLI_E_BAD_RANK` | a rank is not in the job, or is the own rank where a peer is needed |
| -4 | `SPERLI_E_BAD_TAG` | a tag is above 2147483647 |
| -5 | `SPERLI_E_BAD_HANDLE` | the handle is not the live session |
| -6 | `SPERLI_E_NOT_READY` | the session holds no comm |
| -7 | `SPERLI_E_BAD_TYPE` | an element type is above 6 |
| -8 | `SPERLI_E_BAD_OPERATION` | a reduction is 0 or above 10 |
| -9 | `SPERLI_E_BUFFER_TOO_SMALL` | the buffer is shorter than the result; the result is kept |
| -10 | `SPERLI_E_NO_RESULT` | there is no result to take |
| -11 | `SPERLI_E_RESULT_PENDING` | an earlier result has not been taken |
| -12 | `SPERLI_E_BUSY` | another call is running |
| -13 | `SPERLI_E_ALREADY_INITIALISED` | the process holds a session already |
| -14 | `SPERLI_E_BAD_PATH` | a path holds a zero byte |
| -15 | `SPERLI_E_BAD_COUNT` | the data is no whole number of elements or blocks |
| -16 | `SPERLI_E_INTERNAL` | the core answered with a code that is none of these |

- The session is a number, not a pointer, so a handle that was freed or made up is a code and not a crash. A process
  holds one session. One call runs at a time; a call made while another runs answers `SPERLI_E_BUSY`.
- A call that makes data (`recv`, `bcast`, `reduce`, `allreduce`, `gather`, `scatter`, `resume`) keeps it and tells
  its length; `sperli_result` copies it out. `sperli_result` with too short a buffer tells the length needed and keeps
  the result.
- The library is the module `Standard.SperliExport`, which exports the calls with `pragma Foreign_Export`, and
  `libsperli/src/sperli.c`, which checks the arguments before it calls them. The runtime starts at the first
  `sperli_init` and stays until the process ends.
- `sh scripts/libsperli/check-libsperli.sh` builds the library and runs `libsperli/test/test_sperli.c`, which gives
  every function wrong input and holds the code against the table.

## Mixed jobs, the sum example and the benchmark

A job may mix Hilde ranks and ranks of the Go package (`sperli`, which uses `libsperli`); the wire, the certificates
and the tokens are the same. The programmes and the scripts are:

| Path | What it is |
|---|---|
| `examples/sperli-sum` | the sum of a table of 3,000,000 rows over the ranks of a job; row i holds i + 1, so the total is 4500001500000 |
| `examples/sperli-bench` | latency and bandwidth between two ranks: `ping`, `echo`, `stream` and `sink` |
| `libsperli/test/mixed` | the helpers of the tests: the descriptions of a job, and a rank 0 that is wrong in one chosen way |
| `scripts/sperli/mixed-test.sh` | the mixed tests |
| `scripts/sperli/bench.sh` | the benchmark |

- Each rank reads its description from the first line of its standard input. The ranks of one job may be started by
  hand, one after the other; start the highest rank first and rank 0 last, with a second between them, since the C
  library does not wait for a rank that does not listen yet.
- `sperli-sum` cuts the rows by one rule: the first `rows mod size` ranks get one row more, and the parts follow each
  other from row 0. Every rank sums its rows and takes part in a reduction to rank 0 (`Int64`, sum), which prints
  `rows=3000000 total=4500001500000 expected=4500001500000 ok`. The Go example prints the same line.
- `bash scripts/sperli/mixed-test.sh` builds everything into a private directory, copies the Go repository there
  (it is not changed; `SPERLI_REPO` names it, default `/repos/sperli`) and needs `hilde`, `go` and a C compiler. It runs
  the sum of the 3,000,000 rows with rank 0 in Hilde and ranks 1 and 2 in Go, and with three Hilde ranks. Then a Hilde rank 0
  meets a Go rank 1 and is wrong in one way each time: a certificate of another CA, no certificate, an expired token,
  a token of another job, a token of another rank, an oversized frame. The Go rank must end with the code of the
  refusal (H1601, H1601, H1604, H1605, H1606, H1608); a client that is right is let in. A host list that names a host
  the Go rank program refuses is refused by it; `SPERLI_GO_REFUSED_TEST` names that Go test. The test ends with 0 when every check held. It takes about two minutes.
- `bash scripts/sperli/bench.sh [pings [messages]]` measures the round trip of a message of 64 bytes and the rate of
  messages of 1 MiB sent one way, for two Hilde ranks, a Hilde rank 0 with a Go rank 1, and two Go ranks.
- Measured on one host (Linux, loopback, TLS 1.3 with certificates on both sides, 1000 round trips, 32 messages of 1
  MiB; MB are 10^6 bytes):

| Pair | Round trip, mean | Bandwidth |
|---|---|---|
| Hilde and Hilde | 68 us | 90.1 MB/s |
| Hilde (rank 0) and Go | 381 us | 4.3 MB/s |
| Go and Go | 547 us | 4.3 MB/s |

- A pair with a Go rank is slower by a factor of 5 to 20 than two Hilde ranks, and the same on either side of the pair.
  The cause is in the path through the C library; it is not looked into.

## Files

A rank writes its CA, certificate and key to a directory `sperli-<job>-<rank>` of the working directory, readable only
by its user, and removes them when it has joined the job or failed to. It needs a working directory it may write in.
