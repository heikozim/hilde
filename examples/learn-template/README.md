# learn-template

## What it shows

Text made from a template in the syntax of Jinja2, `order.jinja`, filled
from a Hilde record.

- `{{ customer|upper }}` puts in a value, here through a filter.
- `{% for line in lines %}` repeats for each element, and `loop.index`
  and `loop.last` say where in the loop it is.
- `{% if rush %}` chooses between two texts.
- `{%-` takes away the line break before it.

The compiler reads the template and turns it into code.  A name the
record does not have, or a filter that does not exist, is a compile error,
not a surprise when the programme runs.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-template
make
./main
```

## What comes out

```
Order for ANN
1. apples, 6 of them
2. pears, 2 of them
3. plums, 12 of them (the last line)
Ship today.
```
