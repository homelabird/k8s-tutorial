#!/bin/bash
set -euo pipefail

NAMESPACE="netpol-lab"

ALL_POLICIES="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"
[ -n "$ALL_POLICIES" ] || {
  echo "No NetworkPolicies found in namespace '$NAMESPACE'"
  exit 1
}

API_POLICIES="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="api")]}{.metadata.name}{"\n"}{end}')"
DB_POLICIES="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="db")]}{.metadata.name}{"\n"}{end}')"
API_POLICY_YAML="$(kubectl get networkpolicy api-policy -n "$NAMESPACE" -o yaml 2>/dev/null || true)"

[ -n "$API_POLICIES" ] || {
  echo "No NetworkPolicy selects app=api"
  exit 1
}

[ -n "$DB_POLICIES" ] || {
  echo "No NetworkPolicy selects app=db"
  exit 1
}

API_INGRESS_SOURCES="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="api")]}{.spec.ingress[*].from[*].podSelector.matchLabels.app}{"\n"}{end}')"
API_INGRESS_PORTS="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="api")]}{.spec.ingress[*].ports[*].port}{"\n"}{end}')"
API_EGRESS_DESTS="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="api")]}{.spec.egress[*].to[*].podSelector.matchLabels.app}{"\n"}{end}')"
API_EGRESS_PORTS="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="api")]}{.spec.egress[*].ports[*].port}{"\n"}{end}')"
DB_INGRESS_SOURCES="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="db")]}{.spec.ingress[*].from[*].podSelector.matchLabels.app}{"\n"}{end}')"
DB_INGRESS_PORTS="$(kubectl get networkpolicy -n "$NAMESPACE" -o jsonpath='{range .items[?(@.spec.podSelector.matchLabels.app=="db")]}{.spec.ingress[*].ports[*].port}{"\n"}{end}')"

printf '%s\n' "$API_INGRESS_SOURCES" | grep -wq frontend || {
  echo "No api policy allows ingress from app=frontend"
  exit 1
}

printf '%s\n' "$API_INGRESS_PORTS" | grep -wq 8080 || {
  echo "No api policy restricts ingress to port 8080"
  exit 1
}

printf '%s\n' "$API_EGRESS_DESTS" | grep -wq db || {
  echo "No api policy allows egress to app=db"
  exit 1
}

printf '%s\n' "$API_EGRESS_PORTS" | grep -wq 5432 || {
  echo "No api policy restricts egress to port 5432"
  exit 1
}

printf '%s\n' "$DB_INGRESS_SOURCES" | grep -wq api || {
  echo "No db policy allows ingress from app=api"
  exit 1
}

printf '%s\n' "$DB_INGRESS_PORTS" | grep -wq 5432 || {
  echo "No db policy restricts ingress to port 5432"
  exit 1
}

printf '%s\n' "$API_POLICY_YAML" | grep -q 'kubernetes.io/metadata.name: kube-system' || {
  echo "api policy must allow DNS egress to kube-system"
  exit 1
}

printf '%s\n' "$API_POLICY_YAML" | grep -q 'k8s-app: kube-dns' || {
  echo "api policy must target kube-dns Pods for DNS egress"
  exit 1
}

printf '%s\n' "$API_POLICY_YAML" | grep -q 'protocol: UDP' || {
  echo "api policy must allow UDP DNS egress"
  exit 1
}

printf '%s\n' "$API_POLICY_YAML" | grep -q 'protocol: TCP' || {
  echo "api policy must allow TCP DNS egress"
  exit 1
}

DNS_PORT_COUNT="$(printf '%s\n' "$API_POLICY_YAML" | grep -c 'port: 53' || true)"
[ "$DNS_PORT_COUNT" -ge 2 ] || {
  echo "api policy must allow DNS port 53 for both UDP and TCP"
  exit 1
}

echo "NetworkPolicies exist, select the intended Pods, and keep DNS egress available"
