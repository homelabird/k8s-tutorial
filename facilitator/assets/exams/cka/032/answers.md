# CKA 2026 Single Domain Drill 032 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n probe-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health-api
  template:
    metadata:
      labels:
        app: health-api
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - mkdir -p /www && echo ok > /www/healthz && echo probe > /www/index.html && httpd -f -p 8080 -h /www
          ports:
            - containerPort: 8080
          startupProbe:
            httpGet:
              path: /healthz
              port: 8080
            periodSeconds: 2
            failureThreshold: 15
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            periodSeconds: 5
EOF

kubectl rollout status deployment/health-api -n probe-lab
kubectl exec -n probe-lab deploy/health-api -- wget -qO- http://127.0.0.1:8080/healthz
```
