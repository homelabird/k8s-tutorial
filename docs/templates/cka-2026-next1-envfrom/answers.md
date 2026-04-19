# CKA 2026 Next EnvFrom Wave Answers

## Question 2601

One valid repair flow is:

```bash
kubectl apply -n envfrom-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: env-bundle
spec:
  replicas: 1
  selector:
    matchLabels:
      app: env-bundle
  template:
    metadata:
      labels:
        app: env-bundle
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - test "${MODE}" = "production" && test "${SECRET_API_KEY}" = "stable-key" && sleep 3600
          envFrom:
            - configMapRef:
                name: app-env
            - secretRef:
                name: app-secret
              prefix: SECRET_
EOF

kubectl rollout status deployment/env-bundle -n envfrom-lab
kubectl exec -n envfrom-lab deploy/env-bundle -- env | grep -E '^(MODE|SECRET_API_KEY)='
```
