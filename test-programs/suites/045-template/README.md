# 045-template

`@template` and `Standard.Template`.

Two references.  Jinja2 for the syntax and for HTML escaping: 001, 020
and 030 are compared byte for byte with Jinja2 3.1.6 on the same
templates and `data.json` (`scripts/jinja/oracle.py`).  Go's
html/template for escaping in URLs, JavaScript and CSS, and for the
migration check: 031 and 033 hold a `page.gohtml` beside the
`page.jinja` rewrite, and the expected output is Go's
(`scripts/jinja/go-oracle.go`).  Both oracles run on a host with Python
and Go.

Where the two references disagree, or where @template departs from
both, the expected output is this implementation's own, reviewed: 015,
032, 038.  037 renders in several tasks at once, each from its own page,
and 050 renders ONE page lent through a lending scope from eight tasks on
eight workers.  Every other test must not compile, each with its message,
and 039 -- ONE page lent to a task of a plain scope -- is refused (H3002).

The further Jinja2 syntax: 040 compiles every form of it and 041 the
options trim_blocks and lstrip_blocks (given in its options.txt, which the
oracle reads), both compared byte for byte with Jinja2 3.1.6.  042 to 048
must not compile, and 016 refuses /; 049 is the form whose output
departs, with its own reviewed expected output.  051 compiles too: an
attribute xmlns:x is written as a URL, as Go's html/template writes it.
