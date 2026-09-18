# 209 - Non-Root Images

**Concepts:** uid/gid in layers, `User` in the config, least privilege

## Run it

```bash
bazel build //209_nonroot_image:layer
tar tvf bazel-bin/209_nonroot_image/layer.tar
```

```
-r-xr-x--- nonroot/nonroot   28 2000-01-01 00:00 app/app.sh
```

Owner, group and mode are all set - none of them inherited from whoever ran the
build.

## Two halves, both required

**1. File ownership in the layer:**
```python
pkg_attributes(owner = "65532.65532", user = "nonroot", group = "nonroot", mode = "0550")
```

**2. The runtime user in the image config:**
```json
"config": {"User": "65532:65532"}
```

Set only the config and your process runs as uid 65532 against files owned by
root - permission denied. Set only the ownership and the process still runs as
root. You need both.

## Use a numeric uid

```json
"User": "nonroot"     // requires /etc/passwd to exist in the image
"User": "65532:65532" // always works
```

A distroless or scratch image may have no `/etc/passwd`, in which case a name
cannot be resolved and the container fails to start. 65532 is the conventional
`nonroot` uid used by distroless images.

## Why bother

A container escape from a root process is a root escape on the host unless user
namespaces are in play. Running as a non-root uid is the cheapest meaningful
mitigation, and it is a build-time decision - which means it can be *tested*
(sample 211) rather than left to deployment config.

## Key takeaway

Ownership goes in the layer, `User` goes in the config, and the uid should be
numeric.
