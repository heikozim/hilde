# learn-sandbox

## What it shows

A programme that gives up what it does not need, right at its start.  The
policy allows writing to standard output and reading files, and of the
file system only the working directory, for reading.

- On OpenBSD the policy becomes `pledge`, which leaves only the system
  calls of the promises `stdio rpath`, and `unveil`, which hides every path
  but the working directory.  A file outside it, `/etc/hosts`, then no
  longer exists for the programme.
- On macOS the policy becomes a Seatbelt profile: the programme starts
  again under `/usr/bin/sandbox-exec`, and `/etc/hosts` is refused there
  too.  Everything before `applyPolicy` runs twice, which is why it stands
  at the very start.
- On FreeBSD the policy becomes Capsicum: the working directory is opened
  for reading and the programme enters capability mode, where
  `/etc/hosts` lies in no granted path and is refused.
- Linux has neither `pledge` nor `unveil`.  There `Standard.Sandbox` uses
  Landlock and seccomp where it can, and this programme only says what is
  missing.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-sandbox
make
./main
```

## What comes out

On OpenBSD:

```
pledge applied: true
unveil applied: true
reading /etc/hosts: refused
```

On FreeBSD:

```
pledge applied: false
unveil applied: false
capsicum applied: true
reading /etc/hosts: refused
```

On macOS:

```
pledge applied: false
unveil applied: false
seatbelt applied: true
reading /etc/hosts: refused
```

On Linux:

```
pledge applied: false
unveil applied: false
pledge and unveil are OpenBSD's; this system has neither
```
