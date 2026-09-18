# 009 - Shell Tests and `data`

**Concepts:** `sh_test`, `data`, runfiles, working directory

## Run it

```bash
bazel test //009_sh_test:check_format --test_output=all
```

## The `data` attribute

`srcs` is code that runs. `data` is everything the program needs to *read* at
runtime: fixtures, configs, golden files, test corpora.

Delete `data = ["config.ini"]` and the test fails with "cannot find". The file
is still on disk, but the test executes in a sandbox containing only declared
inputs.

## Working directory

A test runs with its working directory set to the **runfiles root**, which
mirrors the workspace layout. That is why the script refers to
`009_sh_test/config.ini` - the full path from the workspace root -
rather than just `config.ini`.

Sample 080 shows the runfiles libraries, which look these paths up properly
instead of hard-coding them.

## Key takeaway

If a program reads a file at runtime, that file belongs in `data`. Forgetting
this is the single most common cause of "works locally, fails in CI".
