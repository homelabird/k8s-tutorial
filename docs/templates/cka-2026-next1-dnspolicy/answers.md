# Answers: Pod DNS policy and dnsConfig diagnostics

## Question 4801

Repair `dns-diagnostics-brief` in namespace `dnspolicy-lab` so it documents the exact Pod DNS wiring used by pod `dns-client`, then export the repaired ConfigMap manifest and a plain-text checklist.

Expected repaired fields:

- `targetWorkload: dns-client`
- `podInventory: kubectl get pod dns-client -n dnspolicy-lab -o wide`
- `dnsPolicyCheck: kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsPolicy}'`
- `dnsNameserverCheck: kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.nameservers[0]}'`
- `dnsSearchCheck: kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.searches[0]}'`
- `dnsOptionCheck: kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.options[0].name}'`
- `resolverFileCheck: kubectl exec -n dnspolicy-lab dns-client -- cat /etc/resolv.conf`
- `eventCheck: kubectl get events -n dnspolicy-lab --sort-by=.lastTimestamp`
- `safeManifestNote: confirm dnsPolicy, dnsConfig nameservers, searches, and options before changing workload manifests or cluster DNS services`

Expected checklist sections and representative lines:

### Pod DNS Inventory

- `kubectl get pod dns-client -n dnspolicy-lab -o wide`
- `kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsPolicy}'`

### dnsConfig Checks

- `kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.nameservers[0]}'`
- `kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.searches[0]}'`
- `kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.spec.dnsConfig.options[0].name}'`
- `kubectl exec -n dnspolicy-lab dns-client -- cat /etc/resolv.conf`
- `kubectl get events -n dnspolicy-lab --sort-by=.lastTimestamp`

### Safe Manifest Review

- `kubectl get pod dns-client -n dnspolicy-lab -o yaml`
- export `/tmp/exam/q1/dns-diagnostics-brief.yaml`
- verify the note about confirming `dnsPolicy`, `dnsConfig`, and resolver settings before changing workload or cluster DNS objects

Unsafe actions for this drill:

- `kubectl delete pod dns-client -n dnspolicy-lab`
- `kubectl rollout restart deployment dns-client -n dnspolicy-lab`
- `kubectl patch deployment dns-client -n dnspolicy-lab ...`
- any edits to cluster DNS services such as CoreDNS or kube-dns
