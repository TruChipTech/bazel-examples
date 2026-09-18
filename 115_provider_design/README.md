# 115 - Designing Providers

**Concepts:** `init` callbacks, derived fields, API evolution

## Run it

```bash
bazel build //115_provider_design:all
cat bazel-bin/115_provider_design/libfoo.version
cat bazel-bin/115_provider_design/check_foo.check
```

Then uncomment the `invalid` target to see the init callback reject it.

## The `init` callback

```python
def _version_info_init(*, major, minor, patch = 0, label = None):
    if major < 0:
        fail("version components must be non-negative")
    return {"major": major, ..., "string": "%d.%d.%d" % (major, minor, patch)}

VersionInfo, _new_version_info = provider(
    fields = {...},
    init = _version_info_init,
)
```

The callback runs whenever the provider is constructed. It gives you:

1. **Validation** at construction, so no consumer ever sees a malformed value.
2. **Normalization** - defaults filled in consistently.
3. **Derived fields** computed once instead of in every consumer.

The second return value is the raw constructor that bypasses the callback.
Keep it private (`_new_version_info`) so nothing outside the file can skip
validation.

## Design guidelines

**Use `depset` for anything transitive.**
```python
fields = {"transitive_srcs": "depset of File"}    # not a list
```
Lists of transitive data are O(n²) to accumulate (sample 116).

**Document every field.** The `fields` dict is your reference documentation and
it also restricts which fields may be set - a typo becomes an error.

**Keep providers narrow.** One provider per concern beats one provider with
twenty optional fields.

**Providers are immutable.** Construct a new one rather than trying to modify.

## Evolving a provider

Adding a field is safe. Removing or renaming one breaks every consumer, and
unlike a normal API you cannot deprecate gradually - there is no overload
mechanism. The usual migration is:

1. Add the new field alongside the old one, populated by the `init` callback.
2. Migrate consumers.
3. Remove the old field.

Designing the `fields` dict carefully up front is worth the time.

## Key takeaway

Use an `init` callback for validation and derived fields. Document every field,
prefer `depset` for transitive data, and keep the raw constructor private.
