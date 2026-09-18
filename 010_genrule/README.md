# 010 - genrule: Running Arbitrary Commands

**Concepts:** `genrule`, `cmd`, Make variables, `$@` / `$<`

## Run it

```bash
bazel build //010_genrule:greetings
cat bazel-bin/010_genrule/greetings.txt

bazel build //010_genrule:build_info
cat bazel-bin/010_genrule/build_info.txt
```

## The rules of genrule

1. **You must declare every output** in `outs`. Bazel creates the parent
   directory but nothing else; writing a file you did not declare is an error,
   and failing to write one you did declare is also an error.
2. **You must declare every input** in `srcs`. The command runs in a sandbox.
3. **The command must be deterministic.** Same inputs, same outputs - otherwise
   caching produces wrong results.

## Variable expansion gotcha

Bazel expands `$(...)` and `$@` *before* the shell sees the command. To pass a
literal `$` to the shell, write `$$`:

```python
cmd = "for f in $(SRCS); do echo $$f; done > $@"
```

Forgetting the double `$` is the most common genrule bug.

## When not to use genrule

genrule is fine for one-offs. Once the same command appears in three BUILD
files, promote it to a macro (sample 051) or a real rule (sample 101), which
gives you validation, better error messages, and reuse.

## Key takeaway

genrule = declared inputs + declared outputs + a shell command. Anything
undeclared is invisible to the command.
