# 220 - Diffing Two Images

**Concepts:** layer-level diff, file-level diff, "what actually changed?"

## Run it

```bash
bazel build //220_image_diff:diff_report
cat bazel-bin/220_image_diff/diff.txt
```

```
layers: A=2 B=2 shared=1
  only in A: sha256:...
  only in B: sha256:...

files:
  removed: app/v1.txt
  added:   app/v2.txt
```

The shared base layer is identified as shared - that is content addressing
doing the work (sample 214).

## The question this answers

Before promoting a release, "what is different about this image?" should have a
precise answer. A digest tells you *that* something changed; a diff tells you
*what*.

Real uses:

- **Review gate.** An unexpected file in the diff blocks the promotion.
- **Debugging.** "It worked in v1" - now you can see exactly what moved.
- **Size regressions.** Which layer grew, and by how much (sample 210).
- **Reproducibility.** Two builds of the same commit should diff to nothing.

That last one is the sharpest: if `IDENTICAL` does not appear when it should,
you have a determinism bug (sample 202).

## Layer diff vs file diff

Both matter and they answer different questions:

| Level | Tells you |
|-------|-----------|
| Layer digests | What must be re-pushed and re-pulled |
| File contents | What actually changed in the filesystem |

A layer can change entirely because one byte moved in one file - the layer
diff shows expensive churn, the file diff shows the real cause.

## Key takeaway

Digests detect change; a diff explains it. Both belong in a promotion gate.
