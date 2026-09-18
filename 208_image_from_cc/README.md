# 208 - An Image Containing One Binary

**Concepts:** static linking, scratch images, runtime closure

## Run it

```bash
bazel build //208_image_from_cc:image
tar tvf bazel-bin/208_image_from_cc/layer.tar
```

One file. No shell, no libc, no package manager.

## Why C++ makes this easy and Python does not

```
cc_binary  + linkstatic  ->  one self-contained ELF        ~20 KB layer
py_binary  + runfiles    ->  interpreter + stdlib + app   ~248 MB layer
```

Sample 085 measured the Python case. The difference is the **runtime closure**:
a statically linked binary has none, an interpreted program's closure includes
its entire interpreter.

## Check what you actually depend on

```bash
bazel build //208_image_from_cc:server
ldd bazel-bin/208_image_from_cc/server || echo "not a dynamic executable"
```

If `ldd` lists anything, those libraries must be in the image too or the
container will not start. `linkstatic = True` removes the question.

## The security argument

An image with no shell cannot be `exec`'d into, has no `curl` for an attacker
to pivot with, and has a near-zero CVE surface because there are no packages to
scan. This is the "distroless" idea, and with a static binary you can go
further - a genuinely empty base.

The cost is debuggability: no shell means no poking around in production. The
usual answer is a separate debug image built from the same layers.

## Key takeaway

Static binary plus one layer is the smallest, most secure image you can build,
and Bazel already knows the exact runtime closure.
