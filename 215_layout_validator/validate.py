"""Validate an OCI image layout against the spec. A hermetic alternative to
shelling out to skopeo/podman."""
import hashlib, json, os, sys

def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 16), b""):
            h.update(c)
    return h.hexdigest()

def main(argv):
    layout = argv[1]
    errors = []

    # 1. oci-layout marker must exist and declare a known version.
    lp = os.path.join(layout, "oci-layout")
    if not os.path.exists(lp):
        errors.append("missing oci-layout")
    else:
        v = json.load(open(lp)).get("imageLayoutVersion")
        if v != "1.0.0":
            errors.append("unexpected imageLayoutVersion %r" % v)

    # 2. index.json must exist and list at least one manifest.
    ip = os.path.join(layout, "index.json")
    if not os.path.exists(ip):
        errors.append("missing index.json")
        print("\n".join("FAIL: " + e for e in errors)); return 1
    index = json.load(open(ip))
    if not index.get("manifests"):
        errors.append("index.json lists no manifests")

    def check_descriptor(desc, what):
        """Every descriptor must point at a blob whose digest and size match."""
        digest = desc["digest"]
        algo, hexd = digest.split(":", 1)
        if algo != "sha256":
            errors.append("%s: unsupported algorithm %s" % (what, algo)); return None
        blob = os.path.join(layout, "blobs", algo, hexd)
        if not os.path.exists(blob):
            errors.append("%s: blob %s missing" % (what, digest)); return None
        actual = sha256_file(blob)
        if actual != hexd:
            errors.append("%s: digest mismatch (declared %s, actual sha256:%s)" % (what, digest, actual))
        size = os.path.getsize(blob)
        if size != desc["size"]:
            errors.append("%s: size mismatch (declared %d, actual %d)" % (what, desc["size"], size))
        return blob

    for m in index["manifests"]:
        blob = check_descriptor(m, "index->manifest")
        if not blob:
            continue
        manifest = json.load(open(blob))
        check_descriptor(manifest["config"], "manifest->config")
        for i, layer in enumerate(manifest.get("layers", [])):
            check_descriptor(layer, "manifest->layer[%d]" % i)

    # 3. No orphan blobs - every blob should be reachable from the index.
    referenced = set()
    for m in index["manifests"]:
        referenced.add(m["digest"].split(":")[1])
        blob = os.path.join(layout, "blobs", "sha256", m["digest"].split(":")[1])
        if os.path.exists(blob):
            mf = json.load(open(blob))
            referenced.add(mf["config"]["digest"].split(":")[1])
            for l in mf.get("layers", []):
                referenced.add(l["digest"].split(":")[1])
    present = set(os.listdir(os.path.join(layout, "blobs", "sha256")))
    for orphan in sorted(present - referenced):
        errors.append("orphan blob not referenced from index: %s" % orphan)

    if errors:
        for e in errors:
            print("FAIL: %s" % e)
        return 1
    print("PASS: layout valid - %d manifest(s), %d blob(s), all digests verified"
          % (len(index["manifests"]), len(present)))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
