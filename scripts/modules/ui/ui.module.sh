#!/usr/bin/env bash

# Load all UI module files.
readonly UI_MODULE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=gum.sh
source "${UI_MODULE_PATH}/gum.sh"
