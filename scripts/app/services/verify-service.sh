#!/usr/bin/env bash

readonly VERIFY_HTTPS_INGRESS_SCRIPT='1-test-https-ingress.sh'
readonly VERIFY_HTTPS_INGRESS_CONFIG='k8s/tests/1-test-https-ingress.yaml'

verifyServiceValidate() {
    [[ -x "${APP_PATH}/scripts/tests/${VERIFY_HTTPS_INGRESS_SCRIPT}" ]] || fail "Required verify test script not found: ${VERIFY_HTTPS_INGRESS_SCRIPT}"
    [[ -r "${APP_PATH}/${VERIFY_HTTPS_INGRESS_CONFIG}" ]] || fail "Required verify test config not found: ${VERIFY_HTTPS_INGRESS_CONFIG}"
}

verifyServiceRunHttpsIngress() {
    devModeRunScript "${APP_PATH}/scripts/tests/${VERIFY_HTTPS_INGRESS_SCRIPT}"
}
