# learn-typeclass

## What it shows

A type class of its own.

- `Shape` names what every shape can say: its area and its name.
- `Square` and `Rectangle` have an instance each.
- A generic instance gives a pair of shapes of one kind an area too, from
  the instance of its parts.
- `report` takes any type that has an instance, and the compiler picks the
  instance from the argument.  A type without one is refused when the
  programme is compiled.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-typeclass
make
./main
```

## What comes out

```
square: 9
rectangle: 20
pair: 25
pair: 40
```
