# 008 - Shell Binaries

**Concepts:** `sh_binary`, wrapping existing scripts

## Run it

```bash
bazel run //008_sh_binary:report -- one two three
```

## Why wrap a script at all?

The script already runs fine with `./report.sh`. Wrapping it buys three things:

1. **It can be a dependency.** Other rules can use it as a `tool`, so the
   script's own dependencies get tracked.
2. **It gets runfiles.** Anything in `data` is staged next to the script and is
   available at a predictable path on every machine.
3. **It is addressable.** `//...:report` works from anywhere in the repo, and
   CI does not need to know where the file lives.

## Note on `srcs`

`sh_binary` expects exactly one script in `srcs` - the entry point. Helper
scripts it sources belong in `data`, not `srcs`.

## Key takeaway

`sh_binary` is the bridge between "we have a pile of shell scripts" and a fully
declared build graph. It is often the first step in migrating a legacy repo.
