#!/usr/bin/env bash

readonly SCRIPTS_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load shared library modules.
# shellcheck source=lib/util.sh
source "${SCRIPTS_PATH}/lib/util.sh"
# shellcheck source=lib/common.sh
source "${SCRIPTS_PATH}/lib/common.sh"

# Load development-only modules.
# shellcheck source=z-dev/dev-mode.sh
source "${SCRIPTS_PATH}/z-dev/dev-mode.sh"
