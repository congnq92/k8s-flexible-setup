#!/usr/bin/env bash

set -Eeuo pipefail

# Requirement: run on a VPS without a local control plane.
# This installs and configures the dedicated Worker prerequisites. Join the
# cluster later with the command generated on the control-plane VPS.

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

install_node_prerequisites "${KUBERNETES_MINOR}"
configure_kubelet_node_ip "${NODE_PRIVATE_IP}"

uiPrintSuccess 'Dedicated worker prerequisites installed'
log 'Generate a join command on the control-plane VPS, then run it on this worker.'
