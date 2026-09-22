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

networkEnsureConfiguration
readonly NODE_PRIVATE_IP="$(networkPrivateIpGet)"

KUBERNETES_MINOR="$(get_kubernetes_minor)" || exit 1
readonly KUBERNETES_MINOR
readonly KUBECTL_USER="${SUDO_USER:-root}"
readonly KUBECTL_HOME="$(getent passwd "${KUBECTL_USER}" | cut -d: -f6)"

[[ -n "${KUBECTL_HOME}" ]] || fail "Cannot determine the home directory for ${KUBECTL_USER}."

if [[ -f /etc/kubernetes/admin.conf ]]; then
    fail 'This host already has a Kubernetes control plane. Do not run kubeadm init again.'
fi

install_node_prerequisites "${KUBERNETES_MINOR}"
configure_kubelet_node_ip "${NODE_PRIVATE_IP}"

KUBERNETES_VERSION="$(kubeadm version -o short)" || fail 'Cannot determine the installed kubeadm version.'
[[ "${KUBERNETES_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Installed kubeadm version is not valid: ${KUBERNETES_VERSION}"
readonly KUBERNETES_VERSION

init_args=(init "--kubernetes-version=${KUBERNETES_VERSION}" "--apiserver-advertise-address=${NODE_PRIVATE_IP}")

if [[ -n "${CONTROL_PLANE_ENDPOINT:-}" ]]; then
    init_args+=("--control-plane-endpoint=${CONTROL_PLANE_ENDPOINT}")
fi

if [[ -n "${POD_NETWORK_CIDR:-}" ]]; then
    init_args+=("--pod-network-cidr=${POD_NETWORK_CIDR}")
fi

log "Initializing the ${KUBERNETES_VERSION} control plane"
kubeadm "${init_args[@]}"

export KUBECONFIG=/etc/kubernetes/admin.conf

# Give the user who started this install local kubectl access.
# admin.conf has cluster-admin privileges and must stay on the control-plane VPS.
install -d -m 0700 -o "${KUBECTL_USER}" -g "$(id -gn "${KUBECTL_USER}")" "${KUBECTL_HOME}/.kube"
install -m 0600 -o "${KUBECTL_USER}" -g "$(id -gn "${KUBECTL_USER}")" /etc/kubernetes/admin.conf "${KUBECTL_HOME}/.kube/config"

if [[ "${ALLOW_WORKLOADS_ON_CONTROL_PLANE:-false}" == 'true' ]]; then
    log 'Allowing workloads on the control-plane node'
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-
fi

log 'Control plane installed'
log 'Install a CNI plugin before expecting nodes and Pods to become Ready'
log 'To join a worker node, run: sudo scripts/admin/1-join-worker.sh'
