# CKA 2026 Next PV Reclaim Wave Answers

## Question 2101

One valid repair flow is:

```bash
kubectl apply -n pv-reclaim-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reports-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reports-db
  template:
    metadata:
      labels:
        app: reports-db
    spec:
      containers:
        - name: db
          image: busybox:1.36
          command:
            - sh
            - -c
            - echo reports-ready > /var/lib/reporting/ready.txt && sleep 3600
          volumeMounts:
            - name: data
              mountPath: /var/lib/reporting
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: reports-data
EOF

kubectl rollout status deployment/reports-db -n pv-reclaim-lab
kubectl exec -n pv-reclaim-lab deploy/reports-db -- cat /var/lib/reporting/ready.txt
```
