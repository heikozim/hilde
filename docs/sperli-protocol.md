# SPERLI wire protocol, version 1

SPERLI (Simple Parallel Execution over Remote Links Interface) is the cluster layer of Hilde: a job of `size`
ranks, each a process on a listed host, talking over TLS. It is **not MPI-compatible**. It takes only the
semantics of MPI: rank, size, send and receive with a tag, barrier, broadcast, reduce, allreduce, gather and
scatter. This document and the vectors in `docs/sperli-vectors.txt` are complete enough to write a second
implementation, for example in pure C. German version: `docs/sperli-protocol.de.md`.

## Scope and status

SPERLI is the own replacement of MPI for spreading computations, in pure C. It comes after the array type and the
compute layer of Hilde, and nothing here is built ahead that depends on the array type.

- **Current:** transport and security, the job description, connections, the frame, and all frame types: HELLO, DATA,
  COLLECTIVE, HEARTBEAT, ABORT, BYE and the checkpoint frames CKPT_BEGIN, CKPT_DATA, CKPT_ACK, CKPT_COMMIT and
  RESUME with the checkpoint files. `Standard.Sperli` implements them. The collectives work on flat arrays of the
  seven element types below, which are bytes on the wire; they need no array structure. A checkpoint holds the
  bytes of a state that a type with an instance of `Checkpointable` gives; no array structure is needed either.
- **Interface to the array type.** SPERLI has no array structure and no serialization of its own. What it needs of
  the array type is a narrow interface with these placeholder signatures, which the array type fills later:
  `encode(value, buffer)` writes a value into a buffer of bytes and returns its length; `decode(bytes)` reads a
  value back and fails on a cut or wrong input; `elementType(value)` gives the element type code of the table
  below; `shape(value)` gives the extents. `combine(a, b, operation)` is built for flat arrays of the element types
  below (`Standard.SperliCollective.combine`); a value with a shape is encoded to bytes by the array type, sent by
  the collectives, and reduced by the array type for shapes that are not flat. Messages of DATA frames are bytes
  already and need nothing of it.
- **No own consensus or state store.** Agreement among ranks and any state that must outlive a job (the epochs and
  commits of checkpoints, the membership) go to the existing Raft integration (`Standard.Raft`, `Standard.RaftTcp`,
  service 1 of the frame header) and the replicated SQLite (`Standard.SqliteReplica`). Version 1 of the checkpoint
  does not use them: which epoch counts is decided by the COMMIT file, which rank 0 signs with the job key and every
  rank verifies, so that no single rank can make an epoch count that the key did not sign.
- **Bindings.** C libraries (libtls) are reached only through unsafe bindings; everything above them is safe.

All integers are little endian and unsigned unless said otherwise. A byte string is written `[n]` for n bytes.
"Must" means the receiver refuses the frame, closes the connection and aborts the job, unless a rule says "drops".

## Transport and security

- One TCP connection per pair of ranks. The rank with the lower number connects to the higher one, so there is
  exactly one connection per pair. Version 1 has a fixed membership of `size` ranks, 1 to 4096.
- TLS 1.3 only. There is no plaintext mode, not for localhost, not for tests. A peer that offers less is refused.
- Mutual authentication. The launcher makes one **job CA** per job, an Ed25519 key with a self-signed
  certificate, and one Ed25519 certificate per rank signed by it. Both sides demand and verify the peer
  certificate against the job CA only. No system trust store is used.
- The subject common name of the certificate of rank `n` is `sperli-<job id as 32 lower-case hex digits>-<n>`, at most
  44 bytes, so that it fits the 64 bytes a common name may have. The host `h` of the rank is the DNS name in the
  subject alternative name of the certificate, which the connecting side checks in the handshake against the host
  list entry it dials. After the handshake each side compares the subject of the peer with the job and the expected
  rank and refuses the connection if they differ. The rank in the subject is also the only `source rank` the peer
  may use on this connection. The host of the peer is checked a second time through the join token, which names it.
- The hosts the operator lists in the environment variable `SPERLI_REFUSED_HOSTS` (names separated by commas,
  blanks or line ends; any domain below a name, any letter case) never run a rank, and neither do the reserved names
  `host-a.invalid` and `host-b.invalid`, which are built in and name no machine. A launcher and a rank refuse a host
  list entry that matches, even if it is listed. The operator may add further names with `--deny-hosts FILE` (one
  name a line); the names of the variable stay refused when that file is empty or missing. The variable has to be
  set wherever a launcher or a rank runs; an unset variable refuses only the two reserved names.
- No new cryptography: TLS certificates are Ed25519 (`Standard.X509`); tokens and commit signatures are
  `Standard.CompositeSig` (ML-DSA-44 and Ed25519 together, 1344-byte public key, 2484-byte signature) with the
  label `COMPSIG-MLDSA44-Ed25519-SHA512` (`CompositeSig.openSshLabel`). The context is `SPERLI-JOIN-1` for join
  tokens and `SPERLI-COMMIT-1` for COMMIT files.
- The launcher makes one CompositeSig key pair per job. The public key (1344 bytes) goes to every rank in the job
  description together with the job id, `size`, the incarnation, the host list and the job CA certificate. The
  secret key stays with the launcher, which signs the join tokens and, for rank 0, the COMMIT files (rank 0 gets
  the key for the lifetime of the job).

## Job description

The launcher tells each rank its job on the standard input of the process, as one line of lower-case hexadecimal
digits and a line feed. The bytes behind the digits are:

| Field | Size | Meaning |
|---|---|---|
| magic | 4 | `SPJD` |
| version | 2 | 1 |
| reserved | 2 | 0 |
| job id | 16 | the job id |
| size | 4 | the number of ranks, 1 to 4096 |
| rank | 4 | the rank of this process, below `size` |
| incarnation | 4 | 1 or more |
| hosts | `size` times | port (2 bytes, not 0), host length (2 bytes), host name |
| public key | 2 + 1344 | length and the CompositeSig public key of the job |
| token | 2 + t | length and the join token of this rank |
| CA | 4 + n | length and the PEM text of the job CA certificate |
| certificate | 4 + n | length and the PEM text of the certificate of this rank |
| key | 4 + n | length and the PEM text of the Ed25519 key of this rank |

Numbers are little endian. A description with other bytes after the key, a cut field, a host that is refused, or a
size, rank or incarnation out of range is refused. The key of the rank is a secret; the line is never written to a
file by the launcher, and a rank writes the three PEM texts to files that only its user may read, in a directory of its
own, for as long as it makes connections.

## Connections

The rank with the lower number connects to the higher one. A rank listens at its port first, connects to every higher
rank (trying again every 100 ms for 30 s, because the peer may not listen yet) and then accepts one connection from
every lower rank. Both sides send their HELLO at once. A rank is silent for at most 5000 ms before it is taken as
lost; a rank that waits for a frame sends nothing of its own in version 1, and a program that computes for longer
than the limit raises it with the silence setting of the library.

## Frame

Every message is a frame: a 52-byte header and `length` bytes of payload.

| Offset | Size | Field | Meaning |
|---|---|---|---|
| 0 | 4 | length | bytes of payload after the header |
| 4 | 1 | type | frame type, see below |
| 5 | 1 | flags | 0 in version 1; others must be refused |
| 6 | 2 | service | 0 = SPERLI; 1 = reserved for a shared Raft transport; others must be refused |
| 8 | 16 | job id | 128-bit job id, the same for every frame of a job |
| 24 | 4 | incarnation | 1 at launch, plus 1 at every restart |
| 28 | 4 | membership epoch | 0 in version 1; reserved for dynamic membership; others must be refused |
| 32 | 8 | epoch | checkpoint epoch the frame belongs to; 0 for frames outside a checkpoint |
| 40 | 4 | source rank | rank of the sender |
| 44 | 4 | target rank | rank of the receiver |
| 48 | 4 | tag | user tag for DATA, 0 for all other types |

- Maximum payload: 16777216 bytes (16 MiB). The maximum frame is 52 + 16777216 bytes. The receiver reads the
  52-byte header, checks `length` against the maximum **before it reads or allocates any payload byte**, and
  refuses a larger value. A larger message is split by the layer above.
- Checks in this order: length, type (1 to 11), flags, service, membership epoch, job id (equal to the job), source
  rank (equal to the authenticated peer) and target rank (equal to the own rank), incarnation.
- Incarnation: a frame with an incarnation **lower** than the receiver's is dropped: its `length` payload bytes are
  read and discarded, nothing else happens. A **higher** one must be refused. Old frames never reach the user.
- User tags are 0 to 2147483647. Tags from 2147483648 are reserved: a DATA frame with one is refused, and a COLLECTIVE
  frame has tag 0 like every type but DATA. These two tag checks come last, after the incarnation, so a frame of an
  older incarnation is still dropped without a verdict on its tag.
- Frames of one connection arrive in the order sent. DATA frames are matched by (source rank, tag) in that order.

## Frame types

| Code | Name | Direction | Payload |
|---|---|---|---|
| 1 | HELLO | both, first frame | capabilities and join token |
| 2 | DATA | any | message bytes |
| 3 | COLLECTIVE | any | collective header and data |
| 4 | HEARTBEAT | both | sender counter |
| 5 | ABORT | any | reason code and text |
| 6 | CKPT_BEGIN | rank 0 to all | checkpoint start |
| 7 | CKPT_DATA | rank to buddy, or fetch | chunk of a rank file |
| 8 | CKPT_ACK | rank to rank 0 | digest of the written file |
| 9 | CKPT_COMMIT | rank 0 to all | the COMMIT file |
| 10 | RESUME | rank 0 to all, and answers | resume epoch and status |
| 11 | BYE | both | empty |

Code 0 and codes above 11 are invalid.

### HELLO (1)

Sent by both sides straight after the TLS handshake; nothing else may come before it. A second HELLO is refused.

| Offset | Size | Field |
|---|---|---|
| 0 | 2 | protocol version, 1 |
| 2 | 1 | language: 0 Hilde, 1 Go, 2 C |
| 3 | 1 | reserved, 0 |
| 4 | 4 | services bit set: bit 0 point-to-point and collectives, bit 1 checkpoint, bit 2 reserved for Raft |
| 8 | 4 | reserved, 0 |
| 12 | 4 | token length `t` |
| 16 | t | join token |

The header of a HELLO carries the sender's rank and incarnation. The peer needs bit 0 in common; a protocol
version other than 1 is refused.

**Join token.** The signed message is

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | magic `SPJT` |
| 4 | 2 | token version, 1 |
| 6 | 2 | reserved, 0 |
| 8 | 16 | job id |
| 24 | 4 | rank |
| 28 | 4 | size |
| 32 | 4 | incarnation |
| 36 | 8 | expiry, seconds since 1970-01-01 UTC |
| 44 | 2 | host length `h`, 1 to 255 |
| 46 | h | host name, ASCII |

and the token is that message, then a 2-byte signature length (2484) and the signature. The receiver verifies the
signature with the job public key and refuses the token if the signature fails, the job id is not its job, the
rank is not the header rank and the rank of the certificate, `size` or incarnation differ from the job, the host
differs from the host list entry of that rank, or the expiry is not later than the receiver's clock.

### DATA (2)

The payload is the message. The tag is in the header. An empty message is valid.

### COLLECTIVE (3)

Payload: a 16-byte collective header, then data. The `tag` of the frame header is 0, and a payload shorter than the
collective header is refused with the frame header (before the payload is read). Data is at most 16777200 bytes, so
that header and data fit the maximum payload.

| Offset | Size | Field |
|---|---|---|
| 0 | 1 | operation: 1 barrier, 2 bcast, 3 reduce, 4 allreduce, 5 gather, 6 scatter |
| 1 | 1 | element type: 0 bytes, 1 int32, 2 int64, 3 uint32, 4 uint64, 5 float32, 6 float64 |
| 2 | 1 | reduce operation: 0 none, 1 sum, 2 min, 3 max, 4 prod, 5 land, 6 lor, 7 lxor, 8 band, 9 bor, 10 bxor |
| 3 | 1 | phase: 0 contribution towards the root, 1 result from the root |
| 4 | 4 | root rank |
| 8 | 8 | sequence number of the collective call, from 1; equal on all ranks for the same call |
| 16 | n | data |

Bytes, barrier, bcast, gather and scatter carry element type 0 and reduce operation 0. Reduce and allreduce carry the
type and operation of the call. Every rank makes the same collective calls in the same order; the sequence number
counts the calls of a rank from 1, and a call that fails still counts.

**Shape.** Version 1 uses a star, not a tree or a ring, so that the result does not depend on timing and every rank is
already connected to every other. For allreduce the root is rank 0.
Reduction runs over the contributions in ascending rank order, and the root's own value is the contribution of its
rank. Rank `r` sends only to the root and receives only from the root, except the root, which talks to every rank.

| Operation | Contributions (phase 0) | Results (phase 1) |
|---|---|---|
| barrier | empty, every rank to rank 0 | empty, rank 0 to every rank |
| bcast | none | the data of the root to every other rank |
| reduce | data of every other rank to the root | none; every rank but the root gets the empty string |
| allreduce | data of every rank to rank 0 | the reduced data, rank 0 to every other rank |
| gather | the block of every other rank to the root | none; the root joins the blocks in rank order, the others get the empty string |
| scatter | none | block i of the root's data to rank i; the root keeps its own block |

**Reduce operations.** The elements of one array are `width` bytes each (1, 4 or 8, by type), least significant byte
first. Two arrays are reduced element by element, the first as the left operand.

| Operation | Element types | Result |
|---|---|---|
| sum, prod | int32, int64, uint32, uint64 | the result modulo 2 to the power of the width in bits; nothing traps |
| sum, prod | float32, float64 | the IEEE result in the width of the type |
| min, max | whole numbers | by the order of the type: signed for int32 and int64, unsigned for the others |
| min, max | floats | min takes the second operand only when it is smaller than the first, max only when it is larger |
| land, lor, lxor | whole numbers | each element is true when it is not 0; the result is 0 or 1 |
| band, bor, bxor | whole numbers and bytes | the bits |

Not allowed, and refused by every rank before anything is sent (H1618): sum, min, max, prod and the logical operations
on bytes; the logical and bitwise operations on floats; reduce operation 0; a type above 6; an operation above 10.

**Argument checks.** Every check that every rank can make alone is made before anything is sent, so that all ranks
refuse the same call and the job goes on: a root of `size` or more, a type or operation that does not go together,
and data that is not a whole number of elements (H1618). Checks that only one rank can make end the job:

- A scatter whose data at the root is not a whole number of blocks of at most 16777200 bytes: the root sends ABORT with
  reason 4 to all ranks and returns H1618; the others return H1612.
- A frame whose collective header differs from the call it answers in operation, type, reduce operation, phase, root or
  sequence number, or is cut (H1617): the rank sends ABORT with reason 3 to all ranks and returns H1617.
- Contributions of different length in a reduce, or blocks of different length in a gather: the same, with H1618 for the
  reduce (the lengths are the data of a call) and H1617 for the gather.

**Order with DATA.** Collective frames and DATA frames of one connection arrive in the order sent. A rank that waits for
a collective frame keeps the DATA frames before it for its own `recv`, and a rank that waits for DATA keeps the collective
frames before it. The tags from 2147483648 are reserved for this: a DATA frame with such a tag is refused with the
frame header (H1610), so a peer cannot pass a data frame off as a collective one.

### HEARTBEAT (4)

Payload: 8 bytes, a counter of the sender that starts at 1 and grows by one per heartbeat. Each side sends one
every 1000 ms on every connection when it has sent nothing else. A connection that has delivered no frame for
5000 ms is lost: the rank sends ABORT with reason 1 to all peers and stops.

### ABORT (5)

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | reason: 1 heartbeat lost, 2 rank failed, 3 protocol error, 4 user abort, 5 checkpoint failed |
| 4 | n | text, UTF-8, at most 1024 bytes |

A rank that receives ABORT forwards nothing, closes all connections and ends the job step. With a checkpoint
the launcher restarts the job from the last COMMIT (see Checkpoints).

### BYE (11)

Empty payload. A rank sends BYE to every peer when it leaves normally and then closes the connection. A close
without BYE is a lost peer.

### CKPT_BEGIN (6)

Rank 0 to every rank, header `epoch` = the new epoch. A rank refuses a version other than 1 or a size other than its own.

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | checkpoint format version, 1 |
| 4 | 4 | size |

### CKPT_DATA (7)

| Offset | Size | Field |
|---|---|---|
| 0 | 1 | kind: 0 buddy copy, 1 fetch request, 2 fetch reply, 3 fetch refused, 4 nothing to fetch |
| 1 | 3 | reserved, 0 |
| 4 | 4 | owner rank, the rank whose file this is |
| 8 | 8 | offset of the chunk in the file |
| 16 | 8 | total length of the file |
| 24 | n | chunk |

Kind 0: rank `r` sends its finished rank file in chunks in order to rank `(r + 1) mod size`, which stores it as
`rank-<r>.ckpt.buddy` in its own epoch directory. Kind 1: a rank asks the buddy for a file it misses; offset and
total are 0 and there is no chunk. Kind 2 answers with the chunks. Kind 3 means the buddy has no valid copy. Kind 4
says that a rank needs nothing, so that the buddy does not wait for a request. A chunk is at most 1 MiB; chunks
come in order, the offset of each is the number of bytes received so far, and the total never changes.

### CKPT_ACK (8)

Payload: 32 bytes, the SHA-256 of the whole rank file just renamed into place. Header `epoch` is the epoch.

### CKPT_COMMIT (9)

Payload: the bytes of the COMMIT file of the epoch. Receivers verify the signature and store a copy.

### RESUME (10)

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | size |
| 4 | 4 | status: 0 request or ready, 1 file fetched from the buddy, 2 failed |
| 8 | 32 | SHA-256 of the COMMIT file, 32 zero bytes for none |
| 40 | n | the COMMIT file, for status 0 from rank 0 and for status 3 |

Status 3 is an offer: every rank other than 0 sends rank 0 the best COMMIT file it holds (header `epoch` = its
epoch, empty when it holds none). Rank 0 takes the highest epoch among the offers and its own files whose
signature verifies and sends status 0 with that epoch (header `epoch`) and the COMMIT file. Every rank answers to
rank 0 with 0 or 1 once its state is loaded, or 2 if it cannot load it, and rank 0 then sends status 0 to all to
go on; status 2 aborts the job.

## Checkpoints

Layout on disk: `<dir>/<job>/<epoch>/rank-<n>.ckpt`, and `<dir>/<job>/<epoch>/COMMIT`. `<job>` is the job id as 32
lower-case hex digits; `<epoch>` is a decimal number, starting at 1.

**Rank file.** A header of 80 bytes, then the state.

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | magic `SPCK` |
| 4 | 2 | format version, 1 |
| 6 | 2 | reserved, 0 |
| 8 | 16 | job id |
| 24 | 8 | epoch |
| 32 | 4 | rank |
| 36 | 4 | size |
| 40 | 8 | payload length |
| 48 | 32 | SHA-256 of the payload |
| 80 | n | payload (the serialized state) |

A reader refuses a file with another magic or version, with a job id, epoch, rank or size that does not match
what it expects, with a file length other than 80 plus the payload length, or whose payload does not hash to the
stored SHA-256.

**COMMIT file.**

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | magic `SPCM` |
| 4 | 2 | format version, 1 |
| 6 | 2 | reserved, 0 |
| 8 | 16 | job id |
| 24 | 8 | epoch |
| 32 | 4 | size |
| 36 | 32 * size | SHA-256 of the whole rank file of rank 0, 1, ... |
| 36 + 32 * size | 2 | signature length (2484) |
| 38 + 32 * size | 2484 | CompositeSig signature over bytes 0 up to 36 + 32 * size |

An epoch without a COMMIT whose signature verifies against the job public key, whose job id, epoch and size match,
and whose hashes match the rank files **does not count**.

**Procedure.** For the collective `checkpoint(state)`, with no open send or receive handle on any rank:

1. Rank 0 sends CKPT_BEGIN with the new epoch `e` to all ranks.
2. Each rank serializes its state and writes the rank file to a temporary name in the epoch directory, calls
   fsync, renames it to `rank-<n>.ckpt`, and sends CKPT_ACK with its SHA-256 to rank 0.
3. Each rank sends the file to its buddy `(n + 1) mod size` as CKPT_DATA kind 0.
4. When rank 0 has all ACKs it writes COMMIT the same way (temporary name, fsync, rename), signed with the job
   key, and sends CKPT_COMMIT to all ranks. Each rank verifies the signature, checks that the COMMIT lists the
   SHA-256 of its own file and of the buddy copy it holds, and keeps a copy. A rank leaves `checkpoint` when it has
   the COMMIT. Rank 0 removes an old COMMIT of the same epoch before it sends CKPT_BEGIN, so a half-made epoch
   never shows a COMMIT from an earlier try.
5. Only epochs `e` and `e - 1` are kept. After the COMMIT of `e`, every older directory, committed or not, is
   deleted. Directories of a later epoch are left alone, because a rank that is further on may be writing them.

A checkpoint with a send or receive still open fails with H1624 on every rank, which is checked at run time; the
state goes through the type class `Checkpointable`, and a type that holds a handle, a connection or a file has no
instance, so the compiler refuses the call. A failed checkpoint sends ABORT with reason 5 to the others.

**Failure and resume.** On heartbeat loss all ranks abort. The launcher restarts the job with the incarnation
plus 1, at most `--restart-max` times; a lost rank may go to another host of the list, never to a refused host (or a host of the deny file).
The resume epoch is the highest epoch with a valid COMMIT. On resume the signature of the COMMIT file is verified
against the job public key, and the SHA-256 of every rank file is checked twice: against the header of the file and
against the entry of the COMMIT file. A rank whose file is missing or invalid fetches it from its buddy with
CKPT_DATA kind 1; the fetched file is checked the same way. A failure is refused with a code: H1619 for a file
that is not the one expected, H1620 for a SHA-256 that does not match, H1621 for a COMMIT that is malformed or whose
signature does not hold, H1622 when no epoch can be resumed. Version 1 requires the same `size` at resume; a
signed COMMIT of another size is refused with H1623. When the newest epoch has no valid COMMIT but an older one has,
the older one is resumed; when a COMMIT fails and no other holds, the code of that failure is given.

## Version 1 limits and reserved fields

Fixed: membership of `size` ranks; `service` 0; `membership epoch` 0; `flags` 0. These are reserved for a shared
Raft and SPERLI transport and for dynamic membership and are not interpreted yet. A receiver of version 1 refuses
nonzero values, so a later version must announce itself in HELLO first.

## Test vectors

`docs/sperli-vectors.txt` holds exact bytes for a frame of every type, for the rank file header, for a COMMIT
file, and the negative cases (oversized length, old and future incarnation, unknown type, flags, service,
membership epoch, a reserved tag, a collective frame with a tag or without its header, bad SHA-256, bad magic).
Records of kind `reduce` give two arrays, an element type and a reduce operation, and the result; they cover wrapping,
signed order, float order, the logical and bitwise operations and the refused combinations. Signatures cannot be fixed (ML-DSA signs with randomness), so vectors
with a signature carry a placeholder of 0xaa bytes and also give the signed part. The file is written and
checked by `scripts/sperli-vectors.py`. The format of the file is explained at its head.
