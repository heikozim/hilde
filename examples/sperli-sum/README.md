# sperli-sum

The sum of a table of 3,000,000 rows over the ranks of a Sperli job. Row i holds the number i + 1, so no table is
kept and the total is known: 4500001500000. The rows are cut by one rule: the first `rows mod size` ranks get one
row more, and the parts follow each other from row 0. Every rank sums its part and the parts are reduced to rank 0
(`Int64`, sum), which prints

```
rows=3000000 total=4500001500000 expected=4500001500000 ok
```

and ends with status 0 when the total is right. The Go example of the sperli repository prints the same line, and
its rank program can be rank 1 or 2 of the same job.

## Build and run

```
hilde compile examples/sperli-sum/SperliSum.hih,examples/sperli-sum/SperliSum.hiq \
    --modules=standard/src:bindings/generated --entrypoint=Example.SperliSum:main --output=sperli-sum
```

Each rank reads the description of the job from the first line of its standard input; `hilde run -n 3 --hosts
hosts.txt ./sperli-sum` starts it so. `bash scripts/sperli/mixed-test.sh` runs it with Hilde ranks and with Go
ranks (docs/sperli.en.md, section Mixed jobs).
