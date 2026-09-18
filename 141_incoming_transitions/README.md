# 141 - Incoming Edge Transitions

**Concepts:** `transition()`, `cfg` on a rule, self-configuring targets

## Run it

```bash
T=//141_incoming_transitions

bazel build $T:beta_release
cat bazel-bin/*/141_incoming_transitions/beta_release.txt 2>/dev/null || \
  find bazel-out -name 'beta_release.txt' -exec cat {} \;
```

The output shows `compilation_mode = opt` **even though you did not pass
`-c opt`**, and `channel = beta` even though the flag's default is `dev`.

## What a transition is

A transition changes the **build configuration** for part of the graph. An
*incoming edge* transition (`cfg` on the rule) applies to the target itself and
everything below it.

```python
def _impl(settings, attr):
    return {"//command_line_option:compilation_mode": "opt"}

_force_release = transition(
    implementation = _impl,
    inputs = [],
    outputs = ["//command_line_option:compilation_mode"],
)

release_artifact = rule(implementation = ..., cfg = _force_release)
```

## `inputs` and `outputs` are strict

- `inputs`: flags the implementation may **read** via the `settings` dict.
- `outputs`: flags it may **write**.

Returning a key not in `outputs`, or declaring an output you never set, is an
analysis error. This strictness is what lets Bazel compute the resulting
configuration without running your code speculatively.

## Referring to native flags

```python
"//command_line_option:compilation_mode"
"//command_line_option:platforms"
"//command_line_option:copt"
"//pkg:my_custom_flag"          # your own build settings, by label
```

## Why this is useful

Some targets have a **fixed** correct configuration regardless of how the
build was invoked:

- A release artifact must always be `-c opt`
- A firmware image must always target the embedded platform
- A test fixture must always use the debug allocator
- A tool bundled into a package must be built for the deployment platform

Without transitions you would rely on everyone remembering the right flags.

## The cost: configuration multiplication

A target built in two configurations is analyzed and built **twice**, with two
cache entries and two output directories. Transitions are therefore a real
performance lever - applied carelessly across a large graph, they can multiply
your analysis time.

Use them where the configuration genuinely must differ, not as a convenience.

## Finding the output

Transitioned outputs live under a different `bazel-out/<config>/` directory, so
the usual `bazel-bin` symlink may not point at them. Use:

```bash
bazel cquery $T:beta_release --output=files
```

## Key takeaway

`cfg = <transition>` on a rule pins the configuration for that target and its
subgraph. Declare `inputs`/`outputs` exactly, and remember each configuration
costs a separate build.
