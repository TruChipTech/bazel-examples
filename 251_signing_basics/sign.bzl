"""Real cryptographic signing and verification as build actions.

Uses the host `openssl`. That is a deliberate hermeticity tradeoff, documented
in the README: a production setup would bring openssl in as a toolchain
(sample 169) or call out to a KMS.
"""

SignatureInfo = provider(
    doc = "A detached signature over a payload.",
    fields = {
        "payload": "File - the bytes that were signed",
        "signature": "File - the detached signature",
        "digest": "File - the payload's sha256, as text",
    },
)

def _sign_impl(ctx):
    sig = ctx.actions.declare_file(ctx.label.name + ".sig")
    digest = ctx.actions.declare_file(ctx.label.name + ".sha256")

    ctx.actions.run_shell(
        inputs = [ctx.file.payload, ctx.file.private_key],
        outputs = [sig, digest],
        arguments = [
            ctx.file.payload.path,
            ctx.file.private_key.path,
            sig.path,
            digest.path,
            ctx.attr.digest_alg,
        ],
        command = """
          set -euo pipefail
          payload="$1"; key="$2"; sig="$3"; dgst="$4"; alg="$5"
          # The signature is over the payload's DIGEST, not the payload itself -
          # that is what lets you sign a 2 GB image with one cheap operation.
          openssl dgst -"$alg" -sign "$key" -out "$sig" "$payload"
          openssl dgst -"$alg" -r "$payload" | cut -d' ' -f1 > "$dgst"
        """,
        env = {"PATH": "/usr/bin:/bin:/usr/local/bin"},
        mnemonic = "Sign",
        progress_message = "Signing %s" % ctx.label,
    )

    return [
        DefaultInfo(files = depset([sig, digest])),
        SignatureInfo(payload = ctx.file.payload, signature = sig, digest = digest),
    ]

sign_file = rule(
    implementation = _sign_impl,
    attrs = {
        "payload": attr.label(allow_single_file = True, mandatory = True),
        "private_key": attr.label(allow_single_file = True, mandatory = True),
        "digest_alg": attr.string(default = "sha256", values = ["sha256", "sha384", "sha512"]),
    },
    provides = [SignatureInfo],
)

def _verify_test_impl(ctx):
    sig_info = ctx.attr.signature[SignatureInfo]
    script = ctx.actions.declare_file(ctx.label.name + "_verify.sh")

    ctx.actions.write(
        output = script,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -uo pipefail
payload="{payload}"
sig="{sig}"
pub="{pub}"

echo "verifying $sig over $payload"
if openssl dgst -{alg} -verify "$pub" -signature "$sig" "$payload"; then
  echo "PASS: signature is valid"
  exit 0
fi
echo "FAIL: signature did NOT verify"
exit 1
""".format(
            payload = sig_info.payload.short_path,
            sig = sig_info.signature.short_path,
            pub = ctx.file.public_key.short_path,
            alg = ctx.attr.digest_alg,
        ),
    )

    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = [
            sig_info.payload,
            sig_info.signature,
            ctx.file.public_key,
        ]),
    )]

verify_signature_test = rule(
    implementation = _verify_test_impl,
    test = True,
    attrs = {
        "signature": attr.label(providers = [SignatureInfo], mandatory = True),
        "public_key": attr.label(allow_single_file = True, mandatory = True),
        "digest_alg": attr.string(default = "sha256"),
    },
)
