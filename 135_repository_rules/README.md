# 135 - Repository Rules

**Concepts:** `repository_rule`, `repository_ctx`, loading phase

## Run it

```bash
bazel build //135_repository_rules:show_host
cat bazel-bin/135_repository_rules/host.txt

# Inspect the generated repository:
bazel query '@host_info//...'
```

## What makes repository rules different

| | Normal rule | Repository rule |
|---|-------------|-----------------|
| Phase | Analysis | **Loading** |
| Produces | Actions | **A repository** (files on disk) |
| Can read the environment | No | **Yes** |
| Can run programs | No (only declare actions) | **Yes**, immediately |
| Can download | No | **Yes** |
| Sandboxed | Yes | **No** |

They run before any BUILD file is evaluated, which is why they can create the
BUILD files that will then be evaluated.

## The `repository_ctx` API

```python
repository_ctx.file(path, content)        # write a file
repository_ctx.template(path, tpl, subs)  # write from a template
repository_ctx.symlink(from, to)          # symlink
repository_ctx.download(url, sha256=...)  # fetch a file
repository_ctx.download_and_extract(...)  # fetch + unpack
repository_ctx.execute([cmd, args])       # run a program
repository_ctx.which("python3")           # find a binary on PATH
repository_ctx.getenv("VAR", "default")   # read an env var (tracked!)
repository_ctx.os.name / .arch            # host info
repository_ctx.path(label_or_string)      # resolve a path
repository_ctx.read(path)                 # read a file
```

## Hermeticity: the thing to get right

A repository rule is **not sandboxed** and its result is **cached**. So an
undeclared dependency on the environment produces a repository that is correct
on the machine that created it and wrong everywhere else - and Bazel will not
notice.

Two mechanisms make the dependency explicit:

```python
repository_rule(
    implementation = _impl,
    environ = ["HOME", "CC"],   # changes to these refetch the repository
    local = True,               # always re-run; do not cache across builds
)
```

Use `repository_ctx.getenv()` rather than reading the environment another way -
it registers the dependency automatically.

`local = True` is right for rules that *probe the machine* (finding a system
compiler, detecting the OS). It is wrong for rules that fetch immutable
content, where caching is the entire point.

## When you need one

- Wrapping a pre-installed system toolchain
- Generating BUILD files for a downloaded archive
- Detecting host capabilities
- Fetching dependencies from a non-standard source

Under bzlmod, repository rules can only be called from a module extension or
via `use_repo_rule` (sample 066).

## Key takeaway

Repository rules run early, unsandboxed, and cached. Declare every environment
dependency with `environ` and `getenv`, or you have built a non-reproducible
build.
