# 077 - Test Sharding

**Concepts:** `shard_count`, `TEST_SHARD_INDEX`, parallelism

## Run it

```bash
bazel test //077_test_sharding:big_test --test_output=all
```

You will see four separate shard runs, each reporting its index.

## How it works

Bazel runs the test binary **N times in parallel**, setting:

| Variable | Meaning |
|----------|---------|
| `TEST_TOTAL_SHARDS` | How many shards exist |
| `TEST_SHARD_INDEX` | Which one this process is (0-based) |
| `TEST_SHARD_STATUS_FILE` | The runner must touch this to confirm shard support |

A **shard-aware test runner** reads these and runs only its slice. The runners
shipped with `py_test`, `java_test` and GoogleTest all support it.

Bazel decides the split, not you. There is no way to assign specific cases to
specific shards - which is deliberate, since it keeps the split an
implementation detail that can be rebalanced.

## If the runner is not shard-aware

Bazel detects this and **fails the test**:

```
Sharding requested, but the test runner did not advertise support for it by
touching TEST_SHARD_STATUS_FILE. Either remove the 'shard_count' attribute,
use a test runner that supports sharding, or temporarily disable this check
via --noincompatible_check_sharding_support.
```

The plain `unittest.main()` entry point does **not** support sharding, which is
why `big_test.py` here implements the protocol by hand: it touches the status
file and filters the suite. Real runners - pytest with `pytest-shard`, the JUnit
runner, GoogleTest - do this for you.

Older Bazel versions silently ran every test in every shard instead: N times
the work and no speedup. The hard failure is a clear improvement.

## Sharding vs splitting the target

| | `shard_count = 4` | Four separate `py_test` targets |
|---|---|---|
| Parallelism | Yes | Yes |
| Caching granularity | Per shard | Per target |
| Failure attribution | "shard 2 failed" | "auth_test failed" |
| BUILD file churn | One attribute | Four targets to maintain |

Sharding is the right tool for one logically cohesive suite that is simply
slow. Splitting is better when the groups are genuinely different concerns.

## Choosing a count

Start with `shard_count = 4` and measure. Too many shards and per-process
startup cost dominates; too few and you keep the long tail. Anything above
about 10 rarely helps unless each case is very slow.

## Key takeaway

`shard_count` is a one-line change that turns a slow suite into a parallel one -
provided the test runner cooperates.
