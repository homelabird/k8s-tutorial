#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="dnspolicy-lab"
DEPLOYMENT="dns-client"

POLICY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.dnsPolicy}')"
NAMESERVER="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.dnsConfig.nameservers[0]}')"
SEARCH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.dnsConfig.searches[0]}')"
OPTION_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.dnsConfig.options[0].name}')"
OPTION_VALUE="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.dnsConfig.options[0].value}')"

[ "${POLICY}" = "None" ] || {
  echo "dns-client must use dnsPolicy None"
  exit 1
}

[ "${NAMESERVER}" = "1.1.1.1" ] || {
  echo "dns-client must use nameserver 1.1.1.1"
  exit 1
}

[ "${SEARCH}" = "lab.local" ] || {
  echo "dns-client must use search domain lab.local"
  exit 1
}

[ "${OPTION_NAME}" = "ndots" ] || {
  echo "dns-client must configure dns option ndots"
  exit 1
}

[ "${OPTION_VALUE}" = "2" ] || {
  echo "dns-client must set ndots to 2"
  exit 1
}

echo "Deployment dns-client uses the intended dnsPolicy and dnsConfig values"
