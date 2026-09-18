# 171 - Container Images

**Concepts:** `rules_oci`, layering, reproducible images

## Run the part that works here

```bash
bazel build //171_container_images:app_layer
tar tzf bazel-bin/171_container_images/app_layer.tar | head
```

The binary here is a `cc_binary` on purpose. A `py_binary` would pull the whole
hermetic CPython interpreter into the layer - 247 MB instead of 20 KB. Sample
085 shows the measurements.

That tarball is an image **layer**. Turning layers into an image needs
`rules_oci`, which is not a dependency of this repo - the configuration below
is what you would add.

## Setup

```python
# MODULE.bazel
bazel_dep(name = "rules_oci", version = "2.2.6")

oci = use_extension("@rules_oci//oci:extensions.bzl", "oci")
oci.pull(
    name = "distroless_base",
    image = "gcr.io/distroless/base-debian12",
    digest = "sha256:abc123...",      # pin by DIGEST, never by tag
    platforms = ["linux/amd64", "linux/arm64"],
)
use_repo(oci, "distroless_base")
```

## Building an image

```python
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push", "oci_load")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

pkg_tar(name = "app_layer", srcs = [":app"], include_runfiles = True, package_dir = "/app")

oci_image(
    name = "image",
    base = "@distroless_base",
    tars = [":app_layer"],
    entrypoint = ["/app/app"],
    env = {"PYTHONUNBUFFERED": "1"},
)

oci_push(
    name = "push",
    image = ":image",
    repository = "registry.internal/my-team/my-app",
    remote_tags = ["latest"],
)

oci_load(name = "load", image = ":image", repo_tags = ["my-app:dev"])
```

```bash
bazel run //171_container_images:load   # into the local daemon
bazel run //171_container_images:push   # to a registry
```

## Why build images in Bazel rather than with a Dockerfile

| | Dockerfile | Bazel |
|---|-----------|-------|
| Reproducible | No - `apt-get` at build time | Yes - all inputs declared |
| Incremental | Layer cache, easily invalidated | Only changed layers rebuild |
| Image contents known | Inspect the built image | `bazel query "deps(:image)"` |
| Build environment | Needs a Docker daemon | None - `rules_oci` is pure Bazel |
| Multi-arch | Emulation or buildx | A platform transition |

`rules_oci` needs no Docker daemon at all, which matters in CI and on remote
execution.

## Layering for cache efficiency

Order layers from **least to most** frequently changing:

```python
oci_image(
    name = "image",
    base = "@distroless_base",
    tars = [
        ":third_party_deps_layer",   # changes rarely
        ":internal_libs_layer",      # changes sometimes
        ":app_layer",                # changes every commit
    ],
)
```

Only the layers after the first change need re-pushing and re-pulling. Putting
the application first defeats the entire layer cache.

## Pin the base by digest

```python
digest = "sha256:abc123..."     # immutable
image = "...:latest"            # changes under you
```

A tag makes the build non-reproducible and silently changes every cache key
when upstream republishes.

## Reproducibility

`rules_oci` produces images with fixed timestamps and sorted entries, so the
same source yields the same digest. That is what allows "has this image
actually changed?" to be answered by comparing digests.

## Key takeaway

Build layers with `pkg_tar`, assemble with `oci_image`, pin the base by digest,
and order layers by change frequency.
