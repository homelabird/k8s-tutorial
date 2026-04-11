#!/bin/bash
set -e

DNS_POLICY=$(kubectl get pod dns-check -n dns-lab -o jsonpath='{.spec.dnsPolicy}' 2>/dev/null || true)

if [ -n "$DNS_POLICY" ] && [ "$DNS_POLICY" != "ClusterFirst" ]; then
  echo "dns-check is not using the default cluster DNS path"
  exit 1
fi

OUTPUT="$(kubectl exec -n dns-lab dns-check -- sh -lc 'nslookup web.dns-lab.svc.cluster.local && nslookup kubernetes.default.svc.cluster.local' 2>&1)" || {
  echo "dns-check failed to resolve one or more cluster service names"
  exit 1
}

printf '%s\n' "$OUTPUT" >/tmp/q1-nslookup.out
echo "dns-check resolves web.dns-lab.svc.cluster.local"
exit 0
