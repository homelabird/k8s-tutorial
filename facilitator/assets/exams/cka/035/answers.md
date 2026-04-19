# CKA 2026 Single Domain Drill 035 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n identity-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-api
  template:
    metadata:
      labels:
        app: metrics-api
    spec:
      serviceAccountName: metrics-sa
      automountServiceAccountToken: false
      volumes:
        - name: identity-token
          projected:
            sources:
              - serviceAccountToken:
                  path: token
                  audience: metrics-api
                  expirationSeconds: 3600
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - test -s /var/run/metrics/token && sleep 3600
          volumeMounts:
            - name: identity-token
              mountPath: /var/run/metrics
              readOnly: true
EOF

kubectl rollout status deployment/metrics-api -n identity-lab
kubectl exec -n identity-lab deploy/metrics-api -- test -s /var/run/metrics/token
```
