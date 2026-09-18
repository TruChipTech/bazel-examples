# 058 - select() Defaults and Errors

**Concepts:** `//conditions:default`, `no_match_error`, fail-fast

## Run it

```bash
bazel build //058_select_defaults:all
cat bazel-bin/058_select_defaults/with_default.txt
cat bazel-bin/058_select_defaults/strict.txt
```

## Default or no default?

**Include `//conditions:default`** when the attribute has a sensible
platform-neutral value. Most `copts`, `deps` and `tags` selects fall here.

**Omit it** when building for an unlisted platform would silently produce
something broken. A missing default turns "unsupported" into a build error,
which is much better than a binary that links but crashes at startup.

## `no_match_error`

Without it:

```
ERROR: Configurable attribute "cmd" doesn't match this configuration.
```

With it, the message tells the reader what to do instead. This matters because
the person hitting the error is usually not the person who wrote the select.

## The "select nothing" idiom

```python
deps = select({
    ":linux": [":epoll_backend"],
    "//conditions:default": [],       # empty list, not an error
})
```

An empty default is the normal way to express "this dependency only exists on
some platforms". Do not confuse it with omitting the default entirely.

For a shell command, the no-op is `"true"` rather than `""`, since an empty
command still has to be a valid shell command.

## Key takeaway

A missing default is a feature. Use it to make unsupported configurations fail
loudly, and always pair it with `no_match_error`.
