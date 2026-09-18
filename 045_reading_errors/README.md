# 045 - Reading Bazel Error Messages

**Concepts:** error taxonomy, `--verbose_failures`, `--sandbox_debug`

```bash
bazel build //045_reading_errors:good
```

Bazel errors name the **phase** they came from. Identifying the phase tells you
where to look.

## Loading errors

```
ERROR: /path/BUILD.bazel:7:11: name 'cc_binary' is not defined
```
A missing `load()`. Nothing was analyzed yet.

```
ERROR: no such package 'foo/bar': BUILD file not found
```
The label points at a directory with no BUILD file.

```
ERROR: no such target '//foo:baz': target 'baz' not declared in package 'foo'
```
Package exists, target name is wrong - or the file is not `exports_files`'d.

## Analysis errors

```
ERROR: target '//a:b' is not visible from target '//c:d'
```
Visibility (sample 015).

```
ERROR: in deps attribute of cc_library rule //a:b: '//x:y' does not have
mandatory provider 'CcInfo'
```
Wrong kind of target in `deps` - e.g. a `filegroup` where a `cc_library` was
expected.

```
ERROR: cycle in dependency graph
```
A depends on B depends on A. Find it with
`bazel query 'somepath(//a:a, //b:b)'`.

## Execution errors

```
ERROR: ... Compiling foo.cc failed: (Exit 1): gcc failed
this rule is missing dependency declarations for the following files
included by 'foo.cc': 'bar.h'
```
The most common C++ error: add the `deps` edge that owns `bar.h`.

## The three flags to reach for

```bash
bazel build //... --verbose_failures   # show the full failing command line
bazel build //... --sandbox_debug      # keep the sandbox dir for inspection
bazel build //... --subcommands        # print EVERY command Bazel runs
```

`--verbose_failures` is already on in this repo's `.bazelrc`.

## Key takeaway

Read the phase first. Loading = your BUILD file. Analysis = your graph.
Execution = your code or a missing declared input.
