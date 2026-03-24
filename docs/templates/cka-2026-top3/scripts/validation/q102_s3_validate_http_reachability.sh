#!/bin/bash
set -e

kubectl exec -n dns-lab dns-check -- wget -qO- http://web.dns-lab.svc.cluster.local >/tmp/q102-http.out 2>/tmp/q102-http.err
echo "dns-check can reach the web service over HTTP"
exit 0
