#!/bin/bash
set -e

CLASS=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.ingressClassName}' 2>/dev/null || true)
HOST=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || true)
PATH_VALUE=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null || true)
BACKEND=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || true)
PORT=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null || true)
CONTROLLER_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)

if [ "$CLASS" != "nginx" ] || [ "$HOST" != "app.example.local" ] || [ "$PATH_VALUE" != "/" ] || [ "$BACKEND" != "web-service" ] || [ "$PORT" != "80" ]; then
  echo "Ingress resource is not configured correctly"
  exit 1
fi

if [ -z "$CONTROLLER_IP" ]; then
  echo "Could not determine ingress-nginx controller service cluster IP"
  exit 1
fi

kubectl wait --for=condition=Ready pod/ingress-check -n ingress-lab --timeout=120s >/dev/null 2>&1
kubectl exec -n ingress-lab ingress-check -- \
  curl -fsS -H "Host: app.example.local" "http://${CONTROLLER_IP}/" >/tmp/q3-ingress.out

echo "Ingress routes app.example.local to web-service"
exit 0
