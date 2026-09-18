# 154 - Remote Execution

**Concepts:** `--remote_executor`, execution platforms, containers

## Configuration

```
# .bazelrc
build:remote --remote_executor=grpcs://rbe.internal:443
build:remote --remote_instance_name=default_instance
build:remote --host_platform=//platforms:rbe_linux
build:remote --extra_execution_platforms=//platforms:rbe_linux
build:remote --jobs=200
build:remote --remote_timeout=3600
```

```bash
bazel build //... --config=remote
```

## Caching vs execution

| | Remote cache | Remote execution |
|---|--------------|------------------|
| Actions run | On your machine | On the cluster |
| You need | A cache server | A worker fleet |
| Speedup from | Not repeating work | **Massive parallelism** |
| `--jobs` | Your cores | Hundreds |

Remote caching makes repeated work free. Remote execution makes *new* work
fast, because 200 compiles run simultaneously on machines you do not own.

## The execution platform defines the container

```python
platform(
    name = "rbe_linux",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    exec_properties = {
        "container-image": "docker://gcr.io/my-project/rbe-toolchain@sha256:abc123...",
        "OSFamily": "Linux",
    },
)
```

`exec_properties` are passed to the execution service. `container-image` is how
you specify exactly what the workers run - pinned by digest, because a moving
tag silently changes every cache key.

## Hermeticity becomes mandatory

Locally, an undeclared dependency on `/usr/include/openssl` usually "works".
Remotely, the container does not have your machine's files and the action
fails - or worse, succeeds differently.

Remote execution is therefore the strictest possible hermeticity test. Most
teams adopting it spend the first weeks fixing:

| Problem | Fix |
|---------|-----|
| Undeclared inputs | Declare them (sample 160) |
| System toolchains | Hermetic toolchains (sample 169) |
| Absolute paths in commands | Relative paths, `$(execpath)` |
| Tools assumed present | Bring them in as targets |
| Network access in actions | Fetch in a repository rule instead |

## Escape hatches

Some actions genuinely cannot run remotely - they need a device, a license
server, or the local network:

```python
tags = ["no-remote"]          # never send remotely
tags = ["no-remote-exec"]     # execute locally, still cache remotely
tags = ["local"]              # no sandbox, no remote
```

Or per mnemonic:

```bash
build --modify_execution_info=MyMnemonic=+no-remote
```

## Build without the bytes

```
build --remote_download_minimal
```

Do not download intermediate outputs at all - only the final artifacts you
asked for. On a large build this eliminates most of the network traffic. See
sample 155.

## Implementations

BuildBuddy, EngFlow, NativeLink, Buildbarn, BuildGrid, and Google Cloud's RBE.
All speak the same Remote Execution API, so switching is mostly a URL change.

## Key takeaway

Remote execution buys parallelism far beyond your machine, and demands
hermeticity in return. Fix hermeticity first; the rest is configuration.
