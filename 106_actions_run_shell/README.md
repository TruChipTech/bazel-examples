# 106 - ctx.actions.run_shell

**Concepts:** `run_shell`, shell pipelines, when not to use it

## Run it

```bash
bazel build //106_actions_run_shell:top
cat bazel-bin/106_actions_run_shell/top.txt
```

## When `run_shell` is justified

Only when you need what a shell provides:

- **Pipelines**: `cat | tr | sort | uniq -c`
- **Redirection**: `> file`, `2>&1`
- **Chaining**: `a && b || c`
- **Loops and conditionals** over inputs

If your command is "run this program with these arguments", use
`ctx.actions.run` (sample 105) instead. It is faster, needs no shell, and has
no quoting hazards.

## The costs

| Cost | Why |
|------|-----|
| Requires bash | Not present on stock Windows or minimal RE containers |
| Extra process | The shell wraps whatever you actually wanted to run |
| Quoting bugs | Every interpolated value is a potential injection |
| Harder to debug | Errors come from the shell, not your tool |

## Always start with `set -euo pipefail`

```python
command = """
  set -euo pipefail
  ...
"""
```

Without it, a failing command mid-pipeline is silently ignored and the action
"succeeds" having produced a truncated output. This is the single most common
bug in shell-based build actions.

## Arguments, not interpolation

```python
# GOOD - values arrive as $1, $2 and are never re-parsed
ctx.actions.run_shell(
    arguments = [src.path, out.path],
    command = 'process "$1" > "$2"',
)

# BAD - a filename with a space or a quote breaks this, or worse
ctx.actions.run_shell(
    command = "process %s > %s" % (src.path, out.path),
)
```

If you must interpolate, use `shell.quote` from skylib (sample 090).

## The better refactor

Shell logic inside a `command` string cannot be unit-tested. Once it grows past
a few lines, move it into a real script or program, make that a Bazel target,
and invoke it with `ctx.actions.run`. Then the logic is testable and the rule
stays simple.

## Key takeaway

`run_shell` is for shell features, not for convenience. Start with
`set -euo pipefail`, pass values as arguments, and migrate complex logic into
a proper tool.
