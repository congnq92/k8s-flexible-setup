#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/init.sh"

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
readonly TEST_GROUP_SCRIPT='0-test-group.sh'
readonly TOPOLOGY_OPTIONS=(
    '0 -   | 0 Test | Test group'
    '1 VPS | VPS 1 | Control-plane + Worker + NGINX Ingress'
    '2 VPS | VPS 1 | Control-plane + Worker + NGINX Ingress'
    '2 VPS | VPS 2 | Worker'
    '3 VPS | VPS 1 | Control-plane + Worker + NGINX Ingress'
    '3 VPS | VPS 2 | Control-plane + Worker + NGINX Ingress'
    '3 VPS | VPS 3 | Control-plane + Worker'
)
readonly MENU_DIVIDER='─────────────────────────────────'
readonly MENU_SWITCH_MODE='2. Switch mode: Dev | Prod'
readonly MENU_EXIT='3. Exit'

for group_script in "${TEST_GROUP_SCRIPT}" "${CONTROL_PLANE_SCRIPT}" "${WORKER_SCRIPT}" "${NGINX_INGRESS_SCRIPT}"; do
    [[ -x "${APP_PATH}/scripts/groups/${group_script}" ]] || fail "Required group script not found: ${group_script}"
done

while true; do
    mode="$(devModeGet)"
    gum style --border double --padding '0 1' --margin '1 0' 'K8s Flexible Setup' "Mode: ${mode}" "Working dir: ${APP_PATH}" "Branch: ${BRANCH}"
    selected_item="$(gum choose --header $'1. Select one VPS row, then press Enter\n  Case  | VPS   | Groups to select\n  ------+-------+-----------------' "${TOPOLOGY_OPTIONS[@]}" "${MENU_DIVIDER}" "${MENU_SWITCH_MODE}" "${MENU_EXIT}")"

    case "${selected_item}" in
        "${MENU_DIVIDER}")
            continue
            ;;
        "${MENU_SWITCH_MODE}")
            gum log --level info "Mode switched to $(devModeSwitch)."
            continue
            ;;
        "${MENU_EXIT}")
            exit 0
            ;;
    esac

    [[ -n "${selected_item}" ]] || continue
    declare -a planned_runs=()

    while IFS='|' read -r selected_case selected_vps selected_groups; do
        selected_vps="${selected_vps# }"
        selected_vps="${selected_vps% }"
        selected_groups="${selected_groups# }"
        selected_groups="${selected_groups% }"

        if [[ "${selected_groups}" == 'Test group' ]]; then
            planned_runs+=("${TEST_GROUP_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Control-plane'* ]]; then
            planned_runs+=("${CONTROL_PLANE_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Worker'* ]]; then
            planned_runs+=("${WORKER_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'NGINX Ingress'* ]]; then
            planned_runs+=("${NGINX_INGRESS_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi
    done <<<"${selected_item}"

    mapfile -t ordered_runs < <(printf '%s\n' "${planned_runs[@]}" | sort)
    gum style --bold 'Scripts to run in order:'
    for planned_run in "${ordered_runs[@]}"; do
        printf '%s\n' "${planned_run%% | *}"
    done

    gum confirm 'Confirm to run these script(s) (1/2)?' >/dev/null || continue
    gum confirm 'Confirm to run these script(s) (2/2)?' >/dev/null || continue

    for planned_run in "${ordered_runs[@]}"; do
        selected_script="${planned_run%% | *}"
        devModeRunScript "${APP_PATH}/scripts/groups/${selected_script}"
    done
done
