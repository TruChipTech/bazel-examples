# 164 - Dependency Update Workflow

**Concepts:** MVS in practice, upgrade hygiene, CI gates

## Seeing where you are

```bash
bazel mod graph                       # the resolved tree
bazel mod explain protobuf            # why THIS version
bazel mod graph --from=rules_cc       # who pulls in rules_cc
bazel mod show_repo rules_python      # details of one module
```

## Updating one module

```python
# MODULE.bazel
bazel_dep(name = "rules_python", version = "1.7.0")   # was 1.6.0
```

```bash
bazel mod deps --lockfile_mode=update   # refresh MODULE.bazel.lock
bazel test //...                        # does anything break?
git add MODULE.bazel MODULE.bazel.lock
```

Both files must be committed together. A `MODULE.bazel` change without the
lockfile update is what `--lockfile_mode=error` in CI is there to catch
(sample 139).

## Minimal Version Selection changes the mental model

Given `A` needs `foo@1.0` and `B` needs `foo@1.5`, bzlmod selects **1.5** - the
lowest version satisfying everyone, *not* the newest published.

Consequences:

- Adding a dependency **cannot** silently upgrade an unrelated module.
- You will not get a new version just because it exists; someone must ask for
  it.
- The build is reproducible without a lockfile - the lockfile is a speed and
  integrity optimization, not the source of determinism.

This is the opposite of npm/Cargo "newest compatible" resolution, and it is why
Bazel dependency upgrades tend to be deliberate rather than accidental.

## Handling a version conflict

```
WARNING: For repository 'rules_cc', the root module requires rules_cc@0.2.16,
but got rules_cc@0.2.17 in the resolved dependency graph.
```

This means a dependency asked for a **newer** version than you declared. The
fix is to update your own declaration to match:

```python
bazel_dep(name = "rules_cc", version = "0.2.17")
```

Do not silence it with `--check_direct_dependencies=off`; the warning is
telling you your declared version is not what you are building against.

## Carrying a patch

```python
single_version_override(
    module_name = "rules_foo",
    version = "1.2.0",
    patches = ["//patches:fix_windows.patch"],
    patch_strip = 1,
)
```

Better than forking: the patch is visible in review, applies to a pinned
version, and disappears cleanly when upstream releases the fix.

## Automating it

Renovate understands `MODULE.bazel`. A workable policy:

- Group rule-set updates into one PR per week
- Require `bazel test //... --lockfile_mode=error` to pass
- Pin `.bazelversion` and upgrade Bazel itself separately (sample 165)

## Before upgrading, know your blast radius

```bash
bazel query "rdeps(//..., @rules_python//...)" --output=package | sort -u | head
```

## Key takeaway

MVS makes upgrades explicit. Commit `MODULE.bazel` and the lockfile together,
enforce it in CI, and patch rather than fork.
