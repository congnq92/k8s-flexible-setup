#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../init.sh"
devModeExitIfEnabled "${BASH_SOURCE[0]}"

readonly KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/kubernetes/admin.conf}"
readonly FLANNEL_MANIFEST_URL="${FLANNEL_MANIFEST_URL:-https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml}"

require_root
require_command kubectl
[[ -r "${KUBECONFIG_PATH}" ]] || fail "Kubernetes admin kubeconfig not found: ${KUBECONFIG_PATH}"

log 'Installing Flannel CNI'
kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f "${FLANNEL_MANIFEST_URL}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" rollout status daemonset/kube-flannel-ds \
    --namespace kube-flannel \
    --timeout=5m

log 'CNI installed successfully'
