#!/usr/bin/env bash

readonly DEV_MODE_DIR='/tmp/k8s-flexible-setup'
readonly DEV_MODE_FILE="${DEV_MODE_DIR}/devmode.txt"

devModeGet() {
    if [[ -r "${DEV_MODE_FILE}" && "$(<"${DEV_MODE_FILE}")" == 'Dev' ]]; then
        printf 'Dev\n'
    else
        printf 'Prod\n'
    fi
}

devModeExitIfEnabled() {
    local script_path="$1"

    if [[ "$(devModeGet)" == 'Dev' ]]; then
        printf 'Dev Mode: will run %s\n' "$(basename -- "${script_path}")"
        exit 0
    fi
}

devModeSwitch() {
    install -d -m 700 "${DEV_MODE_DIR}"

    if [[ "$(devModeGet)" == 'Dev' ]]; then
        printf 'Prod\n' >"${DEV_MODE_FILE}"
    else
        printf 'Dev\n' >"${DEV_MODE_FILE}"
    fi

    chmod 600 "${DEV_MODE_FILE}"
    devModeGet
}

devModeRunScript() {
    local script_path="$1"

    if [[ "$(devModeGet)" == 'Dev' ]]; then
        "${script_path}"
        return
    fi

    if [[ "${EUID}" -eq 0 ]]; then
        "${script_path}"
    else
        sudo "${script_path}"
    fi
}
