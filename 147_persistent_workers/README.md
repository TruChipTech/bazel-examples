# 147 - Persistent Workers

**Concepts:** worker protocol, `supports-workers`, warm processes

## Run it

```bash
W=//147_persistent_workers

# One worker process, so all three requests share it:
bazel build $W:task_a $W:task_b $W:task_c \
  --strategy=WorkerTask=worker --worker_max_instances=1
head -2 bazel-bin/147_persistent_workers/task_*.txt

# Standalone (a fresh process per action), for comparison:
bazel build $W:task_a $W:task_b $W:task_c \
  --strategy=WorkerTask=local
```

With `--worker_max_instances=1` the three outputs share one `worker pid` and
the `requests so far` counter increments 1, 2, 3 - proof the process survived
between actions.

Without that flag Bazel starts up to `--worker_max_instances` workers (4 by
default) and runs the actions in parallel, so you may see three different pids
each reporting 1 request. That is the normal, desirable behavior; force a
single instance only to observe the reuse.

Note that outputs are cached, so a second run shows nothing. Change
`worker.py` (a content change, not just `touch`) to force re-execution.

## What a worker is

An ordinary process that Bazel keeps **alive** between actions, feeding it one
request at a time over stdin/stdout.

```
Bazel  -> {"arguments": ["--output=x", "--word=a"], "inputs": [...], "requestId": 0}
worker -> {"exitCode": 0, "output": "...", "requestId": 0}
```

## Why it matters

For tools with expensive startup, this is transformative:

| Tool | Cold start | Warm |
|------|-----------|------|
| `javac` (JVM boot + class loading) | ~1s | ~10ms |
| `scalac` | several seconds | tens of ms |
| TypeScript compiler | ~2s | ~50ms |

Bazel's Java compilation uses workers by default, which is why compiling 500
small Java targets is fast rather than 500 JVM startups.

## The three requirements

1. **Declare support** in the action:
   ```python
   execution_requirements = {
       "supports-workers": "1",
       "requires-worker-protocol": "json",   # or "proto"
   }
   ```
2. **Use a param file.** The real command line is reserved for
   `--persistent_worker`, so arguments must arrive via `@file`.
3. **Implement both modes.** Bazel may run the tool standalone (when workers
   are disabled, or for `--strategy` overrides), so the tool must still work as
   a one-shot process.

## Worker discipline

A worker process is reused, so it must be **stateless between requests**:

- Do not cache anything keyed on a previous request's inputs
- Do not `chdir`, leak file handles, or mutate globals that affect results
- Never write to stdout except the JSON response - stray prints corrupt the
  protocol

A worker that leaks state produces results that depend on build order. That is
among the hardest classes of bug to reproduce.

## Multiplex workers

```python
"supports-multiplex-workers": "1"
```

Allows one process to handle several requests **concurrently**, which requires
genuine thread-safety. Worth it for tools with a large memory footprint.

## Controlling workers

```bash
--strategy=WorkerTask=worker
--worker_max_instances=4
--worker_verbose               # see workers start, stop and get killed
--worker_quit_after_build
```

## Key takeaway

Workers amortize startup cost across actions. Declare `supports-workers`, pass
arguments in a param file, support standalone mode, and keep the process
stateless.
