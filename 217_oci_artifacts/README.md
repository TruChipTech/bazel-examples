# 217 - OCI Artifacts: Registries Store More Than Images

**Concepts:** `artifactType`, empty config, non-image payloads

## Run it

```bash
bazel build //217_oci_artifacts:sbom_artifact
python3 -m json.tool bazel-bin/217_oci_artifacts/sbom_layout/index.json
```

## An artifact is an image manifest wearing a different hat

```json
{
  "artifactType": "application/spdx+json",
  "config": {"mediaType": "application/vnd.oci.empty.v1+json", ...},
  "layers": [{"mediaType": "application/spdx+json", "digest": "sha256:..."}]
}
```

Same manifest structure, same blob store, same digests. What changes is
`artifactType` and the media types - which tell a client "this is not a
filesystem, do not try to run it".

The config is the spec's **empty descriptor**: the two bytes `{}`. Artifacts
have no runtime configuration, but the field is required.

## Why this matters

It means your registry is already a general-purpose, content-addressed,
authenticated artifact store. Things that ship this way in practice:

| Payload | artifactType |
|---------|--------------|
| Signatures | `application/vnd.dev.cosign.simplesigning.v1+json` |
| SBOMs | `application/spdx+json`, `application/vnd.cyclonedx+json` |
| SLSA attestations | `application/vnd.in-toto+json` |
| Helm charts | `application/vnd.cncf.helm.chart.content.v1.tar+gzip` |
| WASM modules | `application/wasm` |

No separate storage, no separate auth, no separate lifecycle - the SBOM lives
next to the image it describes and is garbage-collected with it.

## Linking it to an image

On its own this artifact floats free. The `subject` field attaches it to a
specific image digest, which is how "show me the SBOM for this image" works -
sample 218.

## Key takeaway

An artifact is a manifest with `artifactType` and an empty config. Registries
are artifact stores that happen to be good at images.
