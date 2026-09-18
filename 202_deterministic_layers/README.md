# 202 - Deterministic Layers

**Concepts:** reproducible tarballs, mtime, ordering, ownership

A layer's digest is the hash of its tarball bytes. Anything that varies between
builds - timestamps, file order, uid/gid - changes the digest, and a changed
digest means a changed image even though nothing real changed.

## Run it

```bash
bazel build //202_deterministic_layers:layer_digest
cat bazel-bin/202_deterministic_layers/layer.sha256

bazel clean && bazel build //202_deterministic_layers:layer_digest
cat bazel-bin/202_deterministic_layers/layer.sha256    # identical
```

## The four sources of nondeterminism

| Source | Fix |
|--------|-----|
| File mtimes | Pin to a fixed epoch |
| Entry order | Sort by name |
| uid/gid/uname | Zero them, `--numeric-owner` |
| Directory entries | Include or exclude consistently |

`pkg_tar` handles all four. A hand-written `tar cf` handles none:

```bash
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner -cf layer.tar .
```

That is the incantation `pkg_tar` saves you from remembering.

## Why it matters more for images than for tarballs

A nondeterministic layer means:

- **Every build pushes a new layer**, even when nothing changed - wasted
  bandwidth and registry storage
- **Cache hit rates collapse** for anything downstream of the image
- **"Did this change?" becomes unanswerable** by comparing digests
- **Signatures are meaningless** for change detection, because every rebuild
  produces a different digest to sign

## Key takeaway

Use `pkg_tar`, not `tar`. A layer digest should change when and only when the
content changes.
