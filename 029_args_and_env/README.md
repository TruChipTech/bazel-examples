# 029 - Arguments and Environment Variables

**Concepts:** `args`, `env`, `env_inherit`, sandbox scrubbing

## Run it

```bash
bazel run //029_args_and_env:show
bazel run //029_args_and_env:show -- extra args here
bazel test //029_args_and_env:env_test
```

## The environment is scrubbed on purpose

Bazel deliberately does **not** hand your shell environment to actions and
tests. If it did, a build would depend on whatever happened to be exported in
your terminal, and the same inputs would produce different outputs on different
machines - which breaks caching and reproducibility.

So these do *not* work:

```bash
GREETING=hi bazel test //...        # test will not see GREETING
export MODE=prod && bazel build ... # actions will not see MODE
```

## The supported ways in

| Mechanism | Scope |
|-----------|-------|
| `env = {...}` on a target | That target |
| `env_inherit = ["VAR"]` on a test | Lets a named var through from the client |
| `--test_env=VAR=value` | All tests in this invocation |
| `--action_env=VAR=value` | All build actions (invalidates the cache) |
| `--repo_env=VAR=value` | Repository rules / toolchain discovery |

## `args` ordering

`args` come first, command-line arguments come after. Use `args` for defaults
the target should always have.

## Key takeaway

If a program needs an environment variable, declare it. Relying on ambient
environment is the fastest way to a build that works only on your machine.
