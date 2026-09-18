# 271 - Signing a Container Image

**Concepts:** manifest digest, cosign payloads, binding a signature to an image

## Run it

```bash
bazel test //271_sign_oci_image:server_signature_test --test_output=all
cat bazel-bin/271_sign_oci_image/server_signature.payload.json
```

```
PASS: signature valid AND bound to image sha256:1971badd83a3...
```

## One signature covers the whole image

```
manifest digest  --covers-->  config digest
                 --covers-->  layer digests  --covers--> every byte
```

Because an OCI image is a digest tree (sample 201), signing the **manifest
digest** transitively authenticates everything. One RSA operation over 64 hex
characters, however many gigabytes the image is.

## The payload, and why it is not just the digest

```json
{"critical":{"identity":{"docker-reference":"registry.example.com/server:v1"},
             "image":{"docker-manifest-digest":"sha256:1971ba..."},
             "type":"cosign container image signature"},
 "optional":null}
```

This is cosign's "simple signing" format. Signing a small JSON document rather
than the bare digest leaves room for claims - who built it, what it is, which
reference it was published under.

## The check almost everyone forgets

A valid signature proves *somebody signed something*. It does **not** prove they
signed **this** image. The verification here does two things:

```bash
# 1. is the signature cryptographically valid over the payload?
openssl dgst -sha256 -verify "$pub" -signature "$sig" "$payload"

# 2. does the payload's digest actually match THIS image?
[ "$claimed" = "$(cat "$layout/digest.txt")" ]
```

Skip step 2 and an attacker can pair a legitimately-signed payload for image A
with image B and pass verification. This is a real class of bug in hand-rolled
verification.

## Where cosign fits

`cosign sign --key k.pem <image>` does what this example does, then **publishes**
the signature to the registry as an OCI artifact tagged
`sha256-<digest>.sig` alongside the image. Sample 247 covers that attachment
model.

cosign is not installed here, so this builds the payload and signature directly
with openssl - the cryptography and the binding check are identical.

## Key takeaway

Sign the manifest digest, and always verify that the signed payload refers to
the image in front of you.
