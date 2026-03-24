# CKA 2026 Single Domain Drill - Cluster DNS Recovery

## Question 1: Cluster-wide CoreDNS recovery

The setup intentionally misconfigures the `kube-system/coredns` ConfigMap so the `kubernetes` plugin serves the wrong zone.

One valid recovery flow is:

```bash
kubectl -n kube-system edit configmap coredns
```

Update the Corefile so the `kubernetes` plugin block uses:

```text
kubernetes cluster.local in-addr.arpa ip6.arpa
```

Then restart CoreDNS:

```bash
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system
```

Verify:

```bash
kubectl exec -n dns-lab dns-check -- nslookup web.dns-lab.svc.cluster.local
kubectl exec -n dns-lab dns-check -- wget -qO- http://web.dns-lab.svc.cluster.local
```
