# 331 - Signed Firmware and Secure Boot

**Concepts:** boot headers, rollback protection, signature over header+payload

## Run it

```bash
bazel test //331_signed_firmware:boot_test --test_output=all
```

```
magic     : BFW1
version   : 7 (minimum 5)
slot      : 0
payload   : 35 bytes
PASS: header, integrity, rollback and signature all check out - would boot
```

## The image layout

```
+--------------------------------+ 0x0000
| header (64 bytes)              |  magic | version | length | slot | sha256
+--------------------------------+ 0x0040
| payload (raw firmware)         |
+--------------------------------+
```

with a detached signature over **header + payload** together.

## Sign the header too, not just the payload

This is the subtle part. If you sign only the payload:

```
signature covers: [payload]
attacker edits:   version 7 -> version 2     (in the header)
result:           signature still verifies, device boots old vulnerable code
```

Signing header+payload binds the version and slot fields into the signature, so
a downgrade invalidates it. Rollback protection that is not covered by the
signature is not protection.

## What the bootloader actually checks

`verify_boot.py` does the four things a ROM bootloader does, in order:

1. **Header sanity** - magic matches, declared length matches actual
2. **Integrity** - `sha256(payload)` equals the header's digest
3. **Rollback** - `version >= minimum` burned into the device
4. **Authenticity** - signature verifies against a public key in OTP fuses

Only then does it jump. Order matters: never hash or execute something you have
not length-checked.

## Try breaking it

```bash
# Flip a byte in the payload
cp bazel-bin/331_signed_firmware/fw_image.bin /tmp/tampered.bin
printf '\xff' | dd of=/tmp/tampered.bin bs=1 seek=70 conv=notrunc 2>/dev/null
bazel run //331_signed_firmware:verify_boot -- /tmp/tampered.bin \
  $PWD/bazel-bin/331_signed_firmware/fw_image.sig \
  $PWD/251_signing_basics/testkeys/rsa_public.pem 5
```

Both the digest check and the signature check fail - defence in depth.

## A/B slots

The `slot` field supports the standard update pattern: write the new image to
the inactive slot, verify it, flip a flag, reboot. If it fails to boot, the
bootloader falls back to the other slot. Sample 341 builds both slots.

## Key takeaway

Sign header and payload together, verify integrity before authenticity, and
make rollback protection part of the signed region.

## Aside: never hard-code a runfiles path

The public key lives in an external repository, so its runfiles path is the
**canonical** repo name:

```
+signing_keys+signing_keys/rsa_public.pem
```

Nobody should type that. This test takes every path as an argument computed by
`$(rootpath ...)`:

```python
args = [
    "$(rootpath :verify_boot)",
    "$(rootpath fw_image.bin)",
    "$(rootpath @signing_keys//:rsa_public.pem)",
    "5",
]
```

Bazel resolves each label to the right runfiles path, and renaming the
repository cannot break the test. Sample 037 introduces the expansions; this is
where it stops being theoretical.
