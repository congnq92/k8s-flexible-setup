#!/usr/bin/env bash

# todo improve by select A groups and then install all of them

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

group="$(gum choose --header 'Select an installation group' 'Control-plane' 'Worker' 'NGINX Ingress')"

case "${group}" in
    'Control-plane')
        script_path="${SCRIPT_DIR}/../groups/install-control-plane.sh"
        ;;
    'Worker')
        script_path="${SCRIPT_DIR}/../groups/install-worker.sh"
        ;;
    'NGINX Ingress')
        script_path="${SCRIPT_DIR}/../groups/install-nginx-ingress.sh"
        ;;
esac

gum style --bold "Selected: ${group}"
gum style --margin '1 0' "Use the final deployment plan to run this script on the assigned VPS:"
printf '%s\n' "${script_path}"
gum confirm 'Return to the main menu?' >/dev/null || true
