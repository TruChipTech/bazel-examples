# 183 - Target Impact Analysis

**Concepts:** affected targets, `bazel-diff`, selective CI

## The question

> Which targets can this commit possibly have changed?

On a repo where `bazel test //...` takes an hour, answering it turns a
one-hour presubmit into a two-minute one.

## The naive approach, and why it is wrong

```bash
# Targets owning the changed files
git diff --name-only main... | xargs -n1 bazel query --output=package

# Everything depending on them
bazel query "rdeps(//..., set($CHANGED_TARGETS))"
```

This works for source changes and **misses everything else**: a changed
`.bazelrc` flag, a dependency version bump in `MODULE.bazel`, a modified macro,
a new Bazel version, a changed toolchain. All of those alter what gets built
without touching a single source file that `git diff` reports.

## The correct approach: hash the action graph

[`bazel-diff`](https://github.com/Tinder/bazel-diff) computes a content hash
for every target from its **full transitive input closure** - sources, flags,
toolchains, external dependencies - and diffs two revisions.

```bash
# At the base revision
git checkout main
bazel-diff generate-hashes -w $(pwd) -b $(which bazel) /tmp/base.json

# At the head revision
git checkout feature-branch
bazel-diff generate-hashes -w $(pwd) -b $(which bazel) /tmp/head.json

# What actually changed
bazel-diff get-impacted-targets -sh /tmp/base.json -fh /tmp/head.json -o /tmp/impacted.txt

bazel test $(cat /tmp/impacted.txt | tr '\n' ' ')
```

Because the hash covers everything Bazel considers an input, a `.bazelrc`
change correctly marks every target as impacted.

## Do you need it?

Often not. With a good remote cache, `bazel test //...` is already
near-instant for unchanged targets - Bazel is doing impact analysis internally,
via the action cache.

Impact analysis pays off when:

| Situation | Why |
|-----------|-----|
| Analysis alone takes minutes | You skip analysis of untouched parts |
| No remote cache available | Nothing else prunes the work |
| Per-test CI cost is high | Provisioning devices, emulators, licenses |
| You need to *report* what changed | Release notes, approval routing |

**Measure first.** Teams frequently build elaborate impact analysis to solve a
problem a remote cache would have solved for free.

## Doing it with plain Bazel

```bash
# A reasonable approximation for source-only changes
CHANGED=$(git diff --name-only origin/main...HEAD)
TARGETS=$(echo "$CHANGED" | sed 's|/[^/]*$||' | sort -u | sed 's|^|//|;s|$|:all|')
bazel query "rdeps(//..., set($TARGETS))" --output=label > impacted.txt
```

Always pair this with a full `bazel test //...` on postsubmit, so anything the
approximation missed is still caught before release.

## Key takeaway

Impact analysis must hash the whole input closure, not diff source files. Try a
remote cache first - it may make the problem disappear.
