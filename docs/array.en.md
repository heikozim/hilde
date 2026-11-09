# Array: numbers with a shape

`Standard.Array` is the array type of Hilde: a block of numbers of one element type with a shape, strides and no
copy when it is sliced. `Standard.ArrayWire` writes an owning array as bytes and reads it back.
`Standard.ArrayCompute` is the compute layer built on the two: elementwise arithmetic with broadcasting, reductions
and the joining of partial results. They are the base of what comes next (matrices, interpolation, random numbers,
calculus, optimization) and the form in which Sperli will carry arrays. Neither module uses a language feature
outside the safe subset; the only C is in `Bindings.Array`, which splits and joins the bytes of a number
(`docs/unsafe.md`).

## Owning arrays and views

- An `Array` owns its bytes. It is linear: `destroy` gives it back. Its elements are packed in row-major order, the
  last axis running fastest, in little endian.
- A `View[R]` borrows the bytes of an array for the region `R` of the borrow. It is a value that can be copied and
  passed on, and it cannot outlive the array. A view can only be read; an array is written through its owner.
- `view` looks at a whole array. `sliceAxis`, `pick`, `swapAxes` and `broadcast` make another view of the same bytes
  and copy no element. `copy` makes a new packed array from a view.

| Function | What the new view is |
|---|---|
| `sliceAxis(v, axis, start, stop, step)` | the positions `start`, `start + step`, ... below `stop` of one axis |
| `pick(v, axis, at)` | the position `at` of one axis, which then goes; the rank falls by one |
| `swapAxes(v, a, b)` | the axes `a` and `b` exchanged; for a matrix, the transpose |
| `broadcast(v, shape)` | stretched to `shape`; a stretched axis has the step 0 |

A view has a shape (the extents), strides (the step from one element to the next along each axis, counted in
elements) and an offset (the position of the first element). The element at the coordinates is at
`offset + sum(coordinate * stride)`. Every read is also checked against the length of the bytes, so that a view can
not reach past them.

## Limits

- The rank is 1 to 4 (`maxRank`). A scalar is a vector of 1.
- Every extent is at least 1, and the number of elements is at most 2^31 (`maxElements`). An empty array does not
  exist.
- The element types are `Nat8`, `Int32`, `Int64`, `Float32`, `Float64` and `Bool`, named by these codes:

| Type | Code | Bytes |
|---|---|---|
| `Nat8` | 0 | 1 |
| `Int32` | 1 | 4 |
| `Int64` | 2 | 8 |
| `Float32` | 5 | 4 |
| `Float64` | 6 | 8 |
| `Bool` | 7 | 1, 0 or 1 |

The codes 0, 1, 2, 5 and 6 are those of the element type table of `docs/sperli-protocol.md` (0 there is "bytes").
Codes 3 and 4 (unsigned 32 and 64 bits) are kept for later and are refused today.

## Broadcasting

Broadcasting follows NumPy. The shapes are lined up from the last axis. Two extents fit when they are equal or one of
them is 1; a missing axis counts as 1. `isBroadcastable(source, target)` says whether a view of one shape can be
stretched to another, `broadcastShapes(a, b)` gives the common shape or `None`, and `broadcast` makes the view, with
the step 0 along each axis that repeats. `broadcast` has the first as a `requires`, so a wrong shape stops the
programme at the call.

## Contracts

A wrong shape, element type or position is a duty of the caller and a `requires`; the message names the call. The
shape of a product shows the form: `productShape(a, b)` has `requires extent(a, 1) = extent(b, 0)`, the columns of
`a` are the rows of `b`. Reading with `getFloat64` has `requires viewElementType(v) = float64Type()`. The wire
decoder never stops the programme: a value from outside is a result, `Left` with a reason.

## The wire form

An owning array is written as a head, then the elements. All numbers are little endian.

| Offset | Bytes | Meaning |
|---|---|---|
| 0 | 4 | magic, the bytes `HLDA` (0x48 0x4c 0x44 0x41) |
| 4 | 1 | version, 1 |
| 5 | 1 | element type code |
| 6 | 1 | rank, 1 to 4 |
| 7 | 1 | reserved, 0 |
| 8 | 8 * rank | the extents, each an unsigned 64 bit number |
| 8 + 8 * rank | count * width | the elements, row-major, `count` the product of the extents |

The decoder checks, in this order, and refuses at the first that fails:

1. at least 8 bytes (`TooShort`), the magic (`BadMagic`), the version (`BadVersion`), the reserved byte
   (`BadFlags`);
2. the element type is one of the six (`BadElementType`), the rank is 1 to 4 (`BadRank`);
3. the head holds the extents (`TooShort`), each extent is 1 to 2^31 (`BadExtent`), and the product stays within 2^31
   (`TooLarge`), checked after each extent so that nothing overflows;
4. the length is exactly the head and `count * width` bytes (`BadLength`);
5. a `Bool` is 0 or 1 (`BadBool`).

Only then are the elements taken. A float keeps its bits, a NaN and the sign of a zero included. A view is not
written; `copy` it first. Whether a view should be written with its strides is open.

`encode(a, out)` appends the bytes to a `Buffer[Nat8]` and returns their number, `encodedSize(a)`. `decode(bytes)`
gives `Right(array)` or `Left(reason)`; `describe(reason)` is a short text.

The test vectors are in `docs/array-vectors.txt`, written and checked by `scripts/array-vectors.py`, which also reads
every vector again with a second, independent reader. `Standard.ArrayWire`'s test decodes each, encodes the result
and compares the bytes.

## The compute layer

`Standard.ArrayCompute` works on views and gives new owning arrays. It is pure Hilde: no C library is reached, and
every operation takes time linear in the elements.

- Elementwise: `add`, `subtract`, `multiply` and `divide` join two views under the rules of NumPy broadcasting and
  give an array of the stretched shape; `negate` and `absolute` map one view. Both operands must carry the same
  element type, one of `Int32`, `Int64`, `Float32` and `Float64`; `Nat8` and `Bool` are refused by a `requires`.
  Nothing is promoted: an `Int32` stays an `Int32`.
- An integer overflow and a division by zero, on floats as well, stop the programme, as the operators of the
  language do; an integer division rounds towards zero.
- Reductions: `sum`, `product`, `minimum`, `maximum` and `mean` over the whole array give an array of one element;
  the same five with `Axis` appended reduce along one axis and give an array with that axis taken out, a vector of
  one element for a rank of 1. The elements are visited in the row-major order of the view, so a result is the same
  on every run.
- `minimum` and `maximum` take an element only when it compares smaller or larger, the rule of the Sperli protocol,
  so a local and a distributed reduction agree (below). This differs from NumPy, which passes a NaN on: here a NaN
  that comes first stays, and one that comes second is passed over.
- `mean` divides the sum by the number of the elements, an integer mean rounds towards zero.
- The tests compare floats with a documented tolerance: a `Float64` holds about 15 decimal places, so sums of
  decimal fractions are compared within 1e-12, and a `Float32` holds about seven, so quotients are compared within
  1e-5.

The check of the broadcast shape is reusable: `broadcastCount(a, b)` in `Standard.Array` gives the number of
elements two shapes stretch to, or 0 when they do not broadcast, and every elementwise operation has it as a
`requires`, so a wrong shape stops the programme at the call. The next step of the compute layer (dot product,
matrix times vector, matrix times matrix) states the same `requires` over `productShape`.

## For Sperli

The interface that `docs/sperli-protocol.md` names is filled so: `encode` and `decode` are those of
`Standard.ArrayWire`, `elementType` and `shape` those of `Standard.Array`, `combine` that of
`Standard.ArrayCompute`. `Standard.Sperli` itself does not use them yet.

`combine(first, second, reduction)` joins two arrays of partial results element by element, `first` as the left
operand, under the reduction code of the protocol header: 1 sum, 2 minimum, 3 maximum, 4 product, named by
`sumReduction()`, `minReduction()`, `maxReduction()` and `productReduction()`. Nothing is broadcast, and a
difference in the element types or the shapes gives `None`. Whole numbers wrap at their width, so no call stops the
programme; on floats the machine's arithmetic applies, and minimum and maximum follow the keep-first rule of the
protocol. The trapping arithmetic of the elementwise operations is not that of `combine`: a distributed reduction
must not stop on an overflow (`docs/sperli-protocol.md`, Reduce operations).
