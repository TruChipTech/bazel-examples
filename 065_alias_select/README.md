# 065 - alias + select: Swappable Implementations

**Concepts:** the alias-select dispatch pattern

## Run it

```bash
A=//065_alias_select

bazel run $A:main                                              # openssl
bazel run $A:main --//065_alias_select:ssl=boringssl  # boringssl
```

## The pattern

```python
alias(
    name = "crypto_impl",
    actual = select({
        ":use_boring": ":crypto_boring",
        "//conditions:default": ":crypto_openssl",
    }),
)
```

One label. Many implementations. Consumers never change.

This is the standard way to express "the same dependency, implemented
differently per platform or per flag". You will see it throughout the Bazel
ecosystem - it is how rule sets let you swap toolchains, SSL libraries,
allocators and test doubles.

## Why alias rather than selecting in each consumer

Selecting inside every consumer duplicates the condition and eventually
diverges - one target ends up on a different branch than another in the same
build, and the result links two implementations at once. Routing through a
single alias makes that impossible.

## Real-world examples

```python
alias(name = "malloc", actual = select({
    ":use_tcmalloc": "@tcmalloc//:tcmalloc",
    "//conditions:default": "@bazel_tools//tools/cpp:malloc",
}))

alias(name = "database", actual = select({
    ":test_mode": "//db:in_memory",
    "//conditions:default": "//db:postgres",
}))
```

## Key takeaway

`alias` + `select` is Bazel's dependency-injection mechanism. Learn it early;
it shows up everywhere.
