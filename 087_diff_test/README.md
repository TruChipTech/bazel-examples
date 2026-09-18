# 087 - Golden File Testing With diff_test

**Concepts:** `diff_test`, golden files, characterization tests

## Run it

```bash
bazel test //087_diff_test:report_matches_golden
```

## Break it

Change any row in `format_report.py` and re-run. The test fails and prints a
unified diff showing exactly what moved.

## When golden tests are the right tool

- **Generated code.** Proves the generator's output is stable.
- **Formatted output.** Reports, CLI help text, rendered templates.
- **Serialized data.** Config files, manifests, schemas.
- **Legacy code you are refactoring.** Capture current behavior, refactor, and
  the test proves nothing observable changed. This is "characterization
  testing", and it is the safest way to start on code with no tests.

## Updating the golden file

The workflow that makes this bearable is a blessing target:

```python
load("@bazel_skylib//rules:write_source_files.bzl", "write_source_files")

write_source_files(
    name = "update_golden",
    files = {"expected_report.txt": ":actual_report.txt"},
)
```

Then:

```bash
bazel run //087_diff_test:update_golden   # copy actual over expected
```

`write_source_files` also generates a *test* that fails when the checked-in
file is stale, so a forgotten update cannot slip through review.

## The failure mode to watch for

Golden tests fail on *any* change, including intentional ones. If updating the
golden becomes routine and unexamined, the test has stopped verifying anything.
Keep goldens small and reviewable - a 4000-line golden file gets rubber-stamped.

## Key takeaway

`diff_test` is a complete assertion framework for "the output should look
exactly like this", and it pairs with `write_source_files` for painless updates.
