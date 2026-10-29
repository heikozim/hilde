# sperli-bench

Latency and bandwidth between two ranks of a Sperli job over TLS 1.3. One programme with four modes, the same as the
Go rank program of the sperli repository, so each rank of a pair may be Hilde or Go:

| Mode | What the rank does |
|---|---|
| `ping count bytes` | sends a message of `bytes` bytes with tag 1, waits for it back, `count` times; prints the mean and the least round trip in microseconds |
| `echo count bytes` | sends back what it gets with tag 1, `count` times |
| `stream count bytes` | sends `count` messages with tag 2, waits for the count of bytes of the sink, prints the rate in MB/s (10^6 bytes) |
| `sink count bytes` | takes `count` messages with tag 2 and answers with the count of bytes as 8 bytes |

Rank 0 of a pair is `ping` or `stream`, rank 1 is `echo` or `sink`. The job must have two ranks.

## Build and run

```
hilde compile examples/sperli-bench/SperliBench.hih,examples/sperli-bench/SperliBench.hiq \
    --modules=standard/src:bindings/generated --entrypoint=Example.SperliBench:main --output=sperli-bench
```

`bash scripts/sperli/bench.sh` builds it and measures Hilde and Hilde, Hilde and Go, and Go and Go; the numbers are in
docs/sperli.en.md, section Mixed jobs.
