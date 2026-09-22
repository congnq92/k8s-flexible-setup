#!/usr/bin/env bash

readonly CONTROL_PLANE_SCRIPT='1-install-control-plane.sh'
readonly CONTROL_PLANE_WORKER_SCRIPT='2-1-install-worker-for-control-plane-node.sh'
readonly DEDICATED_WORKER_SCRIPT='2-2-install-worker-dedicated.sh'
readonly CNI_SCRIPT='3-install-cni.sh'
readonly NGINX_INGRESS_SCRIPT='4-install-nginx-ingress.sh'
readonly LOCAL_STORAGE_SCRIPT='5-install-local-storage.sh'
readonly METRICS_SERVER_SCRIPT='6-install-metrics-server.sh'
readonly ADMIN_TOOLS_SCRIPT='7-install-admin-tools.sh'
readonly GROUP_SERVICE_TOPOLOGY_OPTIONS=(
    '1 VPS | VPS 1 | Control-plane + Worker for Control-plane Node + CNI + NGINX Ingress + Local Storage + Metrics Server + Admin Tools'
    '2 VPS | VPS 1 | Control-plane + Worker for Control-plane Node + CNI + NGINX Ingress + Local Storage + Metrics Server + Admin Tools'
    '2 VPS | VPS 2 | Dedicated Worker'
    '3 VPS | VPS 1 | Control-plane + Worker for Control-plane Node + CNI + NGINX Ingress + Local Storage + Metrics Server + Admin Tools'
    '3 VPS | VPS 2 | Control-plane + Worker for Control-plane Node + NGINX Ingress'
    '3 VPS | VPS 3 | Control-plane + Worker for Control-plane Node'
)

declare -a GROUP_SERVICE_PLANNED_SCRIPTS=()

groupServiceValidate() {
    local group_script

    for group_script in "${CONTROL_PLANE_SCRIPT}" "${CONTROL_PLANE_WORKER_SCRIPT}" "${DEDICATED_WORKER_SCRIPT}" "${CNI_SCRIPT}" "${NGINX_INGRESS_SCRIPT}" "${LOCAL_STORAGE_SCRIPT}" "${METRICS_SERVER_SCRIPT}" "${ADMIN_TOOLS_SCRIPT}"; do
        [[ -x "${APP_PATH}/scripts/groups/${group_script}" ]] || fail "Required group script not found: ${group_script}"
    done
}

groupServicePlan() {
    local selected_item="$1"
    local selected_case
    local selected_vps
    local selected_groups

    GROUP_SERVICE_PLANNED_SCRIPTS=()

    while IFS='|' read -r selected_case selected_vps selected_groups; do
        selected_vps="${selected_vps# }"
        selected_vps="${selected_vps% }"
        selected_groups="${selected_groups# }"
        selected_groups="${selected_groups% }"

        if [[ "${selected_groups}" == *'Control-plane'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${CONTROL_PLANE_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Worker for Control-plane Node'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${CONTROL_PLANE_WORKER_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Dedicated Worker'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${DEDICATED_WORKER_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'CNI'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${CNI_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'NGINX Ingress'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${NGINX_INGRESS_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Local Storage'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${LOCAL_STORAGE_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Metrics Server'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${METRICS_SERVER_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi

        if [[ "${selected_groups}" == *'Admin Tools'* ]]; then
            GROUP_SERVICE_PLANNED_SCRIPTS+=("${ADMIN_TOOLS_SCRIPT} | ${selected_case} | ${selected_vps}")
        fi
    done <<<"${selected_item}"

    mapfile -t GROUP_SERVICE_PLANNED_SCRIPTS < <(printf '%s\n' "${GROUP_SERVICE_PLANNED_SCRIPTS[@]}" | cut -d '|' -f 1 | sed 's/[[:space:]]*$//' | sort -u)
}

groupServiceRunPlan() {
    local selected_script

    for selected_script in "${GROUP_SERVICE_PLANNED_SCRIPTS[@]}"; do
        devModeRunScript "${APP_PATH}/scripts/groups/${selected_script}"
    done
}
