# 138 - Designing Tag Classes

**Concepts:** `tag_class`, extension API design

Sample 137 has a working extension; this one is about the **shape** of the API
you expose through it.

## A tag class is your extension's public API

```python
_install = tag_class(
    attrs = {
        "name": attr.string(mandatory = True, doc = "Repository name to create."),
        "requirements": attr.label(allow_single_file = True, doc = "requirements.txt"),
        "python_version": attr.string(default = "3.11", values = ["3.10", "3.11", "3.12"]),
    },
    doc = "Installs a set of pip packages.",
)

pip = module_extension(
    implementation = _pip_impl,
    tag_classes = {"install": _install, "override": _override, "whl_mods": _whl_mods},
)
```

Callers then write:

```python
pip = use_extension("@rules_python//python/extensions:pip.bzl", "pip")
pip.install(name = "my_deps", requirements = "//:requirements.txt")
use_repo(pip, "my_deps")
```

## Several tag classes, one extension

Real extensions expose a small vocabulary rather than one do-everything tag:

| Tag class | Purpose |
|-----------|---------|
| `install` | The main declaration |
| `override` | Change one entry's version or source |
| `config` | Global settings |

This matters because tags from **different modules** are all visible. A
dependency can `install`, while only the root module is permitted to
`override` - a policy your implementation enforces with `module.is_root`.

## Design guidelines

**Make every attribute typed and documented.** The `doc` strings are the only
documentation users will find.

**Use `values` for enumerations.** A typo should fail at `MODULE.bazel`
evaluation, not produce a mysterious repository.

**Accept labels, not strings, for files.**
`attr.label(allow_single_file = True)` resolves correctly relative to the
declaring module. A string path does not.

**Name the repositories you create predictably.** Users must write
`use_repo(ext, "name")`, so the name has to be derivable from what they wrote.

**Fail loudly on conflicts, and name both parties.**

```python
fail("pip.install: name '%s' requested by both %s and %s" % (name, a, b))
```

## Repository naming and `use_repo`

```python
use_repo(pip, "my_deps")                      # same name
use_repo(pip, local_alias = "my_deps")        # renamed locally
```

If an extension creates repositories whose names the caller cannot predict,
the extension is unusable. Derive them from the tag's `name` attribute.

## Let `bazel mod tidy` help

Return `root_module_direct_deps` from `extension_metadata` (sample 137) and
`bazel mod tidy` will insert the correct `use_repo` lines automatically. This
turns the most common user error into a one-command fix.

## Key takeaway

Tag classes are an API. Type them, document them, validate them, and make
repository names predictable.
