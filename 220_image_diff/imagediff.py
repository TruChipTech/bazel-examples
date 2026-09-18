"""Diff two image layouts: what changed, and did anything need to?"""
import json, os, sys, tarfile

def load(layout):
    d = open(os.path.join(layout, "digest.txt")).read().strip()
    m = json.load(open(os.path.join(layout, "blobs/sha256", d.split(":")[1])))
    return d, m

def files_in(layout, layer_digest):
    blob = os.path.join(layout, "blobs/sha256", layer_digest.split(":")[1])
    with tarfile.open(blob) as tf:
        return {m.name: m.size for m in tf.getmembers() if m.isfile()}

def main(argv):
    a, b = argv[1], argv[2]
    da, ma = load(a)
    db, mb = load(b)

    print("image A: %s" % da)
    print("image B: %s" % db)
    if da == db:
        print("IDENTICAL - same digest, nothing changed")
        return 0

    la = [l["digest"] for l in ma["layers"]]
    lb = [l["digest"] for l in mb["layers"]]
    shared = [d for d in la if d in lb]
    print("\nlayers: A=%d B=%d shared=%d" % (len(la), len(lb), len(shared)))
    for d in la:
        if d not in lb:
            print("  only in A: %s" % d[:19])
    for d in lb:
        if d not in la:
            print("  only in B: %s" % d[:19])

    fa, fb = {}, {}
    for d in la: fa.update(files_in(a, d))
    for d in lb: fb.update(files_in(b, d))
    print("\nfiles:")
    for name in sorted(set(fa) | set(fb)):
        if name not in fb:      print("  removed: %s" % name)
        elif name not in fa:    print("  added:   %s" % name)
        elif fa[name] != fb[name]:
            print("  changed: %s (%d -> %d bytes)" % (name, fa[name], fb[name]))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
