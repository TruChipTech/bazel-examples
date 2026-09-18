# 032 - build vs run vs test

**Concepts:** the three core commands

## The commands

```bash
T=//032_build_run_test

bazel build $T:tool        # produce the artifact, do not execute it
bazel run   $T:tool -- a b # build, then execute, forwarding args after --
bazel test  $T:tool_test   # build, execute as a test, cache the result
```

## What each one actually does

| Command | Builds | Executes | Caches result | Works on |
|---------|--------|----------|---------------|----------|
| `build` | yes | no | outputs | any target |
| `run` | yes | yes | outputs only | executable targets |
| `test` | yes | yes | outputs **and pass/fail** | `*_test` targets |

## Why `--` matters

```bash
bazel run //x:tool --verbose_failures -- --verbose_failures
#                  ^^ flag for Bazel     ^^ argument for your program
```

Everything before `--` is parsed by Bazel. Everything after is handed to the
program untouched. Forgetting `--` is why `bazel run //x:tool --help` prints
Bazel's help instead of your tool's.

## `bazel run` changes the working directory

`bazel run` executes from the runfiles directory, not from where you typed the
command. If your tool needs the caller's directory, use
`$BUILD_WORKING_DIRECTORY`, which Bazel sets for exactly this reason:

```python
import os
user_cwd = os.environ.get("BUILD_WORKING_DIRECTORY", os.getcwd())
```

## Useful relatives

```bash
bazel build //...          # everything
bazel test  //...          # every test
bazel coverage //...       # tests + coverage report
bazel run  //...           # ERROR - run takes exactly one target
```

## Key takeaway

`build` for artifacts, `run` for tools, `test` for verification. Only `test`
caches a *result* rather than just outputs.
