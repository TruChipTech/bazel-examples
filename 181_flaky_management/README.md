# 181 - Managing Flaky Tests at Scale

**Concepts:** detection, quarantine, root-causing

## Try it

```bash
F=//181_flaky_management

# A stable test stays stable
bazel test $F:deterministic_test --runs_per_test=20 --nocache_test_results

# The unreliable one fails some of the runs
bazel test $F:unreliable_test --runs_per_test=20 --nocache_test_results
```

## Detection

```bash
bazel test //... --runs_per_test=10 --nocache_test_results
```

`--nocache_test_results` is essential - without it, Bazel caches the first
pass and you learn nothing.

Run this nightly across the whole repo. It finds flakes **before** they fail a
colleague's presubmit, which is the difference between a known issue and an
interruption.

## The lifecycle

```
1. DETECT      nightly --runs_per_test
2. QUARANTINE  flaky = True, with an owner and a date
3. DIAGNOSE    reproduce, usually under load or with --runs_per_test
4. FIX         remove flaky = True
```

Step 2 without steps 3-4 is how a test suite stops providing signal.

## Quarantine honestly

```python
py_test(
    name = "sometimes_test",
    flaky = True,      # TODO(alice): root cause by 2026-10-15, see BUG-1234
)
```

`flaky = True` retries up to three times and reports `FLAKY` if an earlier
attempt failed. The build still goes green - which is the point, and also the
danger. Every `flaky = True` needs an owner and a deadline in the comment.

Track them:

```bash
bazel query 'attr(flaky, 1, //...)' --output=label
```

If that list only grows, the suite is decaying.

## Root causes, and what actually fixes them

| Cause | Fix |
|-------|-----|
| Shared state between tests | Per-test setup/teardown; `TEST_TMPDIR` |
| Real time, `sleep`, timeouts | Inject a fake clock (`label_flag`, sample 060) |
| Fixed ports | Bind port 0, read back the assigned port |
| Unordered iteration treated as ordered | Sort before comparing |
| Test ordering dependence | `--runs_per_test` plus randomized order |
| Resource contention under load | Correct `size` (sample 026) |
| **Undeclared inputs** | Declare them - the sandbox will tell you |

That last one is worth emphasizing: Bazel's sandbox eliminates a whole class of
flakiness that other build systems suffer from. If a test is flaky *because of*
undeclared inputs, `--spawn_strategy=linux-sandbox` surfaces it immediately.

## Timeouts masquerading as flakes

A test marked `small` that sometimes takes 70 seconds fails intermittently
under load. That is not nondeterminism, it is a mislabeled `size`:

```bash
bazel test //... --test_verbose_timeout_warnings
```

## Key takeaway

Detect nightly with `--runs_per_test --nocache_test_results`, quarantine with
an owner and a date, and fix the cause. `flaky = True` is a bookmark, not a
resolution.
