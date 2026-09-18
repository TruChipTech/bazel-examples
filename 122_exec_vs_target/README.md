# 122 - Exec vs Target Configuration

**Concepts:** `cfg = "exec"`, `cfg = "target"`, cross-compilation

## Run it

```bash
bazel build //122_exec_vs_target:probe
cat bazel-bin/122_exec_vs_target/probe.txt
```

Look at the two tool paths: they differ, because the same target was built
twice in two configurations.

## The three platforms

| Platform | Meaning |
|----------|---------|
| **Host** | Where the `bazel` client runs |
| **Execution** | Where build *actions* run |
| **Target** | What the outputs are *for* |

On a normal local build all three are the same machine, so the distinction is
invisible. It becomes critical when:

- Cross-compiling (building ARM binaries on x86)
- Using remote execution (actions run in a Linux container)

## The rule

```python
"_compiler": attr.label(cfg = "exec", executable = True)   # a TOOL
"deps":      attr.label_list()                             # cfg = "target"
```

**If an action executes it, it needs `cfg = "exec"`.** Anything else defaults
to the target configuration.

## The bug you will hit without it

You write a code generator, use it with `cfg = "target"` (or forget `cfg`
entirely), and everything works for a year. Then someone cross-compiles for
ARM: Bazel dutifully builds your generator *for ARM*, tries to run it on the
x86 build machine, and the build fails with `Exec format error`.

The same applies to remote execution, where the execution platform may differ
from your laptop.

## Why the same target can be built twice

Configurations are part of the output path:

```
bazel-out/k8-fastbuild/bin/pkg/tool          # target configuration
bazel-out/k8-opt-exec-ST-abc123/bin/pkg/tool # exec configuration
```

They do not collide, they cache independently, and a target used both as a tool
and as a shipped artifact simply gets built both ways.

This is also why an exec-configuration build appears in your output even when
you did not ask for it.

## Other `cfg` values

| Value | Meaning |
|-------|---------|
| `"target"` | Default - the platform being built for |
| `"exec"` | The platform running the actions |
| A transition | A custom configuration change (samples 141-143) |

## Key takeaway

`cfg = "exec"` on every tool attribute. It is invisible on a local build and
mandatory for cross-compilation and remote execution.
