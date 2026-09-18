# 149 - aquery: Inspecting the Action Graph

**Concepts:** `aquery`, action inspection, build analysis

## Run it

```bash
A=//149_aquery

# Every action needed to build the binary
bazel aquery "deps($A:app)"

# Only C++ compile actions
bazel aquery 'mnemonic("CppCompile", deps('$A':app))'

# Only actions producing a specific output
bazel aquery 'outputs(".*\.o", deps('$A':app))'

# Only actions consuming a specific input
bazel aquery 'inputs(".*lib\.cc", deps('$A':app))'

# Machine-readable
bazel aquery "deps($A:app)" --output=jsonproto | head -40
bazel aquery "deps($A:app)" --output=textproto | head -40
```

## What aquery shows

For each action: its mnemonic, the target that owns it, the full command line,
every input and output, the environment, and its execution platform.

```
action 'Compiling 149_aquery/lib.cc'
  Mnemonic: CppCompile
  Target: //149_aquery:lib
  Configuration: k8-fastbuild
  Inputs: [...]
  Outputs: [...]
  Command Line: /usr/bin/gcc -U_FORTIFY_SOURCE ... 
```

## The three query levels

| Command | Level | Answers |
|---------|-------|---------|
| `query` | Targets (loading) | "What depends on what?" |
| `cquery` | Configured targets (analysis) | "...after `select()` and transitions" |
| `aquery` | **Actions** (analysis) | "What commands will actually run?" |

## What people use it for

**"Why is this flag not being applied?"**
```bash
bazel aquery 'mnemonic("CppCompile", //x:y)' | grep -- '-DMY_FLAG'
```
The command line is right there; no guessing.

**"How many actions does this target need?"**
```bash
bazel aquery "deps(//x:y)" --output=jsonproto | jq '.actions | length'
```

**"What is the slowest part of my build?"** - combine with a profile
(sample 157).

**"Did my change alter the build at all?"** Diff two aqueries:
```bash
bazel aquery //... --output=textproto > /tmp/before.txt
# make the change
bazel aquery //... --output=textproto > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt
```
This is the basis of tools like `bazel-diff`, which compute exactly which
targets a commit affects (sample 183).

## aquery does not run anything

It performs loading and analysis, then stops. So it is fast and safe, but it
also means a bug that only appears at execution time is invisible to it.

## Key takeaway

`aquery` is the ground truth for "what command will Bazel run". Use it whenever
a flag, input, or environment variable is not doing what you expect.
