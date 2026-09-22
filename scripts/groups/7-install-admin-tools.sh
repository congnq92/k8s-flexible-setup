#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/lib-init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/lib-init.sh"
# shellcheck source=../modules/dev/dev.module.sh
importModule 'dev'
# shellcheck source=../modules/ui/ui.module.sh
importModule 'ui'
devModeExitIfEnabled "${BASH_SOURCE[0]}"
showGroupHeader '7. Admin Tools group'

readonly HELM_INSTALL_SCRIPT_URL="${HELM_INSTALL_SCRIPT_URL:-https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4}"

require_root
require_command curl

temporary_file="$(mktemp)"
trap 'rm -f -- "${temporary_file}"' EXIT

log 'Installing Helm'
curl -fsSL "${HELM_INSTALL_SCRIPT_URL}" --output "${temporary_file}"
bash "${temporary_file}"
helm version

log 'Admin tools installed successfully'
