# 047 - Chaining Build Steps

**Concepts:** implicit ordering, intermediate artifacts, incrementality

## Run it

```bash
bazel build //047_genrule_pipeline:eng_report
cat bazel-bin/047_genrule_pipeline/eng_report.txt
```

## You never declared an order

There is no "step 1, then step 2" instruction anywhere. Step 2 lists step 1's
output in its `srcs`, and that is the entire dependency declaration. Bazel
derives the order, and - just as importantly - derives what can run in
parallel.

## See the chain

```bash
bazel query 'deps(//047_genrule_pipeline:eng_report)' \
  --noimplicit_deps
```

## Incrementality for free

```bash
bazel build //047_genrule_pipeline:eng_report   # runs 3 actions
bazel build //047_genrule_pipeline:eng_report   # runs 0 actions
touch 047_genrule_pipeline/raw.csv              # content unchanged
bazel build //047_genrule_pipeline:eng_report   # STILL 0 actions
```

That last one is the interesting case. Bazel hashes file **contents**, not
timestamps, so touching a file changes nothing. Actually edit `raw.csv` and all
three steps re-run.

## A note on the intermediate files

`body.csv` and `sorted.csv` are real, inspectable artifacts in `bazel-bin`.
When a pipeline misbehaves, you can look at the output of each stage - a
significant debugging advantage over one giant shell script.

## Key takeaway

Declare inputs and outputs; ordering and parallelism follow automatically.
This is the core idea that scales from 3 actions to 3 million.
