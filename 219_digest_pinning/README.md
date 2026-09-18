# 219 - Pinning by Digest, Not Tag

**Concepts:** mutable tags, immutability policy, supply-chain risk

## Run it

```bash
bazel test //219_digest_pinning:pin_policy_test --test_output=all

# The deliberately-failing one:
bazel test //219_digest_pinning:pin_policy_violation_test --test_output=all
```

```
FAIL: ...bad_image_layout: floating tag 'demo:latest' - pin by digest or an immutable tag
```

## Tags move, digests do not

```
demo:latest        -> whatever was pushed most recently
demo@sha256:abc... -> exactly these bytes, forever
```

A tag is an annotation pointing at a digest (sample 201). Anyone with push
access can repoint it - including an attacker who compromises the registry, and
including your own CI on a bad day.

## Why this is a supply-chain control

Build from `base:latest` and your build is not reproducible and not auditable:

- The same commit produces different images on different days
- A compromised upstream tag silently enters your image
- "Which base did this ship with?" is unanswerable after the fact
- Signature verification of the base becomes meaningless

Pinning by digest makes an upstream change a **visible commit** in your repo
rather than an invisible event.

## The objection, and the answer

"But then we never get security updates." Correct - you get them when you
*choose* to, via a bot that opens a PR bumping the digest (sample 164). That PR
runs your tests and is reviewed. That is the point.

## What to enforce

| Rule | Why |
|------|-----|
| No `:latest`, `:main`, `:stable` | Floating by definition |
| Base images pinned `@sha256:` | The big one |
| Release tags immutable in the registry | Belt and braces |

## Key takeaway

Tags are for humans, digests are for machines. Enforce it as a test.
