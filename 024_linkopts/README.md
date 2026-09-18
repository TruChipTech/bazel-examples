# 024 - Link Options

**Concepts:** `linkopts`, system libraries, linkstatic

## Run it

```bash
bazel run //024_linkopts:threaded
```

## linkopts propagate (copts do not)

Put `linkopts = ["-lz"]` on a `cc_library` and every binary that transitively
depends on it links against zlib. That is correct behavior: the library needs
the symbol, but only the final binary has a link step.

## The hermeticity caveat

`-lpthread` means "find libpthread somewhere on this machine". Bazel cannot
sandbox or cache that, and the build now depends on the host having the right
library and version. For a genuinely hermetic build you would instead:

1. Bring the library in as a Bazel module or `http_archive` (sample 066), or
2. Wrap the system library in a `cc_library` whose location is resolved by a
   repository rule (sample 135).

System `linkopts` are a pragmatic compromise, fine for ubiquitous C library
pieces like `-lm` and `-lpthread`, risky for anything version-sensitive.

## Related: `linkstatic`

```python
cc_binary(name = "x", srcs = [...], linkstatic = True)
```

Links dependencies statically. On Linux `cc_binary` already defaults to mostly
static linking of its Bazel-built deps; `linkstatic` controls that explicitly.

## Key takeaway

`linkopts` bridge to the host system. Every one of them is a small hole in
your build's hermeticity - use them knowingly.
