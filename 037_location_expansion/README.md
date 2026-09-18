# 037 - $(location) and Friends

**Concepts:** `$(location)`, `$(execpath)`, `$(rootpath)`, `tools`

## Run it

```bash
bazel build //037_location_expansion:all
cat bazel-bin/037_location_expansion/shouted.txt
cat bazel-bin/037_location_expansion/variants.txt
```

## The problem being solved

A command needs a *path*, but you only have a *label*. Paths depend on the
configuration (`k8-fastbuild` vs `k8-opt`), on whether the file is a source or
generated, and on whether the build is local or remote. Hard-coding one is a
bug waiting to happen.

## The three expansions

| Expansion | Gives you | Use it for |
|-----------|-----------|-----------|
| `$(execpath x)` | Path relative to the execution root | **Build actions** |
| `$(rootpath x)` | Path relative to the runfiles root | **Programs at runtime** |
| `$(location x)` | Older alias; picks one of the above | Legacy / simple cases |

Plural forms exist for targets with several outputs: `$(execpaths x)`,
`$(rootpaths x)`, `$(locations x)`.

Modern guidance: use `$(execpath)` in `genrule.cmd`, and `$(rootpath)` in
`args` of a binary or test.

## `tools` vs `srcs`

Put **executables** in `tools`, data in `srcs`. `tools` are built for the
execution platform; `srcs` for the target platform. On a same-machine build the
difference is invisible - when cross-compiling, putting a tool in `srcs` builds
it for the wrong architecture and it will not run.

## Key takeaway

Never write a literal `bazel-bin/...` path. Let `$(execpath)` compute it.
