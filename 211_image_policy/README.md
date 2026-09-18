# 211 - Image Security Policy as a Test

**Concepts:** policy gates, secret scanning, setuid and world-writable checks

## Run it

```bash
bazel test //211_image_policy:policy_test --test_output=all
```

```
PASS: image satisfies policy (entrypoint, no secrets, no world-writable, no setuid)
```

## What it checks

| Check | Why it matters |
|-------|----------------|
| Entrypoint declared | Otherwise the base image's default runs |
| No `.ssh/`, `id_rsa`, `.env`, `.aws/`, `.git/` | Credentials leak into images constantly |
| No world-writable files | Any process in the container can rewrite them |
| No setuid binaries | A classic privilege-escalation primitive |

`.git/` is worth calling out: a `COPY . .` in a Dockerfile ships your entire
history, including any secret ever committed and later "removed".

## Why this belongs in the build

Registry scanners catch some of this *after* you have published. A test catches
it before the image exists. The layer tarball is right there as a build
artifact - reading it needs no daemon, no registry and no network.

## Extending it

The same shape covers most real policies:

- Base image must be on an approved list (read the annotation)
- Image must run as non-root (read `config.User` - sample 209)
- No package manager binaries present
- Total size under budget (sample 210)

## Make it a validation action

Wrap these checks in the `_validation` output group (sample 120) and they run
on **every build of every image** automatically, in parallel, without anyone
remembering to add a test target.

## Key takeaway

An image is just a tarball and some JSON. Policy checks are file inspection,
and they belong in the build rather than in a post-publish scan.
