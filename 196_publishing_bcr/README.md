# 196 - Publishing a Module

**Concepts:** the Bazel Central Registry, release hygiene

## What a publishable module needs

```
my_module/
  MODULE.bazel          name + version + dependencies
  BUILD.bazel
  LICENSE
  README.md
  rules/
    defs.bzl            the public entry point (sample 195)
  examples/             a working consumer, built in CI
  .bcr/                 registry metadata (below)
```

```python
# MODULE.bazel
module(
    name = "rules_mylang",
    version = "1.0.0",
    compatibility_level = 1,
    bazel_compatibility = [">=7.0.0"],
)

bazel_dep(name = "bazel_skylib", version = "1.8.2")
bazel_dep(name = "platforms", version = "1.0.0")
```

## `compatibility_level`

```python
module(name = "rules_mylang", version = "2.0.0", compatibility_level = 2)
```

This is bzlmod's answer to "two versions cannot coexist". Bumping it tells
Bazel that v2 is **incompatible** with v1, so a build requiring both fails
loudly instead of silently picking one.

Bump it whenever you make a change from sample 195's "No" column.

## Dev dependencies stay out

```python
bazel_dep(name = "buildifier_prebuilt", version = "8.2.0.2", dev_dependency = True)
```

`dev_dependency = True` means consumers never see it. Anything used only for
your own tests, linting or examples should be marked this way - otherwise you
impose your tooling on everyone who depends on you.

## Registry submission

The BCR lives at github.com/bazelbuild/bazel-central-registry. Publishing
means opening a PR adding:

```
modules/rules_mylang/1.0.0/
  MODULE.bazel        a copy of yours
  source.json         URL + integrity hash of the release archive
  presubmit.yml       what CI should build to validate it
```

`source.json`:

```json
{
  "url": "https://github.com/org/rules_mylang/releases/download/v1.0.0/rules_mylang-v1.0.0.tar.gz",
  "integrity": "sha256-base64hash...",
  "strip_prefix": "rules_mylang-1.0.0"
}
```

The `.bcr/` directory in your own repo plus the
[Publish to BCR](https://github.com/bazel-contrib/publish-to-bcr) GitHub App
automates generating that PR on each release.

## `presubmit.yml` is not optional in practice

```yaml
matrix:
  platform: ["debian11", "macos", "ubuntu2004", "windows"]
tasks:
  verify_targets:
    name: Verify build targets
    platform: ${{ platform }}
    build_targets:
      - "@rules_mylang//..."
```

The BCR runs this against your module. It is also the best pressure to keep an
`examples/` directory that actually works - a module whose examples do not
build will not pass.

## Release checklist

1. All tests pass, on every platform you claim to support
2. `examples/` builds against the **released** version, not a local override
3. `compatibility_level` bumped if anything broke
4. Version bumped in `MODULE.bazel`
5. A tagged release with an immutable archive
6. `integrity` computed from that exact archive

## Alternatives to the BCR

You do not have to publish. Consumers can use `archive_override`,
`git_override`, or a **private registry** (`--registry=https://internal/registry`)
which is how companies distribute internal modules.

## Key takeaway

Publishing means a stable API, a `compatibility_level` you maintain honestly,
dev dependencies marked as such, and examples that CI actually builds.
