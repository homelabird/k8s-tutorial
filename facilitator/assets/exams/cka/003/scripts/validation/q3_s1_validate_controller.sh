#!/bin/bash
set -e

helm status ingress-nginx -n ingress-nginx >/dev/null 2>&1
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=180s >/dev/null 2>&1
echo "ingress-nginx Helm release is installed and controller is ready"
exit 0
