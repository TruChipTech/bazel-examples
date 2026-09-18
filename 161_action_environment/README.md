# 161 - The Action Environment

**Concepts:** `--action_env`, `--host_action_env`, cache keys

## Try it

```bash
E=//161_action_environment

export DEMO_VAR=hello
bazel build $E:scrubbed
cat bazel-bin/161_action_environment/scrubbed.txt
# "DEMO_VAR is: <not set>"  - the shell export did not reach the action

bazel build $E:scrubbed --action_env=DEMO_VAR
cat bazel-bin/161_action_environment/scrubbed.txt
```

## Why Bazel scrubs the environment

If actions inherited your shell, the same source would produce different
outputs on different machines - and the cache key would not know. Scrubbing
makes the environment an **explicit, declared input**.

## The four ways in

| Mechanism | Scope | In the cache key? |
|-----------|-------|-------------------|
| `env = {...}` on a target | That target | Yes |
| `--action_env=VAR=value` | All build actions | **Yes** |
| `--action_env=VAR` (no value) | Passes through from the client | **Yes** |
| `--host_action_env=...` | Exec-configuration actions | Yes |
| `--test_env=VAR=value` | Tests only | No (tests are not cached on it) |
| `--repo_env=VAR=value` | Repository rules | Yes, for repo fetching |

## The cache-invalidation trap

```bash
build --action_env=PATH
```

This looks harmless and is a disaster for shared caching: `PATH` differs on
every machine, so every action's key differs, and the remote cache hit rate
goes to zero.

The same applies to `--action_env=HOME`, `USER`, `HOSTNAME`, or anything
containing a home directory.

**Rule:** only pass variables whose value is genuinely the same everywhere, and
prefer pinning the value explicitly:

```bash
build --action_env=LC_ALL=C            # fixed value: safe
build --action_env=SOURCE_DATE_EPOCH=0 # fixed value: safe
build --action_env=PATH                # host-dependent: unsafe
```

## Diagnosing a mysteriously low cache hit rate

```bash
bazel aquery //x:y --output=textproto | grep -A20 'Environment'
```

Compare the environment block between two machines. A single host-specific
variable explains a zero hit rate.

## Tests are different

Test results are cached on the test's inputs, but `--test_env` is deliberately
not part of that key in the same way - which is why `--test_env` is the right
tool for credentials and per-environment settings, and `--action_env` is not.

For a test to depend on a variable reproducibly, declare it on the target:

```python
py_test(name = "t", env = {"REGION": "us-east"})
py_test(name = "t2", env_inherit = ["CI"])
```

## Key takeaway

Every environment variable you let in becomes part of the cache key. Pass fixed
values, never host-dependent ones.

## Aside: `$$` in genrule commands

```python
cmd = "echo ${DEMO_VAR}"     # ERROR: '${...}' syntax is not supported
cmd = "echo $${DEMO_VAR}"    # correct - the shell sees ${DEMO_VAR}
```

Bazel consumes one `$` before the shell does (sample 010), and it now rejects
bare `${...}` with an explicit message rather than silently misbehaving.
