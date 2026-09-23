#!/usr/bin/env bash

readonly SYSTEM_LOCK_WAIT_SECONDS=60
readonly SYSTEM_APT_LOCK_FILES=(
    /var/lib/dpkg/lock-frontend
    /var/lib/dpkg/lock
    /var/lib/apt/lists/lock
    /var/cache/apt/archives/lock
)

systemPackageUpdateLockIsHeld() {
    if [[ "${EUID}" -eq 0 ]]; then
        fuser -s "${SYSTEM_APT_LOCK_FILES[@]}"
        return
    fi

    systemctl is-active --quiet apt-daily.service 2>/dev/null ||
        systemctl is-active --quiet apt-daily-upgrade.service 2>/dev/null
}

waitsForUnattendedUpgrades() {
    while systemPackageUpdateLockIsHeld; do
        log 'Waiting 1 minute for Ubuntu package updates to release the APT lock...'
        sleep "${SYSTEM_LOCK_WAIT_SECONDS}"
    done
}
