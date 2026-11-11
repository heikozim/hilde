# learn-html

## What it shows

What a web application does with HTML a visitor wrote, with
`Standard.Html`.

- `parseHtml` reads a comment into its tokens, as a browser reads them: the
  content of the script is one text token, and the reference `&amp;` is
  decoded.  `attributeOf` finds the address of the link.
- `textOf` gives the text without tags and without the script.
- `sanitize` with the basic policy keeps the paragraph and the link, drops
  the handler `onclick` and the script with its content, and gives the link
  `rel="nofollow noopener"`.  A link to `javascript:`, written with a
  character reference for a tab inside, keeps its text but loses its
  address, and the picture with its handler is dropped.
- `makePolicy` makes a policy that takes pictures with `src` and `alt`;
  `width` was not named, so it is dropped.
- `escapeHtml` writes the five characters that HTML gives a meaning as
  references.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-html
make
./main
```

## What comes out

```
start p
text Fish & chips
start a
text menu
end a
start script
text steal()
end script
end p
the link goes to https://example.org/
text: Fish & chipsmenu
shown: <p>Fish &amp; chips<a href="https://example.org/" rel="nofollow noopener">menu</a></p>
an attack: <a rel="nofollow noopener">x</a>
with pictures: <p><img src="/cat.png" alt="a cat"></p>
escaped: &lt;b&gt;&amp;&quot;&#39;
```
