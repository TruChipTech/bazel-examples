# 059 - Custom Build Settings (string_flag)

**Concepts:** `build_setting`, `BuildSettingInfo`, `flag_values`

## Run it

```bash
F=//059_string_flag

bazel build $F:backend_config
cat bazel-bin/059_string_flag/backend.conf     # driver=memory

bazel build $F:backend_config --//059_string_flag:backend=postgres
cat bazel-bin/059_string_flag/backend.conf     # driver=postgres

bazel build $F:backend_config --//059_string_flag:backend=redis
cat bazel-bin/059_string_flag/backend.conf     # driver=redis
```

## Why not just use `--define`?

`--define` is the old mechanism and has real problems: it is a single global
namespace with no types, no validation, no default, and no documentation. Two
unrelated teams using `--define=mode=x` collide silently.

Custom build settings are **targets**, so they get:

- A label, so the name cannot collide
- A declared type (`config.string`, `config.bool`, `config.int`, `config.string_list`)
- A default value
- Visibility control
- Documentation via a docstring

## The flag name is the label

```bash
--//059_string_flag:backend=postgres
  ^^                          ^
  two slashes, full package   target name
```

Shorten it in `.bazelrc`:

```
build:postgres --//059_string_flag:backend=postgres
```

Then `bazel build --config=postgres //...`.

## Restricting the allowed values

```python
backend_flag = rule(
    implementation = _backend_impl,
    build_setting = config.string(flag = True, values = ["memory", "postgres", "redis"]),
)
```

Now a typo is rejected at flag-parse time instead of falling through to the
default branch.

## Key takeaway

Custom build settings are the modern replacement for `--define`. Use them for
anything a user is meant to toggle.
