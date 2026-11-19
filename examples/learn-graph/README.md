# learn-graph

## What it shows

A small road map as a graph.  The towns are nodes that hold their names,
the roads are edges that hold their length in kilometres.

- `shortestPath` finds the way with the fewest roads.
- `lightestPath` finds the way with the fewest kilometres, and says how
  many.

A node or an edge is named by an id that also carries a generation, so an
id of a removed node is never taken for a node added later.  The names are
strings, which Hilde does not let go unnoticed: before the graph ends,
every town is taken out with its name.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-graph
make
./main
```

## What comes out

```
fewest roads: Aachen Cologne Frankfurt
fewest kilometres: Aachen Bonn Frankfurt, 265 km
```

Two roads either way lead from Aachen to Frankfurt; the one through Bonn
is 5 km shorter than the one through Cologne.
