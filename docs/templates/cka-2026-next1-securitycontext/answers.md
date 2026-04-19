# CKA 2026 Next SecurityContext Wave Answers

## Question 1701

One valid repair flow is:

```bash
kubectl apply -n securitycontext-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-api
  template:
    metadata:
      labels:
        app: secure-api
    spec:
      securityContext:
        runAsUser: 1000
        fsGroup: 2000
      volumes:
        - name: data
          emptyDir: {}
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - id -u | grep -Fx 1000 && echo secure > /data/secure.txt && sleep 3600
          securityContext:
            allowPrivilegeEscalation: false
            seccompProfile:
              type: RuntimeDefault
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: data
              mountPath: /data
EOF

kubectl rollout status deployment/secure-api -n securitycontext-lab
kubectl exec -n securitycontext-lab deploy/secure-api -- sh -c 'id -u && cat /data/secure.txt'
```
