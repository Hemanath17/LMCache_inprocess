#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log_file="${1:-${repo_root}/vllm-e2e.log}"

export LMCACHE_CHUNK_SIZE="${LMCACHE_CHUNK_SIZE:-64}"
export LMCACHE_LOCAL_CPU="${LMCACHE_LOCAL_CPU:-True}"
export LMCACHE_MAX_LOCAL_CPU_SIZE="${LMCACHE_MAX_LOCAL_CPU_SIZE:-2}"
export LMCACHE_TRACK_USAGE="${LMCACHE_TRACK_USAGE:-false}"

python "${repo_root}/scripts/vllm_e2e.py" 2>&1 | tee "${log_file}"

grep -q 'LMCACHE_INPROCESS_E2E_REQUESTS_COMPLETED=2' "${log_file}"
if ! grep -Eq 'LMCache hit tokens: [1-9][0-9]*' "${log_file}"; then
  echo "second request did not report non-zero LMCache cached tokens" >&2
  exit 1
fi

echo "LMCache InProcess GPU end-to-end validation passed"
