#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/dns-diagnostics-checklist.txt"
[[ -f "$CHECKLIST" ]]

grep -Fx -- "Pod DNS Inventory" "$CHECKLIST" >/dev/null
grep -Fx -- "dnsConfig Checks" "$CHECKLIST" >/dev/null
grep -Fx -- "Safe Manifest Review" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get pod dns-client -n dnspolicy-lab -o wide" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsPolicy}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.nameservers[0]}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.searches[0]}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.options[0].name}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl exec -n dnspolicy-lab dns-client -- cat /etc/resolv.conf" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get events -n dnspolicy-lab --sort-by=.lastTimestamp" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get pod dns-client -n dnspolicy-lab -o yaml" "$CHECKLIST" >/dev/null
