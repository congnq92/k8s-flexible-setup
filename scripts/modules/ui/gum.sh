#!/usr/bin/env bash

# Gum setup and shared terminal presentation.

readonly UI_DIVIDER='─────────────────────────────────'

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

uiConfirmTwice() {
    local message="$1"

    gum confirm "${message} (1/2)?" >/dev/null || return 1
    gum confirm "${message} (2/2)?" >/dev/null
}

uiShowCompletion() {
    local message="$1"

    printf '%s\n' "${UI_DIVIDER}"
    gum log --level info "${message}"
    gum log --level info 'To open the app again, run the installer script again.'
}

uiPrintHeader() {
    require_command gum
    echo "---"
    printf '{{ Color "7" "4" "%s" }}' "$1" | gum format -t template
    echo ""
}

uiShowHeader() {
    local app_name="$1"
    local mode="$2"
    local working_dir="$3"
    local branch="$4"

    gum style --border double --padding '0 1' --margin '1 0' "${app_name}" "Mode: ${mode}" "Working dir: ${working_dir}" "Branch: ${branch}"
}

uiPrintInfo() {
    require_command gum
    printf '{{ Color "4" "" "%s" }}' "$1" | gum format -t template
    echo ""
}

uiPrintSuccess() {
    require_command gum
    printf '{{ Color "2" "" "%s" }}' "$1" | gum format -t template
    echo ""
}

uiPrintWarn() {
    require_command gum
    printf '{{ Color "3" "" "%s" }}' "$1" | gum format -t template
    echo ""
}

uiPrintError() {
    require_command gum
    printf '{{ Color "1" "" "%s" }}' "$1" | gum format -t template
    echo ""
}

uiShowScriptHeader() {
    local script_path="$1"
    local relative_path
    local directory_name
    local script_name
    local header

    script_path="$(cd -- "$(dirname -- "${script_path}")" && pwd)/$(basename -- "${script_path}")"
    relative_path="${script_path#"${APP_PATH}/scripts/"}"
    directory_name="${relative_path%%/*}"
    script_name="${relative_path##*/}"
    script_name="${script_name%.sh}"
    header="${directory_name} > ${script_name}"
    header="${header//-/ }"
    header="$(printf '%s\n' "${header}" | sed -E 's/(^| )([[:alpha:]])/\1\u\2/g')"

    uiPrintHeader "${header}"
}
