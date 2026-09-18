# 156 - The Build Event Protocol

**Concepts:** BEP, `--build_event_json_file`, build observability

## Try it

```bash
B=//156_build_event_protocol

bazel test $B:all --build_event_json_file=/tmp/bep.json

# What event types were emitted?
jq -r 'keys[]' /tmp/bep.json | sort | uniq -c | sort -rn | head -20

# Test results
jq 'select(.testResult) | {label: .id.testResult.label, status: .testResult.status}' /tmp/bep.json

# Every artifact produced
jq -r 'select(.namedSetOfFiles) | .namedSetOfFiles.files[].name' /tmp/bep.json | head

# Overall outcome and timing
jq 'select(.finished) | .finished' /tmp/bep.json
```

## What the BEP is

A structured, streaming record of everything that happened during a build:
which targets were requested, which were configured, which actions failed,
which tests ran and with what result, what artifacts were produced, how long
it took, and what the exit status was.

```bash
--build_event_json_file=/tmp/bep.json      # JSON, easy to inspect
--build_event_binary_file=/tmp/bep.bin     # protobuf, compact
--build_event_text_file=/tmp/bep.txt       # human-readable protobuf
--bes_backend=grpcs://bes.internal         # stream to a service
```

## Why it beats scraping stdout

CI systems traditionally parse Bazel's console output with regexes, which
breaks whenever the output format changes and cannot express structure. The BEP
is a stable, versioned schema.

With it you can answer, reliably:

- Which tests failed, and where are their logs?
- Which targets were actually built for this commit?
- How long did each test take? Which are the slowest?
- What is the cache hit rate over time?
- Which artifacts should be uploaded for release?

## The event types that matter

| Event | Contains |
|-------|----------|
| `started` | Invocation ID, command, flags |
| `progress` | Streamed stdout/stderr |
| `configured` | Each configured target |
| `targetCompleted` | Success/failure + output groups |
| `testResult` | Per-test status, duration, log paths |
| `testSummary` | Aggregated per-test-target result |
| `namedSetOfFiles` | Artifact sets (referenced by other events) |
| `buildMetrics` | Action counts, cache hits, memory |
| `finished` | Exit code and overall status |

## `buildMetrics` is the one to graph

```bash
jq 'select(.buildMetrics) | .buildMetrics' /tmp/bep.json
```

It reports actions created vs executed, cache hits, analysis time, and peak
memory. Recording this per CI run gives you a cache-hit-rate trend - the single
most useful health metric for a Bazel repo, because a slow regression in hit
rate is otherwise invisible until builds are painfully slow.

## Build Event Service

```
build --bes_backend=grpcs://your-bes-backend
build --bes_results_url=https://your-ui/invocation/
```

Bazel then prints a URL for every build, where anyone can inspect what
happened. BuildBuddy, EngFlow and others provide this.

## Key takeaway

Do not parse Bazel's console output. Emit the BEP, query it with `jq`, and
graph `buildMetrics` over time.
