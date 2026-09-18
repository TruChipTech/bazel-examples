# 401 - Building and Signing Many Images in Parallel

**Concepts:** fan-out macros, independent targets, parallel signing

## Run it

```bash
P=//401_parallel_signed_images

bazel query $P:all              # 5 services -> 20 targets
bazel build $P:fleet_tests_all  # every image and signature, concurrently
bazel test  $P:fleet_tests      # verify all 5 signatures
```

```
INFO: 21 processes: 6 internal, 15 linux-sandbox.
Executed 5 out of 5 tests: 5 tests pass.
```

## One declaration, twenty targets

```python
signed_image_fleet(
    name = "fleet_tests",
    services = {
        "auth": "auth.sh",
        "billing": "billing.sh",
        ...
    },
    registry = "registry.example.com",
    private_key = "@signing_keys//:rsa_private.pem",
    public_key = "@signing_keys//:rsa_public.pem",
)
```

Per service the macro emits a layer, an image, a signature and a verification
test - plus a `filegroup` that builds everything and a `test_suite` that
verifies everything.

## You do not write the parallelism

There is no thread pool here, no `&`, no `xargs -P`. The five images share no
inputs and no outputs, so the graph says they are independent and Bazel runs
them across every available core automatically.

The work is making the targets genuinely independent:

- No shared mutable output path
- No ordering dependency between services
- Each signature depends only on its own image

Get that right and parallelism is free. Get it wrong - two targets writing the
same file - and Bazel rejects it at analysis time rather than producing a race.

## Scaling further

```bash
bazel build //401_parallel_signed_images:fleet_tests_all --jobs=50
```

With remote execution (sample 154) the same graph fans out across a cluster;
`--jobs` should then far exceed your core count, because the limit is the fleet
rather than the machine.

## Why signing parallelises well

Each signature is an independent action over one small payload (sample 271:
you sign the digest, not the image). Signing 500 images is 500 cheap,
embarrassingly parallel operations - the expensive part is building the layers,
not the crypto.

## Adding a service

One line in the `services` dict. The layer, image, signature and test appear
automatically, and CI picks them up because it references `:fleet_tests`, not a
hard-coded list.

## Key takeaway

Fan-out is a macro plus independent targets. Bazel supplies the concurrency.
