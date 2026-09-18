# 198 - Wrapping Existing Rules

**Concepts:** same-name wrappers, project-wide policy

## Run it

```bash
W=//198_wrapping_rules

bazel test $W:widget_test
bazel query --output=build $W:widget_test | head -20
```

The `--output=build` shows `-Wall -Wextra`, `size = "small"` and
`tags = ["unit"]` - none of which appear in the BUILD file.

## The same-name trick

```python
# defs.bzl
load("@rules_cc//cc:defs.bzl", _cc_library = "cc_library")

def cc_library(name, copts = [], **kwargs):
    _cc_library(name = name, copts = STANDARD_COPTS + copts, **kwargs)
```

```python
# BUILD.bazel - only the load path changed
load("//bazel:defs.bzl", "cc_library")

cc_library(name = "widget", srcs = [...], hdrs = [...])
```

Adopting it across a repo is a mechanical change to `load()` statements, which
buildozer can do:

```bash
buildozer 'fix movePackageToTop' //...:__pkg__
```

Every existing target keeps working.

## What wrappers are good for

| Policy | How |
|--------|-----|
| Standard warning flags | Prepend to `copts` |
| Default test size | `size = "small"` default |
| Mandatory tags for ownership | Append to `tags` |
| A mandatory dependency (logging, allocator) | Append to `deps` |
| Banning an attribute | `fail()` if it is set |
| Enforcing naming conventions | Validate `name` |

```python
def cc_library(name, **kwargs):
    if "linkopts" in kwargs:
        fail("%s: linkopts are banned; add a dependency instead" % name)
    ...
```

## The rules of a good wrapper

**1. Always accept and forward `**kwargs`.** Otherwise every attribute you
forgot becomes a bug report.

**2. Add, do not replace.**
```python
copts = STANDARD_COPTS + copts     # good
copts = STANDARD_COPTS             # silently discards the caller's flags
```

**3. Keep it thin.** A wrapper that adds conditional logic based on the target
name is a wrapper nobody can predict.

**4. Document what it adds.** Users will be confused by flags they did not
write.

## The downsides

- **Discoverability.** `-Wall` appears nowhere in the BUILD file. Anyone
  debugging a warning has to find the wrapper.
- **Divergence from upstream.** New attributes in the real rule are not
  automatically available if you enumerate attributes instead of using
  `**kwargs`.
- **Tooling confusion.** Some IDE integrations resolve the native rule and not
  your wrapper.

## The alternative: `.bazelrc`

```
build --copt=-Wall --copt=-Wextra
```

Simpler and more discoverable for **global** flags. Use a wrapper when the
policy is per-rule-kind (only tests get these tags) or needs validation
(`fail()` on a banned attribute).

## Key takeaway

Same-name wrappers apply repo-wide policy with a one-line change per BUILD
file. Always forward `**kwargs`, always add rather than replace, and prefer
`.bazelrc` for genuinely global flags.
