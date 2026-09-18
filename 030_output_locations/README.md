# 030 - Where Outputs Go

**Concepts:** `bazel-bin`, `bazel-out`, the output base, `bazel clean`

## Run it

```bash
bazel build //030_output_locations:all
cat bazel-bin/030_output_locations/generated.txt
cat bazel-bin/030_output_locations/sub/dir/deep.txt
```

## The convenience symlinks

After a build, Bazel creates these in the workspace root:

| Symlink | Points to |
|---------|-----------|
| `bazel-bin` | Binaries and generated files for the current configuration |
| `bazel-testlogs` | Test logs and XML results |
| `bazel-out` | The root of all configurations |
| `bazel-<workspace>` | The execution root |

They are symlinks into `~/.cache/bazel/...`, **not** real directories. That is
why `.gitignore` lists `/bazel-*`.

## Outputs are never written into your source tree

This is a hard rule. A build can never modify a source file, which is what
makes a clean checkout and an incremental build produce identical results. If
you need generated code committed to the repo, you copy it out explicitly with
a `write_source_files`-style rule.

## The path encodes the configuration

```
bazel-out/k8-fastbuild/bin/030_output_locations/generated.txt
          ^^^^^^^^^^^^
          cpu + compilation mode
```

Different configurations never collide, which is why `-c opt` and `-c dbg`
caches coexist.

## Cleaning

```bash
bazel clean          # delete outputs, keep the analysis cache and server
bazel clean --expunge  # delete everything including external repos (slow!)
```

`--expunge` is almost never the right answer. Reach for it only when you
suspect a corrupted external repository.

## Key takeaway

Outputs live outside the source tree, keyed by configuration. Never edit
anything under `bazel-bin`; it is regenerated.
