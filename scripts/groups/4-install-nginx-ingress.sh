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

readonly INGRESS_NGINX_VERSION="${INGRESS_NGINX_VERSION:-v1.15.1}"
readonly KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/kubernetes/admin.conf}"
readonly INGRESS_NGINX_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${INGRESS_NGINX_VERSION}/deploy/static/provider/baremetal/deploy.yaml"

[[ "${EUID}" -eq 0 ]] || {
    printf 'ERROR: Run this script with sudo or as root.\n' >&2
    exit 1
}
command -v kubectl >/dev/null 2>&1 || {
    printf 'ERROR: Required command not found: kubectl\n' >&2
    exit 1
}
[[ -r "${KUBECONFIG_PATH}" ]] || {
    printf 'ERROR: Kubernetes admin kubeconfig not found: %s\n' "${KUBECONFIG_PATH}" >&2
    exit 1
}

printf '==> Installing ingress-nginx %s\n' "${INGRESS_NGINX_VERSION}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f "${INGRESS_NGINX_MANIFEST_URL}"

printf '==> Binding ingress-nginx to VPS ports 80 and 443\n'
kubectl --kubeconfig "${KUBECONFIG_PATH}" --namespace ingress-nginx patch deployment ingress-nginx-controller \
    --type merge \
    --patch='{"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}'

external_ips="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" --namespace ingress-nginx get service ingress-nginx-controller -o jsonpath='{.spec.externalIPs}')"
if [[ -n "${external_ips}" ]]; then
    printf '==> Removing obsolete ingress-nginx external IP configuration\n'
    kubectl --kubeconfig "${KUBECONFIG_PATH}" --namespace ingress-nginx patch service ingress-nginx-controller \
        --type=json \
        --patch='[{"op":"remove","path":"/spec/externalIPs"}]'
fi

kubectl --kubeconfig "${KUBECONFIG_PATH}" rollout status deployment/ingress-nginx-controller \
    --namespace ingress-nginx \
    --timeout=5m

printf '==> NGINX Ingress installed successfully\n'
