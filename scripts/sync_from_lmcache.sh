#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /path/to/LMCache" >&2
  exit 2
fi

upstream_root="$(cd "$1" && pwd)"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -d "${upstream_root}/.git" || ! -d "${upstream_root}/lmcache/inprocess" ]]; then
  echo "not an LMCache checkout: ${upstream_root}" >&2
  exit 2
fi

revision="$(git -C "${upstream_root}" rev-parse HEAD)"
ref="$(git -C "${upstream_root}" branch --show-current)"

rsync -a --delete --exclude='__pycache__' --exclude='*.pyc' \
  "${upstream_root}/lmcache/inprocess/" "${repo_root}/lmcache/inprocess/"
rsync -a --delete --exclude='__pycache__' --exclude='*.pyc' \
  "${upstream_root}/tests/inprocess/" "${repo_root}/tests/inprocess/"
rsync -a --delete \
  "${upstream_root}/examples/inprocess/" "${repo_root}/examples/inprocess/"
rsync -a --delete \
  "${upstream_root}/benchmarks/inprocess/" "${repo_root}/benchmarks/inprocess/"
rsync -a --delete \
  "${upstream_root}/docs/source/legacy/" "${repo_root}/docs/source/legacy/"

python3 - "${repo_root}/UPSTREAM_REVISION" "${revision}" "${ref}" <<'PY'
from datetime import date
from pathlib import Path
import sys

path = Path(sys.argv[1])
path.write_text(
    "repository=https://github.com/LMCache/LMCache\n"
    f"revision={sys.argv[2]}\n"
    f"ref={sys.argv[3]}\n"
    f"copied_at={date.today().isoformat()}\n",
    encoding="utf-8",
)
PY

echo "Synced LMCache ${revision} (${ref})"
