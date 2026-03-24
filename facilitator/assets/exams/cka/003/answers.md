# CKA 2026 Domain Drill - Security, Ingress, DNS

## Question 1: Pod Security Admission restricted profile

One valid solution is:

```bash
kubectl create namespace secure-workloads

kubectl label namespace secure-workloads \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  --overwrite

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: restricted-shell
  namespace: secure-workloads
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: busybox
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
EOF
```

## Question 2: CoreDNS troubleshooting

The setup intentionally misconfigures a dedicated `CoreDNS` instance inside `dns-lab`.

One valid recovery flow is:

```bash
kubectl -n dns-lab edit configmap coredns
```

Update the Corefile so the `kubernetes` plugin block uses:

```text
kubernetes cluster.local in-addr.arpa ip6.arpa
```

Then restart CoreDNS:

```bash
kubectl rollout restart deployment coredns -n dns-lab
kubectl rollout status deployment coredns -n dns-lab
```

Verify:

```bash
kubectl exec -n dns-lab dns-check -- nslookup web.dns-lab.svc.cluster.local
kubectl exec -n dns-lab dns-check -- wget -qO- http://web.dns-lab.svc.cluster.local
```

The validator also checks that the `dns-lab/coredns` Corefile directly serves `cluster.local`.

## Question 3: ingress-nginx installation and Ingress repair

One valid solution is:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080
```

Then fix the Ingress:

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: ingress-lab
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
EOF
```

The validator also checks that the rule keeps host `app.example.local` and path `/`.
