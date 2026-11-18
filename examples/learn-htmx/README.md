# learn-htmx

## What it shows

A handler for htmx with `Standard.Htmx` and `Standard.Template`.

- `page.jinja` is the whole page; it includes the list, `todos.jinja`.
- A request with `HX-Request: true` gets the list alone, the fragment htmx
  swaps into the page; any other request gets the page.
- Both answers carry `Vary: HX-Request`, so that no cache hands the one out
  for the other.
- The answer to the POST that adds an entry carries `HX-Trigger:
  todo-added`; the list in the page listens for that event and loads itself
  again.
- What a user typed is escaped by the template: `call <Ann>` comes out as
  `call &lt;Ann&gt;`.

The requests are made in memory, as a web server would send them over
FastCGI; nothing listens on a socket.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-htmx
make
./main
```

## What comes out

```
-- GET /todos from a browser:
Status: 200 OK
Content-Type: text/html; charset=utf-8
Vary: HX-Request

<!doctype html>
<html><head><title>Todo</title><script src="/htmx.min.js"></script></head>
<body><h1>Todo</h1>
<ul id="todos" hx-get="/todos" hx-trigger="todo-added from:body">
<li>buy tea</li>
</ul>
</body></html>
-- POST /todos from htmx:
Status: 201 Created
Content-Type: text/html; charset=utf-8
Vary: HX-Request
HX-Trigger: todo-added


-- GET /todos from htmx, after todo-added:
Status: 200 OK
Content-Type: text/html; charset=utf-8
Vary: HX-Request

<li>buy tea</li>
<li>call &lt;Ann&gt;</li>

```
