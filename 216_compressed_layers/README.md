# 216 - Compressed Layers: digest vs diff_id

**Concepts:** `diff_id`, gzip layers, media types

## Run it

```bash
bazel build //216_compressed_layers:identities
cat bazel-bin/216_compressed_layers/identities.txt
```

```
uncompressed tar (diff_id): 6b95e751...
compressed blob  (digest) : 2f8a10c4...
gunzipped again  (diff_id): 6b95e751...     <- matches the first line
```

## Two hashes, two jobs

| Name | Hash of | Lives in | Used for |
|------|---------|----------|----------|
| **digest** | the stored (compressed) blob | the **manifest** | fetching and verifying the download |
| **diff_id** | the uncompressed tar | the **config** `rootfs` | identifying the filesystem layer |

For an *uncompressed* layer they are equal, which is why samples 201-215 could
use one value for both. Add gzip and they diverge permanently.

## Why both exist

A registry verifies what it transferred - that is the compressed digest. A
runtime assembles a filesystem from uncompressed tars and must be able to say
"I already have this layer unpacked" regardless of how it was compressed. Two
different questions, two different hashes.

Recompressing a layer with a different gzip level changes the **digest** but not
the **diff_id** - the filesystem is identical, the blob is not.

## The bug this causes

Populate `rootfs.diff_ids` with compressed digests and the image pulls
successfully and then fails to start, because the runtime cannot match any
unpacked layer to the rootfs. The error is usually opaque. If a hand-built
image pulls but will not run, check this first.

## Media types must agree

```
application/vnd.oci.image.layer.v1.tar        uncompressed
application/vnd.oci.image.layer.v1.tar+gzip   gzipped
application/vnd.oci.image.layer.v1.tar+zstd   zstd
```

A blob whose media type says `+gzip` but which is not gzipped is a hard failure
on pull.

## Key takeaway

digest = compressed blob, diff_id = uncompressed tar. They are equal only when
you skip compression.
