#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

run_privileged() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install Gum.'
        sudo "$@"
    fi
}

ensure_gum() {
    if command -v gum >/dev/null 2>&1; then
        return
    fi

    [[ -r /etc/os-release ]] || fail 'Gum is not installed. Install Gum manually, then run this script again.'
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID}" == 'debian' || "${ID}" == 'ubuntu' ]] || fail 'Gum is not installed. This installer can install Gum only on Debian or Ubuntu.'

    printf '==> Installing Gum\n'
    run_privileged install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | run_privileged gpg --dearmor --yes --output /etc/apt/keyrings/charm.gpg
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' | run_privileged tee /etc/apt/sources.list.d/charm.list >/dev/null
    run_privileged apt-get update
    run_privileged apt-get install -y gum
}

ensure_gum

readonly CONTROL_PLANE_SCRIPT='1-install-control-plane.sh'
readonly WORKER_SCRIPT='2-install-worker.sh'
readonly NGINX_INGRESS_SCRIPT='3-install-nginx-ingress.sh'
readonly TOPOLOGY_OPTIONS=(
    '1 VPS | VPS 1 | Control-plane + Worker + NGINX Ingress'
    '2 VPS | VPS 1 | Control-plane + Worker + NGINX Ingress'
    '2 VPS | VPS 2 | Worker'
    '3 VPS | VPS 1 | Control-plane + Worker + NGINX Ingress'
    '3 VPS | VPS 2 | Control-plane + Worker + NGINX Ingress'
    '3 VPS | VPS 3 | Control-plane + Worker'
)

for group_script in "${CONTROL_PLANE_SCRIPT}" "${WORKER_SCRIPT}" "${NGINX_INGRESS_SCRIPT}"; do
    [[ -x "${SCRIPT_DIR}/groups/${group_script}" ]] || fail "Required group script not found: ${group_script}"
done

while true; do
    gum style --border double --padding '1 2' --margin '1 0' 'K8s Flexible Setup'
    selected_rows="$(gum choose --header $'Select one VPS row, then press Enter\n  Case  | VPS   | Groups to select\n  ------+-------+-----------------' "${TOPOLOGY_OPTIONS[@]}")"

    [[ -n "${selected_rows}" ]] || continue
    declare -a planned_runs=()

    while IFS='|' read -r selected_case selected_vps selected_groups; do
        selected_vps="${selected_vps# }"
        selected_vps="${selected_vps% }"
        selected_groups="${selected_groups# }"
        selected_groups="${selected_groups% }"

        if [[ "${selected_groups}" == *'Control-plane'* ]]; then
            planned_runs+=("${CONTROL_PLANE_SCRIPT} | ${selected_case} | ${selected_vps}")
        elif [[ "${selected_groups}" == *'Worker'* ]]; then
            planned_runs+=("${WORKER_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'NGINX Ingress'* ]]; then
            planned_runs+=("${NGINX_INGRESS_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi
    done <<<"${selected_rows}"

    mapfile -t ordered_runs < <(printf '%s\n' "${planned_runs[@]}" | sort)
    gum style --bold 'Scripts to run in order:'
    printf '%s\n' "${ordered_runs[@]}"

    gum confirm 'Confirm to run these script(s) (1/2)?' >/dev/null || continue
    gum confirm 'Confirm to run these script(s) (2/2)?' >/dev/null || continue

    for planned_run in "${ordered_runs[@]}"; do
        selected_script="${planned_run%% | *}"
        "${SCRIPT_DIR}/groups/${selected_script}"
    done
done

# todo: check scripts to run is incorrect, then run script 1 time, notify done and remind user if they want to run installer again, run the install.sh script from repository