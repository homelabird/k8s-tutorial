# CKA 2026 Single Domain Drill 033 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n init-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-api
  template:
    metadata:
      labels:
        app: report-api
    spec:
      volumes:
        - name: shared-data
          emptyDir: {}
        - name: seed-data
          emptyDir: {}
      initContainers:
        - name: bootstrap
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - mkdir -p /work && echo ready=1 > /work/report.txt
          volumeMounts:
            - name: shared-data
              mountPath: /work
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -Fx 'ready=1' /work/report.txt && sleep 3600
          volumeMounts:
            - name: shared-data
              mountPath: /work
EOF

kubectl rollout status deployment/report-api -n init-lab
kubectl exec -n init-lab deploy/report-api -- cat /work/report.txt
```
