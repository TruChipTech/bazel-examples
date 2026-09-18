# 136 - Repository Rules That Execute and Download

**Concepts:** `execute`, `download`, `which`, generated BUILD files

## Run it

```bash
bazel run //136_repository_rule_execute:use_generated
```

Three Python modules that exist nowhere in this repository - the repository
rule generated them, along with the `BUILD.bazel` that declares them.

## `repository_ctx.execute`

```python
result = repository_ctx.execute(["python3", "-c", "..."])
if result.return_code != 0:
    fail("...: %s" % result.stderr)
value = result.stdout.strip()
```

Returns a struct with `return_code`, `stdout`, `stderr`. **Always check the
return code** - a silent failure here produces a subtly broken repository that
is then cached.

Useful options:

```python
repository_ctx.execute(cmd, timeout = 600, environment = {"LC_ALL": "C"}, quiet = False)
```

## Finding tools

```python
python = repository_ctx.which("python3")
if python == None:
    fail("python3 not found on PATH")
```

`which` returns `None` rather than failing, so you can produce a good error
message or fall back.

## Downloading

```python
repository_ctx.download(
    url = ["https://example.com/tool.bin", "https://mirror/tool.bin"],
    output = "bin/tool",
    sha256 = "abc123...",
    executable = True,
)

repository_ctx.download_and_extract(
    url = "https://example.com/lib-1.0.tar.gz",
    sha256 = "...",
    stripPrefix = "lib-1.0",
)
```

Always pin `sha256`. Always give a list of URLs so a mirror can take over.

## Generating the BUILD file

```python
repository_ctx.file("BUILD.bazel", content = '''
py_library(name = "generated", srcs = [...], visibility = ["//visibility:public"])
''')
```

For anything longer than a few lines, use a template instead:

```python
repository_ctx.template(
    "BUILD.bazel",
    repository_ctx.attr._build_tpl,
    substitutions = {"%{SRCS}": srcs_literal},
)
```

A real, checked-in template file is reviewable and syntax-highlighted; a
string literal in Starlark is neither.

## Remember `visibility`

Targets in a generated repository need `//visibility:public`, or nothing can
depend on them. This is the most common bug in a hand-written repository rule.

## Key takeaway

`execute` + `file` is how you turn anything - a system tool, a package
manager, a code generator - into a Bazel repository. Check return codes, pin
checksums, and make targets public.
