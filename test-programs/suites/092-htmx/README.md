# 092-htmx

`Standard.Htmx` with `Standard.Template`.

- 001: one handler answers a plain request with the whole page and a request with `HX-Request: true` with the fragment the page includes, rendered alone; `True` gets the page; both answers carry `Vary: HX-Request`, and the text of an item is escaped.
- 002: an answer with HX-Trigger, one with HX-Redirect, one with both, and two names tested for HX-Trigger.
