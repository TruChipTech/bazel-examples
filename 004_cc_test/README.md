# 004 - Writing a Test

**Concepts:** `cc_test`, exit codes, test caching

## Run it

```bash
bazel test //004_cc_test:calculator_test

# See the output even when it passes:
bazel test //004_cc_test:calculator_test --test_output=all
```

## The contract for a test

A Bazel test is simply **an executable that exits 0 on success**. No framework
is required. That is why this sample uses plain `printf` and a failure counter;
GoogleTest would work identically but adds a dependency.

## Test caching

Run the test twice. The second run prints:

```
//004_cc_test:calculator_test  (cached) PASSED
```

Bazel knows nothing changed, so it does not re-run the test. This is the single
biggest reason large repos stay testable: CI only re-runs tests whose inputs
actually moved. Force a re-run with `--nocache_test_results`.

## Where output goes

Logs land in `bazel-testlogs/004_cc_test/calculator_test/test.log`.

## Key takeaway

Exit code 0 = pass. Everything else Bazel gives you - caching, parallelism,
log capture - comes for free once that contract is met.
