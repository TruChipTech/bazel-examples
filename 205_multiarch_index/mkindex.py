"""Combine several single-arch images into one multi-architecture index."""
import hashlib, json, os, shutil, sys

def put_json(outdir, obj):
    raw = json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()
    d = hashlib.sha256(raw).hexdigest()
    dest = os.path.join(outdir, "blobs", "sha256", d)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    open(dest, "wb").write(raw)
    return d, len(raw)

def main(argv):
    outdir, ref = argv[1], argv[2]
    entries = argv[3:]  # platform=layoutdir triples
    os.makedirs(os.path.join(outdir, "blobs", "sha256"), exist_ok=True)

    manifests = []
    for entry in entries:
        platform, layout = entry.split("=", 1)
        osname, arch = platform.split("/")
        # Copy every blob from the child layout into the combined one.
        src_blobs = os.path.join(layout, "blobs", "sha256")
        for name in os.listdir(src_blobs):
            shutil.copyfile(os.path.join(src_blobs, name),
                            os.path.join(outdir, "blobs", "sha256", name))
        digest = open(os.path.join(layout, "digest.txt")).read().strip()
        size = os.path.getsize(os.path.join(src_blobs, digest.split(":")[1]))
        manifests.append({
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": digest,
            "size": size,
            "platform": {"os": osname, "architecture": arch},
        })

    index = {"schemaVersion": 2,
             "mediaType": "application/vnd.oci.image.index.v1+json",
             "manifests": manifests,
             "annotations": {"org.opencontainers.image.ref.name": ref}}
    raw = json.dumps(index, sort_keys=True, separators=(",", ":")).encode()
    open(os.path.join(outdir, "index.json"), "wb").write(raw)
    open(os.path.join(outdir, "oci-layout"), "w").write('{"imageLayoutVersion":"1.0.0"}')
    open(os.path.join(outdir, "digest.txt"), "w").write(
        "sha256:" + hashlib.sha256(raw).hexdigest() + "\n")
    print("index covers %d platforms" % len(manifests))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
