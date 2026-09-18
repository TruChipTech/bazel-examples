# 060 - bool_flag, int_flag and label_flag

**Concepts:** skylib flag rules, `label_flag`, dependency injection

## Run it

```bash
F=//060_bool_and_label_flags

bazel build $F:runtime_config
cat bazel-bin/060_bool_and_label_flags/runtime.conf

bazel build $F:runtime_config --//060_bool_and_label_flags:enable_telemetry=true
cat bazel-bin/060_bool_and_label_flags/runtime.conf

# label_flag: swap an entire dependency from the command line
bazel build $F:chosen_impl
cat bazel-bin/060_bool_and_label_flags/chosen.txt   # safe

bazel build $F:chosen_impl --//060_bool_and_label_flags:impl=$F:fast_impl
cat bazel-bin/060_bool_and_label_flags/chosen.txt   # fast
```

## Ready-made flags from skylib

```python
load("@bazel_skylib//rules:common_settings.bzl",
     "bool_flag", "int_flag", "string_flag", "string_list_flag")

bool_flag(name = "debug", build_setting_default = False)
string_flag(name = "env", build_setting_default = "dev", values = ["dev", "prod"])
```

Write your own only when you need custom validation.

## `label_flag` is the interesting one

Its value is a **target**, which makes it dependency injection at the build
level. Real uses:

- Swap a real backend for a fake in an integration test
- Point at a different toolchain or SDK
- Let a downstream repo override a default implementation without forking

```python
label_flag(name = "clock", build_setting_default = "//time:system_clock")

cc_binary(name = "server", deps = [":clock"])
```

CI can then run the whole suite against a deterministic clock with one flag.

## `bool_flag` values on the command line

```bash
--//pkg:flag=true      # explicit
--//pkg:flag           # shorthand for =true
--no//pkg:flag         # shorthand for =false
```

## Key takeaway

`bool_flag` and `string_flag` cover configuration. `label_flag` covers
substitution, and it is far more powerful than it first appears.
