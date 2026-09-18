"""Sign an OCI image the way cosign does: sign the MANIFEST DIGEST.

The manifest digest transitively covers the config and every layer, so one
signature over ~64 hex characters authenticates the entire image, however
large. This is the single most important idea in image signing.
"""

load("//201_oci_layout_basics:oci.bzl", "OciImageInfo")

SignedImageInfo = provider(
    fields = {
        "layout": "File - the image layout",
        "payload": "File - the signed payload (JSON, cosign-style)",
        "signature": "File - detached signature over the payload",
    },
)

def _sign_image_impl(ctx):
    image = ctx.attr.image[OciImageInfo]
    payload = ctx.actions.declare_file(ctx.label.name + ".payload.json")
    sig = ctx.actions.declare_file(ctx.label.name + ".sig")

    ctx.actions.run_shell(
        inputs = [image.layout, ctx.file.private_key],
        outputs = [payload, sig],
        arguments = [
            image.layout.path,
            ctx.file.private_key.path,
            payload.path,
            sig.path,
            ctx.attr.image_ref,
        ],
        command = """
          set -euo pipefail
          layout="$1"; key="$2"; payload="$3"; sig="$4"; ref="$5"

          digest=$(cat "$layout/digest.txt")

          # A cosign "simple signing" payload: a small, stable JSON document
          # that names WHAT is being attested and WHICH image it refers to.
          # Signing this rather than the raw digest leaves room for claims.
          printf '{"critical":{"identity":{"docker-reference":"%s"},"image":{"docker-manifest-digest":"%s"},"type":"cosign container image signature"},"optional":null}' \
            "$ref" "$digest" > "$payload"

          openssl dgst -sha256 -sign "$key" -out "$sig" "$payload"
        """,
        env = {"PATH": "/usr/bin:/bin:/usr/local/bin"},
        mnemonic = "SignImage",
        progress_message = "Signing image %s" % ctx.label,
    )

    return [
        DefaultInfo(files = depset([payload, sig])),
        SignedImageInfo(layout = image.layout, payload = payload, signature = sig),
    ]

sign_oci_image = rule(
    implementation = _sign_image_impl,
    attrs = {
        "image": attr.label(providers = [OciImageInfo], mandatory = True),
        "private_key": attr.label(allow_single_file = True, mandatory = True),
        "image_ref": attr.string(mandatory = True),
    },
    provides = [SignedImageInfo],
)

def _verify_image_impl(ctx):
    signed = ctx.attr.signed_image[SignedImageInfo]
    script = ctx.actions.declare_file(ctx.label.name + "_verify.sh")

    ctx.actions.write(
        output = script,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -uo pipefail
layout="{layout}"
payload="{payload}"
sig="{sig}"
pub="{pub}"

fail() {{ echo "FAIL: $1"; exit 1; }}

# 1. The signature must be valid over the payload.
openssl dgst -sha256 -verify "$pub" -signature "$sig" "$payload" \
  || fail "signature does not verify"

# 2. The payload must actually refer to THIS image. A valid signature over
#    somebody else's payload proves nothing - this is the step people skip.
claimed=$(sed 's/.*"docker-manifest-digest":"\\([^"]*\\)".*/\\1/' "$payload")
actual=$(cat "$layout/digest.txt")
[ "$claimed" = "$actual" ] || fail "payload digest $claimed != image digest $actual"

echo "PASS: signature valid AND bound to image $actual"
""".format(
            layout = signed.layout.short_path,
            payload = signed.payload.short_path,
            sig = signed.signature.short_path,
            pub = ctx.file.public_key.short_path,
        ),
    )

    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = [
            signed.layout,
            signed.payload,
            signed.signature,
            ctx.file.public_key,
        ]),
    )]

verify_oci_signature_test = rule(
    implementation = _verify_image_impl,
    test = True,
    attrs = {
        "signed_image": attr.label(providers = [SignedImageInfo], mandatory = True),
        "public_key": attr.label(allow_single_file = True, mandatory = True),
    },
)
