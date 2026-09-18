# 100 - Capstone: Composable Build

**Concepts:** everything from 051-099 together

## Run it

```bash
C=//100_capstone_composition

bazel build $C/...
bazel run   $C/cli:tasks
bazel test  $C:all_tests

# Flip the backend flag - one line changes the generated config module:
bazel run $C/cli:tasks --//100_capstone_composition/engine:backend=disk

# Package it:
bazel build $C:dist
tar tzf bazel-bin/100_capstone_composition/dist.tar.gz | head
```

`dist.tar.gz` is ~77 MB, because `include_runfiles = True` on a `py_binary`
bundles the hermetic CPython interpreter along with the app. This is the one
place in the repo that ships it, deliberately - sample 085 breaks down where
every megabyte goes.

## The layout

```
100_capstone_composition/
  schema/     proto_library + py_proto_library    the contract
  engine/     string_flag + expand_template + py_library
  cli/        py_binary
  tests/      py_test
  BUILD       test_suite + pkg_tar
```

## What each piece exercises

| Concept | Sample | Where it appears |
|---------|--------|------------------|
| Protobuf schema | 074-076 | `schema/` |
| Custom build setting | 059 | `engine:backend` |
| `config_setting` + `select` | 056-058 | `engine:backend_config` |
| `expand_template` | 083 | Generated `backend_config.py` |
| Generated source in a library | 048 | `py_library(srcs = [":backend_config.py"])` |
| Subpackage visibility | 015-016 | `__subpackages__` |
| `test_suite` | 028 | `:all_tests` |
| Packaging | 085 | `:dist` |

## The idea worth taking away

The backend is chosen by a **flag**, turned into a **generated source file** by
`expand_template`, and consumed by a library that has no idea a flag was
involved. Nothing in `store.py` reads configuration at runtime - the
configuration was resolved at build time, and the two variants are cached
separately.

That pattern - configuration resolved during analysis, not at startup - is
what makes Bazel builds both fast and reproducible.

## Where this leads

That covers composing builds: macros, configuration, external dependencies,
packaging and multi-language integration.

Samples 101-150 move from *using* rules to *writing* them: actions, providers,
depsets, aspects and toolchains.
