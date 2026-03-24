#!/bin/bash
set -e

kubectl exec -n dns-lab dns-check -- nslookup web.dns-lab.svc.cluster.local >/tmp/q2-nslookup.out 2>/tmp/q2-nslookup.err
echo "dns-check can resolve web.dns-lab.svc.cluster.local"
exit 0
