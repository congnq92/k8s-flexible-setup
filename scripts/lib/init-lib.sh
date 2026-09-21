#!/usr/bin/env bash

# Load all shared scripts in scripts/lib by sourcing this file.
readonly LIB_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=util.sh
source "${LIB_PATH}/util.sh"
# shellcheck source=dev-mode.sh
source "${LIB_PATH}/dev-mode.sh"
# shellcheck source=common.sh
source "${LIB_PATH}/common.sh"
