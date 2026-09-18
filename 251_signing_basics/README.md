# 251 - Signing and Verifying With Real Keys

**Concepts:** `openssl`, RSA vs ECDSA, detached signatures, verification as a test

Real cryptography as build actions. No mocking: this generates genuine RSA-2048
and ECDSA P-256 signatures and verifies them.

## Run it

```bash
bazel test //251_signing_basics:all --test_output=all
bazel build //251_signing_basics:artifact_rsa_sig
xxd bazel-bin/251_signing_basics/artifact_rsa_sig.sig | head -3
```

## You sign a digest, not the bytes

```bash
openssl dgst -sha256 -sign key.pem -out out.sig payload
```

`dgst -sign` hashes the payload, then signs the *hash*. That is why signing a
2 GB disk image costs the same as signing a 20-byte file, and why every later
example signs a digest rather than content.

## RSA vs ECDSA

| | RSA-2048 | ECDSA P-256 |
|---|---|---|
| Signature size | 256 bytes | ~70 bytes |
| Signing speed | Slower | Faster |
| Verify speed | **Faster** | Slower |
| Ubiquity | Universal | Universal now |

For firmware, verify speed and signature size matter most - a ROM bootloader
verifies on every boot, and the signature occupies flash. Both are shown here.

## Verification is a test, not a script

```python
verify_signature_test(
    name = "rsa_verify_test",
    signature = ":artifact_rsa_sig",
    public_key = "@signing_keys//:rsa_public.pem",
)
```

Making verification a `*_test` target means CI runs it automatically, the result
is cached, and a broken signature fails the build rather than a nightly job
nobody reads.

## The keys are generated, not committed

There is no keypair in this repository. `keys.bzl` defines a **repository
rule** that runs `openssl` once per workspace:

```python
signing_keys = use_repo_rule("//251_signing_basics:keys.bzl", "signing_keys")
signing_keys(name = "signing_keys")
```

Targets then reference `@signing_keys//:rsa_private.pem`.

### Why not just commit a test keypair?

It is tempting - it would make signatures byte-identical everywhere. But a file
beginning `-----BEGIN PRIVATE KEY-----` in a public repository:

- Trips GitHub push protection, which may **reject the push**
- Generates secret-scanning alerts somebody has to trumpet as false positives
- Teaches the wrong reflex to anyone reading the repo

### What it costs

A repository rule's output is cached in the output base, so the keys are stable
for every build on this machine. They are **not** identical across machines, so
signature *bytes* differ between checkouts.

That does not matter here, because what these examples verify is that a
signature **validates** - not that it equals a fixed string. If you ever did
need reproducible signature bytes, you would need a fixed key, and it would
have to come from a secret store rather than from git.

### What production does

Neither of the above. The private key lives in a KMS or HSM, the build calls
out to sign, and the key never exists as a file at all.

## The hermeticity tradeoff

These rules shell out to the host `openssl`. That is a declared dependency on
the machine, and a different openssl version could in principle behave
differently. A fully hermetic setup would bring openssl in as a toolchain
(sample 169). The tradeoff is called out here rather than hidden.

## Key takeaway

Sign digests, verify in a test target, and keep private keys out of the build.
