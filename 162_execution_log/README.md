# 162 - The Execution Log

**Concepts:** `--execution_log_json_file`, diffing builds

## Try it

```bash
L=//162_execution_log

bazel build $L:app --execution_log_json_file=/tmp/exec.json

# What ran, and how?
jq -r '.mnemonic + " -> " + (.runner // "?")' /tmp/exec.json | sort | uniq -c

# Full detail for one action
jq 'select(.mnemonic == "CppCompile")' /tmp/exec.json | head -60

# Every input, with its content hash
jq -r 'select(.mnemonic=="CppCompile") | .inputs[]? | .path' /tmp/exec.json | head
```

Note: the file is **one JSON object per spawn**, not a single array. `jq`
handles that natively.

## What it records

For every spawn Bazel executed: the command line, the full environment, every
input with its digest, every output with its digest, the platform properties,
the runner that executed it (`linux-sandbox`, `worker`, `remote`, cache hit),
and timing.

It is the most complete record Bazel can give you.

## The killer application: diffing two builds

```bash
bazel build //... --execution_log_json_file=/tmp/a.json
bazel clean
bazel build //... --execution_log_json_file=/tmp/b.json

diff <(jq -S . /tmp/a.json) <(jq -S . /tmp/b.json)
```

Empty diff = the build is reproducible. Any difference points at the exact
action and the exact field that varied - a timestamp in an output digest, an
environment variable, a path.

The same technique across two *machines* diagnoses "why does CI not hit the
cache?" definitively, rather than by guesswork.

## Other useful queries

```bash
# Which actions were NOT cached?
jq -r 'select(.runner != "remote cache hit") | .mnemonic' /tmp/exec.json | sort | uniq -c

# Slowest spawns
jq -r '[.walltime, .mnemonic, .targetLabel] | @tsv' /tmp/exec.json | sort -rn | head

# Actions with a suspicious environment
jq -r 'select(.environmentVariables[]?.name == "PATH") | .targetLabel' /tmp/exec.json | head
```

## Formats

```bash
--execution_log_json_file=/tmp/exec.json      # JSON lines, greppable
--execution_log_binary_file=/tmp/exec.bin     # compact protobuf
--execution_log_compact_file=/tmp/exec.zst    # smallest; needs a converter
```

Use JSON while investigating; the binary/compact forms for large builds where
the JSON would be gigabytes.

## Related

- `--explain=/tmp/explain.txt` - *why* each action ran (sample 148)
- `--subcommands` - the raw command lines
- BEP (sample 156) - build-level rather than spawn-level

## Key takeaway

The execution log is the ground truth for reproducibility and cache-miss
debugging. Diff two logs before theorizing about either.
