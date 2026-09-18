# 048 - Code Generation With a Tool

**Concepts:** `tools`, generated sources, tool dependency tracking

## Run it

```bash
bazel run //048_tools_in_genrule:use_generated
cat bazel-bin/048_tools_in_genrule/generated_constants.h
```

## The full dependency chain

```
names.txt ─┐
           ├─> gen_constants ─> generated_constants.h ─> use_generated
codegen.py ┘
```

Edit `names.txt` **or** `codegen.py` and the header regenerates and the binary
relinks. Edit neither and nothing runs. The generator being a real target is
what makes the second half of that true - Bazel knows the tool is an input.

## `tools` vs `srcs`, again

```python
tools = [":codegen"],   # executed BY the action, built for the exec platform
srcs  = ["names.txt"],  # read by the action, built for the target platform
```

If you put `:codegen` in `srcs` it still appears to work on a normal build -
and then breaks the moment someone cross-compiles, because the generator gets
built for the target architecture and cannot run on the build machine.

## Generated files are normal files

`":generated_constants.h"` in `srcs` of the `cc_binary` is an ordinary label
reference. Nothing about consuming a generated file differs from consuming a
checked-in one - which is why generated code does not need to be committed.

## Key takeaway

Make your generators Bazel targets. Then "the generator changed" is a real
graph edge instead of a stale artifact nobody notices.
