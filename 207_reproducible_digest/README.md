# 207 - Pinning the Image Digest

**Concepts:** reproducibility as a test, golden digests

## Run it

```bash
bazel test //207_reproducible_digest:digest_test --test_output=all
```

## Why pin it

An image digest should change when, and only when, the image content changes.
Pinning it in a checked-in file turns that from a hope into a test:

```
expected: sha256:a1b2c3...
actual:   sha256:a1b2c3...
PASS: image digest is stable
```

Break it deliberately - edit `content.txt` - and the test fails with the new
digest, ready to paste in. That is the same blessing workflow as a golden file
(sample 087), applied to a hash.

## What it catches

| Regression | How it shows up |
|------------|-----------------|
| A timestamp crept into a layer | Digest changes every build |
| Sort order became unstable | Digest flaps between two values |
| uid/gid leaked from the build machine | Digest differs per developer |
| A dependency silently updated | Digest changes with no local edit |

The last one is the valuable one: it makes an invisible upstream change
visible as a failing test rather than a surprise in production.

## Pair it with a review rule

Because updating the expected digest is a code change, a digest change becomes
something a human approves in review. "Why did the image change?" gets asked
before release rather than after.

## Key takeaway

A pinned digest is the cheapest possible reproducibility regression test.
