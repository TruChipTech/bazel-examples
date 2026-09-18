# 075 - C++ Protocol Buffers

**Concepts:** `cc_proto_library`, generated headers, transitivity

## Run it

```bash
bazel run //075_cc_proto:use_event
```

## The generated header path

```cpp
#include "event.pb.h"
```

The rule is mechanical: take the **import path** of the `.proto` and replace
`.proto` with `.pb.h`. Because sample 074 sets `strip_import_prefix`, the
import path is just `event.proto`, so the header is `event.pb.h`. Without that
attribute it would be the full workspace-relative path.

The header lives in `bazel-bin`, but you never write that prefix - the
generated include path is set up for you.

```bash
find bazel-bin -name 'event.pb.h'
```

## The one-to-one rule

```python
cc_proto_library(name = "event_cc_proto", deps = [":event_proto"])
```

Convention: exactly **one** `cc_proto_library` per `proto_library`, named with
a `_cc_proto` suffix. Wrapping several proto_libraries in one cc_proto_library
works, but then consumers cannot depend on just the part they need, and you get
symbol duplication if another target wraps the same proto.

## Transitivity is automatic

`event.proto` imports `common.proto`, and `:event_cc_proto` wraps only
`:event_proto`. The C++ code for `common.proto` still arrives, because
`cc_proto_library` follows the proto dependency graph and generates the whole
closure.

## gRPC services

`cc_proto_library` generates **messages only**. Service stubs need the gRPC
plugin:

```python
load("@grpc//bazel:cc_grpc_library.bzl", "cc_grpc_library")

cc_grpc_library(
    name = "service_cc_grpc",
    srcs = [":service_proto"],
    grpc_only = True,
    deps = [":service_cc_proto"],
)
```

## Key takeaway

One `proto_library`, one `cc_proto_library`, and the include path is the
`.proto` path with a `.pb.h` extension.
