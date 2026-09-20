#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_URL='https://github.com/congnq92/k8s-flexible-setup.git'
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null || pwd)"

log() {
    printf '==> %s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

run_privileged() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install Gum.'
        sudo "$@"
    fi
}

ensure_gum() {
    if command -v gum >/dev/null 2>&1; then
        return
    fi

    [[ -r /etc/os-release ]] || fail 'Gum is not installed. Install Gum manually, then run this script again.'
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID}" == 'debian' || "${ID}" == 'ubuntu' ]] || fail 'Gum is not installed. This installer can install Gum only on Debian or Ubuntu.'

    log 'Installing Gum'
    run_privileged install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | run_privileged gpg --dearmor --yes --output /etc/apt/keyrings/charm.gpg
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' | run_privileged tee /etc/apt/sources.list.d/charm.list >/dev/null
    run_privileged apt-get update
    run_privileged apt-get install -y gum
}

get_kubernetes_version() {
    local branch

    branch="$(git -C "${PROJECT_ROOT}" branch --show-current 2>/dev/null || true)"
    [[ "${branch}" =~ ^v-([0-9]+)-([0-9]+)-x$ ]] || fail 'Run from a version branch named v-<major>-<minor>-x, for example v-1-37-x.'
    printf 'v%s.%s.x\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}

prompt_nonempty() {
    local prompt="$1"
    local placeholder="$2"
    local value

    while true; do
        value="$(gum input --prompt "${prompt}: " --placeholder "${placeholder}")"
        [[ -n "${value}" ]] && {
            printf '%s\n' "${value}"
            return
        }
        gum log --level warn 'A value is required.'
    done
}

prompt_node_name() {
    local value

    while true; do
        value="$(prompt_nonempty 'VPS node name' 'node-1')"
        [[ "${value}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] && {
            printf '%s\n' "${value}"
            return
        }
        gum log --level warn 'Use lowercase letters, numbers, and hyphens only.'
    done
}

prompt_ipv4() {
    local prompt="$1"
    local value

    while true; do
        value="$(prompt_nonempty "${prompt}" '203.0.113.10')"
        [[ "${value}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && {
            printf '%s\n' "${value}"
            return
        }
        gum log --level warn 'Enter an IPv4 address.'
    done
}

has_group() {
    local groups="$1"
    local group="$2"

    grep -Fxq "${group}" <<<"${groups}"
}

validate_groups_for_role() {
    local role="$1"
    local groups="$2"

    case "${role}" in
        'Control-plane')
            has_group "${groups}" 'Control-plane' || fail 'A control-plane role requires the Control-plane group.'
            ;;
        'Worker')
            has_group "${groups}" 'Worker' || fail 'A worker role requires the Worker group.'
            ;;
        'Control-plane + Worker')
            has_group "${groups}" 'Control-plane' || fail 'This role requires the Control-plane group.'
            has_group "${groups}" 'Worker' || fail 'This role requires the Worker group.'
            ;;
    esac

    if has_group "${groups}" 'NGINX Ingress'; then
        has_group "${groups}" 'Worker' || fail 'The NGINX Ingress group requires the Worker group on the same VPS.'
    fi
}

group_list_for_table() {
    tr '\n' ';' <<<"$1" | sed 's/;$//'
}

generate_deployment_id() {
    printf 'deploy-%s-%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" "$$"
}

print_remote_prepare_command() {
    local branch="$1"

    printf 'git clone --branch %s %s && cd k8s-flexible-setup\n' "${branch}" "${REPOSITORY_URL}"
}

ensure_gum

readonly KUBERNETES_VERSION="$(get_kubernetes_version)"
readonly ACTIVE_BRANCH="$(git -C "${PROJECT_ROOT}" branch --show-current)"

gum style --border double --padding '1 2' --margin '1 0' 'K8s Flexible Setup' "Kubernetes ${KUBERNETES_VERSION} · ${ACTIVE_BRANCH}"

NETWORK_MODE="$(gum choose --header 'Select network mode' 'vpc' 'wireguard')"
VPS_COUNT="$(gum input --prompt 'Amount of VPSs: ' --placeholder '1')"
[[ "${VPS_COUNT}" =~ ^[1-9][0-9]*$ ]] || fail 'Amount of VPSs must be a positive integer.'

declare -a NODE_NAMES=()
declare -a PUBLIC_IPS=()
declare -a PRIVATE_IPS=()
declare -a ROLES=()
declare -a GROUPS=()

for ((index = 1; index <= VPS_COUNT; index++)); do
    gum style --bold --margin '1 0 0 0' "VPS ${index}"
    NODE_NAMES+=("$(prompt_node_name)")
    PUBLIC_IPS+=("$(prompt_ipv4 'Public IP')")
    PRIVATE_IPS+=("$(prompt_ipv4 'Private IP')")
    ROLES+=("$(gum choose --header 'Select VPS role' 'Control-plane' 'Worker' 'Control-plane + Worker')")

    selected_groups="$(printf '%s\n' 'Control-plane' 'Worker' 'NGINX Ingress' | gum choose --no-limit --header 'Select installation groups (space to select, enter to confirm)')"
    [[ -n "${selected_groups}" ]] || fail 'Select at least one installation group.'
    validate_groups_for_role "${ROLES[index - 1]}" "${selected_groups}"
    GROUPS+=("${selected_groups}")
done

control_plane_count=0
worker_count=0
for ((index = 0; index < VPS_COUNT; index++)); do
    has_group "${GROUPS[index]}" 'Control-plane' && ((control_plane_count += 1))
    has_group "${GROUPS[index]}" 'Worker' && ((worker_count += 1))
done
((control_plane_count > 0)) || fail 'Select the Control-plane group for at least one VPS.'
((worker_count > 0)) || fail 'Select the Worker group for at least one VPS.'

readonly DEPLOYMENT_ID="$(generate_deployment_id)"
readonly DEPLOYMENT_DIR="${KFS_STATE_DIR:-${PROJECT_ROOT}/state}/deployments/${DEPLOYMENT_ID}"
mkdir -p "${DEPLOYMENT_DIR}/logs"

{
    printf 'deploymentId: %s\n' "${DEPLOYMENT_ID}"
    printf 'kubernetesVersion: %s\n' "${KUBERNETES_VERSION}"
    printf 'branch: %s\n' "${ACTIVE_BRANCH}"
    printf 'networkMode: %s\n' "${NETWORK_MODE}"
    printf 'nodes:\n'
    for ((index = 0; index < VPS_COUNT; index++)); do
        printf '  - name: %s\n' "${NODE_NAMES[index]}"
        printf '    publicIp: %s\n' "${PUBLIC_IPS[index]}"
        printf '    privateIp: %s\n' "${PRIVATE_IPS[index]}"
        printf '    role: %s\n' "${ROLES[index]}"
        printf '    groups:\n'
        while IFS= read -r group; do
            printf '      - %s\n' "${group}"
        done <<<"${GROUPS[index]}"
    done
} >"${DEPLOYMENT_DIR}/plan.yaml"

printf 'deploymentId: %s\nstatus: planned\n' "${DEPLOYMENT_ID}" >"${DEPLOYMENT_DIR}/status.yaml"

gum style --bold --margin '1 0' 'Final deployment plan'
table_data=$'VPS,Public IP,Private IP,Role,Groups\n'
for ((index = 0; index < VPS_COUNT; index++)); do
    table_data+="${NODE_NAMES[index]},${PUBLIC_IPS[index]},${PRIVATE_IPS[index]},${ROLES[index]},$(group_list_for_table "${GROUPS[index]}")"$'\n'
done
printf '%s' "${table_data}" | gum table

gum confirm 'Continue and show the commands for each VPS?' || {
    gum log --level info "Plan saved locally: ${DEPLOYMENT_DIR}"
    exit 0
}

control_plane_endpoint=''
for ((index = 0; index < VPS_COUNT; index++)); do
    if has_group "${GROUPS[index]}" 'Control-plane'; then
        control_plane_endpoint="${PRIVATE_IPS[index]}:6443"
        break
    fi
done

gum style --bold --margin '1 0' 'Commands to run'
for ((index = 0; index < VPS_COUNT; index++)); do
    gum style --bold "${NODE_NAMES[index]} (${PUBLIC_IPS[index]})"
    print_remote_prepare_command "${ACTIVE_BRANCH}"

    if has_group "${GROUPS[index]}" 'Control-plane'; then
        if has_group "${GROUPS[index]}" 'Worker'; then
            printf 'sudo env API_ADVERTISE_ADDRESS=%s CONTROL_PLANE_ENDPOINT=%s ALLOW_WORKLOADS_ON_CONTROL_PLANE=true ./scripts/groups/install-control-plane.sh\n' \
                "${PRIVATE_IPS[index]}" "${control_plane_endpoint}"
        else
            printf 'sudo env API_ADVERTISE_ADDRESS=%s CONTROL_PLANE_ENDPOINT=%s ./scripts/groups/install-control-plane.sh\n' \
                "${PRIVATE_IPS[index]}" "${control_plane_endpoint}"
        fi
    fi

    if has_group "${GROUPS[index]}" 'Worker' && ! has_group "${GROUPS[index]}" 'Control-plane'; then
        printf '# First generate the join data on the first control-plane VPS.\n'
        printf 'sudo env CONTROL_PLANE_ENDPOINT=%s JOIN_TOKEN=<token> DISCOVERY_TOKEN_CA_CERT_HASH=<sha256-hash> ./scripts/groups/install-worker.sh\n' \
            "${control_plane_endpoint}"
    fi

    if has_group "${GROUPS[index]}" 'NGINX Ingress'; then
        printf '# Run this after the cluster is Ready, from a control-plane VPS with admin kubeconfig.\n'
        printf 'sudo ./scripts/groups/install-nginx-ingress.sh\n'
    fi
    printf '\n'
done

gum style --bold --margin '1 0' 'Verification commands'
cat <<'EOF'
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get nodes -o wide
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl cluster-info
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get ingress -A
EOF

gum log --level info "Plan saved locally: ${DEPLOYMENT_DIR}"
