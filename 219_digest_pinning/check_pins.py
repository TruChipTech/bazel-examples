"""Fail the build if any image reference is a floating tag."""
import json, os, re, sys

FLOATING = re.compile(r":(latest|main|master|stable|dev|edge)$")

def main(argv):
    failures = []
    for layout in argv[1:]:
        index = json.load(open(os.path.join(layout, "index.json")))
        for m in index["manifests"]:
            ref = m.get("annotations", {}).get("org.opencontainers.image.ref.name", "")
            if FLOATING.search(ref):
                failures.append("%s: floating tag %r - pin by digest or an immutable tag" % (layout, ref))
            base = m.get("annotations", {}).get("org.opencontainers.image.base.name", "")
            if base and "@sha256:" not in base:
                failures.append("%s: base image %r is not pinned by digest" % (layout, base))
    if failures:
        for f in failures:
            print("FAIL: %s" % f)
        return 1
    print("PASS: all image references are immutable")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
