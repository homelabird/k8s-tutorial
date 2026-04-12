# CKA 2026 Single Domain Drill - NetworkPolicy Troubleshooting

## Question 1: intended traffic graph with NetworkPolicies

Use NetworkPolicies only to enforce the intended traffic graph inside `netpol-lab`.

```yaml
cat <<'EOF_API' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - podSelector:
        matchLabels:
          app: db
    ports:
    - protocol: TCP
      port: 5432
EOF_API

cat <<'EOF_DB' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 5432
EOF_DB
```

The validator also checks that:

- `api` is reachable only from `frontend` on TCP `8080`
- `db` is reachable only from `api` on TCP `5432`
- `api` keeps DNS egress to `kube-dns` so service discovery still works
- direct `frontend -> db` traffic is denied
- unrelated ingress to `api` and `db` is denied by default
