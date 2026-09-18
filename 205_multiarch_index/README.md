# 205 - Multi-Architecture Image Index

**Concepts:** image index, per-platform manifests, one tag many images

## Run it

```bash
bazel build //205_multiarch_index:multiarch
python3 -m json.tool bazel-bin/205_multiarch_index/multiarch_layout/index.json
```

## What an index is

A manifest describes **one** image. An index is a list of manifests, each
tagged with the platform it is for:

```json
{"mediaType": "application/vnd.oci.image.index.v1+json",
 "manifests": [
   {"digest": "sha256:aaa...", "platform": {"os":"linux","architecture":"amd64"}},
   {"digest": "sha256:bbb...", "platform": {"os":"linux","architecture":"arm64"}}
 ]}
```

`docker pull demo:v1` on an ARM machine reads the index, finds the arm64 entry,
and pulls only that manifest and its layers. One tag, correct image everywhere.

## The blobs all live together

The index layout contains every child image's blobs. Layers shared between
architectures (rarely, but config-only differences happen) are stored once,
because they are content-addressed.

## Building the children in parallel

This example lists the two images explicitly. The scalable version uses a
**split transition** (sample 142) so one target builds itself for N platforms
automatically - see sample 411.

## Key takeaway

An index is a platform-keyed list of manifest digests. It is what makes a
single image reference work on every architecture.
