# LMCache InProcess Buildkite pipelines

This directory owns the accelerator pipelines that moved out of the LMCache
core repository with the InProcess implementation. The pipelines test the
current `lmcache_inprocess` checkout against the exact LMCache commit recorded
in `UPSTREAM_REVISION`.

## Pipelines

| Pipeline | Bootstrap file | Purpose | GPU |
| --- | --- | --- | --- |
| Integration | `k3_tests/integration/buildkite-pipeline.yml` | Two-request CPU and disk backend smoke tests | 1 |
| Correctness | `k3_tests/correctness/buildkite-pipeline.yml` | Baseline-vs-InProcess output comparison | 1 |
| Comprehensive | `k3_tests/comprehensive/buildkite-pipeline.yml` | Configuration matrix, performance checks, PD, and P2P | 1 or 2 |

For each Buildkite pipeline, copy the corresponding bootstrap file into the
Buildkite **Steps** editor. The bootstrap performs path filtering and uploads
the full repository-owned pipeline.

The jobs expect the existing LMCache K3 environment:

- agent queue `k8s`;
- Kubernetes plugin access;
- image `lmcache/ci-base:latest` preloaded on the nodes;
- `/data/huggingface` for the Hugging Face cache;
- `/data/datasets` for correctness data;
- `HF_TOKEN` for gated models when needed.

## Dependency boundary

`k3_harness/setup-env.sh` installs vLLM, then invokes
`scripts/install_ci_dependencies.sh`. That helper installs LMCache from the
40-character commit in `UPSTREAM_REVISION`, followed by the current
`lmcache_inprocess` checkout. It never treats this repository as the LMCache
core source tree.

Every vLLM launch uses `LMCacheConnectorV1Dynamic` with
`kv_connector_module_path=lmcache.inprocess.integration.vllm.lmcache_connector_v1`.
This prevents vLLM's built-in wrapper from silently selecting a different
connector implementation.

## Local static validation

The pipeline definitions can be checked without a Buildkite agent:

```bash
bash scripts/validate_buildkite.sh
```

GPU execution still requires the Buildkite K3 runners described above.
