#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

run_privileged() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install Gum.'
        sudo "$@"
    fi
}

ensure_gum() {
    if command -v gum >/dev/null 2>&1; then
        return
    fi

    [[ -r /etc/os-release ]] || fail 'Gum is not installed. Install Gum manually, then run this script again.'
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID}" == 'debian' || "${ID}" == 'ubuntu' ]] || fail 'Gum is not installed. This installer can install Gum only on Debian or Ubuntu.'

    printf '==> Installing Gum\n'
    run_privileged install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | run_privileged gpg --dearmor --yes --output /etc/apt/keyrings/charm.gpg
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' | run_privileged tee /etc/apt/sources.list.d/charm.list >/dev/null
    run_privileged apt-get update
    run_privileged apt-get install -y gum
}

ensure_gum

while true; do
    gum style --border double --padding '1 2' --margin '1 0' 'K8s Flexible Setup'
    action="$(gum choose --header 'Select an action' 'Deployment plan' 'Group install' 'Last deployment plan' 'Exit')"

    case "${action}" in
        'Deployment plan')
            "${SCRIPT_DIR}/menu/deployment-plan.sh"
            ;;
        'Group install')
            "${SCRIPT_DIR}/menu/group-install.sh"
            ;;
        'Last deployment plan')
            "${SCRIPT_DIR}/menu/last-deployment-plan.sh"
            ;;
        'Exit')
            exit 0
            ;;
    esac
done
