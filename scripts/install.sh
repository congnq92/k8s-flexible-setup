#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_URL='https://github.com/congnq92/k8s-flexible-setup.git'
readonly KFS_HOME="${KFS_HOME:-${HOME}/.local/share/k8s-flexible-setup}"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || fail 'Git is required. Install Git, then run this command again.'

if [[ -e "${KFS_HOME}" && ! -d "${KFS_HOME}/.git" ]]; then
    fail "The install location exists but is not a k8s-flexible-setup repository: ${KFS_HOME}"
fi

if [[ ! -d "${KFS_HOME}/.git" ]]; then
    mkdir -p "$(dirname -- "${KFS_HOME}")"
    git clone "${REPOSITORY_URL}" "${KFS_HOME}"
fi

# shellcheck source=lib/lib-init.sh
source "${KFS_HOME}/scripts/lib/lib-init.sh"
# shellcheck source=modules/ui/ui.module.sh
importModule 'ui'
uiEnsureGum

printf '\nRepository installed: %s\n' "${KFS_HOME}"
printf 'Run the app with:\n'
uiPrintCode "bash ${KFS_HOME}/scripts/app/main.sh"
