# CKAD Single-Question Template Answers

## Question 1: Create namespace `app-team` and Deployment `web-frontend`

One valid solution is:

```bash
kubectl create namespace app-team

kubectl create deployment web-frontend \
  --image=nginx:1.27.0-alpine \
  -n app-team

kubectl scale deployment web-frontend \
  --replicas=2 \
  -n app-team

kubectl label deployment web-frontend \
  app=web-frontend \
  -n app-team \
  --overwrite
```

Or as a manifest:

```yaml
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
```

This template intentionally uses a simple creation task so you can replace the resource names, image, replica count, and validation logic with your own requirements.
