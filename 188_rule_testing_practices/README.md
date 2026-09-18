# 188 - Rule Testing Practices

**Concepts:** what to test, how to structure it, what to skip

Samples 185-187 showed the mechanics. This one is about judgement.

## What is worth testing

| Test this | Because |
|-----------|---------|
| Provider fields are populated | Consumers break silently otherwise |
| `fail()` messages | They are your users' entire error experience |
| Command lines for each `select()` branch | Nobody builds every configuration |
| Attribute defaults | A changed default breaks callers invisibly |
| Transitive collection (depsets) | Diamond dependencies and dedup |
| Output filenames that are part of the API | Renaming breaks consumers |

## What is not worth testing

- That Bazel itself works
- Third-party rule behavior - test *your* usage, not their implementation
- Trivial pass-throughs with no logic
- Exact byte output of a compiler you do not control

## Structure

```
rules/
  defs.bzl           the rules
  defs_test.bzl      analysistest implementations
  BUILD.bazel        the test targets + a test_suite
  testdata/          golden files and fixtures
```

Keep the tests next to the rules. A `tests/` directory two levels away gets
forgotten.

## Name the subject targets clearly

```python
tagged_file(name = "subject_ok", ..., tags = ["manual"])
tagged_file(name = "subject_missing_srcs", ..., tags = ["manual"])
tagged_file(name = "subject_bad_count", ..., tags = ["manual"])
```

Always `tags = ["manual"]` on a target that is meant to fail, or
`bazel build //...` breaks.

## Test the errors, not just the successes

```python
failure_test = analysistest.make(_impl, expect_failure = True)

def _impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "srcs must not be empty")
    return analysistest.end(env)
```

A rule's error messages are load-bearing documentation. Pinning them in a test
stops a refactor from turning a clear message into an internal stack trace.

## Do not test through the filesystem

```python
# Bad: asserts on a hard-coded bazel-bin path
asserts.equals(env, "bazel-out/k8-fastbuild/bin/pkg/out.txt", f.path)

# Good: asserts on the property you care about
asserts.true(env, f.basename.endswith(".txt"))
asserts.equals(env, 1, len(files))
```

Output paths contain the configuration, so a hard-coded path test fails the
moment anyone builds with a different flag.

## Run the tests in CI - obviously

```python
test_suite(name = "rule_tests", tests = [...])
```

Rule tests are fast (mostly analysis-only), so they belong in presubmit.

## The maintenance argument

Rules are infrastructure: every BUILD file in the repo depends on them. A bug
in a rule does not fail in the rule - it fails in someone else's target, with a
confusing message, hours later. Tests are how you keep that from being the
normal experience of your rule set.

## Key takeaway

Test providers, error messages and command lines. Skip anything you do not
own. Keep tests next to the rules and run them in presubmit.
