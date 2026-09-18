# 091 - Workspace Status and Stamping

**Concepts:** `--stamp`, `--workspace_status_command`, `info_file` vs `version_file`

## Run it

```bash
bazel build //091_workspace_status:build_info
cat bazel-bin/091_workspace_status/build_info.txt

# With the repo's status script (see //.bazelrc --config=release):
bazel build --config=release //091_workspace_status:build_info
cat bazel-bin/091_workspace_status/build_info.txt
```

## The status script

`--workspace_status_command` points at a program that prints `KEY VALUE` lines.
This repo ships [`tools/workspace_status.sh`](../../tools/workspace_status.sh):

```bash
echo "BUILD_TIMESTAMP $(date +%s)"
echo "BUILD_HOST $(hostname)"
echo "STABLE_GIT_COMMIT $(git rev-parse HEAD)"
```

## The critical distinction

| Starlark field | Actual file | Contains | Changing a value... |
|----------------|-------------|----------|---------------------|
| `ctx.info_file` | `stable-status.txt` | keys **with** `STABLE_` | **does** trigger a rebuild |
| `ctx.version_file` | `volatile-status.txt` | keys **without** `STABLE_` | does **not** invalidate anything |

**The names are counter-intuitive**: `version_file` is the *volatile* one, and
`info_file` is the *stable* one. Run this sample and read the output - it prints
both files with their real names, which is the quickest way to confirm which is
which.

This is the whole point of the design. A timestamp changes on every build - if
it invalidated the cache, nothing would ever be cached again. So timestamps go
in the volatile file, and the git SHA (which only changes on a real commit)
goes in the stable file.

**Getting this backwards destroys your cache.** Prefixing a timestamp with
`STABLE_` means every build rebuilds everything downstream of it.

## Using it in a rule

```python
ctx.actions.run_shell(
    inputs = [ctx.info_file],                    # the STABLE_ values
    outputs = [out],
    command = "grep '^STABLE_GIT_COMMIT ' \"$1\" | cut -d' ' -f2- > \"$2\"",
    arguments = [ctx.info_file.path, out.path],
)
```

Whichever files you read must be declared as action inputs.

## `--stamp` and `--nostamp`

Most rules that support stamping have a `stamp` attribute:

```python
cc_binary(name = "server", stamp = 1)   # 1 = always, 0 = never, -1 = follow --stamp
```

Default is `-1`: stamping happens only when `--stamp` is passed. Keep
development builds unstamped so they stay cacheable, and stamp releases.

## Key takeaway

`STABLE_` means "part of the cache key". Use it only for values that genuinely
identify the source state.
