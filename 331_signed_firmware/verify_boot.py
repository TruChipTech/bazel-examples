"""Simulate what a ROM bootloader does before jumping to firmware."""

import hashlib
import struct
import subprocess
import sys

HEADER_SIZE = 64
MAGIC = b"BFW1"


def main(argv):
    image_path, sig_path, pubkey_path, min_version = argv[1], argv[2], argv[3], int(argv[4])

    with open(image_path, "rb") as handle:
        blob = handle.read()

    failures = []

    # 1. Header sanity - a bootloader refuses to parse garbage.
    magic, version, length, slot, digest = struct.unpack("<4sIII32s", blob[:48])
    if magic != MAGIC:
        failures.append("bad magic %r" % magic)
    payload = blob[HEADER_SIZE:]
    if len(payload) != length:
        failures.append("length mismatch: header says %d, got %d" % (length, len(payload)))

    # 2. Integrity - does the payload match the hash the header claims?
    actual = hashlib.sha256(payload).digest()
    if actual != digest:
        failures.append("payload digest mismatch")

    # 3. Rollback protection - refuse to boot an older, possibly vulnerable build.
    if version < min_version:
        failures.append("rollback: version %d < minimum %d" % (version, min_version))

    # 4. Authenticity - the signature must verify against the burned-in key.
    result = subprocess.run(
        ["openssl", "dgst", "-sha256", "-verify", pubkey_path, "-signature", sig_path, image_path],
        capture_output=True,
    )
    if result.returncode != 0:
        failures.append("signature invalid: %s" % result.stderr.decode().strip())

    print("magic     : %s" % magic.decode(errors="replace"))
    print("version   : %d (minimum %d)" % (version, min_version))
    print("slot      : %d" % slot)
    print("payload   : %d bytes" % len(payload))
    print("sha256    : %s" % actual.hex())

    if failures:
        for f in failures:
            print("FAIL: %s" % f)
        return 1
    print("PASS: header, integrity, rollback and signature all check out - would boot")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
