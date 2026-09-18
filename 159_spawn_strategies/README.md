# 159 - Execution Strategies

**Concepts:** `--spawn_strategy`, `--strategy`, dynamic execution

## Selecting strategies

```bash
# Global default, with fallbacks in order
bazel build //... --spawn_strategy=remote,worker,linux-sandbox,local

# Per mnemonic - the precise tool
bazel build //... --strategy=Javac=worker
bazel build //... --strategy=CppCompile=remote
bazel build //... --strategy=Genrule=local

# Per mnemonic for tests
bazel test //... --test_strategy=exclusive
```

`--strategy` beats `--spawn_strategy` for the mnemonic it names, which is why
sample 105 stressed choosing good mnemonics: they are the handle for all of
this.

## Dynamic execution

```
build --internal_spawn_scheduler
build --spawn_strategy=dynamic
build --dynamic_local_strategy=worker,sandboxed
build --dynamic_remote_strategy=remote
```

Dynamic execution starts the action **locally and remotely at the same time**
and takes whichever finishes first, cancelling the other.

This is genuinely clever: small actions finish locally before the remote round
trip completes, while large ones benefit from the remote fleet. You get the
better of the two without having to classify actions by hand.

The cost is duplicated work - you are paying for both. That is usually the
right trade when developer latency is the expensive resource.

## Execution requirements from rules

A rule can constrain how its actions run:

```python
ctx.actions.run(
    ...,
    execution_requirements = {
        "no-remote": "1",        # never remote
        "no-cache": "1",         # never cache the result
        "no-sandbox": "1",       # cannot be sandboxed
        "requires-network": "1", # needs network access
        "supports-workers": "1", # eligible for worker strategy
        "cpu:4": "1",            # reserve 4 cores
    },
)
```

The same keys work as `tags` on a target.

## Overriding from the command line

```bash
bazel build //... --modify_execution_info=CppCompile=+no-remote
bazel build //... --modify_execution_info=.*=+no-cache
```

Useful for bisecting: "does this failure go away if nothing is cached?"

## Tuning parallelism

```bash
--jobs=200            # concurrent actions (raise it a lot for remote execution)
--local_cpu_resources=HOST_CPUS*0.8
--local_ram_resources=HOST_RAM*0.5
```

With remote execution, `--jobs` should be far larger than your core count - the
limit is the remote fleet, not your machine. Locally, `--jobs` above your core
count mostly causes thrashing.

## Diagnosing which strategy ran

```bash
bazel build //... --execution_log_json_file=/tmp/exec.json
jq -r '.runner' /tmp/exec.json | sort | uniq -c
```

Or read the build summary:

```
INFO: 512 processes: 300 remote cache hit, 200 remote, 12 linux-sandbox.
```

## Key takeaway

Strategies are chosen per mnemonic. Start with the defaults, measure with the
execution log, and only then pin specific mnemonics.
