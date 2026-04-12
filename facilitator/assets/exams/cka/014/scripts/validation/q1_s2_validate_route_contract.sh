#!/bin/bash
set -euo pipefail

NAMESPACE="gateway-lab"
ROUTE="app-routes"

kubectl get httproute "$ROUTE" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "HTTPRoute $ROUTE not found"
  exit 1
}

HOST="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.hostnames[0]}')"
PARENT="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.parentRefs[0].name}')"
APP1_PATH="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.rules[?(@.matches[0].path.value=="/app1")].matches[0].path.value}' 2>/dev/null || true)"
APP2_PATH="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.rules[?(@.matches[0].path.value=="/app2")].matches[0].path.value}' 2>/dev/null || true)"
APP1_BACKEND="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.rules[?(@.matches[0].path.value=="/app1")].backendRefs[0].name}' 2>/dev/null || true)"
APP2_BACKEND="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.rules[?(@.matches[0].path.value=="/app2")].backendRefs[0].name}' 2>/dev/null || true)"
APP1_PORT="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.rules[?(@.matches[0].path.value=="/app1")].backendRefs[0].port}' 2>/dev/null || true)"
APP2_PORT="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.rules[?(@.matches[0].path.value=="/app2")].backendRefs[0].port}' 2>/dev/null || true)"
LEGACY_PATH="$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.spec.rules[?(@.matches[0].path.value=="/legacy")].matches[0].path.value}' 2>/dev/null || true)"

[ "$HOST" = "apps.example.local" ] || { echo "HTTPRoute must use host apps.example.local"; exit 1; }
[ "$PARENT" = "main-gateway" ] || { echo "HTTPRoute must attach to main-gateway"; exit 1; }
[ "$APP1_PATH" = "/app1" ] || { echo "Missing /app1 route"; exit 1; }
[ "$APP2_PATH" = "/app2" ] || { echo "Missing /app2 route"; exit 1; }
[ "$APP1_BACKEND" = "app1-svc" ] || { echo "/app1 must route to app1-svc"; exit 1; }
[ "$APP2_BACKEND" = "app2-svc" ] || { echo "/app2 must route to app2-svc"; exit 1; }
[ "$APP1_PORT" = "8080" ] || { echo "/app1 backend port must be 8080"; exit 1; }
[ "$APP2_PORT" = "8080" ] || { echo "/app2 backend port must be 8080"; exit 1; }
[ -z "$LEGACY_PATH" ] || { echo "Stale /legacy route must be removed"; exit 1; }

echo "HTTPRoute contract is correct"
