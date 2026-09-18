"""Build a minimal, spec-compliant OCI image layout. No daemon, no network.

An OCI image is four kinds of content-addressed blob plus an index:

    blobs/sha256/<digest>   layer tarballs, the config JSON, the manifest JSON
    index.json              entry point: points at manifest(s) by digest
    oci-layout              {"imageLayoutVersion": "1.0.0"}

Every reference is BY DIGEST, which is what makes an image immutable and
verifiable. Change one byte of a layer and every digest above it changes.
"""

import hashlib
import json
import os
import shutil
import sys


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def put_blob(outdir, path):
    """Copy a file into blobs/sha256/<digest>, return (digest, size)."""
    digest = sha256_file(path)
    size = os.path.getsize(path)
    dest = os.path.join(outdir, "blobs", "sha256", digest)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copyfile(path, dest)
    return digest, size


def put_json(outdir, obj):
    """Serialize deterministically, store as a blob, return (digest, size)."""
    # separators + sort_keys => byte-identical output for identical input.
    raw = json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()
    digest = hashlib.sha256(raw).hexdigest()
    dest = os.path.join(outdir, "blobs", "sha256", digest)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as handle:
        handle.write(raw)
    return digest, len(raw)


def main(argv):
    if len(argv) < 5:
        print("usage: mkoci OUTDIR REF ENTRYPOINT LAYER_TAR...", file=sys.stderr)
        return 2
    outdir, ref, entrypoint = argv[1], argv[2], argv[3]
    layers = argv[4:]

    os.makedirs(os.path.join(outdir, "blobs", "sha256"), exist_ok=True)

    layer_descriptors = []
    diff_ids = []
    for tar_path in layers:
        digest, size = put_blob(outdir, tar_path)
        layer_descriptors.append({
            "mediaType": "application/vnd.oci.image.layer.v1.tar",
            "digest": "sha256:" + digest,
            "size": size,
        })
        # For an UNCOMPRESSED layer the diff_id equals the blob digest.
        diff_ids.append("sha256:" + digest)

    config = {
        "architecture": "amd64",
        "os": "linux",
        "config": {"Entrypoint": [entrypoint]},
        "rootfs": {"type": "layers", "diff_ids": diff_ids},
    }
    config_digest, config_size = put_json(outdir, config)

    manifest = {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.manifest.v1+json",
        "config": {
            "mediaType": "application/vnd.oci.image.config.v1+json",
            "digest": "sha256:" + config_digest,
            "size": config_size,
        },
        "layers": layer_descriptors,
    }
    manifest_digest, manifest_size = put_json(outdir, manifest)

    index = {
        "schemaVersion": 2,
        "manifests": [{
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:" + manifest_digest,
            "size": manifest_size,
            "annotations": {"org.opencontainers.image.ref.name": ref},
        }],
    }
    with open(os.path.join(outdir, "index.json"), "w") as handle:
        json.dump(index, handle, sort_keys=True, separators=(",", ":"))
    with open(os.path.join(outdir, "oci-layout"), "w") as handle:
        json.dump({"imageLayoutVersion": "1.0.0"}, handle)

    # The image's identity is the MANIFEST digest.
    with open(os.path.join(outdir, "digest.txt"), "w") as handle:
        handle.write("sha256:" + manifest_digest + "\n")

    print("image digest: sha256:%s" % manifest_digest)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
