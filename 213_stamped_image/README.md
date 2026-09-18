# 213 - Stamping Provenance Into an Image

**Concepts:** `ctx.info_file`, STABLE_ keys, commit not clock

## Run it

```bash
bazel build //213_stamped_image:released
python3 -m json.tool bazel-bin/213_stamped_image/released_layout/index.json

# With the release config, which enables --stamp and the status script:
bazel build --config=release //213_stamped_image:released
```

## Use the commit, never the clock

```python
ann["org.opencontainers.image.revision"] = values["STABLE_GIT_COMMIT"]
```

A build timestamp changes on every build, so the index bytes change, so the
image is "new" every time - defeating reproducibility (sample 207) and layer
reuse. A commit SHA changes only when the source does, which is exactly the
semantics you want.

## Which status file

| Field | File | Changing a value |
|-------|------|------------------|
| `ctx.info_file` | `stable-status.txt` | **does** invalidate downstream |
| `ctx.version_file` | `volatile-status.txt` | does not |

Counter-intuitively `version_file` is the *volatile* one (sample 091). For
stamping an image you want `info_file`, because you *do* want a new commit to
produce a new image.

## Annotations are not signed

These land in the index, outside the manifest digest - so they are not covered
by an image signature (sample 271). For tamper-evident provenance use a signed
attestation instead (sample 281). Annotations are for humans and dashboards.

## Key takeaway

Stamp the commit into annotations via `ctx.info_file`; never stamp a timestamp.

## Gotcha: copying a tree artifact

```python
shutil.copytree(src, out)                                   # files are read-only
shutil.copytree(src, out, copy_function=shutil.copyfile)    # writable
```

Bazel makes action outputs **read-only**. `copytree` defaults to `copy2`, which
preserves mode, so every copied file arrives read-only and the next write
fails:

```
PermissionError: [Errno 13] Permission denied: '.../index.json'
```

`copyfile` copies content without mode. Any tool that reads a Bazel output and
writes a modified copy hits this.
