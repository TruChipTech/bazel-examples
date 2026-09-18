"""Assert security policy over a built image layout."""
import json, os, sys, tarfile

def main(argv):
    layout = argv[1]
    failures = []

    manifest_digest = open(os.path.join(layout, "digest.txt")).read().strip().split(":")[1]
    manifest = json.load(open(os.path.join(layout, "blobs/sha256", manifest_digest)))
    config_digest = manifest["config"]["digest"].split(":")[1]
    config = json.load(open(os.path.join(layout, "blobs/sha256", config_digest)))

    # 1. Must declare an entrypoint - otherwise the runtime default applies.
    if not config.get("config", {}).get("Entrypoint"):
        failures.append("no Entrypoint declared")

    # 2. Inspect every layer for things that must never ship.
    BANNED = (".ssh/", "id_rsa", ".env", ".git/", "credentials", ".aws/")
    for layer in manifest["layers"]:
        blob = os.path.join(layout, "blobs/sha256", layer["digest"].split(":")[1])
        with tarfile.open(blob) as tf:
            for member in tf.getmembers():
                low = member.name.lower()
                for bad in BANNED:
                    if bad in low:
                        failures.append("banned path in layer: %s" % member.name)
                # 3. No world-writable files.
                if member.isfile() and member.mode & 0o002:
                    failures.append("world-writable: %s (mode %o)" % (member.name, member.mode))
                # 4. No setuid binaries.
                if member.mode & 0o4000:
                    failures.append("setuid binary: %s" % member.name)

    if failures:
        for f in failures:
            print("FAIL: %s" % f)
        return 1
    print("PASS: image satisfies policy (entrypoint, no secrets, no world-writable, no setuid)")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
