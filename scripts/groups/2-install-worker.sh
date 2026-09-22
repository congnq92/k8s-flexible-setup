#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/lib-init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/lib-init.sh"
# shellcheck source=../modules/dev/dev.module.sh
importModule 'dev'
devModeExitIfEnabled "${BASH_SOURCE[0]}"

networkEnsureConfiguration
readonly NODE_PRIVATE_IP="$(networkPrivateIpGet)"

readonly KUBERNETES_MINOR="$(get_kubernetes_minor)"

[[ -n "${CONTROL_PLANE_ENDPOINT:-}" ]] || fail 'Set CONTROL_PLANE_ENDPOINT to the control-plane private address and port, for example 10.10.0.10:6443.'
[[ "${JOIN_TOKEN:-}" =~ ^[a-z0-9]{6}\.[a-z0-9]{16}$ ]] || fail 'Set JOIN_TOKEN to a valid kubeadm bootstrap token.'
[[ "${DISCOVERY_TOKEN_CA_CERT_HASH:-}" =~ ^sha256:[a-f0-9]{64}$ ]] || fail 'Set DISCOVERY_TOKEN_CA_CERT_HASH to the control-plane discovery hash.'

install_node_prerequisites "${KUBERNETES_MINOR}"
configure_kubelet_node_ip "${NODE_PRIVATE_IP}"

log "Joining the ${KUBERNETES_MINOR} Kubernetes cluster"
kubeadm join "${CONTROL_PLANE_ENDPOINT}" \
    --token "${JOIN_TOKEN}" \
    --discovery-token-ca-cert-hash "${DISCOVERY_TOKEN_CA_CERT_HASH}"

log 'Worker node joined successfully'
