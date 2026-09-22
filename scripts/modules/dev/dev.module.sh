#!/usr/bin/env bash

readonly DEV_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load development-only modules.
# shellcheck source=dev-mode.sh
source "${DEV_PATH}/dev-mode.sh"
