"""Attach an artifact to an image with the `subject` field (referrers API)."""
import hashlib, json, os, shutil, sys

def put(outdir, data):
    d = hashlib.sha256(data).hexdigest()
    p = os.path.join(outdir, "blobs", "sha256", d)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "wb").write(data)
    return d, len(data)

def main(argv):
    outdir, image_layout, artifact_type, payload_path = argv[1], argv[2], argv[3], argv[4]
    os.makedirs(os.path.join(outdir, "blobs", "sha256"), exist_ok=True)

    # Bring the image's blobs along so the result is self-contained.
    src = os.path.join(image_layout, "blobs", "sha256")
    for name in os.listdir(src):
        shutil.copyfile(os.path.join(src, name),
                        os.path.join(outdir, "blobs", "sha256", name))

    subject_digest = open(os.path.join(image_layout, "digest.txt")).read().strip()
    subject_size = os.path.getsize(os.path.join(src, subject_digest.split(":")[1]))

    payload = open(payload_path, "rb").read()
    pd, psize = put(outdir, payload)
    ed, esize = put(outdir, b"{}")

    manifest = {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.manifest.v1+json",
        "artifactType": artifact_type,
        "config": {"mediaType": "application/vnd.oci.empty.v1+json",
                   "digest": "sha256:" + ed, "size": esize},
        "layers": [{"mediaType": artifact_type, "digest": "sha256:" + pd, "size": psize}],
        # THE point: this manifest declares what it is ABOUT.
        "subject": {"mediaType": "application/vnd.oci.image.manifest.v1+json",
                    "digest": subject_digest, "size": subject_size},
    }
    raw = json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()
    md, msize = put(outdir, raw)

    index = {"schemaVersion": 2, "manifests": [
        {"mediaType": "application/vnd.oci.image.manifest.v1+json",
         "digest": subject_digest, "size": subject_size,
         "annotations": {"org.opencontainers.image.ref.name": "image"}},
        {"mediaType": "application/vnd.oci.image.manifest.v1+json",
         "artifactType": artifact_type, "digest": "sha256:" + md, "size": msize,
         "subject": {"digest": subject_digest}},
    ]}
    open(os.path.join(outdir, "index.json"), "w").write(
        json.dumps(index, sort_keys=True, separators=(",", ":")))
    open(os.path.join(outdir, "oci-layout"), "w").write('{"imageLayoutVersion":"1.0.0"}')
    print("attached %s to %s" % (artifact_type, subject_digest))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
