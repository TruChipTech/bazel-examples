# 062 - Constraints and Platforms

**Concepts:** `constraint_setting`, `constraint_value`, `platform`

## Run it

```bash
C=//062_constraints

bazel build $C:gpu_report
cat bazel-bin/062_constraints/gpu.txt        # CPU fallback

bazel build $C:gpu_report --platforms=$C:ci_linux_nvidia
cat bazel-bin/062_constraints/gpu.txt        # CUDA kernels enabled
```

## The vocabulary

```
constraint_setting   a QUESTION      "which OS?"
constraint_value     an ANSWER       "linux"
platform             a SET of answers describing one machine
```

## The built-in dimensions

The `@platforms` module ships the standard ones:

```
@platforms//os:linux, :macos, :windows, :android, :ios, :freebsd, ...
@platforms//cpu:x86_64, :aarch64, :arm, :wasm32, ...
```

Use these rather than inventing your own for OS and CPU - every rule set in
the ecosystem already understands them.

## Defining your own

Define a custom `constraint_setting` when you have a genuine machine property
that affects the build: GPU vendor, libc flavor, availability of a licensed
tool, hardware test rig capabilities.

`default_constraint_value` makes the dimension optional - platforms that do not
mention it get the default, as `gpu_none` does here.

## The three platform roles

Bazel tracks three platforms at once:

| Platform | Meaning | Flag |
|----------|---------|------|
| Host | Where Bazel itself runs | `--host_platform` |
| Execution | Where build actions run | Resolved automatically |
| Target | What the output is for | `--platforms` |

On a normal local build all three are the same machine. They diverge when
cross-compiling (sample 129) or using remote execution (sample 154).

## Key takeaway

Constraints describe machines declaratively, which lets Bazel *resolve* the
right toolchain instead of you hard-coding one.
