# CKAD Quick Drill - Deployment Basics

## Question 1: Create namespace `app-team` and Deployment `web-frontend`

One valid solution is:

```bash
kubectl create namespace app-team

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: app-team
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.0-alpine
EOF
```

You can also create the Deployment with `kubectl create deployment` and patch or edit it afterward, but the final resource must keep the selector and Pod template labels aligned on `app=web-frontend`.
