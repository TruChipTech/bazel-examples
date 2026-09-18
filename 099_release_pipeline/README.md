# 099 - A Complete Release Pipeline

**Concepts:** build → metadata → layout → package → verify

## Run it

```bash
R=//099_release_pipeline

bazel build $R:release
tar tzvf bazel-bin/099_release_pipeline/release.tar.gz
bazel test  $R:release_test --test_output=all
```

## The five stages

```
py_binary(:app)                 1. build
expand_template(:version_file)  2. generate metadata
pkg_files(x3)                   3. lay out the install tree with permissions
pkg_tar(:release)               4. package
sh_test(:release_test)          5. verify the artifact
```

Every stage is a target. That means the whole pipeline is:

- **Incremental** - changing the config re-packages but does not rebuild the app
- **Cacheable and remote-executable** - like any other build
- **Queryable** - `bazel query "deps(:release)"` lists exactly what ships
- **Testable** - stage 5 is an ordinary test

## Stage 5 is the one people skip

A packaging rule that produces a tarball is not evidence that the tarball is
correct. `release_test` extracts it and asserts the files are present, in the
right place, with the right content. Without it, a `strip_prefix` typo produces
a perfectly valid archive with everything in the wrong directory, and you find
out during deployment.

## Combining with stamping

Add sample 092's stamped manifest and the release records its own commit:

```python
pkg_files(
    name = "metadata_files",
    srcs = [":VERSION", "//092_stamped_release:manifest"],
    prefix = "/opt/demo-app",
)
```

Then `bazel build --config=release //...:release`.

## The CI shape

```bash
bazel test  //... --test_tag_filters=-release     # fast: unit + integration
bazel build --config=release //...:release        # build the artifact
bazel test  //...:release_test                    # verify it
```

## Key takeaway

Put packaging *in* the build graph. A release becomes a reproducible,
incremental, verifiable target rather than a shell script nobody trusts.
