# CKA 2026 Next RWOP Wave Answers

## Question 2801

One valid repair flow is:

```bash
kubectl apply -n rwop-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rwop-reader
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rwop-reader
  template:
    metadata:
      labels:
        app: rwop-reader
    spec:
      containers:
        - name: reader
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - echo reader-ready > /data/app/reader.txt && sleep 3600
          volumeMounts:
            - name: data
              mountPath: /data/app
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: data-claim
EOF

kubectl rollout status deployment/rwop-reader -n rwop-lab
kubectl exec -n rwop-lab deploy/rwop-reader -- cat /data/app/reader.txt
```
