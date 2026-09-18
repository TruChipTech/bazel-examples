# 191 - Memory and JVM Tuning

**Concepts:** `--host_jvm_args`, the analysis cache, OOM recovery

## Where Bazel's memory goes

The Bazel **server** is a long-lived JVM holding:

- The loaded package graph (every BUILD file it has read)
- The **analysis cache** - every configured target and action
- Skyframe's incremental state

That is what makes the second build fast, and what makes Bazel memory-hungry on
large repos.

## Seeing it

```bash
bazel info | grep -i memory
bazel build //... --build_event_json_file=/tmp/bep.json
jq 'select(.buildMetrics) | .buildMetrics.memoryMetrics' /tmp/bep.json
```

## Raising the heap

```
# .bazelrc - note: STARTUP options, so they must be at the top
startup --host_jvm_args=-Xmx8g
startup --host_jvm_args=-Xms2g
```

Changing a startup flag **restarts the server**, discarding the analysis cache.
So do not put these behind a `--config`; they belong in the base `.bazelrc`.

## When you hit OOM

```
java.lang.OutOfMemoryError: Java heap space
```

In order of preference:

1. **Raise `-Xmx`.** Often the whole answer.
2. **Build less at once.** `//services/...` instead of `//...`.
3. **Reduce configurations.** Every transition multiplies configured targets
   (sample 143). This is frequently the real cause.
4. **`--discard_analysis_cache`** - frees the analysis cache after the build.
   The next build re-analyzes, so use it only for one-off large builds.
5. **`--notrack_incremental_state`** for CI, which does not need incrementality
   between invocations.

## CI versus developer settings

```
# CI: one build then exit; incrementality is worthless
build:ci --notrack_incremental_state
build:ci --nokeep_state_after_build

# Developers: keep everything, iterate fast
```

CI servers are often configured exactly backwards - carrying incremental state
they never reuse, and then running out of memory.

## Do not `bazel shutdown` casually

Every shutdown throws away the analysis cache, so the next build re-analyzes
everything. Most "Bazel is slow today" reports are a recently restarted server.

Legitimate reasons to restart: changing a startup flag, upgrading Bazel,
recovering from a suspected server bug.

## The real fix is usually graph shape

Memory scales with **configured targets**, not source lines. Two things blow it
up:

- Transitions creating many configurations of the same target (sample 143)
- Macros generating far more targets than anyone realizes

```bash
bazel config | wc -l                              # how many configurations?
bazel query //... | wc -l                         # how many targets?
bazel cquery //... | wc -l                        # how many CONFIGURED targets?
```

If the third number is several times the second, find the transition.

## Key takeaway

Raise `-Xmx` first, then look for configuration multiplication. Avoid
`bazel shutdown`, and turn off incremental state in CI.
