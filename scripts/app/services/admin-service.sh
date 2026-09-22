#!/usr/bin/env bash

readonly ADMIN_JOIN_WORKER_SCRIPT='1-join-worker.sh'

adminServiceValidate() {
    [[ -x "${APP_PATH}/scripts/admin/${ADMIN_JOIN_WORKER_SCRIPT}" ]] || fail "Required admin script not found: ${ADMIN_JOIN_WORKER_SCRIPT}"
}

adminServiceRunJoinWorker() {
    devModeRunScript "${APP_PATH}/scripts/admin/${ADMIN_JOIN_WORKER_SCRIPT}"
}
