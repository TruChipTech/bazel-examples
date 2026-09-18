# 178 - Test Result Caching

**Concepts:** cached test results, `--cache_test_results`, `external`

## Try it

```bash
T=//178_test_caching

bazel test $T:cached_test --test_output=all     # runs
bazel test $T:cached_test --test_output=all     # "(cached) PASSED" - did NOT run

bazel test $T:never_cached_test --test_output=all   # runs
bazel test $T:never_cached_test --test_output=all   # runs AGAIN
```

Watch the printed timestamp: for the cached test it never changes.

## What gets cached

A test result is cached on the test's **complete input closure**: the binary,
its runfiles, its environment, the test's own attributes. If none of that
changed, the result cannot change either, so Bazel reuses it.

This is why `bazel test //...` on a large repo takes seconds when nothing
changed - it is not running 10,000 tests, it is confirming 10,000 unchanged
input hashes.

## Controlling it

```bash
--cache_test_results=auto    # default: cache passing results
--cache_test_results=yes     # cache pass AND fail
--cache_test_results=no      # never cache (alias: --nocache_test_results)
--runs_per_test=10           # implies no caching
```

Note the default: **failures are not cached**. A failing test re-runs, which is
what you want while fixing it.

## Opting out per target

```python
tags = ["external"]     # never cached - depends on something outside the graph
tags = ["no-cache"]     # same effect for the action
```

Use `external` for a test that genuinely talks to an outside system. Be honest
about it: a test marked `external` that is actually hermetic just wastes CI
time, and a hermetic-looking test that secretly hits the network will be cached
and give stale results.

## When caching hides a real problem

"My test passes in CI but the code is broken" occasionally means the test
result was cached from before the change. That is almost always because a
dependency was **not declared** - the test reads a file nobody listed, so
changing that file does not invalidate the result.

The fix is to declare the dependency, not to disable caching. Confirm with:

```bash
bazel test //x:y --nocache_test_results   # does it fail now?
```

If yes, something is undeclared. Find it with `--sandbox_debug` (sample 158).

## Remote test caching

With a remote cache, test results are shared across the whole team: CI runs the
suite once, and every developer's `bazel test //...` is a cache hit. This is
often the largest single win from remote caching.

## Key takeaway

Test caching is why `bazel test //...` scales. If a cached result looks wrong,
suspect an undeclared input before disabling the cache.
