#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if PROJECT_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null)"; then
    :
else
    PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
fi
readonly PROJECT_ROOT
readonly DEPLOYMENTS_DIR="${KFS_STATE_DIR:-${PROJECT_ROOT}/state}/deployments"

latest_plan="$(find "${DEPLOYMENTS_DIR}" -mindepth 2 -maxdepth 2 -name plan.yaml -type f -print 2>/dev/null | sort | tail -n 1 || true)"

if [[ -z "${latest_plan}" ]]; then
    gum log --level info 'No saved deployment plan was found.'
    exit 0
fi

gum pager <"${latest_plan}"

status_file="$(dirname -- "${latest_plan}")/status.yaml"
if [[ -f "${status_file}" ]]; then
    gum style --bold 'Deployment status'
    gum pager <"${status_file}"
fi
