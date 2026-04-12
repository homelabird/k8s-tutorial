## Question 201: RBAC least-privilege repair

Create a namespace-scoped Role and RoleBinding so the existing ServiceAccount `report-reader` can only `get` and `list` Pods in namespace `rbac-lab`.

```yaml
cat <<'EOF_ROLE' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: report-reader
  namespace: rbac-lab
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF_ROLE

cat <<'EOF_ROLEBINDING' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: report-reader
  namespace: rbac-lab
subjects:
- kind: ServiceAccount
  name: report-reader
  namespace: rbac-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: report-reader
EOF_ROLEBINDING
```

Expected checks:

- the Role and RoleBinding are namespace-scoped in `rbac-lab`
- `kubectl auth can-i get pods` and `kubectl auth can-i list pods` succeed for `system:serviceaccount:rbac-lab:report-reader`
- write verbs and unrelated resources such as `secrets` are not granted

## Question 202: Deployment rolling update and rollback

The existing Deployment `web-app` in namespace `rollout-lab` should be updated to `nginx:1.25.5`, its rolling update strategy should be tightened, rollout history should be written to `/tmp/exam/q202/rollout-history.txt`, and the Deployment should then be rolled back to the original image.

```bash
kubectl patch deployment web-app -n rollout-lab --type merge -p '{
  "spec": {
    "strategy": {
      "type": "RollingUpdate",
      "rollingUpdate": {
        "maxUnavailable": 1,
        "maxSurge": 1
      }
    }
  }
}'

kubectl annotate deployment web-app -n rollout-lab \
  kubernetes.io/change-cause='update image to nginx:1.25.5' \
  --overwrite

kubectl set image deployment/web-app nginx=nginx:1.25.5 -n rollout-lab
kubectl rollout status deployment/web-app -n rollout-lab

kubectl rollout history deployment/web-app -n rollout-lab > /tmp/exam/q202/rollout-history.txt

kubectl rollout undo deployment/web-app -n rollout-lab
kubectl rollout status deployment/web-app -n rollout-lab
```

Expected checks:

- the Deployment strategy is `RollingUpdate` with `maxUnavailable=1` and `maxSurge=1`
- rollout history is saved to `/tmp/exam/q202/rollout-history.txt`
- ReplicaSet history shows both the original image and `nginx:1.25.5`
- the final running image is the original pre-update image after rollback

## Question 203: NetworkPolicy troubleshooting

Use NetworkPolicies only to enforce the intended traffic graph inside `netpol-lab`.

```yaml
cat <<'EOF_API' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - podSelector:
        matchLabels:
          app: db
    ports:
    - protocol: TCP
      port: 5432
EOF_API

cat <<'EOF_DB' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 5432
EOF_DB
```

Expected checks:

- `api` is reachable only from `frontend` on TCP `8080`
- `db` is reachable only from `api` on TCP `5432`
- `api` keeps DNS egress to `kube-dns` so service discovery still works
- direct `frontend -> db` traffic is denied
- unrelated ingress to `api` and `db` is denied by default

## Question 204: PersistentVolume / PersistentVolumeClaim troubleshooting

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

Expected checks:

- `app-data` is `Bound` to `app-data-pv`
- `reporting-app` becomes `Available`
- the application Pod mounts the claim at `/data`
- the PV keeps the intended `Retain` policy and points to `storage-lab/app-data`

## Question 205: Scheduling with taints, tolerations, and node targeting

The existing Deployment `metrics-agent` in namespace `scheduling-lab` must be updated so it runs only on the ops node pool.

```bash
kubectl patch deployment metrics-agent -n scheduling-lab --type merge -p '{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "workload": "ops"
        },
        "tolerations": [
          {
            "key": "dedicated",
            "operator": "Equal",
            "value": "ops",
            "effect": "NoSchedule"
          }
        ]
      }
    }
  }
}'

kubectl rollout status deployment metrics-agent -n scheduling-lab
```

Expected checks:

- the Deployment tolerates `dedicated=ops:NoSchedule`
- the Deployment targets nodes labeled `workload=ops`
- Pods become Running on an ops-labeled node and do not escape to a broader node pool
