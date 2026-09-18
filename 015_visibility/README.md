# 015 - Visibility: Enforcing Architecture

**Concepts:** `visibility`, `__pkg__`, encapsulation

## Run it

```bash
bazel run //015_visibility/consumer:use
```

## Break it on purpose

Add `"//015_visibility/internal:secret"` to the consumer's `deps`:

```
ERROR: target '//...:secret' is not visible from target '//...:use'
```

The build *fails*. Not a lint warning, not a code review comment - a hard
failure. This is how Bazel turns architectural intent into something the
machine enforces.

## The visibility vocabulary

| Value | Meaning |
|-------|---------|
| `//visibility:private` | Only this package (the default) |
| `//visibility:public` | Everyone |
| `//some/pkg:__pkg__` | Exactly that one package |
| `//some/pkg:__subpackages__` | That package and everything beneath it |
| `//some:my_group` | A `package_group` (sample 046) |

## Why this matters more than it looks

In a large repo, "please don't import internals" is a rule everyone violates
eventually. Visibility makes the layering real: the internal implementation
stays replaceable because nothing can quietly grow a dependency on it.

## Key takeaway

Default to private. Grant the narrowest visibility that works -
`__pkg__` over `__subpackages__` over `public`.
