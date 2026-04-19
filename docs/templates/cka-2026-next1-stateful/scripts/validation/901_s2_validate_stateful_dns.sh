#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status statefulset/web -n stateful-lab --timeout=180s >/dev/null
kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local 2>/dev/null | grep -Eq 'Name:|Address:' || {
  echo "dns-debug must resolve web-0.web-svc.stateful-lab.svc.cluster.local"
  exit 1
}

echo "StatefulSet web is Ready and ordinal DNS resolves through web-svc"
