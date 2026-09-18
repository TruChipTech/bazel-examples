# 214 - Sharing a Base Layer

**Concepts:** content-addressed dedup, registry storage, pull cost

## Run it

```bash
bazel build //214_shared_base_layers:dedup_report
cat bazel-bin/214_shared_base_layers/dedup.txt
```

The base layer's digest appears **three times** - once per image - because all
three manifests reference the identical blob.

## Why this is free

Layers are addressed by the hash of their content, not by which image built
them. Three images referencing the same bytes reference the same digest, so:

- The registry stores **one** copy
- A host that already pulled image A gets image B's base for free
- Pushing 50 services with a shared base transfers the base **once**

Nothing declares the sharing. It falls out of content addressing.

## The corollary

If your base layer is not byte-identical across images, none of this happens.
A base built with a timestamp, or with per-service uid/gid, silently produces
N distinct blobs that look identical. Sample 202 is the prerequisite for this
one.

## Scaling it

Sample 401 builds five signed images; add a shared base and the marginal cost
of each additional service is only its own application layer. That is the
architecture behind a large service fleet.

## Key takeaway

Deduplication is automatic and free - provided your layers are deterministic.
