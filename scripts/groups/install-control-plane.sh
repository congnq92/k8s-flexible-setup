#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly KUBERNETES_MINOR="$(get_kubernetes_minor)"

if [[ -f /etc/kubernetes/admin.conf ]]; then
    fail 'This host already has a Kubernetes control plane. Do not run kubeadm init again.'
fi

install_node_prerequisites "${KUBERNETES_MINOR}"

init_args=(init "--kubernetes-version=${KUBERNETES_MINOR}")

if [[ -n "${API_ADVERTISE_ADDRESS:-}" ]]; then
    init_args+=("--apiserver-advertise-address=${API_ADVERTISE_ADDRESS}")
fi

if [[ -n "${CONTROL_PLANE_ENDPOINT:-}" ]]; then
    init_args+=("--control-plane-endpoint=${CONTROL_PLANE_ENDPOINT}")
fi

if [[ -n "${POD_NETWORK_CIDR:-}" ]]; then
    init_args+=("--pod-network-cidr=${POD_NETWORK_CIDR}")
fi

log "Initializing the ${KUBERNETES_MINOR} control plane"
kubeadm "${init_args[@]}"

export KUBECONFIG=/etc/kubernetes/admin.conf

if [[ "${ALLOW_WORKLOADS_ON_CONTROL_PLANE:-false}" == 'true' ]]; then
    log 'Allowing workloads on the control-plane node'
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-
fi

log 'Control plane installed'
log 'Install a CNI plugin before expecting nodes and Pods to become Ready'
log 'Generate a short-lived worker join command when ready:'
printf 'sudo kubeadm token create --print-join-command\n'
