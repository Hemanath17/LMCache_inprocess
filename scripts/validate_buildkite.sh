#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if [[ -n "${PYTHON:-}" ]]; then
  python_bin="${PYTHON}"
elif command -v python3.12 >/dev/null 2>&1; then
  python_bin="$(command -v python3.12)"
else
  python_bin="$(command -v python3)"
fi

while IFS= read -r -d '' script; do
  bash -n "${script}"
done < <(find .buildkite scripts -type f -name '*.sh' -print0)

"${python_bin}" - <<'PY'
from pathlib import Path

import yaml

for path in sorted(Path('.buildkite').rglob('*.yml')) + sorted(
    Path('.buildkite').rglob('*.yaml')
):
    with path.open(encoding='utf-8') as stream:
        yaml.safe_load(stream)
    print(f'validated YAML: {path}')
PY

if rg -n '"kv_connector":"LMCacheConnectorV1"|lmcache\.integration\.vllm\.lmcache_connector_v1' .buildkite; then
  echo "Buildkite files contain an implicit or core-owned InProcess connector" >&2
  exit 1
fi

for bootstrap in \
  .buildkite/k3_tests/integration/buildkite-pipeline.yml \
  .buildkite/k3_tests/correctness/buildkite-pipeline.yml \
  .buildkite/k3_tests/comprehensive/buildkite-pipeline.yml; do
  test -s "${bootstrap}"
done

echo "Buildkite static validation passed"
