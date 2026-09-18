# 204 - The Image Config Blob

**Concepts:** image config JSON, entrypoint vs cmd, rootfs diff_ids

## Run it

```bash
bazel build //204_image_config:show_config
cat bazel-bin/204_image_config/config_dump.json
```

## What is in it

```json
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Entrypoint": ["/app/run.sh"],
    "Cmd": [],
    "Env": ["PATH=/usr/bin"],
    "WorkingDir": "/app",
    "User": "1000:1000"
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": ["sha256:...", "sha256:..."]
  }
}
```

Two distinct halves:

- **`config`** - runtime behaviour. The container engine reads this to start
  the process.
- **`rootfs.diff_ids`** - the identity of the filesystem, in order.

## diff_id is not the layer digest

| | Covers | When they differ |
|---|--------|------------------|
| **digest** (in the manifest) | the blob as stored | compressed layers |
| **diff_id** (in the config) | the *uncompressed* tar | always, if gzipped |

For uncompressed layers they are the same value, which is why this example's
`mkoci` sets both from one hash. Add gzip and they diverge - sample 220.

Getting this backwards produces an image that pulls fine and then fails to
start, because the runtime cannot match layers to the rootfs.

## Entrypoint vs Cmd

```
Entrypoint: ["/app/run.sh"]   Cmd: ["--verbose"]
docker run image              -> /app/run.sh --verbose
docker run image --quiet      -> /app/run.sh --quiet      (Cmd replaced)
```

`Entrypoint` is the program; `Cmd` is the default arguments. Putting the whole
command in `Cmd` means any user argument replaces your program entirely.

## Key takeaway

The config blob answers "how do I run this?" and "what filesystem is this?".
`diff_ids` are uncompressed hashes; manifest digests are stored-blob hashes.
