# Svg: SVG documents, line charts and graphs

`Standard.Svg` is the SVG base of Hilde: a document builder with escaping, scale and tick helpers, and a line chart
core. `Standard.GraphSvg` builds on it and draws node and edge networks. Both modules write the same drawing for the
same input on every machine: all coordinates are whole numbers, no floating point takes part. Neither module knows a
colour of its own; every part carries a class and the colours the caller hands over are written as they stand, so a
style sheet colours the drawing.

## The document builder

- A `Builder` is linear: `destroyBuilder` gives it back. It collects elements and attributes and `render` makes the
  `String` at the end.
- `escapeText` and `escapeAttribute` write the five XML characters as entities, in text as `&lt;` `&gt;` `&amp;`
  `&quot;` `&#39;` and in values the same way. Every text and value is escaped where it is written; nothing is
  passed through.
- Element names are checked against a small whitelist (a letter, `_` or `:` to start, then also digits, `.` and `-`);
  anything else stops the programme. An unknown name cannot break out of a tag.
- An element with nothing in it is written as `<g />`; a document whose root is never closed is written as one empty
  element. The root of `beginSvg` carries the namespace, the size and the `viewBox`.

| Function | Writes |
|---|---|
| `beginElement(b, "g")` | an element open until the matching `endElement` |
| `attribute(b, "class", "chart")` | an attribute with an escaped value |
| `attributeInt(b, "width", 200)` | an attribute with a whole number |
| `text(b, content)` | escaped text inside the open element |
| `rect` `rectFilled` `circleFilled` `textAt` `path` `polyline` | the usual shapes as one call each |

## Scales and ticks

The tick helpers choose steps of the form 1, 2 or 5 times a power of ten, so a chart never shows steps like 3.7. A
`Step` record holds the multiple and the exponent, `stepValue` its worth, `firstTick` and `lastTick` cut the range to
ticks, `formatTick` writes a tick in plain decimal.

`mapX` and `mapY` map a value of a data range onto a pixel range, `mapY` with the low end at the bottom. A `Frame`
record holds the plot rectangle in pixels and the data range; `pixelX` and `pixelY` map through it, and `drawXAxis`
and `drawYAxis` draw the axes with their ticks and labels for the frame.

## The line chart

- `LineChart` is linear: `destroyLineChart` gives it back. `makeLineChart` takes the size of the document, a title
  and the labels of the two axes; an empty title or label draws nothing.
- `addSeries` takes two buffers of equal length and the class of the series; at most `mostSeries` series of at most
  `mostPoints` points each.
- `renderLineChart` draws the axes with their ticks over the range of the data (0 to 1 when no series holds a
  point), then one `polyline` per series with its points mapped to pixels. A series with one point is a circle at
  its place. The root carries the class `svg-chart`, the parts carry `svg-title`, `svg-axis`, `svg-tick`.

## Graphs as SVG

`Standard.GraphSvg.renderGraph` takes a `Graph[String, E]` -- the label of a node is its value -- and a `GraphOptions`
record with the size, the classes and the colours. The layout is decided by the graph alone, so the same graph and
the same options give the same bytes on every run.

- A graph without a cycle is laid out in layers: a node stands on the layer after the layers of the nodes its edges
  come from, the layers side by side over the width, the nodes of one layer spread over the height in the order of
  their slots.
- A graph with a cycle is laid out on a circle around the middle of the document, in the order of the slots, the
  first at the top.
- A node is a circle of the radius 20 with its label escaped in the middle. An edge is a line from the rim of its
  source to the rim of its target with an arrowhead at the target; an edge that leads from a node to itself is drawn
  as nothing.
- The root carries the class `svg-graph`; the classes `graph-node`, `graph-edge` and `graph-label` and the colours
  come from the options.

## Limits

- The size of a chart or a graph document is 100 to 10000 pixels in each direction.
- A chart holds at most 1000 series of at most 1000 points (`mostSeries`, `mostPoints`).
- Tick steps cover the range where `multiple * 10^exponent` stays inside an `Int64`; `tickStep` demands `low < high`.
- The scale helpers take any `Int64` the contract of a function allows: a difference, a sum or a product that would
  go past an end of the type stops at that end, and a product that does not fit is divided bit by bit, so a chart of
  numbers a caller did not check is drawn to its ends instead of stopping the programme. A data range wider than
  `Int64` is halved before it is mapped, so its ends still fall on the ends of the axis and no range stops the
  programme.
- The layout of a graph runs on whole numbers only: the sine of the circle layout comes from four terms of the
  Taylor series at the fixed point 65536, which is exact to far under a thousandth of a pixel over the sizes above.

## Layering

The modules are the shared base for layers on top of them: a layer that colours charts and graphs from a style sheet
only has to rewrite the classes; a layer over another array type feeds its series through `addSeries`; a layer that
wants another layout draws its nodes itself over the builder. Nothing in `Standard.Svg` or `Standard.GraphSvg` knows
about the layers.

## Contracts

Every public function of the two modules carries its contract. The bounds of the table:

| Function | Guarantee |
|---|---|
| `beginElement` | the depth of open elements grows by one |
| `endElement` | the depth falls by one; a call at depth 0 stops the programme |
| `tickStep` | the multiple is 1, 2 or 5 |
| `mapX`, `mapY`, `pixelX`, `pixelY` | the result lies in the pixel range |
| `addSeries` | the series count grows by one |
| `renderLineChart`, `renderGraph` | the result is not empty |
