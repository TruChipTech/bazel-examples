# 078 - Flaky Tests

**Concepts:** `flaky`, `--runs_per_test`, `--flaky_test_attempts`

## Detect flakiness

```bash
# Run the test 20 times; any failure means it is flaky.
bazel test //078_flaky_tests:stable_test --runs_per_test=20

# Do not let caching hide the problem:
bazel test //078_flaky_tests:stable_test \
  --runs_per_test=20 --nocache_test_results
```

`--runs_per_test` is the single most useful flakiness tool. A test that passes
20 times in a row is probably deterministic; one that fails once in 20 will
fail in CI eventually.

## `flaky = True`

```python
py_test(name = "quarantined_test", flaky = True)
```

Bazel retries up to 3 times and reports `FLAKY` if an earlier attempt failed
but a later one passed. The result still counts as a pass.

Use it as a **temporary quarantine** with an owner and a deadline, never as a
permanent state. A `flaky = True` test that nobody is fixing is a test that has
stopped providing signal - it will pass regardless of whether the code works.

## Command-line equivalents

```bash
--flaky_test_attempts=3          # treat everything as flaky (CI triage only)
--flaky_test_attempts=//foo:bar@5  # per-target
```

## The usual causes

| Cause | Fix |
|-------|-----|
| Shared global state between tests | Isolate setup/teardown |
| Real time / `sleep` | Inject a fake clock (sample 060's `label_flag`) |
| Network or external services | Hermetic fakes; tag `external` if unavoidable |
| Unordered iteration assumed ordered | Sort before comparing |
| Ports, temp files with fixed names | Use `TEST_TMPDIR`, bind port 0 |
| Undeclared inputs | The sandbox usually catches these - do not disable it |

## Bazel makes flakiness *findable*

Because inputs are declared and tests are sandboxed, a test that depends on
something undeclared fails immediately rather than intermittently. Most
remaining flakiness is genuine nondeterminism in the code under test.

## Key takeaway

`--runs_per_test` to find flakiness, `flaky = True` to quarantine briefly, and
a real fix to close it out.
