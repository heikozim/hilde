# learn-session

## What it shows

A login as a web application sees it, without the web.

- `Standard.Cookie` writes Set-Cookie values with the safe attributes,
  removes a cookie, refuses a value that would add a Domain attribute,
  and reads one cookie out of a Cookie header.
- `Standard.Session` keeps a session through `Standard.Database` in an SQLite file in the example's
  directory: it is made, loaded through the token the cookie brought
  back, given a new token at the login, so that the old one opens
  nothing, and removed at the logout.
- `Standard.Csrf` makes the token of a form for the session and checks
  it, and refuses a form that another site sent.

The times are fixed numbers of seconds, the key is a fixed example key,
and the database is removed again.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-session
make
./main
```

## What comes out

```
Set-Cookie: theme=dark; Path=/; Secure; HttpOnly; SameSite=Strict
Set-Cookie: theme=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Strict
refused
a new session, its token has the form of one: true
the cookie came back with the token: true
the session holds: user=ann
the form's token is valid: true
the same form from another site is taken: false
after the login the token is a new one:
  the old token: no session
  the new token: the session holds: user=ann
after the logout: no session
```
