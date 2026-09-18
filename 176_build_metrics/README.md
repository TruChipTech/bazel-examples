# 176 - Build Metrics and Health

**Concepts:** cache hit rate, trend tracking, `buildMetrics`

## Run it

```bash
M=//176_build_metrics

bazel test //156_build_event_protocol:all \
  --build_event_json_file=/tmp/bep.json
bazel run $M:bep_metrics -- /tmp/bep.json
```

## The metric that matters most

```
cache hit rate : 94.2%
```

**Actions created vs actions executed.** Everything else follows from it: a
build that hits 95% of its cache is fast regardless of how big the repo is, and
a build that hits 40% is slow regardless of how fast your machines are.

Graph it per CI run. A slow decline is the earliest warning of a hermeticity
regression, and it is invisible in any single build.

## Metrics worth recording per invocation

| Metric | From | Watch for |
|--------|------|-----------|
| Cache hit rate | `actionSummary` | Gradual decline = hermeticity leak |
| Analysis time | `timingMetrics` | Growth = too many targets/configurations |
| Execution time | `timingMetrics` | Growth = more work, or lost parallelism |
| Peak heap | `memoryMetrics` | Approaching the limit = OOM soon |
| Actions created | `actionSummary` | Sudden jumps = a macro gone wrong |
| Test count and duration | `testSummary` | Slowest tests, flake rate |

## Reading them directly

```bash
jq 'select(.buildMetrics) | .buildMetrics.actionSummary' /tmp/bep.json
jq 'select(.buildMetrics) | .buildMetrics.timingMetrics' /tmp/bep.json
jq 'select(.buildMetrics) | .buildMetrics.memoryMetrics' /tmp/bep.json
```

## Diagnosing a hit-rate drop

When the rate falls, the cause is almost always one of:

1. A new `--action_env` carrying a host-specific value (sample 161)
2. A non-hermetic toolchain - each machine's compiler differs (sample 169)
3. A timestamp or path leaking into an output (sample 163)
4. A Bazel version mismatch between CI and developers (sample 165)
5. A new transition multiplying configurations (sample 143)

Confirm with an execution-log diff between two machines (sample 162).

## Wiring it into CI

```yaml
- run: bazel test //... --build_event_json_file=bep.json
- run: bazel run //176_build_metrics:bep_metrics -- bep.json
- run: ./tools/push_metrics.sh bep.json      # to your metrics backend
```

Or use a BES backend (sample 156), which does the collection and graphing for
you.

## Key takeaway

Track the cache hit rate over time. It is the leading indicator for every
Bazel performance problem you are going to have.
