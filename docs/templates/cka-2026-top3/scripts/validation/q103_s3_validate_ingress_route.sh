#!/bin/bash
set -e

CLASS=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.ingressClassName}' 2>/dev/null || true)
BACKEND=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || true)
PORT=$(kubectl get ingress web-ingress -n ingress-lab -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null || true)

if [ "$CLASS" != "nginx" ] || [ "$BACKEND" != "web-service" ] || [ "$PORT" != "80" ]; then
  echo "Ingress resource is not configured correctly"
  exit 1
fi

kubectl run ingress-test --rm -i --restart=Never --image=curlimages/curl:8.7.1 -- \
  curl -fsS -H "Host: app.example.local" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/ >/tmp/q103-ingress.out

echo "Ingress routes app.example.local to web-service"
exit 0
