# 210 - Enforcing an Image Size Budget

**Concepts:** size regression tests, bloat detection

## Run it

```bash
bazel test //210_image_size_budget:size_budget_test --test_output=all
```

```
layer size: 8192 bytes (limit 102400)
PASS: within budget (94208 bytes to spare)
```

## Why a test and not a dashboard

Image size grows one innocuous dependency at a time. Nobody reviews a PR and
notices that the image went from 40 MB to 47 MB. A failing test at the moment
of the change names the commit responsible.

```
FAIL: layer exceeds budget by 3400 bytes
      Inspect with: tar tvf ... | sort -k3 -rn | head
```

The error message tells you how to find the culprit - a habit worth keeping in
every policy test.

## Setting the number

Set the ceiling a little above current size, not at some aspirational target.
The purpose is to catch *change*, not to force an immediate diet. Ratchet it
down as you shrink things.

## What usually causes a jump

| Cause | Sample |
|-------|--------|
| A `py_binary` dragged the interpreter in | 085 |
| Debug symbols not stripped | 025 |
| Test fixtures packaged with production files | 041 |
| An entire base image pulled in for one utility | 203 |
| Runfiles of a tool included by accident | 111 |

## Key takeaway

Budget tests turn gradual bloat into an immediate, attributable failure.
