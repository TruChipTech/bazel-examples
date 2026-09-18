# 206 - Image Annotations

**Concepts:** standard OCI annotations, provenance metadata, digest stability

## Run it

```bash
bazel build //206_image_annotations:annotated_index
cat bazel-bin/206_image_annotations/annotated_index.json
```

## The standard keys

| Annotation | Meaning |
|------------|---------|
| `org.opencontainers.image.source` | Repository URL |
| `org.opencontainers.image.revision` | Commit SHA |
| `org.opencontainers.image.created` | Build timestamp (RFC 3339) |
| `org.opencontainers.image.licenses` | SPDX expression |
| `org.opencontainers.image.title` | Human name |
| `org.opencontainers.image.base.digest` | Base image, pinned |

Using the standard keys matters: scanners, policy engines and registry UIs read
them. A custom `mycompany.git_sha` key is invisible to all of that.

## `created` and reproducibility

A real timestamp makes the index bytes change on every build. Two options:

- **Zero it** (`1970-01-01T00:00:00Z`) and get byte-identical images
- **Stamp it** with the *commit* time, not the build time - it changes only
  when the source does

Never use the wall clock. Sample 213 covers this properly.

## Annotations do not change the image digest

They live in the index, beside the manifest descriptor - not inside the
manifest. So re-annotating does not produce a new image, which is exactly what
you want: the same bits can be re-published with corrected metadata.

The flip side: **annotations are not covered by an image signature** over the
manifest digest. If provenance must be tamper-evident it belongs in a signed
attestation (sample 281), not an annotation.

## Key takeaway

Use the standard `org.opencontainers.image.*` keys, keep `created`
deterministic, and remember annotations sit outside the signed digest.
