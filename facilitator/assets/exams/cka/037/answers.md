# CKA 2026 Single Domain Drill 037 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n priority-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: batch-api
  template:
    metadata:
      labels:
        app: batch-api
    spec:
      priorityClassName: ops-critical
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
EOF

kubectl rollout status deployment/batch-api -n priority-lab
kubectl get pods -n priority-lab -l app=batch-api -o jsonpath='{.items[0].spec.priorityClassName}{"\n"}'
```
