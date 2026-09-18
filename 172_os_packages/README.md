# 172 - Operating System Packages

**Concepts:** `pkg_deb`, `pkg_rpm`, install layouts

## Run it

```bash
bazel build //172_os_packages:demo_service_deb
ls -la bazel-bin/172_os_packages/

# Inspect it (on a Debian-family machine):
dpkg-deb --info     bazel-bin/172_os_packages/demo_service_deb.deb
dpkg-deb --contents bazel-bin/172_os_packages/demo_service_deb.deb
```

## The pipeline

```
pkg_files  ->  pkg_tar  ->  pkg_deb
(layout)      (payload)    (package)
```

`pkg_files` (sample 086) decides *what goes where with which permissions*.
`pkg_tar` bundles it. `pkg_deb` adds the control metadata.

The same `pkg_files` targets feed `pkg_rpm`, `pkg_zip` or an OCI layer - define
the layout once, emit any number of formats.

## pkg_deb metadata

```python
pkg_deb(
    name = "deb",
    data = ":payload",
    package = "demo-service",
    version = "1.4.2",
    architecture = "amd64",
    maintainer = "Platform Team <platform@example.com>",
    description = "...",
    depends = ["libc6 (>= 2.31)", "ca-certificates"],
    postinst = "postinst.sh",
    prerm = "prerm.sh",
    conffiles = ["/etc/demo-service/service.conf"],
)
```

`conffiles` matters in practice: it tells dpkg the file may have been edited by
an administrator, so an upgrade must not silently overwrite it.

## RPM

```python
load("@rules_pkg//pkg:rpm.bzl", "pkg_rpm")

pkg_rpm(
    name = "rpm",
    srcs = [":binaries", ":configs"],
    spec_template = "service.spec.tpl",
    version = "1.4.2",
    release = "1",
    architecture = "x86_64",
)
```

`pkg_rpm` requires `rpmbuild` on the build machine, so it is less hermetic than
`pkg_deb` - worth knowing before you put it in a container-based CI.

## Version from the build

Hard-coding `version = "1.4.2"` means editing a BUILD file for every release.
Drive it from a build setting instead:

```python
string_flag(name = "version", build_setting_default = "0.0.0-dev")

pkg_deb(version = "$(VERSION)", toolchains = [":version_vars"], ...)
```

using `TemplateVariableInfo` (sample 144), or stamp it (sample 092).

## Always test the package

```python
sh_test(
    name = "deb_contents_test",
    srcs = ["verify_deb.sh"],
    data = [":demo_service_deb"],
)
```

A packaging rule that produces a valid but wrongly-laid-out `.deb` fails at
install time, on someone else's machine. Sample 099 makes this point; it
applies doubly to OS packages.

## Key takeaway

`pkg_files` defines the layout once; `pkg_deb`/`pkg_rpm`/`pkg_tar`/`oci_image`
consume it. Test the artifact, and drive the version from the build.
