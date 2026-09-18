# 165 - Repository Layout and Bazel Upgrades

**Concepts:** monorepo structure, `.bazelversion`, incompatible flags

## A layout that scales

```
/
  MODULE.bazel            external dependencies, one place
  MODULE.bazel.lock       committed
  .bazelrc                shared flags and --config definitions
  .bazelversion           pins the Bazel version
  .bazelignore            directories Bazel must not scan

  bazel/                  build infrastructure
    config/BUILD          shared config_settings (linux, opt, ...)
    platforms/BUILD       platform definitions
    toolchains/BUILD      toolchain registrations
    rules/                your own rule sets
    macros/               shared macros

  src/  or  services/     application code
  tools/                  developer and CI tooling
  third_party/            vendored or wrapped external code
```

Three properties matter more than the exact names:

1. **One `//bazel/config` package** owning shared `config_setting`s. Redefining
   `:linux` in forty packages is the most common avoidable duplication.
2. **Build infrastructure separated from product code**, so `//bazel/...` can
   have different ownership and review rules.
3. **`.bazelignore` for anything Bazel should not scan** - `node_modules`,
   nested modules, generated output directories. Scanning them costs loading
   time on every build.

## Pin the Bazel version

```bash
echo "9.2.0" > .bazelversion
```

Bazelisk (and the `bazel` wrapper most distributions ship) reads this file and
downloads exactly that version. Without it, developers and CI silently run
different Bazel versions - which changes cache keys and produces
"works for me" in its purest form.

## Upgrading Bazel

Bazel's compatibility policy is built around **incompatible flags**: a breaking
change lands first as an opt-in flag, then becomes the default a release or two
later.

```bash
# Try the next version's defaults today
bazel build //... --incompatible_disallow_empty_glob

# See what is coming
bazel build //... --all_incompatible_changes
```

The upgrade procedure that works:

1. Run the current version with `--all_incompatible_changes`.
2. Fix what breaks, one flag at a time, merging each fix independently.
3. Bump `.bazelversion` once nothing fails.

Doing it this way means the upgrade PR is a one-line change, because the actual
work happened in reviewable increments beforehand.

## Migration tooling

```bash
buildifier --lint=fix -r .        # fixes many mechanical migrations
bazel mod tidy                    # fixes use_repo() calls
```

Bazel's own error messages usually name the exact `buildozer` command to run -
as sample 076 demonstrated.

## `.bazelrc` discipline

Put in `.bazelrc` anything required for **correctness** (toolchain selection,
hermeticity flags). Put convenience in `--config`s. Keep personal preferences in
a gitignored `user.bazelrc` pulled in with `try-import` (sample 033).

## Key takeaway

Pin `.bazelversion`, centralize `config_setting`s, keep build infrastructure in
its own tree, and upgrade Bazel through incompatible flags rather than in one
jump.
