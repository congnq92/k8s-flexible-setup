#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../init.sh"
devModeExitIfEnabled "${BASH_SOURCE[0]}"

readonly KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/kubernetes/admin.conf}"
readonly LOCAL_PATH_PROVISIONER_VERSION="${LOCAL_PATH_PROVISIONER_VERSION:-v0.0.32}"
readonly LOCAL_PATH_PROVISIONER_MANIFEST_URL="https://raw.githubusercontent.com/rancher/local-path-provisioner/${LOCAL_PATH_PROVISIONER_VERSION}/deploy/local-path-storage.yaml"

require_root
require_command kubectl
[[ -r "${KUBECONFIG_PATH}" ]] || fail "Kubernetes admin kubeconfig not found: ${KUBECONFIG_PATH}"

log "Installing local-path-provisioner ${LOCAL_PATH_PROVISIONER_VERSION}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f "${LOCAL_PATH_PROVISIONER_MANIFEST_URL}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" rollout status deployment/local-path-provisioner \
    --namespace local-path-storage \
    --timeout=5m
kubectl --kubeconfig "${KUBECONFIG_PATH}" patch storageclass local-path \
    --type merge \
    --patch '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

log 'Local storage installed successfully'
