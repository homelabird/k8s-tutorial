# CKA 2026 Single Domain Drill 041 Answers

## Question 1

One valid repair flow is:

```bash
kubectl patch pvc analytics-data -n pv-resize-lab --type merge -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'

kubectl apply -n pv-resize-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: analytics-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: analytics-api
  template:
    metadata:
      labels:
        app: analytics-api
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - sh
            - -c
            - echo resize-ready > /var/lib/analytics/resize-ready.txt && sleep 3600
          volumeMounts:
            - name: data
              mountPath: /var/lib/analytics
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: analytics-data
EOF

kubectl rollout status deployment/analytics-api -n pv-resize-lab
kubectl exec -n pv-resize-lab deploy/analytics-api -- cat /var/lib/analytics/resize-ready.txt
```
