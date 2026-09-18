# 160 - Hermeticity: The Checklist

**Concepts:** reproducibility, the prerequisites for caching

A build is **hermetic** when the same inputs produce the same outputs on any
machine, at any time. Everything else in this level - remote caching, remote
execution, reliable incremental builds - depends on it.

## The seven leaks, in order of frequency

### 1. Undeclared inputs

The action reads a file nobody listed. Caught by the sandbox (sample 158);
invisible without it.

```bash
bazel build //... --spawn_strategy=linux-sandbox   # make it fail loudly
```

### 2. System toolchains

```python
linkopts = ["-lssl"]            # whatever OpenSSL this machine has
```

Different machines, different versions, same cache key. Fix with a hermetic
toolchain (sample 169) or by bringing the library in as a dependency.

### 3. The environment

```python
cmd = "echo $$USER > $@"        # differs per developer
```

Bazel scrubs most of the environment for exactly this reason. Anything you need
must be declared with `env`, `--action_env` or `--repo_env` - and every one you
declare becomes part of the cache key.

### 4. Timestamps and paths in outputs

```cpp
printf("built at %s\n", __DATE__);   // changes every day
```

Bazel already redacts `__DATE__`, `__TIME__` and `__TIMESTAMP__` for C++. Your
own generators must do the same. Embed a **commit SHA** (sample 092), never a
timestamp.

### 5. Network access during actions

An action that downloads something is not reproducible - the remote content can
change. Fetch in a **repository rule** with a pinned `sha256` instead
(sample 136).

### 6. Nondeterministic tool output

Map iteration order, unstable sorts, parallel output interleaving, embedded
random seeds. The usual fixes: sort before writing, set `PYTHONHASHSEED=0`,
pass `-frandom-seed`, or use the tool's determinism flag.

### 7. Absolute paths

```
/home/alice/project/src/foo.cc      # in a generated file, or a debug path
```

Anything containing a user's home directory cannot be shared. Bazel offers
`--experimental_convenience_symlinks` and toolchains offer
`-fdebug-prefix-map`; generators should emit workspace-relative paths.

## Verifying reproducibility

```bash
bazel build //... --execution_log_json_file=/tmp/a.json
bazel clean
bazel build //... --execution_log_json_file=/tmp/b.json
diff <(jq -S . /tmp/a.json) <(jq -S . /tmp/b.json)
```

Any difference is a leak. For output bytes specifically:

```bash
bazel build //x:y && sha256sum bazel-bin/x/y > /tmp/h1
bazel clean && bazel build //x:y && sha256sum bazel-bin/x/y > /tmp/h2
diff /tmp/h1 /tmp/h2
```

## The payoff

| Hermetic | Not hermetic |
|----------|--------------|
| Remote cache works | Cache serves wrong results |
| Remote execution works | Actions fail in the container |
| CI matches local | "Works on my machine" |
| Incremental builds correct | Stale outputs survive |
| Old commits rebuild | Bit rot |

## Key takeaway

Hermeticity is not a purity goal - it is the precondition for every performance
feature in this level. Keep the sandbox on, declare everything, and pin your
toolchains.
