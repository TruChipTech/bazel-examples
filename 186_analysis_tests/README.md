# 186 - Analysis Tests

**Concepts:** `analysistest`, testing rule implementations

## Run it

```bash
bazel test //186_analysis_tests:rules_tests --test_output=errors
```

Three tests: one checks a custom provider, one checks the declared outputs, and
one asserts the rule **fails** on invalid input.

## What analysistest gives you

`unittest` (sample 185) tests pure Starlark functions. `analysistest` tests a
**rule implementation** by analyzing a real target and inspecting the result.

```python
def _impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.true(env, MyInfo in target)
    asserts.equals(env, "expected", target[MyInfo].field)

    return analysistest.end(env)

my_test = analysistest.make(_impl)

my_test(name = "my_test", target_under_test = ":some_target")
```

## What you can inspect

```python
target[DefaultInfo].files.to_list()       # declared outputs
target[MyProvider].field                  # custom providers
analysistest.target_actions(env)          # the ACTIONS the rule registered
analysistest.target_bin_dir_path(env)
```

`target_actions` is the powerful one - you can assert on the actual command
line without running anything:

```python
actions = analysistest.target_actions(env)
compile_actions = [a for a in actions if a.mnemonic == "MyCompile"]
asserts.equals(env, 1, len(compile_actions))
asserts.true(env, "--optimize" in compile_actions[0].argv)
```

## Testing failure

```python
failure_test = analysistest.make(_impl, expect_failure = True)

def _impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "count must not be negative")
    return analysistest.end(env)
```

Testing your `fail()` messages matters more than it sounds: those messages are
the entire user experience when someone misuses your rule. A test pins them so
a refactor cannot silently degrade them into a stack trace.

## Testing under a different configuration

```python
my_test = analysistest.make(
    _impl,
    config_settings = {"//command_line_option:compilation_mode": "opt"},
)
```

The target under test is analyzed with those settings - which is how you test
`select()` branches and transitions without running a build in that mode.

## Tag the subjects `manual`

```python
tagged_file(name = "subject_bad", count = -1, tags = ["manual"])
```

The deliberately-broken target must not be built by `bazel build //...`.
`manual` keeps it out of wildcards while the test can still reference it
directly.

## Key takeaway

`analysistest` verifies providers, outputs, actions and failure messages
without executing anything. A rule set without analysis tests breaks silently.
