# 092 - Stamping a Release Artifact

**Concepts:** traceable builds, stamped manifests, `--config=release`

## Run it

```bash
bazel build //092_stamped_release:manifest
cat bazel-bin/092_stamped_release/manifest.json

# With the release config, which enables --stamp and the status script:
bazel build --config=release //092_stamped_release:release
tar tzf bazel-bin/092_stamped_release/release.tar.gz
```

(This directory is not a git repository, so the commit shows as `unknown`. In a
real checkout it is the actual SHA.)

## The problem being solved

Someone reports a bug against "version 2.4.1 running in production". Which
commit is that? Without stamping, the honest answer is a guess.

Embedding the commit in the artifact makes it a fact:

```json
{
  "app": "demo-service",
  "git_commit": "a1b2c3d4...",
  "git_branch": "main"
}
```

## Why the manifest is a separate target

The stamped manifest is tiny and cheap to rebuild. The application binary is
expensive. Keeping them separate means a new commit invalidates only the
manifest - the binary stays cached.

The alternative, compiling the SHA into the binary with a `-D` flag, forces a
full relink on every commit. That is sometimes worth it (for `--version`
output), but do it deliberately.

## The release config

From this repo's `.bazelrc`:

```
build:release -c opt
build:release --stamp
build:release --workspace_status_command=./tools/workspace_status.sh
```

CI then runs `bazel build --config=release //...` and everything is consistent.

## Rules of thumb

1. Do **not** stamp development builds - it costs cache hits for no benefit.
2. Put only genuinely-identifying values in `STABLE_` keys.
3. Keep stamped outputs small and downstream of expensive work, not upstream.
4. Verify the artifact: `tar xzOf release.tar.gz ./opt/demo/manifest.json`.

## Key takeaway

Stamping connects a deployed artifact to the source that produced it. Structure
it so that connection costs you almost nothing in build time.
