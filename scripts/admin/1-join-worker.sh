#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/lib-init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/lib-init.sh"
# shellcheck source=../modules/dev/dev.module.sh
importModule 'dev'
# shellcheck source=../modules/ui/ui.module.sh
importModule 'ui'
uiShowScriptHeader "${BASH_SOURCE[0]}"
devModeExitIfEnabled "${BASH_SOURCE[0]}"

readonly KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/kubernetes/admin.conf}"

require_root
require_command gum
require_command kubeadm
require_command kubectl
[[ -r "${KUBECONFIG_PATH}" ]] || fail "Kubernetes admin kubeconfig not found: ${KUBECONFIG_PATH}"

mapfile -t existing_nodes < <(kubectl --kubeconfig "${KUBECONFIG_PATH}" get nodes -o name | sort)
join_command="sudo $(kubeadm token create --print-join-command)"

gum style --bold 'Run this command on the worker node:'
printf '\n%s\n\n' "${join_command}"
gum input --header 'After the worker join command finishes, press Enter to verify the new node.' >/dev/null

mapfile -t current_nodes < <(kubectl --kubeconfig "${KUBECONFIG_PATH}" get nodes -o name | sort)
mapfile -t new_nodes < <(comm -13 <(printf '%s\n' "${existing_nodes[@]}") <(printf '%s\n' "${current_nodes[@]}"))

((${#new_nodes[@]} > 0)) || fail 'No new worker node was found. Run the printed join command on the worker, then run this script again.'

if ! workload_group_index="$(networkWorkloadGroupIndexGet)"; then
    workload_group_index=1
    networkWorkloadGroupIndexSave "${workload_group_index}"
    uiPrintInfo 'Workload group state initialized: group-1'
fi

for new_node in "${new_nodes[@]}"; do
    workload_group_index=$((workload_group_index + 1))
    workload_group_value="group-${workload_group_index}"

    log "Waiting for ${new_node} to become Ready"
    kubectl --kubeconfig "${KUBECONFIG_PATH}" wait --for=condition=Ready "${new_node}" --timeout=5m
    log "Labeling ${new_node} as a worker"
    kubectl --kubeconfig "${KUBECONFIG_PATH}" label "${new_node}" node-role.kubernetes.io/worker= --overwrite
    uiPrintInfo "Worker role label applied: ${new_node}"
    log "Labeling ${new_node} with ${WORKLOAD_GROUP_LABEL}=${workload_group_value}"
    kubectl --kubeconfig "${KUBECONFIG_PATH}" label "${new_node}" "${WORKLOAD_GROUP_LABEL}=${workload_group_value}" --overwrite
    networkWorkloadGroupIndexSave "${workload_group_index}"
    uiPrintInfo "Workload group label applied: ${new_node} -> ${WORKLOAD_GROUP_LABEL}=${workload_group_value}"
done

uiPrintSuccess 'New worker node is Ready'
