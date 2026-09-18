# 197 - Rule Composition Patterns

**Concepts:** macros vs rules vs aspects, choosing the right tool

## Run it

```bash
C=//197_rule_composition

bazel query $C:all
bazel test  $C:api_test
bazel build $C:release_bundle
cat bazel-bin/197_rule_composition/release_bundle.manifest
```

## The decision table

| You want to... | Use |
|----------------|-----|
| Declare several targets from one call | **Macro** (051, 052) |
| Create files / run commands | **Rule** (101) |
| Add behavior to targets you do not own | **Aspect** (130) |
| Give a dependency a stable name | **alias** (020) |
| Change a dependency's configuration | **Transition** (141, 142) |
| Combine other targets' outputs | **Rule** reading `DefaultInfo` |

Reach for the cheapest that works. A macro costs nothing at analysis time; a
rule costs an analysis node; an aspect costs one per visited target.

## Pattern 1: a macro over existing rules

```python
python_service = macro(
    implementation = _service_impl,
    attrs = {...},
)
```

This is the workhorse. It encodes a **convention** - "a service is a library
plus a binary plus a test" - without inventing new build semantics.

Most "we should write a custom rule" instincts are really this.

## Pattern 2: a rule composing providers

```python
def _bundle_impl(ctx):
    parts = depset(transitive = [t[DefaultInfo].files for t in ctx.attr.parts])
```

A rule that reads other targets' providers and produces something new. The key
insight: it does not care *what kind* of rule produced its inputs - any target
with `DefaultInfo` works, so it composes with `py_binary`, `cc_binary`,
`filegroup` and your own rules equally.

Designing rules to consume **providers** rather than specific rule kinds is
what makes a rule set composable.

## Pattern 3: layered rules

```
low-level rule    (mylang_compile)     one file -> one object
mid-level rule    (mylang_library)     many files + deps
high-level macro  (mylang_service)     library + binary + test + package
```

Users work at the top; power users drop down a layer. `rules_go`, `rules_java`
and `rules_python` all have this shape.

## Anti-patterns

**A rule that could have been a macro.** If it creates no actions, it should
not be a rule.

**A macro that hides too much.** If users cannot predict what targets appear,
they cannot depend on them. Symbolic macros' naming rules (sample 052) exist
for this reason.

**Deep macro nesting.** Three layers of macros calling macros makes
`--output=build` the only way to understand a BUILD file.

**Rules that require a specific rule kind.** Accept a provider instead.

## Key takeaway

Macro for convention, rule for actions, aspect for other people's targets.
Compose on providers, not on rule kinds.
