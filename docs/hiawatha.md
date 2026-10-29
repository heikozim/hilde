# Hiawatha in front of a Hilde service

## What Hiawatha is, and why it is ours

[Hiawatha](https://hiawatha.leisink.net/) is an open source web server by Hugo Leisink, built for security,
ease of use and a small footprint. It speaks FastCGI, TLS and HTTP/2, rewrites URLs, proxies, and blocks SQL
injection, XSS, CSRF and exploit attempts by itself; it runs on Linux, the BSDs and macOS. Its manual is
hiawatha(1), on the website and in its source.

**Hiawatha is the preferred web server for everything built in Hilde.** Heiko Zimmermann, who makes Hilde, has
run Hiawatha since 2010 and is a contributor to it by now. A Hilde programme does not listen on
the network itself: it serves FastCGI on a Unix socket, and Hiawatha takes the connections, holds TLS, serves
the static files and hands every other request to the socket. The services built in Hilde run that way.

How it fits together:

    browser --TLS--> Hiawatha (:443) --FastCGI over a Unix socket--> the Hilde programme

## What this file holds

The settings of Hiawatha a Hilde service needs, each with the reason and where it comes from. The examples are those of an OpenID provider written in Hilde, its host `auth.example.org`.
`Standard.Doctor`'s `init` prints the FastCGIserver and UrlToolkit blocks for a service with a socket.

Hiawatha's configuration is read at start only: there is no reload. After a change, check it with
`hiawatha -k`, then restart Hiawatha (`rcctl restart hiawatha` on OpenBSD, `systemctl restart hiawatha` on
Linux).

## Global settings (hiawatha.conf, outside every VirtualHost)

| Setting | Value | Why |
|---|---|---|
| `MaxUrlLength` | `8192` | An ID token of ML-DSA-44 travels in the query of a logout (`id_token_hint`). Hiawatha's default is 1000, and it answers a longer URL with 414 before the service sees it. On a test instance: ID token 3688 bytes, logout URL 3710, refused with 414 under the default, answered with 8192. The setting is one of the whole server; a VirtualHost cannot set it (hiawatha(1)). |

## The FastCGI server and the toolkit

```
FastCGIserver {
    FastCGIid = Auth
    ConnectTo = /var/run/auth/auth.sock
}

UrlToolkit {
    ToolkitId = auth
    Match ^/static/[A-Za-z0-9._-]+$ Exit
    Match ^/favicon\.ico$ Exit
    Match .* UseFastCGI Auth
}
```

- `ConnectTo` is the socket the service makes, as its configuration names it; the socket's group is the one
  Hiawatha runs in (`www` on OpenBSD).
- The files of the website root are served by Hiawatha (`Exit`); every other path goes to the service.
- A directory of configuration files that Hiawatha includes is read whole, a copy ending in `.bak` included: a
  copy that should not count goes out of the directory, not next to the file.

## The virtual host

```
VirtualHost {
    Hostname = auth.example.org
    WebsiteRoot = /usr/local/share/auth/www
    UseToolkit = auth
    RequireTLS = yes, 31536000; includeSubDomains
    TLScertFile = tls/auth.example.org.pem
    BanByCGI = yes, 3600
    HTTPAuthToCGI = yes
    CustomHeaderClient = X-Content-Type-Options: nosniff
    CustomHeaderClient = Referrer-Policy: no-referrer
    CustomHeaderClient = X-Frame-Options: DENY
}
```

| Setting | Why |
|---|---|
| `HTTPAuthToCGI = yes` | Hiawatha passes the `Authorization` header to FastCGI only with it; a client of an OpenID provider authenticates at `/token` with `client_secret_basic` in that header. |
| `BanByCGI = yes, <seconds>` | The service may have Hiawatha ban an address after repeated failed sign-ins; the seconds are the most a ban may last, so the service's own ban time stays at or under them. |
| `RequireTLS`, `TLScertFile` | The service sets `Secure` and `__Host-` cookies, which a browser keeps over TLS only. |
| `CustomHeaderClient` | For the static files Hiawatha serves itself; the service sets the same headers on its own pages. |

## Hiawatha's confinement

- Hiawatha keeps its file access narrow on purpose: its own sandbox, and on Linux an AppArmor profile where the
  system ships one. A change of its configuration may not make it touch a path it did not touch before.
- Inside its sandbox it takes no signal from outside; in a container, let it end with the container.
- A test that needs Hiawatha runs it in a container of its own, never against a Hiawatha that serves others.

## For a load measurement only

A measurement of a service behind Hiawatha sets `ThreadPoolSize = 50`, `ListenBacklog = 128`,
`ConnectionsPerIP` and `ConnectionsTotal = 1000`, `MaxKeepAlive = 1000` on the binding and
`SetResourceLimits = no`, so that Hiawatha's limits are not what is measured. They are not settings for
production.
