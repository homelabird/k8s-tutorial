# CKA 2026 Single Domain Drill 021 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n service-debug-lab -f - <<'EOF_SERVICE'
apiVersion: v1
kind: Service
metadata:
  name: echo-api
spec:
  type: ClusterIP
  selector:
    app: echo-api
  ports:
    - port: 8080
      targetPort: 8080
EOF_SERVICE

kubectl rollout status deployment/echo-api -n service-debug-lab
kubectl get endpoints echo-api -n service-debug-lab -o wide
kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz
```

Expected checks:

- Service `echo-api` uses the intended type, selector, and port wiring
- Deployment `echo-api` stays Available and Service `echo-api` publishes two ready endpoints
- `net-debug` fetches `ok` through `http://echo-api:8080/healthz`
