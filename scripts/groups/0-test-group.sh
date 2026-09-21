#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/init-lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/init-lib.sh"

devModeExitIfEnabled "${BASH_SOURCE[0]}"

echo 'run test group scripts'
