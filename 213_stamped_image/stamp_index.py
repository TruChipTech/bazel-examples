"""Inject stamped provenance into an image index, deterministically."""
import json, os, shutil, sys

def main(argv):
    src, status_file, out = argv[1], argv[2], argv[3]
    # copy_function=shutil.copyfile copies CONTENT ONLY. The default (copy2)
    # preserves permissions, and Bazel's outputs are read-only - so the copied
    # index.json would be unwritable and the rewrite below fails with
    # "PermissionError: [Errno 13] Permission denied".
    shutil.copytree(src, out, dirs_exist_ok=True, copy_function=shutil.copyfile)

    values = {}
    for line in open(status_file):
        parts = line.strip().split(" ", 1)
        if len(parts) == 2:
            values[parts[0]] = parts[1]

    index = json.load(open(os.path.join(out, "index.json")))
    ann = index["manifests"][0].setdefault("annotations", {})
    ann["org.opencontainers.image.revision"] = values.get("STABLE_GIT_COMMIT", "unknown")
    # NOTE: the commit, not the clock. A build timestamp would change the index
    # on every build and destroy reproducibility.
    ann["org.opencontainers.image.version"] = values.get("STABLE_GIT_BRANCH", "unknown")
    json.dump(index, open(os.path.join(out, "index.json"), "w"),
              sort_keys=True, separators=(",", ":"))
    print("stamped revision=%s" % ann["org.opencontainers.image.revision"])
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
