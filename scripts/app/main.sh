#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/lib-init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/lib-init.sh"
# shellcheck source=../modules/dev/dev.module.sh
importModule 'dev'
# shellcheck source=../modules/ui/ui.module.sh
importModule 'ui'
# shellcheck source=../config/config.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../config/config.sh"
# shellcheck source=services/group-service.sh
source "${APP_PATH}/scripts/app/services/group-service.sh"
# shellcheck source=services/admin-service.sh
source "${APP_PATH}/scripts/app/services/admin-service.sh"
# shellcheck source=services/verify-service.sh
source "${APP_PATH}/scripts/app/services/verify-service.sh"
# shellcheck source=ui.sh
source "${APP_PATH}/scripts/app/ui.sh"

uiRun
