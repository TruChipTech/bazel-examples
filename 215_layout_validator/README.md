# 215 - Validating an Image Layout

**Concepts:** spec conformance, digest verification, orphan blobs

## Run it

```bash
bazel test //215_layout_validator:all --test_output=all
```

```
PASS: layout valid - 1 manifest(s), 3 blob(s), all digests verified
```

## What it checks

| Check | Catches |
|-------|---------|
| `oci-layout` present, version 1.0.0 | Malformed layout |
| `index.json` lists manifests | Empty image |
| Every descriptor's blob exists | Dangling reference |
| **Recomputed digest matches** | Corruption, or a builder that lied |
| Declared size matches actual | Off-by-one in a hand-rolled builder |
| No orphan blobs | Leftovers bloating the artifact |

The digest recomputation is the important one. It is the same check a registry
and a runtime perform on pull, so failing here means failing in production.

## Why not just run skopeo or podman?

A validator written in Python is **hermetic**: no daemon, no network, no
container runtime, and it runs identically under remote execution. Shelling out
to podman would make every image test depend on a working container stack.

The tradeoff is that this validates the spec as I understand it, not as the
canonical implementation does. For a production pipeline, run both - this in
every build, a real tool in a nightly.

## Reusable across examples

One validator, applied to three different images from three different examples:

```python
for name, target, path in [
    ("basic", "//201_oci_layout_basics:image", ...),
    ("layered", "//203_layer_caching:image", ...),
    ("multiarch", "//205_multiarch_index:multiarch", ...),
]
```

## Key takeaway

An image layout is checkable without any container tooling. Verify digests,
not just structure.
