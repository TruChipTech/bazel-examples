# 157 - Profiling a Build

**Concepts:** `--profile`, `analyze-profile`, critical path

## Try it

```bash
P=//157_profiling

bazel build $P:app --profile=/tmp/prof.gz

# `bazel analyze-profile` was REMOVED in Bazel 9, so this sample ships a
# replacement that reads the same profile:
bazel run $P:summarize_profile -- /tmp/prof.gz
```

> **Bazel 9 note.** Older guides tell you to run `bazel analyze-profile
> /tmp/prof.gz`. That subcommand no longer exists:
> `Command 'analyze-profile' not found`. The `--profile` flag itself is
> unchanged - it writes a gzipped **Chrome Trace Event JSON** - but you now
> analyze it with a trace viewer or a script like the one here.

## Reading the summary

```
=== TIME BY CATEGORY ===
  action processing                   2.104 s  (30 events)
  general information                 0.512 s  (18 events)
  ...

=== SLOWEST INDIVIDUAL EVENTS ===
     0.412 s  [action processing] Compiling 157_profiling/mod.cc
```

The phase breakdown tells you **where to look**, and the three cases are
completely different problems:

| Dominant phase | Meaning | Look at |
|----------------|---------|---------|
| **Loading** | Too many packages / expensive globs | Samples 190, 191 |
| **Analysis** | Too many configured targets, transitions | Samples 143, 191 |
| **Execution** | Actual compilation | Caching, parallelism, remote execution |

A build that is slow in *analysis* will not be helped by a bigger machine or a
remote cache - a very common and expensive misdiagnosis.

## The trace viewer

```bash
bazel build //... --profile=/tmp/prof.gz
```

Load `/tmp/prof.gz` into https://ui.perfetto.dev (or `chrome://tracing`).
You get a timeline with one lane per thread showing every action, its duration,
and the gaps.

What to look for:

- **Long single bars** - one action dominating; can it be split?
- **Wide empty gaps** - insufficient parallelism; a bottleneck dependency
- **A staircase** - a serialized chain, often an artificial dependency
- **A long tail** - a few slow actions at the end delaying everything

## The critical path

```
Critical Path: 12.34s
  4.10s CppCompile some/big/file.cc
  3.02s CppLink //app:server
  ...
```

The critical path is the longest dependency chain. **It is the floor on your
build time** - no amount of parallelism or extra cores makes the build faster
than this. Optimizing anything *not* on the critical path changes nothing.

## Useful flags

```bash
--profile=/tmp/prof.gz              # write a profile
--noslim_profile                    # keep full detail for small builds
--experimental_profile_include_target_label
--experimental_profile_include_primary_output
--experimental_command_profile=cpu  # a JVM CPU profile of Bazel itself
```

`--experimental_command_profile` accepts `cpu`, `wall`, `alloc` or `lock` and
profiles the Bazel *server*, which is what you want when analysis - not
execution - is slow.

The last two make each trace entry say which target and output it belongs to,
which turns "some CppCompile is slow" into "this file is slow".

## Measure the right build

```bash
bazel clean                 # cold build: worst case
bazel build //...           # warm: what developers feel
touch some/file.cc && bazel build //...   # incremental: the common case
```

These are three different performance problems. Most day-to-day pain is the
incremental case, which is dominated by how many targets depend on what you
touched - a *graph shape* problem, not a machine problem.

## Key takeaway

Profile before optimizing. The phase breakdown says which of three unrelated
problems you actually have, and the critical path bounds what is achievable.
