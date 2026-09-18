# 113 - Custom Test Rules

**Concepts:** `test = True`, test environment, policy tests

## Run it

```bash
T=//113_custom_test_rules

bazel test $T:configs_have_names --test_output=all

# The deliberately failing one:
bazel test $T:configs_have_owners --test_output=all
```

## `test = True`

```python
schema_test = rule(implementation = _impl, test = True, attrs = {...})
```

That single change turns an executable rule into a test rule:

- `bazel test` finds and runs it
- The **result** is cached, not just the outputs
- It receives `TEST_TMPDIR`, `TEST_SHARD_INDEX`, `TEST_SRCDIR` etc.
- `size`, `timeout`, `flaky`, `shard_count` become available automatically
- Convention requires the rule name to end in `_test`

## Inputs go in runfiles, not inputs

A test executes in the **runfiles tree**. Files it must read belong in
`DefaultInfo.runfiles`, and paths must be `short_path`. Putting them in an
action's `inputs` is meaningless - the test is not an action, it is a program
Bazel runs afterwards.

## Why write a custom test rule?

For **policy tests** - assertions about the repo rather than about code
behavior:

- Every service config declares an owner
- No BUILD file in `//public/...` depends on `//internal/...`
- Every proto has a corresponding language binding
- Generated files are up to date (`diff_test`, sample 087)
- Every `*_test` target carries a `size`

These scale far better as a rule than as a shell script, because the rule takes
the files as declared inputs - so the test re-runs exactly when a relevant file
changes and is cached otherwise.

## The alternative: a generic runner

If the logic is complex, write the checker as a normal program and use a
`sh_test`/`py_test` with the files in `data`. Write a custom rule when you want
the *declaration* in BUILD files to be concise and typed.

## Key takeaway

`test = True` is the whole difference. Custom test rules are the natural home
for repo-wide policy checks.
