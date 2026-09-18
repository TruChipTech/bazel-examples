# 089 - Combining Conditions With config_setting_group

**Concepts:** `selects.config_setting_group`, AND / OR logic

## Run it

```bash
G=//089_config_setting_group

bazel build $G:deploy_config
cat bazel-bin/089_config_setting_group/deploy.conf     # telemetry=off

bazel build $G:deploy_config --//089_config_setting_group:env=prod
cat bazel-bin/089_config_setting_group/deploy.conf     # telemetry=on

bazel build $G:log_config --//089_config_setting_group:verbose=true
cat bazel-bin/089_config_setting_group/log.conf        # level=trace
```

## The gap it fills

A single `config_setting` ANDs its own conditions:

```python
config_setting(
    name = "prod_linux",
    flag_values = {":env": "prod"},
    constraint_values = ["@platforms//os:linux"],
)   # prod AND linux
```

But there is no way to express **OR**, and no way to AND two *existing*
settings without duplicating their conditions.

```python
selects.config_setting_group(name = "deployed", match_any = [":is_prod", ":is_staging"])
selects.config_setting_group(name = "verbose_linux", match_all = [":is_linux", ":is_verbose"])
```

## Composition

The groups are themselves valid `select()` keys, so they nest:

```python
selects.config_setting_group(
    name = "needs_hardening",
    match_all = [":deployed", ":is_linux"],
)
```

## Avoiding "ambiguous match" errors

Without groups, people write overlapping settings and hit:

```
ERROR: Illegal ambiguous match on configurable attribute
```

Explicit groups make the intended combination a named target, so the select has
exactly one matching key.

## `selects.with_or` for a shorthand

For a one-off OR inside a single select, skylib also offers:

```python
load("@bazel_skylib//lib:selects.bzl", "selects")

copts = selects.with_or({
    (":is_prod", ":is_staging"): ["-DDEPLOYED"],
    "//conditions:default": [],
})
```

A tuple key means OR. Use `config_setting_group` when the combination is reused;
`with_or` when it appears once.

## Key takeaway

`match_any` = OR, `match_all` = AND. Name your combinations rather than
duplicating conditions.
