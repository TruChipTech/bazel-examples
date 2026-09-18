# 074 - proto_library

**Concepts:** `proto_library`, import paths, language neutrality

## Build it

```bash
bazel build //074_proto_library:event_proto

# It produces a descriptor set, not source code:
find bazel-bin/074_proto_library -name '*.proto.bin'
```

## One schema, many languages

```
        proto_library(:event_proto)          <- the schema
         /            |             \
cc_proto_library  java_proto_library  py_proto_library
```

The `proto_library` target is declared **once**. Each language wrapper
generates bindings from it. This is why Bazel is popular for polyglot services:
the schema cannot drift between the C++ server and the Python client, because
both are generated from the same target in the same build.

## Import paths, and why this sample needs `strip_import_prefix`

By default the import string must be the file's **workspace-relative path**:

```protobuf
import "074_proto_library/common.proto";   // the default
```

That is verbose, and here it is also *broken*: the C++ generator derives an
include guard from the path, and this directory starts with a digit, producing
the invalid macro `#ifndef 02_starter_074_proto_library_common_2eproto`:

```
event.pb.h:6:9: error: macro names must be identifiers
```

`strip_import_prefix` fixes both problems at once:

```python
proto_library(
    name = "event_proto",
    srcs = ["event.proto"],
    strip_import_prefix = "/074_proto_library",  # leading / = from workspace root
)
```

Now the import is simply `import "common.proto";` and the generated header is
`event.pb.h`.

The general lesson: proto import paths are part of your API and they leak into
generated code. Give protos a short, stable, identifier-safe path - either with
`strip_import_prefix` or by putting them in a dedicated top-level directory.

## `deps` mirrors `import`

Every `import` in a `.proto` needs a matching entry in `deps`. Miss one and
protoc fails with "File not found" even though the file is in the repo - the
same strictness as C++ headers, for the same reason.

## Key takeaway

`proto_library` describes the schema; it never generates code. Always declare
`deps` to match your `import` statements.
