#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=../lib/lib-init.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/lib-init.sh"
# shellcheck source=../modules/dev/dev.module.sh
importModule 'dev'
# shellcheck source=../modules/ui/ui.module.sh
importModule 'ui'
uiShowScriptHeader "${BASH_SOURCE[0]}"
devModeExitIfEnabled "${BASH_SOURCE[0]}"

readonly KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/kubernetes/admin.conf}"
readonly VERIFY_NAMESPACE='kfs-verify-test'
readonly VERIFY_DEPLOYMENT='nginx-https-test'
readonly VERIFY_CONFIG_PATH="${APP_PATH}/k8s/tests/1-test-https-ingress.yaml"
readonly EXPECTED_RESPONSE='https nginx test 443'
readonly KUBERNETES_WAIT_TIMEOUT='90s'
readonly NODE_PRIVATE_IP="$(networkPrivateIpGet)"

require_root
require_command kubectl
require_command curl
[[ -r "${KUBECONFIG_PATH}" ]] || fail "Kubernetes admin kubeconfig not found: ${KUBECONFIG_PATH}"
[[ -r "${VERIFY_CONFIG_PATH}" ]] || fail "Verify test config not found: ${VERIFY_CONFIG_PATH}"

uiPrintInfo 'Waiting for ingress-nginx to become Ready'
kubectl --kubeconfig "${KUBECONFIG_PATH}" --namespace ingress-nginx wait deployment/ingress-nginx-controller \
    --for=condition=available \
    --timeout="${KUBERNETES_WAIT_TIMEOUT}"

uiPrintInfo 'Deploying HTTPS ingress verify test'
kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f "${VERIFY_CONFIG_PATH}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" --namespace "${VERIFY_NAMESPACE}" wait deployment/"${VERIFY_DEPLOYMENT}" \
    --for=condition=available \
    --timeout="${KUBERNETES_WAIT_TIMEOUT}"

uiPrintInfo 'Waiting for ingress-nginx to load the test Ingress'
sleep 5

if ! curl_response="$(curl --insecure --silent --show-error --connect-timeout 5 --max-time 10 \
    --write-out $'\n%{http_code}' "https://${NODE_PRIVATE_IP}/")"; then
    uiPrintError "FAIL: HTTPS request to ${NODE_PRIVATE_IP}:443 could not be completed."
    fail 'HTTPS ingress verification failed.'
fi

http_status="${curl_response##*$'\n'}"
response_body="${curl_response%$'\n'*}"
response_body="${response_body%$'\n'}"
if [[ "${http_status}" == '200' && "${response_body}" == "${EXPECTED_RESPONSE}" ]]; then
    uiPrintSuccess "PASS: HTTPS ingress returned HTTP ${http_status}: ${response_body}"
    uiPrintInfo 'Removing HTTPS ingress verify test resources'
    kubectl --kubeconfig "${KUBECONFIG_PATH}" delete -f "${VERIFY_CONFIG_PATH}" --ignore-not-found
    uiPrintSuccess 'HTTPS ingress verify test resources removed'
    exit 0
fi

uiPrintError "FAIL: expected HTTP 200 and '${EXPECTED_RESPONSE}'; received HTTP ${http_status} and '${response_body}'."
fail 'HTTPS ingress verification failed.'
