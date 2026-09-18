# 179 - Splitting Tests Across CI

**Concepts:** tag filters, `test_suite`, sharding strategies

## Try it

```bash
S=//179_ci_sharding

bazel test $S:presubmit                                  # a named subset
bazel test $S/... --test_tag_filters=unit                # by tag
bazel test $S/... --test_tag_filters=-slow               # everything but slow
bazel test $S/... --test_tag_filters=integration,-slow   # combine
```

## Four ways to split, in order of preference

### 1. Do not split - let Bazel decide

```bash
bazel test //...
```

With test caching (sample 178) and a remote cache, only affected tests actually
run. This is the right default and most repos never need more.

### 2. Tag filters

```bash
bazel test //... --test_tag_filters=-integration   # fast presubmit
bazel test //... --test_tag_filters=integration    # nightly
```

Semantic, and the membership lives in BUILD files rather than CI config.

### 3. `test_suite` targets

```python
test_suite(name = "presubmit", tests = [...])
```

CI references one stable label forever; what is in it is a code change,
reviewed like any other.

### 4. Sharding across machines

```bash
# Runner i of N
bazel query 'tests(//...)' | sort | awk "NR % $N == $i" | xargs bazel test
```

Works, but note that it defeats some of Bazel's own scheduling and makes cache
locality worse. Prefer a bigger machine with `--jobs` and remote execution.

## `shard_count` vs CI sharding

| | `shard_count` (sample 077) | CI sharding |
|---|---------------------------|-------------|
| Splits | One test target | The set of targets |
| Parallelism | Within one machine | Across machines |
| Needs runner support | Yes | No |

They compose: CI splits targets across runners, `shard_count` splits a slow
target within a runner.

## The presubmit/postsubmit split

```bash
# Presubmit - must be fast, gates the merge
bazel test //... --test_tag_filters=-integration,-slow,-flaky

# Postsubmit - runs on main, may be slow
bazel test //...

# Nightly - everything, several times, to find flakes
bazel test //... --runs_per_test=5 --nocache_test_results
```

The nightly `--runs_per_test` run is how you find flaky tests **before** they
fail a colleague's presubmit (sample 181).

## What to avoid

Hard-coded target lists in CI config. They drift from reality within weeks,
nobody notices when a new test is not in them, and the CI file becomes a second
source of truth about the repo. Use tags and `test_suite` instead.

## Key takeaway

Start with `bazel test //...` and caching. Add tag filters when presubmit gets
slow. Keep the membership in BUILD files, never in CI YAML.
