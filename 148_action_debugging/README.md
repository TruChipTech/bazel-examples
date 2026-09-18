# 148 - Debugging Actions

**Concepts:** `--subcommands`, `--sandbox_debug`, `--execution_log`

## The toolkit

```bash
D=//148_action_debugging

# Print every command Bazel runs
bazel build $D:simple --subcommands

# Print the full command line for FAILING actions only (already on in .bazelrc)
bazel build $D:simple --verbose_failures

# Keep the sandbox directory so you can look inside after a failure
bazel build $D:simple --sandbox_debug

# See which actions would run, without running them
bazel aquery $D:subject

# Explain why an action was NOT cached
bazel build $D:simple --explain=/tmp/explain.txt --verbose_explanations
cat /tmp/explain.txt
```

## `--subcommands` is the blunt instrument

It prints the literal command line for every action, including environment and
working directory. Enormous output, but it answers "what did Bazel actually
run?" definitively.

```bash
bazel build //x:y --subcommands 2>&1 | grep -A5 'MyMnemonic'
```

## `--sandbox_debug`

When an action fails with "file not found" but the file obviously exists, it
is almost always an undeclared input. `--sandbox_debug` leaves the sandbox
directory in place so you can list what was actually there:

```bash
bazel build //x:y --sandbox_debug
# the error names the sandbox path; then:
ls -R /path/to/sandbox/
```

If the file is missing from the sandbox, add it to `inputs`/`srcs`/`data`.

## `--explain`

```bash
bazel build //x:y --explain=/tmp/explain.txt --verbose_explanations
```

Writes a line per action saying why it ran: an input changed, the command line
changed, it was not in the cache. This is the tool for "why did this rebuild
when I only touched a comment?"

## The execution log

```bash
bazel build //... --execution_log_json_file=/tmp/exec.json
```

A complete record of every spawn: inputs with hashes, outputs, environment,
platform. Comparing two logs is the definitive way to diagnose
non-reproducibility:

```bash
# Build twice, compare
bazel build //... --execution_log_json_file=/tmp/a.json
bazel clean && bazel build //... --execution_log_json_file=/tmp/b.json
diff <(jq -S . /tmp/a.json) <(jq -S . /tmp/b.json)
```

## Mnemonics as handles

A good `mnemonic` makes an action addressable:

```bash
bazel aquery 'mnemonic("WordFreq", //...)'
bazel build //... --strategy=WordFreq=local
bazel build //... --modify_execution_info=WordFreq=+no-remote
```

This is why sample 105 insisted on picking a short, stable mnemonic.

## Starlark-side debugging

```python
print("value is %s" % x)     # emits during analysis
fail("bad input: %s" % x)    # stops with a message
```

`print()` in a rule implementation fires during analysis - once per target per
configuration, which can be a lot of output. Remove them before committing.

## Key takeaway

`--subcommands` for what ran, `--sandbox_debug` for missing inputs,
`--explain` for unexpected rebuilds, `--execution_log_json_file` for
reproducibility.
