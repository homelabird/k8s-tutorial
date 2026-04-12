# CKA 2026 Single Domain Drill - CRD and Operator Installation Checks

## Question 1: repair the CRD, operator Deployment, and custom resource bundle

Repair the installation bundle so the CRD, operator Deployment, and custom resource all use the intended contract.

```bash
cat <<'EOF_CRD' | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.training.cka.io
spec:
  group: training.cka.io
  scope: Namespaced
  names:
    plural: widgets
    singular: widget
    kind: Widget
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required:
            - image
            - replicas
            properties:
              image:
                type: string
              replicas:
                type: integer
EOF_CRD

kubectl wait --for=condition=established --timeout=120s crd/widgets.training.cka.io

cat <<'EOF_OPERATOR' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: widget-operator
  namespace: operator-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: widget-operator
  template:
    metadata:
      labels:
        app: widget-operator
    spec:
      containers:
      - name: manager
        image: busybox:1.36.1
        command:
        - sh
        - -c
        - sleep 3600
EOF_OPERATOR

kubectl rollout status deployment/widget-operator -n operator-lab --timeout=180s

cat <<'EOF_WIDGET' | kubectl apply -f -
apiVersion: training.cka.io/v1alpha1
kind: Widget
metadata:
  name: sample-widget
  namespace: operator-lab
spec:
  image: nginx:1.25.5
  replicas: 2
EOF_WIDGET

mkdir -p /tmp/exam/q1
kubectl get crd widgets.training.cka.io -o yaml > /tmp/exam/q1/widget-crd.yaml
```

Expected checks:

- the CRD uses group `training.cka.io`, kind `Widget`, plural `widgets`, scope `Namespaced`, and requires `spec.image` and `spec.replicas`
- `spec.image` is a string and `spec.replicas` is an integer in the CRD schema
- `widget-operator` runs one ready replica with image `busybox:1.36.1` and a long-running `sleep 3600` command
- `sample-widget` uses `training.cka.io/v1alpha1`, `nginx:1.25.5`, and `replicas: 2`
- the repaired CRD manifest is exported to `/tmp/exam/q1/widget-crd.yaml`
