# learn-password

## What it shows

Passwords are stored as Argon2id hashes, never as they were typed.

- `hashPassword` makes a new hash with a random salt, so the hash is
  different every time.  Only its start, which names the method and its
  costs, is always the same, and only that is printed.
- `checkPassword` checks a password against a stored hash and says more
  than yes or no: an old bcrypt hash that matches asks for a new hash to
  be stored, and a string that is not a hash is said to be one.

The stored Argon2id hash in the source was made by another programme with
the same method; the bcrypt hash is the known test vector for the password
`U*U`.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-password
make
./main
```

The Argon2 library and libcrypto have to be installed.

## What comes out

On Linux, OpenBSD and FreeBSD:

```
a new hash starts with: $argon2id$v=19$m=65536,t=3,p=4$
the right password: matches
a wrong password: does not match
a stored Argon2id hash: matches
an old bcrypt hash: matches, store a new hash
a broken string: not a hash this module can read
```

On macOS, whose C library has no bcrypt, the old hash cannot be checked:

```
a new hash starts with: $argon2id$v=19$m=65536,t=3,p=4$
the right password: matches
a wrong password: does not match
a stored Argon2id hash: matches
an old bcrypt hash: the check failed
a broken string: not a hash this module can read
```

`m=65536,t=3,p=4` is 64 MiB of memory, three passes and four lanes.
