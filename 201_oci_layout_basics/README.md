# 201 - An OCI Image From First Principles

**Concepts:** OCI image layout, content addressing, manifests, no daemon

A container image is not a magic format. It is a directory of content-addressed
blobs plus a JSON index. This example builds one with nothing but `tar`, a
Python script and `sha256`.

## Run it

```bash
bazel build //201_oci_layout_basics:image
find bazel-bin/201_oci_layout_basics/image_layout -type f | sort
cat bazel-bin/201_oci_layout_basics/image_layout/digest.txt
```

## The anatomy

```
image_layout/
  oci-layout                     {"imageLayoutVersion":"1.0.0"}
  index.json                     entry point -> manifest digest
  blobs/sha256/<digest>          the manifest JSON
  blobs/sha256/<digest>          the config JSON
  blobs/sha256/<digest>          the layer tarball
```

Four files. That is the whole image.

## Everything references by digest

```
index.json  --digest-->  manifest  --digest-->  config
                                   --digest-->  layer.tar
```

Nothing refers to anything by name or path. That is what makes an image
**immutable and verifiable**: change one byte in the layer tarball and its
digest changes, which changes the manifest, which changes the image digest.

It is also what makes signing possible at all (sample 251 onward) - you sign
the manifest digest, and that single hash transitively covers every byte in the
image.

## Tags are not identity

```json
"annotations": {"org.opencontainers.image.ref.name": "demo:v1"}
```

A tag is an *annotation in the index* pointing at a digest. It can be moved to
point somewhere else at any time. `sha256:abc...` cannot.

This is why production deployments and base images should be pinned by digest,
never by tag (sample 240).

## No Docker daemon anywhere

Nothing in this example talks to a daemon, a socket or a registry. `rules_oci`
works the same way - building an image is pure file manipulation, which is
exactly why it fits a build system: it is hermetic, cacheable and parallelizable
like any other action.

## Key takeaway

An OCI image is blobs addressed by their own hash plus a JSON index. Understand
that and every later topic - layers, multi-arch, signing, attestation - is a
variation on it.
