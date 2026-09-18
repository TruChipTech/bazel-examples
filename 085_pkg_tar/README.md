# 085 - Packaging With pkg_tar

**Concepts:** `pkg_tar`, `package_dir`, `strip_prefix`, `deps`

## Run it

```bash
bazel build //085_pkg_tar:release_tar
tar tzf bazel-bin/085_pkg_tar/release_tar.tar.gz | head -30
```

## The three useful patterns

**1. Files into a directory**

```python
pkg_tar(
    name = "config_tar",
    srcs = glob(["config/*.yaml"]),
    strip_prefix = "config",      # remove this from the source paths
    package_dir = "/etc/demo",    # put everything here in the archive
)
```

**2. A binary with its runfiles**

```python
pkg_tar(
    name = "service_tar",
    srcs = [":service"],
    include_runfiles = True,      # the crucial attribute
    package_dir = "/opt/demo",
)
```

Without `include_runfiles`, you package the launcher and none of the files it
needs. The result installs cleanly and fails at startup.

### ...but know what "everything it needs" means

`include_runfiles` bundles the binary's **entire runtime closure**, and for an
interpreted language that includes the interpreter. Packaging a `py_binary`
this way with `rules_python`'s hermetic toolchain produces:

```
service_tar.tar   248 MB   2504 entries
                           2485 of them are CPython 3.11
                           19 are the actual application
```

Three 55 MB copies of the `python3` binary plus a 55 MB `libpython3.11.so`, to
ship one 200-byte script.

That is not a bug - it is what hermetic really costs, and it is why this sample
packages a `cc_binary` instead (32 KB). When you do need to ship Python:

- Build the image in layers so the interpreter layer is cached and pushed once
  (sample 171)
- Or use a base image that already contains a matching interpreter and package
  only your sources
- Or check whether you needed a self-contained artifact at all

**3. Composition**

```python
pkg_tar(name = "release_tar", deps = [":config_tar", ":service_tar"])
```

`deps` merges other tarballs, letting each component own its own packaging
rules and layout.

## Other rules_pkg outputs

| Rule | Produces |
|------|----------|
| `pkg_tar` | `.tar`, `.tar.gz`, `.tar.bz2`, `.tar.xz` |
| `pkg_zip` | `.zip` |
| `pkg_deb` | Debian package |
| `pkg_rpm` | RPM package |

All of them consume `pkg_files` / `pkg_filegroup` for fine-grained control over
permissions, ownership and renaming - see sample 086.

## Why package in Bazel at all?

Because the packaging step then shares the build graph: the tarball is rebuilt
exactly when its contents change, it is cacheable and remotely executable, and
"what is in the release" is answerable with `bazel query` rather than by
reading a shell script.

## Key takeaway

`pkg_tar` turns build outputs into a distributable artifact. Remember
`include_runfiles = True` for anything executable.
