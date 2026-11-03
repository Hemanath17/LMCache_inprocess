#!/usr/bin/env bash
# Decide whether an InProcess K3 pipeline is relevant to the current change.
set -uo pipefail

_path_filter_is_trivial() {
    case "$1" in
        *.md|LICENSE|LICENSE.*|NOTICE|NOTICE.*|.gitignore|.gitattributes|docs/*|.github/*)
            return 0
            ;;
    esac
    return 1
}

_path_filter_pipeline_kind() {
    case "$1" in
        *k3_tests/integration/pipeline.yml) echo integration ;;
        *k3_tests/correctness/pipeline.yml) echo correctness ;;
        *k3_tests/comprehensive/pipeline.yml) echo comprehensive ;;
        *) echo generic ;;
    esac
}

_path_filter_is_relevant() {
    local pipeline_kind="$1"
    local changed_file="$2"

    # Package, dependency, and shared harness changes affect every pipeline.
    case "${changed_file}" in
        lmcache/inprocess/*|lmcache/integration/vllm/*|pyproject.toml|UPSTREAM_REVISION|requirements/*|scripts/install_ci_dependencies.sh|.buildkite/k3_harness/*|.buildkite/k3_tests/common_scripts/*)
            return 0
            ;;
    esac

    case "${pipeline_kind}:${changed_file}" in
        integration:.buildkite/k3_tests/integration/*)
            return 0
            ;;
        correctness:.buildkite/k3_tests/correctness/*)
            return 0
            ;;
        comprehensive:.buildkite/configs/*|comprehensive:.buildkite/k3_tests/comprehensive/*|comprehensive:benchmarks/*|comprehensive:examples/inprocess/disagg_prefill/*)
            return 0
            ;;
        *:.buildkite/k3_tests/*|*:tests/*|*:examples/*)
            return 1
            ;;
    esac

    # Unknown non-trivial files run the pipeline rather than risking a false skip.
    return 0
}

_path_filter_get_changed_files() {
    local base_branch base merge_base

    if [[ -n "${BUILDKITE_PULL_REQUEST:-}" && "${BUILDKITE_PULL_REQUEST:-}" != "false" ]]; then
        base_branch="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-main}"
        git fetch --no-tags --depth=200 origin "${base_branch}" 2>/dev/null || \
            git fetch --no-tags origin "${base_branch}" 2>/dev/null || true
        if base="$(git rev-parse --verify "origin/${base_branch}" 2>/dev/null)"; then
            if merge_base="$(git merge-base HEAD "${base}" 2>/dev/null)"; then
                git diff --name-only "${merge_base}" HEAD
            else
                git diff --name-only "${base}" HEAD
            fi
            return 0
        fi
        return 1
    fi

    if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        git diff --name-only HEAD~1 HEAD
        return 0
    fi
    return 1
}

should_skip_ci() {
    local pipeline_file="${1:-}"
    local pipeline_kind changed_files

    if [[ ",${BUILDKITE_PULL_REQUEST_LABELS:-}," == *",force-ci,"* ]]; then
        echo "path-filter: force-ci label present; running" >&2
        return 1
    fi
    if [[ "${BUILDKITE_SOURCE:-}" == "schedule" ]]; then
        echo "path-filter: scheduled build; running" >&2
        return 1
    fi
    if ! changed_files="$(_path_filter_get_changed_files)" || [[ -z "${changed_files}" ]]; then
        echo "path-filter: could not determine changes; running" >&2
        return 1
    fi

    pipeline_kind="$(_path_filter_pipeline_kind "${pipeline_file}")"
    while IFS= read -r changed_file; do
        [[ -z "${changed_file}" ]] && continue
        if _path_filter_is_trivial "${changed_file}"; then
            echo "  [trivial] ${changed_file}" >&2
        elif _path_filter_is_relevant "${pipeline_kind}" "${changed_file}"; then
            echo "  [relevant] ${changed_file}" >&2
            return 1
        else
            echo "  [unrelated] ${changed_file}" >&2
        fi
    done <<< "${changed_files}"

    echo "path-filter: no relevant files changed for ${pipeline_kind}; skipping" >&2
    return 0
}
