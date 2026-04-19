# CKA 2026 Single Domain Drill 020 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n connectivity-lab -f - <<'EOF_SERVICE'
apiVersion: v1
kind: Service
metadata:
  name: echo-api
spec:
  selector:
    app: echo-api
  ports:
    - port: 8080
      targetPort: 8080
EOF_SERVICE

kubectl apply -n connectivity-lab -f - <<'EOF_HEADLESS'
apiVersion: v1
kind: Service
metadata:
  name: echo-api-headless
spec:
  clusterIP: None
  selector:
    app: echo-api
  ports:
    - port: 8080
      targetPort: 8080
EOF_HEADLESS

kubectl rollout status statefulset/echo-api -n connectivity-lab
kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local
kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz
kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz
```

Expected checks:

- Services `echo-api` and `echo-api-headless` use the intended selectors and ports
- StatefulSet `echo-api` stays Ready with `serviceName: echo-api-headless`
- `net-debug` resolves the Service name and fetches `ok` through both the ClusterIP and headless ordinal DNS paths
