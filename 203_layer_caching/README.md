# 203 - Layer Ordering and Caching

**Concepts:** layer granularity, change frequency, push cost

## Run it

```bash
bazel build //203_layer_caching:image
cat bazel-bin/203_layer_caching/image_layout/digest.txt

# Touch only the app layer's content
echo "new app content" > 203_layer_caching/app.txt
bazel build //203_layer_caching:image
```

Only `app_layer` is rebuilt. `base_layer` and `deps_layer` are cache hits, and
their blobs keep the same digests.

## Order by change frequency

```python
layers = [
    ":base_layer",   # OS packages      - changes monthly
    ":deps_layer",   # vendored deps    - changes weekly
    ":app_layer",    # your code        - changes hourly
]
```

Layers are content-addressed independently, so a registry only needs the blobs
it does not already have. Put the application first and every push transfers
everything.

## The granularity tradeoff

| Too few layers | Too many layers |
|----------------|-----------------|
| Any change repushes everything | Per-layer metadata overhead |
| No reuse between images | Slower manifest resolution |
| | Diminishing returns past ~10 |

Three to five layers is typical: base, runtime dependencies, application.

## Sharing across images

Two images built from the same `base_layer` reference the **same blob digest**.
The registry stores it once; a host that already has it skips the download.
That is why a fleet of 50 services sharing one base is far cheaper than 50
independent images - see sample 401.

## Key takeaway

Layer order is a caching decision. Least-frequently-changed first.
