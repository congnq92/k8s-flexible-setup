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
readonly CNI_SCRIPT='3-install-cni.sh'
readonly NGINX_INGRESS_SCRIPT='4-install-nginx-ingress.sh'
readonly LOCAL_STORAGE_SCRIPT='5-install-local-storage.sh'
readonly METRICS_SERVER_SCRIPT='6-install-metrics-server.sh'
readonly ADMIN_TOOLS_SCRIPT='7-install-admin-tools.sh'
readonly ADMIN_JOIN_WORKER_SCRIPT='1-join-worker.sh'
readonly TOPOLOGY_OPTIONS=(
    '1 VPS | VPS 1 | Control-plane + Worker + CNI + NGINX Ingress + Local Storage + Metrics Server + Admin Tools'
    '2 VPS | VPS 1 | Control-plane + Worker + CNI + NGINX Ingress + Local Storage + Metrics Server + Admin Tools'
    '2 VPS | VPS 2 | Worker'
    '3 VPS | VPS 1 | Control-plane + Worker + CNI + NGINX Ingress + Local Storage + Metrics Server + Admin Tools'
    '3 VPS | VPS 2 | Control-plane + Worker + NGINX Ingress'
    '3 VPS | VPS 3 | Control-plane + Worker'
)
readonly MENU_DIVIDER='─────────────────────────────────'
readonly MENU_ADMIN_JOIN_WORKER='2.1 Join worker node'
readonly MENU_SWITCH_MODE='3.1 Switch mode: Dev | Prod'
readonly MENU_EXIT='3.2 Exit'

for group_script in "${CONTROL_PLANE_SCRIPT}" "${WORKER_SCRIPT}" "${CNI_SCRIPT}" "${NGINX_INGRESS_SCRIPT}" "${LOCAL_STORAGE_SCRIPT}" "${METRICS_SERVER_SCRIPT}" "${ADMIN_TOOLS_SCRIPT}"; do
    [[ -x "${APP_PATH}/scripts/groups/${group_script}" ]] || fail "Required group script not found: ${group_script}"
done
[[ -x "${APP_PATH}/scripts/admin/${ADMIN_JOIN_WORKER_SCRIPT}" ]] || fail "Required admin script not found: ${ADMIN_JOIN_WORKER_SCRIPT}"

while true; do
    mode="$(devModeGet)"
    gum style --border double --padding '0 1' --margin '1 0' 'K8s Flexible Setup' "Mode: ${mode}" "Working dir: ${APP_PATH}" "Branch: ${BRANCH}"
    selected_item="$(gum choose --header $'1.1 Select one VPS row, then press Enter\n  Case  | VPS   | Groups to select\n  ------+-------+-----------------' "${TOPOLOGY_OPTIONS[@]}" "${MENU_DIVIDER}" "${MENU_ADMIN_JOIN_WORKER}" "${MENU_DIVIDER}" "${MENU_SWITCH_MODE}" "${MENU_EXIT}")"

    case "${selected_item}" in
        "${MENU_DIVIDER}")
            continue
            ;;
        "${MENU_ADMIN_JOIN_WORKER}")
            gum style --bold 'Admin script to run:'
            printf '%s\n' "${ADMIN_JOIN_WORKER_SCRIPT}"
            gum confirm 'Confirm to run this script (1/2)?' >/dev/null || continue
            gum confirm 'Confirm to run this script (2/2)?' >/dev/null || continue
            devModeRunScript "${APP_PATH}/scripts/admin/${ADMIN_JOIN_WORKER_SCRIPT}"
            printf '%s\n' "${MENU_DIVIDER}"
            gum log --level info 'Admin script completed.'
            gum log --level info 'To open the app again, run the installer script again.'
            exit 0
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

        if [[ "${selected_groups}" == *'Control-plane'* ]]; then
            planned_runs+=("${CONTROL_PLANE_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Worker'* ]]; then
            planned_runs+=("${WORKER_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'CNI'* ]]; then
            planned_runs+=("${CNI_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'NGINX Ingress'* ]]; then
            planned_runs+=("${NGINX_INGRESS_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Local Storage'* ]]; then
            planned_runs+=("${LOCAL_STORAGE_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Metrics Server'* ]]; then
            planned_runs+=("${METRICS_SERVER_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Admin Tools'* ]]; then
            planned_runs+=("${ADMIN_TOOLS_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi
    done <<<"${selected_item}"

    mapfile -t ordered_scripts < <(printf '%s\n' "${planned_runs[@]}" | cut -d '|' -f 1 | sed 's/[[:space:]]*$//' | sort -u)
    gum style --bold 'Scripts to run in order:'
    for selected_script in "${ordered_scripts[@]}"; do
        printf '%s\n' "${selected_script}"
    done

    gum confirm 'Confirm to run these script(s) (1/2)?' >/dev/null || continue
    gum confirm 'Confirm to run these script(s) (2/2)?' >/dev/null || continue

    for selected_script in "${ordered_scripts[@]}"; do
        devModeRunScript "${APP_PATH}/scripts/groups/${selected_script}"
    done

    printf '%s\n' "${MENU_DIVIDER}"
    gum log --level info 'Selected group scripts completed.'
    gum log --level info 'To open the app again, run the installer script again.'
    exit 0
done
