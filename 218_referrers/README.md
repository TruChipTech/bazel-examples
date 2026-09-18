# 218 - Referrers: Attaching Signatures and SBOMs to an Image

**Concepts:** the `subject` field, referrers API, discoverability

## Run it

```bash
bazel build //218_referrers:signed_bundle
python3 -m json.tool bazel-bin/218_referrers/bundle_layout/index.json
```

## The `subject` field

```json
{
  "artifactType": "application/vnd.dev.cosign.simplesigning.v1+json",
  "layers": [{"digest": "sha256:<the signature payload>"}],
  "subject": {"digest": "sha256:<the image being signed>"}
}
```

One field turns a free-floating artifact (sample 217) into something
**attached** to a specific image digest.

## Why not just use a tag?

The original cosign convention was a tag: `sha256-abc123.sig`. It works, but:

| Tag convention | Referrers |
|----------------|-----------|
| One artifact per kind per image | Many artifacts per image |
| Mangled digest as a tag name | Proper reference |
| Cannot list "everything about this image" | `GET /v2/<name>/referrers/<digest>` |
| Garbage collection misses it | GC follows the subject link |

The referrers API answers "what do you know about this image?" in one request -
signatures, SBOMs, attestations, vulnerability scans, all discoverable without
knowing what to look for.

## Attached, not embedded

The signature is **not** inside the image. The image digest is unchanged by
signing it - which is essential, because signing something must not alter the
thing you signed.

That is also why you can sign an image you did not build, and why several
parties can each attach their own signature to the same digest.

## Key takeaway

`subject` links an artifact to an image digest without modifying the image.
It is what makes signatures and SBOMs discoverable.
