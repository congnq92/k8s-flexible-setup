#!/usr/bin/env bash

readonly MENU_INSTALL_GROUPS='1. Install groups'
readonly MENU_ADMIN_JOIN_WORKER='2. Join worker node'
readonly MENU_SWITCH_MODE='3. Switch mode: Dev | Prod'
readonly MENU_EXIT='4. Exit'

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

    uiConfirmTwice 'Confirm to run these script(s)' || return 0
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
        uiShowHeader "${APP_NAME}" "$(devModeGet)" "${APP_PATH}" "${BRANCH}"
        selected_item="$(gum choose "${MENU_INSTALL_GROUPS}" "${MENU_ADMIN_JOIN_WORKER}" "${MENU_SWITCH_MODE}" "${MENU_EXIT}")"

        case "${selected_item}" in
            "${MENU_INSTALL_GROUPS}")
                uiRunInstallGroups
                ;;
            "${MENU_ADMIN_JOIN_WORKER}")
                gum style --bold 'Admin script to run:'
                printf '%s\n' "${ADMIN_JOIN_WORKER_SCRIPT}"
                uiConfirmTwice 'Confirm to run this script' || continue
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
