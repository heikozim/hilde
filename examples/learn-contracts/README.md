# learn-contracts

## What it shows

A bank account with a contract on each of its functions.  A contract says
what must be true when a function is called (`requires`) and what is true
when it returns (`ensures`).  The contract of a public function stands in
the module's interface, `LearnContracts.hih`, next to the function it is
about.  Hilde checks it while the programme runs.

- `deposit` requires a positive amount and ensures that the balance grew
  by exactly that amount.
- `withdraw` requires a positive amount that the account holds, and
  ensures that the balance shrank by exactly that amount.

There are two programmes.  `main` keeps every contract.  `broken` asks to
withdraw more than the account holds: the programme stops before
`withdraw` runs, and the message says which contract did not hold, where
it is written, and where the call was made.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-contracts
make
./main
./broken
```

## What comes out

`./main` prints three lines and ends normally:

```
150
30
30
```

`./broken` prints one line, then stops with a message on standard error
and an exit status that is not 0:

```
70
Hilde: contract violated: the requires (amount > 0) and (amount <= balance(&account)) of Example.LearnContracts.withdraw (LearnContracts.hih:38) does not hold for the call at LearnContractsBroken.hiq:25; the caller is at fault
```

The file names in the message are the ones given to the compiler; from
another directory they carry that directory.
