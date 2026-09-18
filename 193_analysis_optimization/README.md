# 193 - Analysis Phase Optimization

**Concepts:** configured targets, configuration explosion

## Measure it

```bash
bazel build --nobuild //... --profile=/tmp/prof.gz
bazel run //157_profiling:summarize_profile -- /tmp/prof.gz
```

`--nobuild` performs loading and analysis then stops, isolating analysis cost
from execution cost.

## What analysis time scales with

Not source lines. **Configured targets** - the product of:

```
targets  x  configurations they are built in
```

```bash
bazel query //... | wc -l       # targets
bazel cquery //... | wc -l      # CONFIGURED targets
bazel config | wc -l            # distinct configurations
```

If `cquery` returns several times what `query` does, something is multiplying
configurations.

## The main causes, in order

**1. Transitions.** Every transition applied high in the graph rebuilds
everything below it in a second configuration (samples 141-142). A split
transition with three keys triples that subgraph.

*Fix:* apply transitions as close to the leaves as possible, and check whether
you need one at all.

**2. Exec-configuration tools.** A target used both as a tool and as a
dependency is analyzed twice (sample 122). That is correct and unavoidable -
but a large library pulled into the exec configuration by accident is not.

*Fix:* keep tool dependencies small; do not let a tool depend on the
application.

**3. Aspects.** An aspect runs once per (target, aspect) pair. A broad
`attr_aspects = ["*"]` over a big graph is expensive (sample 131).

*Fix:* narrow `attr_aspects`.

**4. Too many targets.** Usually a macro generating more than anyone intended.

```bash
bazel query 'kind(".*", //some/package:all)' | wc -l
```

## Finding the multiplication

```bash
# Which labels appear in the most configurations?
bazel cquery //... --output=label 2>/dev/null | sed 's/ (.*//' | sort | uniq -c | sort -rn | head -20
```

A label appearing 6 times is being analyzed 6 times. Then find out why:

```bash
bazel config                  # list configurations
bazel config <hash1> <hash2>  # diff two of them
```

The diff names the exact flag that differs, which points at the transition.

## Flags that help

```bash
--discard_analysis_cache        # free memory after the build (CI)
--notrack_incremental_state     # CI: no incrementality needed
--nokeep_state_after_build      # CI
```

All three trade incrementality for memory. They are right for CI and wrong for
a developer machine.

## The analysis cache is why builds feel fast

A warm server skips analysis entirely for unchanged targets. Anything that
discards it - `bazel shutdown`, a startup flag change, a `.bazelrc` edit -
costs a full re-analysis. That is the usual explanation for a build that was
fast yesterday and slow today.

## Key takeaway

Analysis cost scales with configured targets. Compare `query` and `cquery`
counts; if they diverge, hunt the transition.
