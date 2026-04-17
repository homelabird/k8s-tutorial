#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/dns-diagnostics-brief.yaml"
[[ -f "$MANIFEST" ]]

grep -F "targetWorkload: dns-client" "$MANIFEST" >/dev/null
grep -F "safeManifestNote" "$MANIFEST" >/dev/null
grep -F "confirm dnsPolicy, dnsConfig nameservers, searches, and options before changing workload manifests or cluster DNS services" "$MANIFEST" >/dev/null
! grep -Eq 'kubectl delete pod dns-client|kubectl rollout restart deployment dns-client|kubectl patch deployment dns-client|CoreDNS|kube-dns' "$MANIFEST"
