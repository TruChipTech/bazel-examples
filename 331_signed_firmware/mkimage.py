"""Wrap a raw flash image in a signed boot header (secure-boot style).

Layout written to flash:

    +----------------------------------+ 0x0000
    | header (64 bytes, fixed)         |  magic, version, length, payload sha256
    +----------------------------------+ 0x0040
    | payload (the raw firmware)       |
    +----------------------------------+
    | signature (detached, appended)   |
    +----------------------------------+

A real ROM bootloader does exactly this in reverse: read header, hash payload,
compare, verify signature with a public key burned into OTP, then jump.
"""

import hashlib
import struct
import sys

MAGIC = b"BFW1"
HEADER_SIZE = 64


def main(argv):
    if len(argv) != 6:
        print("usage: mkimage PAYLOAD VERSION SLOT OUT_HEADER OUT_IMAGE", file=sys.stderr)
        return 2
    payload_path, version, slot, out_header, out_image = argv[1:]

    with open(payload_path, "rb") as handle:
        payload = handle.read()

    digest = hashlib.sha256(payload).digest()

    header = struct.pack(
        "<4sIII32s",
        MAGIC,                 # magic
        int(version),          # firmware version, for rollback protection
        len(payload),          # payload length
        int(slot),             # A/B slot index
        digest,                # sha256 of the payload
    )
    header += b"\x00" * (HEADER_SIZE - len(header))
    assert len(header) == HEADER_SIZE

    with open(out_header, "wb") as handle:
        handle.write(header)
    with open(out_image, "wb") as handle:
        handle.write(header)
        handle.write(payload)

    print("payload   : %d bytes" % len(payload))
    print("sha256    : %s" % digest.hex())
    print("image     : %d bytes (header %d + payload)" % (HEADER_SIZE + len(payload), HEADER_SIZE))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
