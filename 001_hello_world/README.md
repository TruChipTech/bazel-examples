# 001 - Hello World

**Concepts:** `cc_binary`, targets, labels, `load()`

The smallest possible Bazel build: one source file, one rule, one executable.

## Run it

```bash
bazel run //001_hello_world:hello
```

## What is happening

A **package** is any directory containing a `BUILD.bazel` file. This directory
is the package `001_hello_world`.

A **target** is one rule instance inside a package. Here the target is `hello`.

A **label** uniquely names a target across the whole build:

```
//001_hello_world:hello
  ^                          ^
  package path               target name
```

The leading `//` means "from the workspace root". Bazel never uses relative
filesystem paths to refer to targets, which is what makes a label mean the
same thing no matter which directory you run the command from.

## Key takeaway

`load()` is mandatory in Bazel 9. If you see
`name 'cc_binary' is not defined`, you forgot the load statement.
