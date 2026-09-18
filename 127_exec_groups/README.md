# 127 - Exec Groups

**Concepts:** `exec_group`, per-action execution requirements

## Run it

```bash
bazel build //127_exec_groups:artifact
cat bazel-bin/127_exec_groups/artifact.linked

# Route one group's actions differently:
bazel build //127_exec_groups:artifact \
  --strategy=MultiLink=local
```

## The problem

A rule's actions are not homogeneous. A C++ rule compiles (many small,
parallel, low-memory actions) and links (one big, serial, memory-hungry
action). Without exec groups, both share one execution platform and one set of
execution requirements.

Exec groups let a rule say "these actions are different":

```python
my_rule = rule(
    implementation = _impl,
    exec_groups = {
        "compile": exec_group(),
        "link": exec_group(exec_compatible_with = ["//constraints:high_memory"]),
    },
)
```

and then tag each action:

```python
ctx.actions.run(..., exec_group = "link")
```

## What each group gets

| Capability | How |
|-----------|-----|
| Its own execution platform | `exec_group(exec_compatible_with = [...])` |
| Its own toolchains | `exec_group(toolchains = [...])` |
| Its own strategy/flags | `--strategy=<Mnemonic>=local` |

## Accessing a group's toolchains

```python
exec_groups = {"link": exec_group(toolchains = ["//pkg:linker_type"])}

# In the implementation:
ctx.exec_groups["link"].toolchains["//pkg:linker_type"]
```

This is the main reason exec groups exist: one rule needing **two different
toolchains** for two different steps.

## Where this matters in practice

- Remote execution with heterogeneous workers (big-memory pool for linking)
- Actions that must run locally (touching a device, a licensed tool) while the
  rest runs remotely
- Tests that need a GPU while their compilation does not

## Related: exec properties

```python
exec_group(exec_properties = {"container-image": "docker://my-image:latest"})
```

Passes remote-execution properties per group - a different container for the
link step, for example.

## Key takeaway

Exec groups partition a rule's actions so each subset can get its own
platform, toolchains and execution properties.
