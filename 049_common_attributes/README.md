# 049 - The Common Attributes

**Concepts:** attributes shared by all rules

Every rule - `cc_library`, `py_binary`, `java_test`, your own custom rules -
accepts this set. Learning them once covers most of what you read in BUILD
files.

## The universal attributes

| Attribute | Type | Purpose |
|-----------|------|---------|
| `name` | string | Required. Unique in the package. |
| `deps` | label_list | Build-time dependencies |
| `srcs` | label_list | Source files consumed by this target |
| `data` | label_list | Runtime files (runfiles) |
| `visibility` | label_list | Who may depend on this (sample 015) |
| `tags` | string_list | Metadata + special behavior (sample 027) |
| `testonly` | bool | Restrict to test code (sample 041) |
| `toolchains` | label_list | Extra Make variables in scope (sample 038) |
| `compatible_with` / `target_compatible_with` | label_list | Platform constraints (sample 128) |
| `exec_compatible_with` | label_list | Execution-platform constraints (sample 127) |
| `features` | string_list | Toolchain feature toggles |
| `licenses` | string_list | License declaration |
| `deprecation` | string | Warning text shown to anyone depending on this |
| `restricted_to` | label_list | Legacy constraint mechanism |

## Test-only attributes

| Attribute | Purpose |
|-----------|---------|
| `size` | small / medium / large / enormous (sample 026) |
| `timeout` | short / moderate / long / eternal |
| `flaky` | Retry up to 3 times before failing (sample 078) |
| `shard_count` | Split across N parallel runners (sample 077) |
| `local` | Never sandbox or remote |
| `env` / `env_inherit` | Environment control (sample 029) |
| `args` | Arguments passed to the test binary |

## `deprecation` is underused

```python
py_library(
    name = "old_client",
    deprecation = "Use //net:client_v2 instead; removed after 2026-12-01.",
)
```

Anyone who depends on it sees the message on every build. It is the cheapest
possible migration nudge.

## Key takeaway

The common attributes are consistent across languages. `deps` means the same
thing in `cc_library` and `java_library`, which is why moving between languages
in a Bazel repo is easy.
