#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/init-lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/init-lib.sh"
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
kubectl --kubeconfig "${KUBECONFIG_PATH}" rollout status deployment/ingress-nginx-controller \
    --namespace ingress-nginx \
    --timeout=5m

printf '==> NGINX Ingress installed successfully\n'
