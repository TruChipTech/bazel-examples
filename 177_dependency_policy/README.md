# 177 - Enforcing Dependency Policy

**Concepts:** `genquery` + tests, architectural rules as CI gates

## Run it

```bash
P=//177_dependency_policy

bazel test $P:policy_test --test_output=all
cat bazel-bin/177_dependency_policy/api_deps
```

## Break it on purpose

Add the internal library to the public API's deps:

```python
# public_api/BUILD.bazel
py_library(
    name = "api",
    srcs = ["api.py"],
    deps = ["//177_dependency_policy/internal:secret"],   # violation
)
```

```bash
bazel test $P:policy_test --test_output=all
```

```
POLICY VIOLATION: the public API depends on internal code:
  //177_dependency_policy/internal:secret
```

## How it works

```python
genquery(
    name = "api_deps",
    expression = "deps(//public_api:api)",
    scope = ["//public_api:api"],
)

sh_test(name = "policy_test", srcs = ["check_policy.sh"], data = [":api_deps"])
```

`genquery` turns a query result into a **build artifact**. A test then asserts
something about it. Because the artifact is a normal build output, the test:

- Re-runs exactly when the dependency graph changes
- Is cached the rest of the time
- Runs in the same `bazel test //...` as everything else

## Why not just use visibility?

Visibility (samples 015, 046) is stronger where it applies - it is a hard
analysis-time failure. Use it first.

Policy tests cover what visibility cannot:

| Rule | Mechanism |
|------|-----------|
| "Package X may not depend on Y" | **Visibility** |
| "Nothing in the public closure may be `testonly`" | Policy test |
| "No target may depend on more than N packages" | Policy test |
| "Every service must depend on the logging library" | Policy test |
| "This closure must not grow past 500 targets" | Policy test |
| "No deprecated API in new code" | Policy test |

Visibility answers "who may depend on me". Policy tests answer arbitrary
questions about the shape of the graph.

## Other policies worth writing

```bash
# No test target without a size
bazel query 'attr(size, "^$", kind(".*_test", //...))'

# Anything still depending on a deprecated target
bazel query 'rdeps(//..., //legacy:old_client)'

# Targets with no owner tag
bazel query 'attr(tags, "^((?!team-).)*$", //...)'
```

Each becomes a `genquery` plus an assertion.

## `scope` is mandatory

`genquery` requires `scope` to cover everything the expression touches. That is
what makes the query hermetic and cacheable - Bazel knows exactly which
packages the result depends on.

## Key takeaway

`genquery` + a test turns an architectural rule into a CI gate that fails the
moment someone violates it, rather than at review time.

## Gotcha: the genquery output filename

`genquery(name = "api_deps")` produces a file called exactly `api_deps` - **no
extension**. A script looking for `api_deps.txt` fails with "not found", which
reads like a missing `data` dependency but is not.

Check the real name with:

```bash
bazel cquery //177_dependency_policy:api_deps --output=files
```
