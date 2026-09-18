"""Store arbitrary content in an OCI layout as an ARTIFACT, not an image.

Registries are general-purpose content-addressed stores. Signatures, SBOMs,
attestations, Helm charts and WASM modules all ship this way: a manifest whose
artifactType says what it is, with the payload as a layer.
"""
import hashlib, json, os, sys

def put(outdir, data):
    d = hashlib.sha256(data).hexdigest()
    p = os.path.join(outdir, "blobs", "sha256", d)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "wb").write(data)
    return d, len(data)

def main(argv):
    outdir, artifact_type, payload_path, ref = argv[1], argv[2], argv[3], argv[4]
    os.makedirs(os.path.join(outdir, "blobs", "sha256"), exist_ok=True)

    payload = open(payload_path, "rb").read()
    pd, psize = put(outdir, payload)

    # An artifact still needs a config blob; the spec defines an "empty" one.
    ed, esize = put(outdir, b"{}")

    manifest = {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.manifest.v1+json",
        "artifactType": artifact_type,
        "config": {"mediaType": "application/vnd.oci.empty.v1+json",
                   "digest": "sha256:" + ed, "size": esize},
        "layers": [{"mediaType": artifact_type,
                    "digest": "sha256:" + pd, "size": psize}],
    }
    raw = json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()
    md, msize = put(outdir, raw)

    index = {"schemaVersion": 2, "manifests": [
        {"mediaType": "application/vnd.oci.image.manifest.v1+json",
         "artifactType": artifact_type,
         "digest": "sha256:" + md, "size": msize,
         "annotations": {"org.opencontainers.image.ref.name": ref}}]}
    open(os.path.join(outdir, "index.json"), "w").write(
        json.dumps(index, sort_keys=True, separators=(",", ":")))
    open(os.path.join(outdir, "oci-layout"), "w").write('{"imageLayoutVersion":"1.0.0"}')
    open(os.path.join(outdir, "digest.txt"), "w").write("sha256:" + md + "\n")
    print("artifact %s -> sha256:%s" % (artifact_type, md))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
