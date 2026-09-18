# 076 - One Schema, Multiple Languages

**Concepts:** `java_proto_library`, polyglot schema sharing

## Run both

```bash
bazel run //075_cc_proto:use_event            # C++
bazel run //076_multi_language_proto:read_event   # Java
```

Both read and write the same wire format, generated from the same
`//074_proto_library:event_proto`.

## The language wrappers

| Rule | Load from |
|------|-----------|
| `cc_proto_library` | `@protobuf//bazel:cc_proto_library.bzl` |
| `java_proto_library` | `@protobuf//bazel:java_proto_library.bzl` |
| `py_proto_library` | `@protobuf//bazel:py_proto_library.bzl` |
| `go_proto_library` | `@rules_go//proto:def.bzl` |

Each takes `deps = [<proto_library>]` and generates the full transitive
closure.

## Java class naming

The generated Java class names come from the proto package and options:

```java
import samples.event.EventOuterClass.Event;
```

`EventOuterClass` is the default outer class name derived from the **file**
name (`event.proto`). Control it explicitly in the `.proto`:

```protobuf
option java_package = "com.example.events.proto";
option java_outer_classname = "EventProto";
option java_multiple_files = true;   // no outer class at all
```

`java_multiple_files = true` is usually what you want in a real project - it
gives you `import com.example.events.proto.Event` directly.

## Why this matters architecturally

The schema is a **build target**, not a file someone copies between repos. A
breaking change to `event.proto` fails the C++ build and the Java build in the
same CI run, immediately, rather than at integration time.

## Key takeaway

Declare the schema once with `proto_library`, then add one wrapper per language
that needs it. The wrappers cost nothing when nobody depends on them.

## Java strict deps

C++ let `use_event.cc` use `samples::common::SEVERITY_WARNING` while depending
only on `:event_cc_proto`, because the symbol arrived transitively. Java does
not:

```
ERROR: Using type samples.common.Common.Severity from an indirect dependency.
Please add the following dependencies:
  //074_proto_library:common_proto
```

This is **strict deps**, and it is on by default for Java. The rule: if a file
names a symbol, its target must declare a direct dependency on whatever
provides that symbol. Transitive availability is not enough.

That is why this BUILD file declares `common_java_proto` as well as
`event_java_proto`.

Strict deps is a significant scalability feature: it means removing a
dependency from a library cannot silently break distant consumers who were
relying on it transitively. Bazel even prints the exact `buildozer` command to
fix it.

The equivalent for C++ is `layering_check` (sample 167), which is opt-in.
