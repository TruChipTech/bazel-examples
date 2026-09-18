# 026 - Test Size and Timeout

**Concepts:** `size`, `timeout`, scheduling

## Run it

```bash
bazel test //026_test_size_timeout/...
```

## The tables

**size** - resources + default timeout:

| size | Default timeout | Assumed to use |
|------|----------------|----------------|
| `small` | 60s (short) | 1 core, little RAM |
| `medium` | 300s (moderate) | 1 core, moderate RAM |
| `large` | 900s (long) | 1 core, lots of RAM |
| `enormous` | 3600s (eternal) | Many cores |

**timeout** - duration only:

| timeout | Seconds |
|---------|---------|
| `short` | 60 |
| `moderate` | 300 |
| `long` | 900 |
| `eternal` | 3600 |

## Why this is not just documentation

Bazel uses `size` to decide how many tests to run concurrently. A test suite
where everything is marked `small` will oversubscribe the machine and produce
timeout flakes that look like real failures. A suite where everything is
`large` runs serially and wastes hours.

## Finding mislabeled tests

```bash
bazel test //... --test_verbose_timeout_warnings
```

Bazel reports tests that finished far faster than their size implies, so you
can right-size them.

## Key takeaway

`size` is a scheduling hint that happens to set a timeout. Use `timeout` to
adjust the clock without lying about the resources.
