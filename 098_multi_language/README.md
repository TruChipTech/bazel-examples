# 098 - A Multi-Language Application

**Concepts:** polyglot builds, shared schema, cross-language testing

## Run it

```bash
M=//098_multi_language

bazel build $M/...
bazel test  $M:all_tests --test_output=all
```

## The architecture

```
proto/metric.proto           the single source of truth
   |                |
cc_proto_library   py_proto_library
   |                |
cc/writer        py/reader
   \                /
    e2e/roundtrip_test        proves they agree
```

## What this demonstrates that a single-language build cannot

**The schema cannot drift.** Add a field to `metric.proto` and both the C++ and
Python bindings regenerate in the same build. There is no "we updated the
server but forgot the client" window, because there is only one artifact
defining the contract.

**One test covers the seam.** `roundtrip_test` depends on both binaries, so it
re-runs whenever either side changes. This is the test that catches
serialization mismatches - historically the most expensive kind of bug in
polyglot systems, because it only shows up at integration time.

**One command builds everything.** No "first run the proto generator, then
build the server, then install the Python package". `bazel build //...` is the
whole procedure, and it is incremental.

## Try breaking the contract

Change `double value = 2;` to `string value = 2;` in the proto and run the
test. Both bindings regenerate, the C++ code fails to compile, and you learn
about it in seconds rather than in staging.

## The general pattern

| Layer | Rule | Owns |
|-------|------|------|
| Schema | `proto_library` | The contract |
| Bindings | `*_proto_library` | Generated code, one per language |
| Implementations | `cc_binary`, `py_binary`, ... | Behavior |
| Seam test | `sh_test` depending on all of them | Interoperability |

## Key takeaway

Bazel's value grows with the number of languages in the repo. The schema is a
build target, so the compiler enforces the contract across language boundaries.
