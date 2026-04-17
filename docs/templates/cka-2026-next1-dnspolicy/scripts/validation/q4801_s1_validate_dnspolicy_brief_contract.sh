#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="dnspolicy-lab"
CONFIGMAP="dns-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o "jsonpath={.data.${key}}")"
  [[ "$actual" == "$expected" ]]
}

expect_data "targetWorkload" "dns-client"
expect_data "podInventory" "kubectl get pod dns-client -n dnspolicy-lab -o wide"
expect_data "dnsPolicyCheck" "kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsPolicy}'"
expect_data "dnsNameserverCheck" "kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.nameservers[0]}'"
expect_data "dnsSearchCheck" "kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.searches[0]}'"
expect_data "dnsOptionCheck" "kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.options[0].name}'"
expect_data "resolverFileCheck" "kubectl exec -n dnspolicy-lab dns-client -- cat /etc/resolv.conf"
expect_data "eventCheck" "kubectl get events -n dnspolicy-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm dnsPolicy, dnsConfig nameservers, searches, and options before changing workload manifests or cluster DNS services"
