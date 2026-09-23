#!/usr/bin/env bash

set -Eeuo pipefail

# Requirement: run on a VPS where 1-install-control-plane.sh has already completed.
# This enables workload scheduling on the local control-plane node; it never joins a cluster.

# shellcheck source=../lib/lib-init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/lib-init.sh"
# shellcheck source=../modules/dev/dev.module.sh
importModule 'dev'
# shellcheck source=../modules/ui/ui.module.sh
importModule 'ui'
uiShowScriptHeader "${BASH_SOURCE[0]}"
devModeExitIfEnabled "${BASH_SOURCE[0]}"

readonly KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/kubernetes/admin.conf}"

require_root
require_command kubectl
[[ -r "${KUBECONFIG_PATH}" ]] || fail 'A local control plane is required before enabling its Worker role.'

log 'Enabling workload scheduling on control-plane nodes'
kubectl --kubeconfig "${KUBECONFIG_PATH}" taint nodes --all node-role.kubernetes.io/control-plane-

uiPrintSuccess 'Control-plane Worker role enabled'
