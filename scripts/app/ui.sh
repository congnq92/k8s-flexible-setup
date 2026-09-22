#!/usr/bin/env bash

readonly MENU_DIVIDER='─────────────────────────────────'
readonly MENU_INSTALL_GROUPS='1. Install groups'
readonly MENU_ADMIN_JOIN_WORKER='2. Join worker node'
readonly MENU_SWITCH_MODE='3. Switch mode: Dev | Prod'
readonly MENU_EXIT='4. Exit'

uiRunPrivileged() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install Gum.'
        sudo "$@"
    fi
}

uiEnsureGum() {
    if command -v gum >/dev/null 2>&1; then
        return
    fi

    [[ -r /etc/os-release ]] || fail 'Gum is not installed. Install Gum manually, then run this script again.'
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID}" == 'debian' || "${ID}" == 'ubuntu' ]] || fail 'Gum is not installed. This installer can install Gum only on Debian or Ubuntu.'

    printf '==> Installing Gum\n'
    uiRunPrivileged install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | uiRunPrivileged gpg --dearmor --yes --output /etc/apt/keyrings/charm.gpg
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' | uiRunPrivileged tee /etc/apt/sources.list.d/charm.list >/dev/null
    uiRunPrivileged apt-get update
    uiRunPrivileged apt-get install -y gum
}

uiShowHeader() {
    local mode

    mode="$(devModeGet)"
    gum style --border double --padding '0 1' --margin '1 0' 'K8s Flexible Setup' "Mode: ${mode}" "Working dir: ${APP_PATH}" "Branch: ${BRANCH}"
}

uiShowCompletion() {
    local message="$1"

    printf '%s\n' "${MENU_DIVIDER}"
    gum log --level info "${message}"
    gum log --level info 'To open the app again, run the installer script again.'
}

uiRunInstallGroups() {
    local selected_item
    local selected_script

    selected_item="$(gum choose --header $'1. Install groups\nSelect one VPS row, then press Enter\n  Case  | VPS   | Groups to select\n  ------+-------+-----------------' "${GROUP_SERVICE_TOPOLOGY_OPTIONS[@]}")"
    [[ -n "${selected_item}" ]] || return

    groupServicePlan "${selected_item}"
    gum style --bold 'Scripts to run in order:'
    for selected_script in "${GROUP_SERVICE_PLANNED_SCRIPTS[@]}"; do
        printf '%s\n' "${selected_script}"
    done

    gum confirm 'Confirm to run these script(s) (1/2)?' >/dev/null || return 0
    gum confirm 'Confirm to run these script(s) (2/2)?' >/dev/null || return 0
    groupServiceRunPlan
    uiShowCompletion 'Selected group scripts completed.'
    exit 0
}

uiRun() {
    local selected_item

    uiEnsureGum
    groupServiceValidate
    adminServiceValidate

    while true; do
        uiShowHeader
        selected_item="$(gum choose "${MENU_INSTALL_GROUPS}" "${MENU_ADMIN_JOIN_WORKER}" "${MENU_SWITCH_MODE}" "${MENU_EXIT}")"

        case "${selected_item}" in
            "${MENU_INSTALL_GROUPS}")
                uiRunInstallGroups
                ;;
            "${MENU_ADMIN_JOIN_WORKER}")
                gum style --bold 'Admin script to run:'
                printf '%s\n' "${ADMIN_JOIN_WORKER_SCRIPT}"
                gum confirm 'Confirm to run this script (1/2)?' >/dev/null || continue
                gum confirm 'Confirm to run this script (2/2)?' >/dev/null || continue
                adminServiceRunJoinWorker
                uiShowCompletion 'Admin script completed.'
                exit 0
                ;;
            "${MENU_SWITCH_MODE}")
                gum log --level info "Mode switched to $(devModeSwitch)."
                continue
                ;;
            "${MENU_EXIT}")
                exit 0
                ;;
        esac
    done
}
