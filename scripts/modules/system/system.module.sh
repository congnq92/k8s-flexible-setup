#!/usr/bin/env bash

readonly SYSTEM_MODULE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=system.sh
source "${SYSTEM_MODULE_PATH}/system.sh"
