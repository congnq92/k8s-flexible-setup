#!/usr/bin/env bash

set -Eeuo pipefail

readonly PROJECT_ROOT="${APP_PATH:?Load scripts/lib/util.sh before scripts/lib/common.sh.}"

log() {
    printf '==> %s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_root() {
    [[ "${EUID}" -eq 0 ]] || fail 'Run this script with sudo or as root.'
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

require_debian_or_ubuntu() {
    [[ -r /etc/os-release ]] || fail 'Cannot detect the Linux distribution.'
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID}" == 'debian' || "${ID}" == 'ubuntu' ]] || fail 'Only Debian and Ubuntu are supported by these scripts.'
}

get_kubernetes_minor() {
    local branch

    if [[ -n "${KUBERNETES_MINOR:-}" ]]; then
        [[ "${KUBERNETES_MINOR}" =~ ^v[0-9]+\.[0-9]+$ ]] || fail 'KUBERNETES_MINOR must use the format v<major>.<minor>, for example v1.37.'
        printf '%s\n' "${KUBERNETES_MINOR}"
        return
    fi

    require_command git
    branch="$(git -C "${PROJECT_ROOT}" branch --show-current)"
    [[ "${branch}" =~ ^v-([0-9]+)-([0-9]+)-x$ ]] || fail 'The active Git branch must use v-<major>-<minor>-x, for example v-1-37-x.'
    printf 'v%s.%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}

configure_kernel() {
    log 'Configuring Kubernetes kernel requirements'
    modprobe overlay
    modprobe br_netfilter

    install -d -m 0755 /etc/modules-load.d /etc/sysctl.d
    cat >/etc/modules-load.d/k8s.conf <<'EOF'
overlay
br_netfilter
EOF
    cat >/etc/sysctl.d/k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
    sysctl --system >/dev/null
}

configure_containerd() {
    log 'Installing and configuring containerd'
    apt-get update
    apt-get install -y containerd

    install -d -m 0755 /etc/containerd
    if [[ ! -f /etc/containerd/config.toml ]]; then
        containerd config default >/etc/containerd/config.toml
    fi

    sed -i -E 's/^([[:space:]]*)SystemdCgroup = false/\1SystemdCgroup = true/' /etc/containerd/config.toml
    systemctl enable --now containerd
    systemctl restart containerd
}

disable_swap() {
    log 'Disabling swap'
    swapoff -a
    sed -i -E '/^[^#].*[[:space:]]swap[[:space:]]/ s/^/# /' /etc/fstab
}

install_kubernetes_tools() {
    local kubernetes_minor="$1"
    local repository_url="https://pkgs.k8s.io/core:/stable:/${kubernetes_minor}/deb/"

    log "Installing Kubernetes tools for ${kubernetes_minor}"
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gpg
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL "${repository_url}Release.key" | gpg --dearmor --yes --output /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    printf 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] %s /\n' "${repository_url}" >/etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    systemctl enable --now kubelet
}

install_node_prerequisites() {
    local kubernetes_minor="$1"

    require_root
    require_debian_or_ubuntu
    disable_swap
    configure_kernel
    configure_containerd
    install_kubernetes_tools "${kubernetes_minor}"
}
