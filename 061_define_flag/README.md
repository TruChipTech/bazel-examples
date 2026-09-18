# 061 - The --define Flag

**Concepts:** `--define`, `define_values`, why it is legacy

## Run it

```bash
E=//061_define_flag

bazel build $E:env_config
cat bazel-bin/061_define_flag/env.conf          # localhost

bazel build $E:env_config --define=env=prod
cat bazel-bin/061_define_flag/env.conf          # api.example.com

# The raw Make-variable form needs the value or it fails to expand:
bazel build $E:raw_define --define=VERSION=1.2.3
cat bazel-bin/061_define_flag/raw.txt
```

## Why `--define` is discouraged

| Problem | Consequence |
|---------|-------------|
| One flat global namespace | Two teams using `--define=mode=` collide |
| No declared values | A typo silently falls through to the default |
| No defaults | `$(VERSION)` fails to expand if not passed |
| No visibility or ownership | Nobody can tell who owns a define |
| Invalidates broadly | Changing any define can re-analyze large parts of the graph |

Custom build settings (sample 059) fix every one of these.

## When you will still use it

- Reading or maintaining an existing repo
- Interacting with rules that document a `--define` interface
- Quick local experiments where declaring a flag target is overkill

## Migration path

```python
# Before
config_setting(name = "prod", define_values = {"env": "prod"})

# After
string_flag(name = "env", build_setting_default = "dev", values = ["dev", "staging", "prod"])
config_setting(name = "prod", flag_values = {":env": "prod"})
```

Consumers change from `--define=env=prod` to `--//pkg:env=prod`.

## Key takeaway

Recognize `--define` when you read it; reach for `string_flag` when you write
it.

## Note on the `manual` tag

`:raw_define` reads `$(VERSION)` directly and has no default, so it fails
unless you pass `--define=VERSION=...`. It is tagged `manual` so
`bazel build //...` skips it.

That workaround is the point: a raw `$(VAR)` read makes a target that cannot
participate in a normal repo-wide build. A `string_flag` with a
`build_setting_default` has no such problem.
