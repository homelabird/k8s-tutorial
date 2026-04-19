# CKA 2026 Single Domain Drill 042 Answers

## Question 1

One valid repair flow is:

```bash
kubectl debug pod/orders-api -n debug-lab \
  --image=busybox:1.36 \
  --target=api \
  --container=debugger \
  --attach=false \
  -- sh -c 'echo debug-ready && sleep 3600'

until kubectl get pod orders-api -n debug-lab -o jsonpath='{.status.ephemeralContainerStatuses[*].name}' | grep -qw debugger; do
  sleep 2
done

kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[*].name}{"\n"}'
until kubectl logs -n debug-lab orders-api -c debugger 2>/dev/null | grep -Fx 'debug-ready' >/dev/null; do
  sleep 2
done
```
