# 067 - Renaming External Repositories

**Concepts:** `repo_name`, repository name mapping

## Run it

```bash
bazel build //067_repo_renaming:license_files
head -3 bazel-bin/067_repo_renaming/licensing_license.txt
```

## The declaration

```python
bazel_dep(name = "rules_license", version = "1.0.0", repo_name = "licensing")
```

The module's real name is `rules_license`. Inside *this* repository it is
addressed as `@licensing`.

## Why you would do this

1. **Migration.** Old code says `@com_google_foo`; the module is now `foo`.
   `repo_name = "com_google_foo"` keeps thousands of labels working while you
   migrate them gradually.
2. **Shorter names.** `@rules_foo_bar_baz` becomes `@fbb`.
3. **Collision avoidance.** Two modules that each want to be `@ssl`.

## Repository name mapping is per-module

This is the deep improvement over WORKSPACE. Each module has its **own**
mapping from apparent names (`@licensing`) to canonical names
(`@@rules_license+`). Your renaming does not affect your dependencies, and
theirs does not affect you.

Under WORKSPACE the namespace was global, so two libraries wanting different
versions of the same repo name was unsolvable.

## Seeing the canonical names

```bash
bazel mod dump_repo_mapping ""     # the root module's mapping
```

Canonical names contain `+` and are what you see in error messages:

```
@@rules_license+//:LICENSE
```

You should never type a canonical name in a BUILD file - always use the
apparent name.

## Key takeaway

`repo_name` decouples "what the module calls itself" from "what I call it".
The mapping is local to your module, which is what makes bzlmod compose.
