# 158 - Sandboxing

**Concepts:** sandbox strategies, undeclared inputs, `--sandbox_debug`

## Try it

```bash
S=//158_sandboxing

# Sandboxed (the default): the undeclared file is invisible
bazel test $S:sandbox_test --test_output=all

# Without a sandbox: the undeclared file becomes visible
bazel test $S:sandbox_test --test_output=all \
  --spawn_strategy=local --nocache_test_results
```

The second command is what a non-hermetic build looks like: the test can read a
file nobody declared, so it will pass on your machine and fail anywhere else.

## What the sandbox does

Each action runs in a directory containing **only its declared inputs**,
assembled with symlinks or a mount namespace. The rest of the filesystem is
either absent or read-only, and the working directory is discarded afterwards.

That is what turns "I forgot to declare a dependency" from a latent bug into an
immediate, local failure.

## The strategies

| Strategy | Isolation | Speed |
|----------|-----------|-------|
| `linux-sandbox` | Mount + PID namespaces | Fast (Linux default) |
| `processwrapper-sandbox` | Symlink forest only | Medium (macOS default) |
| `docker` | Full container | Slow |
| `local` | **None** | Fastest, unsafe |
| `worker` | Persistent process (sample 147) | Fastest for warm tools |
| `remote` | Remote worker | Depends on the network |

```bash
--spawn_strategy=linux-sandbox
--strategy=CppCompile=local          # per mnemonic
--strategy=Javac=worker
```

Bazel accepts a comma-separated fallback list, taking the first that works:

```bash
--spawn_strategy=remote,worker,linux-sandbox,local
```

## Debugging sandbox failures

```bash
bazel build //x:y --sandbox_debug
```

Keeps the sandbox directory after a failure and prints its path, so you can
list exactly what the action could see. If a file you expected is absent, it is
undeclared - add it to `srcs`, `data`, `deps` or the action's `inputs`.

## When to loosen it

```python
tags = ["no-sandbox"]         # this action cannot be sandboxed
tags = ["local"]              # no sandbox, no remote
```

Legitimate cases: a tool that needs a device node, a test that binds a fixed
port, something that genuinely requires the host filesystem.

Each of these is a hole in reproducibility. They should be rare, individually
justified, and reviewed - not a repo-wide default.

## Sandboxing has a cost

Setting up a sandbox per action is not free; for very short actions the
overhead can exceed the work. That is the argument for workers (sample 147)
rather than for disabling the sandbox.

```bash
--experimental_reuse_sandbox_directories   # reduce setup cost
```

## Key takeaway

The sandbox is what makes undeclared inputs fail fast. Do not switch it off to
make a build pass - fix the declaration.
