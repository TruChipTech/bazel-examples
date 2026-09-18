# 033 - .bazelrc: Persistent Flags

**Concepts:** `.bazelrc`, flag precedence, `try-import`

Read the repo's [`.bazelrc`](../../.bazelrc) alongside this file.

## The format

```
<command> <flag>
```

```
build --verbose_failures      # applies to build
test  --test_output=errors    # applies to test
common --announce_rc          # applies to EVERY command
```

Because `test` implies `build`, a `build` line also affects `bazel test`.

## Where Bazel looks, in order

1. The **system** rc: `/etc/bazel.bazelrc`
2. The **workspace** rc: `.bazelrc` in the workspace root (this repo's file)
3. The **home** rc: `~/.bazelrc`
4. Any file named by `--bazelrc=<path>`

Later files win. Command-line flags always beat every rc file.

## `try-import` for personal settings

```
# In .bazelrc, checked in:
try-import %workspace%/user.bazelrc
```

`try-import` does not fail if the file is missing, so each developer can keep a
`user.bazelrc` (gitignored) with local overrides - a personal disk cache path,
extra `--jobs`, and so on - without touching the shared file.

## See what is actually being applied

```bash
bazel build --announce_rc //033_bazelrc_basics:show_rc
```

This prints every rc line Bazel picked up. It is the first thing to run when a
build behaves differently than you expect.

## Key takeaway

`.bazelrc` is how a repo makes correct flags the default. If a flag matters for
correctness, it belongs there, not in a README or someone's shell alias.
