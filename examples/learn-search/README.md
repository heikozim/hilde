# learn-search

## What it shows

The search box of a small site, with `Standard.Search` over the FTS5 module
of SQLite, through `Standard.Database`.

- `prepareSearch` makes the index, `indexDocument` puts three pages into
  it under their paths.
- A search for coffee finds all three, the page whose title has the word
  first; the snippet is escaped for HTML (the `<here>` of the menu comes
  out as `&lt;here&gt;`), and the words found stand between the markers
  the caller chose, here `<mark>` and `</mark>`.
- `cake*` finds cakes.  `title:menu OR about` is four words that must all
  be found, not a column filter and an OR, so it finds nothing; `?!` has
  no word and searches nothing.
- `countMatches` counts for a pager; `removeDocument` takes the menu out,
  and cakes are not found any more.

The database is a file `learn-search.db` in the example's directory, made
and removed by the programme.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-search
make
./main
```

## What comes out

```
search: coffee
  the query of FTS5: "coffee"
  /about: A house for <mark>coffee</mark> since 1904.
  /menu: <mark>Coffee</mark>, tea and cakes. The <mark>coffee</mark> is roasted &lt;here&gt;.
  /hours: The cafe opens at seven; <mark>coffee</mark> from eight.
search: Coffee cake*
  the query of FTS5: "Coffee" "cake"*
  /menu: <mark>Coffee</mark>, tea and <mark>cakes</mark>. The <mark>coffee</mark> is roasted &lt;here&gt;.
search: title:menu OR about
  the query of FTS5: "title" "menu" "OR" "about"
search: ?!
  no words
  nothing searched
documents with coffee: 3
menu removed: true
search: cakes
  the query of FTS5: "cakes"
```
