# CKA 2026 Single Domain Drill - Persistent Storage Troubleshooting

## Question 1: repair PV/PVC binding without breaking the workload contract

Keep the existing Deployment and PersistentVolume, and repair the claim binding so the workload can start on the intended storage.

Because the broken claim may be immutable, recreating the PVC with the same name is acceptable. Recreating the Deployment is not required.

```yaml
kubectl delete pvc app-data -n storage-lab --wait=true

cat <<'EOF_PVC' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
  namespace: storage-lab
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual
  volumeName: app-data-pv
EOF_PVC
```

```bash
kubectl rollout status deployment/reporting-app -n storage-lab
```

The validator also checks that:

- `app-data` is `Bound` to `app-data-pv`
- `reporting-app` becomes `Available`
- the application Pod mounts the claim at `/data`
- the PV keeps the intended `Retain` policy and points to `storage-lab/app-data`
