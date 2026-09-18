# 146 - Parameter Files

**Concepts:** `use_param_file`, ARG_MAX, long command lines

## Run it

```bash
P=//146_param_files

bazel build $P:small $P:small_forced $P:huge
cat bazel-bin/146_param_files/huge.txt

# See the actual command line Bazel used:
bazel aquery $P:huge --output=text | head -30
```

`huge` passes 20,000 arguments. On Linux the limit is around 2 MB of command
line; on Windows it is about 32,000 **characters**.

## The problem

```
/bin/sh: Argument list too long
```

A link step in a large C++ project can easily reference tens of thousands of
object files. Without param files, the build simply cannot run.

## The mechanism

```python
args.use_param_file("@%s", use_always = False)
args.set_param_file_format("multiline")
```

Bazel writes the arguments to a file and passes `@/path/to/file` instead. The
tool must understand that convention and expand it:

```python
def expand(argv):
    out = []
    for arg in argv:
        if arg.startswith("@"):
            with open(arg[1:]) as f:
                out.extend(line.rstrip("\n") for line in f if line.strip())
        else:
            out.append(arg)
    return out
```

Most real toolchains already do: `gcc`, `ld`, `javac`, `protoc`, `rustc`, MSVC.

## The formats

| Format | Contents |
|--------|----------|
| `"shell"` | Shell-quoted, may be on one line |
| `"multiline"` | One argument per line, no quoting |

Prefer `multiline` for your own tools - parsing is trivial and there are no
quoting rules to get wrong. Use `shell` only if the tool expects it.

## `use_always`

```python
args.use_param_file("@%s", use_always = True)
```

Without it, Bazel decides based on length - so the same rule behaves
differently for small and large inputs, and a param-file bug only appears in
production. Setting `use_always = True` makes behavior uniform and is worth it
while developing the tool.

## This is why `Args` matters

Param files only work with `ctx.actions.args()`. A plain Python list of strings
cannot spill, so a rule that builds command lines by hand will fail on large
inputs with no warning until it does.

## Key takeaway

Any rule whose argument count scales with the number of inputs needs
`use_param_file`. Make your tools accept `@file`, and prefer the `multiline`
format.

## Aside: Starlark's `%` formatting is limited

```python
"%06d" % i     # ERROR: unsupported format character "0"
"%d" % i       # fine
```

Starlark supports only `%s`, `%d`, `%r` and `%%` - no width, padding or
precision specifiers. Use `str().rjust()` or build the string manually when you
need alignment.
