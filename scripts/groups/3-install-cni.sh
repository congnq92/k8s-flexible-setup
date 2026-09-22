#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/lib-init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/lib-init.sh"
# shellcheck source=../modules/dev/dev.module.sh
importModule 'dev'
# shellcheck source=../modules/ui/ui.module.sh
importModule 'ui'
# shellcheck source=../config/config.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../config/config.sh"
uiShowScriptHeader "${BASH_SOURCE[0]}"
devModeExitIfEnabled "${BASH_SOURCE[0]}"

readonly KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/kubernetes/admin.conf}"
readonly FLANNEL_MANIFEST_URL="${FLANNEL_MANIFEST_URL:-https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml}"

require_root
require_command kubectl
[[ -r "${KUBECONFIG_PATH}" ]] || fail "Kubernetes admin kubeconfig not found: ${KUBECONFIG_PATH}"

local_node_pod_cidr="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" get node "$(hostname)" -o jsonpath='{.spec.podCIDR}')"
if [[ "${local_node_pod_cidr}" != "${POD_NETWORK_CIDR}" ]]; then
    fail $'Flannel requires Pod network CIDR 10.244.0.0/16.\nThis cluster was initialized without it. Reset this new cluster,\nthen run Install groups again.'
fi

log 'Installing Flannel CNI'
kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f "${FLANNEL_MANIFEST_URL}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" rollout status daemonset/kube-flannel-ds \
    --namespace kube-flannel \
    --timeout=5m

log 'CNI installed successfully'
