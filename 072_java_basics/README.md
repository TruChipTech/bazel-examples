# 072 - Java Libraries and Binaries

**Concepts:** `java_library`, `java_binary`, `main_class`, hermetic JDK

## Run it

```bash
bazel run //072_java_basics:main -- Bazel
```

## No JDK on this machine - and it still works

This repo's `.bazelrc` contains:

```
build --java_runtime_version=remotejdk_21
build --tool_java_runtime_version=remotejdk_21
```

Bazel downloads a JDK and uses it for the build. Nothing depends on what
`java -version` prints on your machine, which is exactly the point: the same
bytecode is produced on a developer laptop and in CI.

| Flag | Controls |
|------|----------|
| `--java_runtime_version` | The JDK used to **run** and target |
| `--tool_java_runtime_version` | The JDK used to **build** (javac itself) |
| `--java_language_version` | The `--release` level of the source |

Set `local_jdk` instead of `remotejdk_21` to use the system JDK.

## Directory layout

Bazel does **not** require `src/main/java`. The package path in the label and
the Java package in the file are independent. Maven-style layout here is only
convention; many Bazel repos flatten it.

What Bazel does care about is that the Java package matches the directory
structure **relative to the source root** it infers - which is why
`java_library` sometimes needs `resource_strip_prefix` or a `java_package`
setting in unusual layouts.

## `deploy_jar`: the self-contained artifact

```bash
bazel build //072_java_basics:main_deploy.jar
java -jar bazel-bin/072_java_basics/main_deploy.jar Bazel
```

Every `java_binary` implicitly offers a `_deploy.jar` target: a fat jar with all
dependencies bundled. This is usually what you ship.

## Key takeaway

`java_library` + `java_binary` mirror `cc_library` + `cc_binary` exactly. The
Java-specific parts are `main_class`, the implicit `_deploy.jar`, and the
hermetic JDK selection.
