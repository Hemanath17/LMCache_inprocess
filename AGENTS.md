# LMCache InProcess contributor guidance

## Package boundary

- The distribution name is `lmcache_inprocess`, while its import namespace is
  `lmcache.inprocess` for compatibility with existing integrations.
- This repository owns `lmcache/inprocess/**`, `docs/source/legacy/**`, plus the
  single compatibility shim `lmcache/integration/vllm/vllm_v1_adapter.py` required by vLLM's
  canonical connector import. Do not add `lmcache/__init__.py` or copy shared
  `lmcache/v1/**` modules; those belong to the `lmcache` dependency.
- Native extensions are built and shipped by LMCache. This project must remain
  a pure-Python wheel.
- `NO_NATIVE_EXT=1` LMCache builds are CLI-only and do not define the
  `device_ops` required by the in-process connector. Use `NO_GPU_EXT=1` for
  CPU-only packaging and smoke validation so the common native extension is
  present.
- Record every imported upstream snapshot in `UPSTREAM_REVISION` and keep its
  dependency lower bound synchronized with the first compatible LMCache
  release.
- `scripts/sync_from_lmcache.sh` must accept both ordinary clones and linked
  Git worktrees. Detect a repository with `git rev-parse`; do not assume that
  `<upstream>/.git` is a directory.

## Validation

- Build with `python -m build` and validate with `python -m twine check dist/*`.
- Inspect wheel contents and verify that they contain `lmcache/inprocess/**`
  plus only the explicitly allowed vLLM compatibility shim outside that tree.
- Run `python -m pytest -q tests/smoke` after installing a compatible LMCache
  build. Accelerator-specific tests belong on the matching self-hosted runner.
- For H200 builds of the LMCache dependency, use
  `TORCH_CUDA_ARCH_LIST=9.0 MAX_JOBS=1` unless broader targets are required.
- `vllm/vllm-openai:latest` starts `vllm serve`; use `--entrypoint bash` for
  build and debug containers.
- For an InProcess-specific vLLM E2E, do not rely only on the registered
  `LMCacheConnectorV1` name: current vLLM resolves that name through its own
  wrapper module. Set `kv_connector` to `LMCacheConnectorV1Dynamic` and
  `kv_connector_module_path` to
  `lmcache.inprocess.integration.vllm.lmcache_connector_v1`, then require the
  log to show that exact module path, a non-zero `LMCache hit tokens` value on
  the second request, and no `LMCacheMPConnector` creation.

## Contributions

- Python files require an SPDX Apache-2.0 header.
- Commits must include a `Signed-off-by` trailer.
- Run `pre-commit run --all-files` before push. On macOS, document the
  Linux-only Rust limitation inherited from LMCache if Rust validation is
  relevant; this repository itself contains no Rust sources.
