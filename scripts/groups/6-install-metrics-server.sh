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
readonly METRICS_SERVER_MANIFEST_URL="${METRICS_SERVER_MANIFEST_URL:-https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml}"

require_root
require_command kubectl
[[ -r "${KUBECONFIG_PATH}" ]] || fail "Kubernetes admin kubeconfig not found: ${KUBECONFIG_PATH}"

log 'Installing Metrics Server'
kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f "${METRICS_SERVER_MANIFEST_URL}"

metrics_args="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" --namespace kube-system get deployment metrics-server -o jsonpath='{.spec.template.spec.containers[0].args[*]}')"
if [[ " ${metrics_args} " != *' --kubelet-insecure-tls '* ]]; then
    kubectl --kubeconfig "${KUBECONFIG_PATH}" --namespace kube-system patch deployment metrics-server \
        --type=json \
        --patch='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi

kubectl --kubeconfig "${KUBECONFIG_PATH}" rollout status deployment/metrics-server \
    --namespace kube-system \
    --timeout=5m

uiPrintSuccess 'Metrics Server installed successfully'
