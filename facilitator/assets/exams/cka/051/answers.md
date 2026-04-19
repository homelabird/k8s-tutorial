# CKA 2026 Single Domain Drill 051 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n taints-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: taint-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: taint-api
  template:
    metadata:
      labels:
        app: taint-api
    spec:
      nodeSelector:
        workload: ops
      tolerations:
        - key: dedicated
          operator: Equal
          value: ops
          effect: NoExecute
          tolerationSeconds: 60
      containers:
        - name: api
          image: nginx:1.25.3
EOF

kubectl rollout status deployment/taint-api -n taints-lab
kubectl get pods -n taints-lab -l app=taint-api -o wide
```
