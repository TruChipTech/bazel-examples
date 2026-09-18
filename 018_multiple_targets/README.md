# 018 - Many Targets in One Package

**Concepts:** target granularity, caching, parallelism

## Run it

```bash
bazel run  //018_multiple_targets:server
bazel test //018_multiple_targets:storage_test
```

## See the graph

```bash
bazel query 'deps(//018_multiple_targets:server)' \
  --output=graph --noimplicit_deps
```

## Why granularity pays

Targets are the unit of caching *and* the unit of parallelism. With this
layout:

- Editing `cache.cc` rebuilds `cache` and `server`. `storage` and
  `storage_test` stay cached, so the test does not even re-run.
- `storage` and an unrelated library compile at the same time on different
  cores.

Collapsing all four files into one `cc_binary` would mean every edit rebuilds
everything and no test result is ever reusable.

## But do not overdo it

One target per file sounds optimal and usually is not: each target has analysis
overhead, and a BUILD file with 200 tiny targets is unreadable. The practical
rule is **one target per cohesive unit** - roughly, per thing you would give a
name in a design document.

## Key takeaway

Package = directory. Target = build unit. There is no rule that they map 1:1,
and good repos have several targets per package.
