# 108 - declare_directory and Tree Artifacts

**Concepts:** tree artifacts, unpredictable outputs

## Run it

```bash
bazel build //108_declare_directory:docs
find bazel-bin/108_declare_directory/docs_site -type f

bazel build //108_declare_directory:site_listing
cat bazel-bin/108_declare_directory/listing.txt
```

## The problem it solves

Bazel normally requires every output to be **declared during analysis**, before
anything runs. That is impossible when the tool decides how many files to
produce:

- A documentation generator emitting one page per source file
- A compiler producing one object per discovered translation unit
- `npm install` populating `node_modules`
- An archive extractor

`declare_directory` declares the *directory* as the output. Bazel tracks its
entire contents as one artifact.

## The tradeoffs

| | Regular files | Tree artifact |
|---|---------------|---------------|
| Outputs known at analysis | Required | Not required |
| Per-file caching | Yes | No - the whole tree is one unit |
| Downstream granularity | Per file | Whole directory |
| Remote execution | Efficient | Whole tree transferred |

Because the tree is one artifact, changing one generated page invalidates every
consumer of the directory. Prefer explicit outputs when you *can* enumerate
them; reach for a tree artifact when you genuinely cannot.

## Consuming a tree artifact

An action receiving a tree artifact gets the directory path. In Starlark you
can also expand it per-file with `Args.add_all(directory, expand_directories =
True)`, or map over entries using `ctx.actions.declare_directory` plus
`args.add_all(..., map_each = ...)`.

## Gotcha: the directory must be created

The tool **must** create the declared directory, even if empty. Bazel fails the
action otherwise. In this sample `os.makedirs(outdir, exist_ok=True)` does it.

## Key takeaway

Tree artifacts trade caching granularity for the ability to model tools whose
output set is dynamic. Use them deliberately, not by default.

## Gotcha: use `$(locations)` for a tree artifact in a genrule

```python
cmd = "ls -1 $(locations :docs) > $@"     # works
cmd = "find $(location :docs) -type f"    # produced nothing here
```

The plural `$(locations)` expands a tree artifact to its directory path in the
form downstream commands expect. If a genrule consuming a tree artifact
mysteriously produces an empty result, this is the first thing to check.
