#!/usr/bin/env bash

readonly LIB_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load shared runtime modules.
# shellcheck source=util.sh
source "${LIB_PATH}/util.sh"
# shellcheck source=common.sh
source "${LIB_PATH}/common.sh"
# shellcheck source=../modules/system/system.module.sh
importModule 'system'
# shellcheck source=network.sh
source "${LIB_PATH}/network.sh"
