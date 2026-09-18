# 123 - Toolchains: The Basics

**Concepts:** `toolchain_type`, `toolchain()`, `ctx.toolchains`

## Run it

```bash
T=//123_toolchain_basics

bazel build $T:greeting \
  --extra_toolchains=$T:english_toolchain
cat bazel-bin/123_toolchain_basics/greeting.txt

bazel build $T:greeting \
  --extra_toolchains=$T:french_toolchain \
  --platforms=$T:french_platform
cat bazel-bin/123_toolchain_basics/greeting.txt
```

The same target produces a different result, with no change to the BUILD file -
Bazel resolved a different toolchain.

## The four pieces

```
toolchain_type(name = "greeter_toolchain_type")   1. the SLOT (abstract)
greeter_toolchain(name = "english_impl", ...)     2. an IMPLEMENTATION
toolchain(name = "english_toolchain",             3. the BINDING + constraints
          toolchain = ":english_impl",
          toolchain_type = ":greeter_toolchain_type")
greet(name = "greeting")                          4. a CONSUMER
```

The consumer declares `toolchains = ["//pkg:greeter_toolchain_type"]` and reads
`ctx.toolchains["//pkg:greeter_toolchain_type"]`.

## Why the indirection?

Without toolchains, a rule that needs a compiler must either hard-code a path
(not hermetic) or take it as an attribute (every caller must supply it).

Toolchain resolution lets the rule say *"I need a C++ compiler"* and lets Bazel
answer *"for this target platform, executing on that platform, here is one"*.
That is what makes `cc_binary` work unchanged whether you build for Linux,
macOS, or an embedded ARM board.

## The constraints that drive selection

```python
toolchain(
    name = "french_toolchain",
    toolchain_type = ":greeter_toolchain_type",
    toolchain = ":french_impl",
    target_compatible_with = [":france"],       # usable only for this target platform
    exec_compatible_with = ["@platforms//os:linux"],  # runnable only on this exec platform
)
```

Bazel picks the **first registered toolchain** whose constraints are satisfied.

## `platform_common.ToolchainInfo`

A toolchain rule must return `ToolchainInfo`. You can put fields on it
directly, or - as here - nest your own provider inside it, which keeps the data
typed and documented.

## Key takeaway

A toolchain type is an interface; toolchains are implementations; platforms and
constraints select between them. Rules depend on the interface only.
