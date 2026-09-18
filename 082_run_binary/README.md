# 082 - run_binary: Invoking a Tool Without a Shell

**Concepts:** `run_binary`, genrule alternatives, portability

## Run it

```bash
bazel build //082_run_binary:people_json
cat bazel-bin/082_run_binary/people.json
```

## genrule vs run_binary

```python
# genrule: a shell command
genrule(
    name = "people_json",
    srcs = ["people.csv"],
    outs = ["people.json"],
    tools = [":csv_to_json"],
    cmd = "$(execpath :csv_to_json) $(execpath people.csv) $@",
)

# run_binary: a direct invocation
run_binary(
    name = "people_json",
    srcs = ["people.csv"],
    outs = ["people.json"],
    tool = ":csv_to_json",
    args = ["$(execpath people.csv)", "$(execpath people.json)"],
)
```

| | genrule | run_binary |
|---|---------|-----------|
| Needs a shell | Yes | No |
| Windows behavior | Needs bash | Works natively |
| Argument quoting | Your problem | Handled - `args` is a list |
| Shell features (pipes, `&&`) | Yes | No |

## Why "no shell" matters

A genrule's `cmd` is a shell script. That means quoting bugs, `$$` escaping
(sample 010), and a hard dependency on bash - which is not present on a stock
Windows machine or in a minimal remote-execution container.

`run_binary` passes `args` as an argv array. A filename containing a space just
works.

## When to keep the genrule

When you genuinely need shell features: pipelines, conditionals, several
commands chained with `&&`. If you find yourself writing more than one command,
consider moving that logic *into the tool* instead - it is easier to test there.

## Related

`expand_template` (sample 083) for simple substitution, and a custom rule
(sample 106) when you need full control over the action.

## Key takeaway

Reach for `run_binary` when the job is "run this program with these
arguments". Keep `genrule` for genuine shell work.
