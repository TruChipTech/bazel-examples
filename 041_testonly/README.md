# 041 - testonly: Keeping Test Code Out of Production

**Concepts:** `testonly`, dependency hygiene

## Run it

```bash
bazel test //041_testonly:clock_test
```

## Break it on purpose

Add `deps = [":fake_clock"]` to the `real_clock` library:

```
ERROR: non-test target '//...:real_clock' depends on testonly target
'//...:fake_clock' and doesn't have testonly attribute set
```

## Why this rule exists

Test doubles, fixture generators, and debug helpers are written for
convenience, not for production: they skip validation, hard-code credentials,
or keep everything in memory. Once one of them is reachable from a production
binary, it ships.

`testonly` makes that structurally impossible rather than a code-review
concern.

## The propagation rule

- A `testonly` target may depend on anything.
- A non-`testonly` target may **not** depend on a `testonly` target.
- All `*_test` rules are implicitly `testonly = True`.

## Package-wide

```python
package(default_testonly = True)
```

Useful for an entire `testing/` or `fakes/` directory.

## Key takeaway

Mark every test helper `testonly = True`. It costs one line and permanently
prevents a whole class of accident.
