# 042 - bazel info and the Directory Layout

**Concepts:** `bazel info`, output base, execution root, the server

## Try it

```bash
bazel info                        # everything
bazel info workspace              # one key
bazel info output_base
bazel info execution_root
bazel info bazel-bin
bazel info release
```

## The keys that matter

| Key | What it is |
|-----|-----------|
| `workspace` | Your source root (where `MODULE.bazel` lives) |
| `output_base` | Per-workspace cache dir under `~/.cache/bazel/` |
| `execution_root` | Where actions actually run; a symlink forest of inputs |
| `bazel-bin` | Build outputs for the **current** configuration |
| `bazel-testlogs` | Test logs |
| `repository_cache` | Downloaded archives, shared across all workspaces |
| `server_pid` | PID of the background Bazel server |

Note that `bazel info bazel-bin` respects flags, so this prints two different
paths:

```bash
bazel info bazel-bin -c dbg
bazel info bazel-bin -c opt
```

## The Bazel server

Bazel runs as a long-lived JVM server; the `bazel` command is a thin client.
That is why the first build after a reboot is slow and later ones are fast -
the server keeps the entire analysis graph in memory.

```bash
bazel shutdown        # stop the server (loses the in-memory cache)
bazel info server_pid # who is holding all that RAM
```

Almost every "Bazel is slow today" report is really "the server restarted".
Stopping it discards the analysis cache; avoid `bazel shutdown` as a reflex.

## Key takeaway

`bazel info` is how you find anything Bazel produced without guessing at paths.
