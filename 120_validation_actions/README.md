# 120 - Validation Actions

**Concepts:** the `_validation` output group, non-blocking checks

## Run it

```bash
V=//120_validation_actions

bazel build $V:clean          # validation runs and passes

bazel build $V:leaky          # the copy succeeds, validation FAILS
bazel build $V:leaky --norun_validations   # validation skipped
```

## The special `_validation` output group

```python
return [
    DefaultInfo(files = depset([out])),
    OutputGroupInfo(_validation = depset([validation_marker])),
]
```

Bazel treats `_validation` specially: it builds that group for **every
requested target**, automatically, even though nothing depends on it.

## Why not just make the check a dependency?

If validation were an input to the real output, then:

- The output could not be produced until validation finished - serializing
  what should be parallel
- A validation failure would block downstream work entirely
- Consumers would pay the validation cost transitively, repeatedly

With a validation action, the real compilation and the check run **in
parallel**, and the check's failure is reported without having gated anything.

## What validation actions are for

| Check | Example |
|-------|---------|
| Security | No hardcoded secrets (this sample) |
| Policy | Every config declares an owner |
| Style | Generated files match their source |
| Correctness | A schema is well-formed |
| Deprecation | No use of a banned API |

## The flags

```bash
--run_validations       # default: on
--norun_validations     # skip them (useful for a fast local iteration loop)
```

Because they are on by default, a validation action added to a rule
immediately applies to every existing user of that rule - which is exactly what
you want for a new policy, and worth knowing before you add one.

## Validation vs a test

| | Validation action | Test |
|---|-------------------|------|
| Runs on | `bazel build` | `bazel test` |
| Granularity | Per target, automatic | Explicit target |
| Best for | Universal invariants | Specific behavior |

A validation action is the right tool when the rule *itself* should enforce
something on every one of its users.

## Key takeaway

`OutputGroupInfo(_validation = ...)` gives you checks that run on every build,
in parallel with real work, without becoming a dependency.
