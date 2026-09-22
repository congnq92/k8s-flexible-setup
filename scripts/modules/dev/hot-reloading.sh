#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_DIR="$(cd -- "${SCRIPT_DIR}/../../.." && pwd -P)"
readonly SOURCE_PARENT="$(dirname -- "${SOURCE_DIR}")"
readonly HOME_DIR="$(cd -- "${HOME}" && pwd -P)"
readonly TARGET_REQUESTED="${KFS_HOME:-${HOME_DIR}/.local/share/k8s-flexible-setup}"
readonly TARGET_NAME="$(basename -- "${TARGET_REQUESTED}")"
readonly TARGET_PARENT_REQUESTED="$(dirname -- "${TARGET_REQUESTED}")"

if [[ "${TARGET_NAME}" == '.' || "${TARGET_NAME}" == '..' ]]; then
    printf 'Refusing unsafe target directory: %s\n' "${TARGET_REQUESTED}" >&2
    exit 1
fi

mkdir -p -- "${TARGET_PARENT_REQUESTED}"
readonly TARGET_PARENT="$(cd -- "${TARGET_PARENT_REQUESTED}" && pwd -P)"
readonly TARGET_DIR="${TARGET_PARENT}/${TARGET_NAME}"

if [[ "${TARGET_DIR}" == '/' || "${TARGET_DIR}" == "${HOME_DIR}" || "${TARGET_DIR}" == "${SOURCE_DIR}" || "${TARGET_DIR}" == "${SOURCE_PARENT}" || "${TARGET_DIR}" == "${SOURCE_DIR}/"* ]]; then
    printf 'Refusing unsafe target directory: %s\n' "${TARGET_DIR}" >&2
    exit 1
fi

rm -rf -- "${TARGET_DIR}"
cp -a -- "${SOURCE_DIR}" "${TARGET_DIR}"
exec "${TARGET_DIR}/scripts/app/main.sh"
