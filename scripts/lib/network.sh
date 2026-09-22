#!/usr/bin/env bash

# Store node network settings outside the repository so they persist across updates.
readonly NETWORK_APP_USER="${SUDO_USER:-${USER}}"
readonly NETWORK_APP_HOME="$(getent passwd "${NETWORK_APP_USER}" | cut -d: -f6)"
readonly NETWORK_STATE_DIR="${NETWORK_APP_HOME:-${HOME}}/.local/state/k8s-flexible-setup"
readonly NETWORK_STATE_FILE="${NETWORK_STATE_DIR}/network.env"

networkIsValidIp() {
    local private_ip="$1"
    local octet
    local -a octets

    [[ "${private_ip}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || return 1
    IFS='.' read -r -a octets <<<"${private_ip}"
    for octet in "${octets[@]}"; do
        ((10#${octet} <= 255)) || return 1
    done
}

networkLoad() {
    local mode
    local private_ip

    [[ -r "${NETWORK_STATE_FILE}" ]] || return 1
    mode="$(sed -n 's/^NETWORK_MODE=//p' "${NETWORK_STATE_FILE}")"
    private_ip="$(sed -n 's/^NODE_PRIVATE_IP=//p' "${NETWORK_STATE_FILE}")"

    [[ "${mode}" == 'vpc' || "${mode}" == 'wireguard' ]] || return 1
    networkIsValidIp "${private_ip}" || return 1
}

networkModeGet() {
    networkLoad || fail 'Network is not configured. Run scripts/app/main.sh first.'
    sed -n 's/^NETWORK_MODE=//p' "${NETWORK_STATE_FILE}"
}

networkPrivateIpGet() {
    networkLoad || fail 'Network is not configured. Run scripts/app/main.sh first.'
    sed -n 's/^NODE_PRIVATE_IP=//p' "${NETWORK_STATE_FILE}"
}

networkConfigure() {
    local selected_mode
    local private_ip

    require_command gum
    require_command ip
    selected_mode="$(gum choose --header 'Select network mode for this VPS' 'VPC' 'WireGuard')"

    case "${selected_mode}" in
        VPC)
            selected_mode='vpc'
            ;;
        WireGuard)
            selected_mode='wireguard'
            ;;
        *)
            fail 'Select VPC or WireGuard.'
            ;;
    esac

    private_ip="$(gum input --header 'Kubernetes private IP for this VPS' --placeholder '10.10.0.12')"
    networkIsValidIp "${private_ip}" || fail 'Enter a valid IPv4 address.'
    ip -4 -o addr show | awk '{print $4}' | cut -d/ -f1 | grep -Fxq "${private_ip}" || fail "The private IP is not assigned on this VPS: ${private_ip}"

    install -d -m 700 "${NETWORK_STATE_DIR}"
    printf 'NETWORK_MODE=%s\nNODE_PRIVATE_IP=%s\n' "${selected_mode}" "${private_ip}" >"${NETWORK_STATE_FILE}"
    chmod 600 "${NETWORK_STATE_FILE}"

    gum log --level info "Network saved: ${selected_mode}, ${private_ip}"
}

networkEnsureConfiguration() {
    networkLoad || networkConfigure
}
