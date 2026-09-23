#!/usr/bin/env bash

readonly SYSTEM_LOCK_WAIT_SECONDS=60
readonly SYSTEM_APT_LOCK_FILES=(
    /var/lib/dpkg/lock-frontend
    /var/lib/dpkg/lock
    /var/lib/apt/lists/lock
    /var/cache/apt/archives/lock
)

waitsForUnattendedUpgrades() {
    local lock_is_held=false

    if [[ "${EUID}" -eq 0 ]]; then
        fuser -s "${SYSTEM_APT_LOCK_FILES[@]}" && lock_is_held=true
    elif pgrep -f '[u]nattended-upgrade' >/dev/null 2>&1; then
        lock_is_held=true
    fi

    while [[ "${lock_is_held}" == true ]]; do
        log 'Waiting 1 minute for Ubuntu package updates to release the APT lock...'
        sleep "${SYSTEM_LOCK_WAIT_SECONDS}"

        lock_is_held=false
        if [[ "${EUID}" -eq 0 ]]; then
            fuser -s "${SYSTEM_APT_LOCK_FILES[@]}" && lock_is_held=true
        elif pgrep -f '[u]nattended-upgrade' >/dev/null 2>&1; then
            lock_is_held=true
        fi
    done
}
