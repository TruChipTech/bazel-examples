# 083 - expand_template: Generating Files From Templates

**Concepts:** `expand_template`, generated headers, substitution

## Run it

```bash
bazel run //083_expand_template:print_version
cat bazel-bin/083_expand_template/version.h
```

## The rule

```python
expand_template(
    name = "version_header",
    template = "version.h.tpl",
    out = "version.h",
    substitutions = {
        "{VERSION}": "2.4.1",
    },
)
```

Substitutions are **literal string replacements**, applied in unspecified
order. They are not regexes, so no escaping is needed - but also no capture
groups or patterns.

## Choose distinctive placeholders

`{VERSION}`, `@VERSION@`, `%%VERSION%%` are all common. Pick something that
cannot occur naturally in the file. Using bare `VERSION` would also rewrite the
word inside `#ifndef VERSION_H_`.

## The classic use: a version header

Combine with stamping (sample 092) to inject the real git SHA:

```python
expand_template(
    name = "version_header",
    template = "version.h.tpl",
    out = "version.h",
    substitutions = {"{VERSION}": "$(VERSION)"},
)
```

...though for genuinely volatile values like a commit hash, a stamped genrule
is usually the better fit, because `expand_template` substitutions are fixed at
analysis time.

## Why not sed in a genrule?

```python
cmd = "sed 's/{VERSION}/2.4.1/g' $< > $@"   # needs a shell; escaping is fragile
```

A value containing `/`, `&`, or a newline breaks the sed command. The
`substitutions` dict has no such problem.

## Key takeaway

`expand_template` is the portable way to turn a template plus values into a
generated source file. Use unmistakable placeholder syntax.
