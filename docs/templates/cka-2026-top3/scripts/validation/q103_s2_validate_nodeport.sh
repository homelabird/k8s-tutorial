#!/bin/bash
set -e

TYPE=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.type}' 2>/dev/null || true)
NODEPORT=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || true)

if [ "$TYPE" = "NodePort" ] && [ "$NODEPORT" = "30080" ]; then
  echo "ingress-nginx controller service uses NodePort 30080"
  exit 0
fi

echo "Expected NodePort 30080, got type='${TYPE:-missing}' nodePort='${NODEPORT:-missing}'"
exit 1
