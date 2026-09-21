#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../init.sh"

devModeExitIfEnabled "${BASH_SOURCE[0]}"

echo 'run test group scripts'
