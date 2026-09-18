# 027 - Test Tags and Filtering

**Concepts:** `tags`, `--test_tag_filters`, special tags

## Run it

```bash
# Everything except the manual one:
bazel test //027_test_tags/...

# Only unit tests:
bazel test //027_test_tags/... --test_tag_filters=unit

# Everything except integration tests (note the minus):
bazel test //027_test_tags/... --test_tag_filters=-integration

# The manual test runs only when named explicitly:
bazel test //027_test_tags:manual_test
```

## Tags with special meaning

| Tag | Effect |
|-----|--------|
| `manual` | Excluded from `//...` wildcards |
| `external` | Never cached - always re-runs |
| `local` | No sandbox, no remote execution |
| `exclusive` | Runs alone, nothing in parallel |
| `no-cache` | Result is not cached |
| `no-remote` | Never sent to remote execution |
| `no-sandbox` | Runs outside the sandbox |
| `requires-network` | Grants network access in the sandbox |

Everything else is a free-form label you can filter on.

## The CI pattern

```bash
# Pull request: fast feedback
bazel test //... --test_tag_filters=-integration,-slow

# Nightly: the whole thing
bazel test //...
```

## Do not reach for `manual` too fast

A `manual` test is one nobody runs, which means it is one nobody notices
breaking. Prefer a real tag plus a filter, so the test still runs *somewhere*.

## Key takeaway

Tags are how you carve one test suite into several audiences without
maintaining separate lists.
