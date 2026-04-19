# CKA 2026 Next subPath Wave Answers

## Question 2701

One valid repair flow is:

```bash
kubectl apply -n subpath-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: subpath-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: subpath-api
  template:
    metadata:
      labels:
        app: subpath-api
    spec:
      volumes:
        - name: app-config
          configMap:
            name: app-config
            items:
              - key: app.conf
                path: config/app.conf
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -q '^mode=production$' /etc/app/app.conf && grep -q '^feature=stable$' /etc/app/app.conf && sleep 3600
          volumeMounts:
            - name: app-config
              mountPath: /etc/app/app.conf
              subPath: config/app.conf
              readOnly: true
EOF

kubectl rollout status deployment/subpath-api -n subpath-lab
kubectl exec -n subpath-lab deploy/subpath-api -- cat /etc/app/app.conf
```
