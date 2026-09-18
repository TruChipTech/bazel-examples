# Bazel Command Cheatsheet

Everything here works in this repository. Bazel 9.2.

## The three commands

```bash
bazel build //pkg:target        # produce artifacts
bazel run   //pkg:target -- ARG # build and execute (args after --)
bazel test  //pkg:target        # build, run as a test, cache the result
```

## Target patterns

```bash
//pkg:name        one target
//pkg:all         every rule target in that package
//pkg:*           every target including source files
//pkg/...         that package and everything below it
//...             the whole workspace
-- -//pkg/...     exclude (must come after --)
```

## Querying

```bash
bazel query "deps(//x:y)"                  # what it needs
bazel query "deps(//x:y, 1)"               # direct only
bazel query "rdeps(//..., //x:y)"          # what needs it
bazel query "somepath(//a:a, //b:b)"       # why are these connected?
bazel query "allpaths(//a:a, //b:b)"       # every path
bazel query "kind(cc_library, //...)"      # by rule type
bazel query "attr(tags, manual, //...)"    # by attribute
bazel query "tests(//...)"                 # test targets

bazel cquery "deps(//x:y)"                 # after select() and transitions
bazel cquery //x:y --output=files          # where are the outputs?
bazel aquery "mnemonic(CppCompile, //x:y)" # what command will run?
```

Add `--noimplicit_deps` to hide toolchains, and `--output=graph|build|label_kind|jsonproto`.

## Debugging

```bash
--verbose_failures            # full command line on failure
--subcommands                 # every command Bazel runs
--sandbox_debug               # keep the sandbox after a failure
--explain=/tmp/e.txt --verbose_explanations    # why did this rebuild?
--announce_rc                 # which .bazelrc lines are active
--toolchain_resolution_debug='.*type.*'
--execution_log_json_file=/tmp/exec.json      # ground truth per spawn
--build_event_json_file=/tmp/bep.json         # structured build record
--profile=/tmp/prof.gz                        # timeline (see sample 157)
--starlark_cpu_profile=/tmp/s.pprof           # slow macros/rules
```

> `bazel analyze-profile` was **removed in Bazel 9**. Use a trace viewer
> (ui.perfetto.dev) or `//157_profiling:summarize_profile`.

## Configuration

```bash
-c fastbuild | dbg | opt      # compilation mode
--platforms=//platforms:x     # target platform
--config=NAME                 # a named flag bundle from .bazelrc
--//pkg:flag=value            # a custom build setting
--define=KEY=value            # legacy
```

## Caching

```bash
--disk_cache=~/.cache/bazel-disk-cache
--remote_cache=grpcs://cache:9092
--remote_executor=grpcs://rbe:443
--remote_download_minimal|toplevel|all
--noremote_upload_local_results
--repository_cache=/shared/repos
```

## Testing

```bash
--test_output=summary|errors|all
--test_tag_filters=unit,-slow
--runs_per_test=20            # find flakes
--nocache_test_results
--test_filter=SomeTestName
--test_env=VAR=value
--test_verbose_timeout_warnings
bazel coverage //... --combined_report=lcov
```

## Modules

```bash
bazel mod graph               # the resolved dependency tree
bazel mod graph --from=X
bazel mod explain X           # why this version?
bazel mod show_repo X
bazel mod show_extension //pkg:ext.bzl%name
bazel mod tidy                # fix use_repo() calls
bazel vendor --vendor_dir=vendor //...
--lockfile_mode=update|error|refresh|off
```

## Information

```bash
bazel info                    # all keys
bazel info output_base
bazel info execution_root
bazel info bazel-bin -c opt   # respects flags
bazel config                  # list configurations
bazel config <hash1> <hash2>  # diff two configurations
bazel version
```

## Cleaning

```bash
bazel clean                   # outputs + action cache (keeps the disk cache)
bazel clean --expunge         # everything, including external repos - rarely right
bazel shutdown                # stop the server, DISCARDING the analysis cache
```

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Build failed |
| 2 | Bad command line |
| 3 | **Tests failed** (build succeeded) |
| 4 | No tests found |
| 8 | Interrupted |
