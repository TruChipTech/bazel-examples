# 187 - Testing a Rule Set End to End

**Concepts:** the three stages of rule testing

## Run it

```bash
bazel test //187_testing_rule_sets/... --test_output=errors
```

Three tests, testing three genuinely different things about one rule.

## The three stages

| Stage | Tool | Answers | Cost |
|-------|------|---------|------|
| 1. It builds | `build_test` | Does analysis succeed? | Cheapest |
| 2. It is wired correctly | `analysistest` | Right actions, providers, flags? | Cheap - no execution |
| 3. It is correct | `diff_test` | Is the OUTPUT right? | Runs the actions |

A rule set needs all three, and they catch different bugs:

- **Stage 1** catches a broken attribute schema or a missing load.
- **Stage 2** catches "the flag is not being passed", "the action has the wrong
  inputs", "the provider field is empty" - without ever running a compiler.
- **Stage 3** catches "the tool produces the wrong bytes".

## Stage 2 is the one people skip

```python
actions = analysistest.target_actions(env)
report_actions = [a for a in actions if a.mnemonic == "CsvReport"]
asserts.equals(env, 1, len(report_actions))
asserts.true(env, "--optimize" in report_actions[0].argv)
```

You can assert on the exact command line with no execution at all. That makes
it feasible to test every `select()` branch, every configuration, and every
flag combination - something stage 3 could never afford.

## Stage 3 with a blessing target

Golden files rot unless updating them is trivial:

```python
load("@bazel_skylib//rules:write_source_files.bzl", "write_source_files")

write_source_files(
    name = "update_golden",
    files = {"expected_report.txt": ":roster"},
)
```

```bash
bazel run //187_testing_rule_sets:update_golden
```

This also generates a test that fails when the checked-in file is stale, so a
forgotten update cannot merge.

## Testing across configurations

```python
opt_test = analysistest.make(
    _impl,
    config_settings = {"//command_line_option:compilation_mode": "opt"},
)
```

This is how you verify that the `-c opt` branch of a `select()` does what you
think, without building anything in opt mode.

## What to test in a rule set you publish

1. Every rule builds with minimal attributes (`build_test`)
2. Every provider field is populated (`analysistest`)
3. Every `fail()` message fires on the right input (`expect_failure`)
4. The generated command line contains the expected flags (`target_actions`)
5. At least one end-to-end golden test per rule (`diff_test`)

## Key takeaway

`build_test` for analysis, `analysistest` for wiring, `diff_test` for output.
Stage 2 is the cheapest place to catch the most bugs.
