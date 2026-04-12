#!/bin/bash
set -euo pipefail

NAMESPACE="gateway-lab"
GATEWAY_CLASS="cka-014-gc"
GATEWAY="main-gateway"

kubectl get gatewayclass "$GATEWAY_CLASS" >/dev/null 2>&1 || {
  echo "GatewayClass $GATEWAY_CLASS not found"
  exit 1
}

CONTROLLER_NAME="$(kubectl get gatewayclass "$GATEWAY_CLASS" -o jsonpath='{.spec.controllerName}')"
GATEWAY_CLASS_NAME="$(kubectl get gateway "$GATEWAY" -n "$NAMESPACE" -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null || true)"
PORT="$(kubectl get gateway "$GATEWAY" -n "$NAMESPACE" -o jsonpath='{.spec.listeners[0].port}' 2>/dev/null || true)"
PROTOCOL="$(kubectl get gateway "$GATEWAY" -n "$NAMESPACE" -o jsonpath='{.spec.listeners[0].protocol}' 2>/dev/null || true)"

[ "$CONTROLLER_NAME" = "example.com/gateway-controller" ] || { echo "GatewayClass controllerName must be example.com/gateway-controller"; exit 1; }
[ "$GATEWAY_CLASS_NAME" = "$GATEWAY_CLASS" ] || { echo "Gateway must use GatewayClass $GATEWAY_CLASS"; exit 1; }
[ "$PORT" = "80" ] || { echo "Gateway must listen on port 80"; exit 1; }
[ "$PROTOCOL" = "HTTP" ] || { echo "Gateway protocol must be HTTP"; exit 1; }

echo "GatewayClass and Gateway contract are correct"
