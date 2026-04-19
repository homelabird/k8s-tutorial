# CKA 2026 Next Projected Volume Wave Answers

## Question 2501

One valid repair flow is:

```bash
kubectl apply -n projectedvolume-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bundle-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bundle-api
  template:
    metadata:
      labels:
        app: bundle-api
    spec:
      volumes:
        - name: bundle-data
          projected:
            sources:
              - configMap:
                  name: bundle-config
                  items:
                    - key: app.conf
                      path: config/app.conf
              - secret:
                  name: bundle-secret
                  items:
                    - key: token
                      path: secret/token
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -Fx 'mode=production' /etc/bundle/config/app.conf && grep -Fx 'token=stable' /etc/bundle/secret/token && sleep 3600
          volumeMounts:
            - name: bundle-data
              mountPath: /etc/bundle
              readOnly: true
EOF

kubectl rollout status deployment/bundle-api -n projectedvolume-lab
kubectl exec -n projectedvolume-lab deploy/bundle-api -- sh -c 'cat /etc/bundle/config/app.conf && cat /etc/bundle/secret/token'
```
