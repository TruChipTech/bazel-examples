# 064 - Selecting on the Target Platform

**Concepts:** `@platforms//os`, selecting `deps` and `data`

## Run it

```bash
bazel run //064_select_on_platform:net
bazel build //064_select_on_platform:net \
  --platforms=//063_platforms:macos_arm64
```

## select() works on almost every attribute

This sample selects `copts` *and* `data`. The same works for:

```python
cc_library(
    name = "platform_io",
    srcs = select({
        ":linux": ["io_epoll.cc"],
        ":macos": ["io_kqueue.cc"],
    }),
    deps = select({
        ":linux": ["@libaio"],
        "//conditions:default": [],
    }),
)
```

Selecting `srcs` and `deps` is the standard way to write portable C++ in
Bazel: one target, per-platform implementation files, no `#ifdef` maze.

## Use `@platforms//os`, not custom settings

```python
# Good - the ecosystem-standard constraint
config_setting(name = "linux", constraint_values = ["@platforms//os:linux"])

# Avoid - a private dimension nobody else understands
constraint_setting(name = "my_os")
```

## `@platforms//host`

For the common "am I building for the machine I am on?" case:

```python
config_setting(name = "on_host", constraint_values = ["@platforms//host"])
```

## Reusable settings package

Define these `config_setting`s **once** in a shared package:

```python
# //bazel/config/BUILD.bazel
config_setting(name = "linux", constraint_values = ["@platforms//os:linux"],
               visibility = ["//visibility:public"])
```

Then every BUILD file writes `"//bazel/config:linux"`. Redefining them locally
is the most common avoidable duplication in Bazel repos.

## Key takeaway

`select()` + `@platforms//os` is the portable-code idiom. Centralize the
`config_setting` definitions.
