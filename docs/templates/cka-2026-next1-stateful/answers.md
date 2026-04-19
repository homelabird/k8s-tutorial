# CKA 2026 Next Stateful Wave Answers

## Question 901

One valid repair flow is:

```bash
kubectl apply -n stateful-lab -f - <<'EOF_SERVICE'
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  clusterIP: None
  selector:
    app: web
  ports:
    - name: http
      port: 80
      targetPort: 80
EOF_SERVICE

kubectl rollout status statefulset/web -n stateful-lab
kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local
kubectl get pvc -n stateful-lab
```
