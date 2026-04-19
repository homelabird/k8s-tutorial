#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="staticpod-lab"
OUTPUT_DIR="/tmp/exam/q2401"
MANIFEST_DIR="/etc/kubernetes/manifests"
MANIFEST_PATH="${MANIFEST_DIR}/audit-agent.yaml"
SYNC_SCRIPT="/tmp/staticpod-sync-audit-agent.sh"
SYNC_PID_FILE="/tmp/staticpod-sync-audit-agent.pid"
MIRROR_POD_NAME="audit-agent-ckad9999"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete pod -n "${NAMESPACE}" -l app=audit-agent --ignore-not-found >/dev/null 2>&1 || true

if [ -f "${SYNC_PID_FILE}" ]; then
  EXISTING_PID="$(cat "${SYNC_PID_FILE}" 2>/dev/null || true)"
  if [ -n "${EXISTING_PID}" ] && kill -0 "${EXISTING_PID}" 2>/dev/null; then
    kill "${EXISTING_PID}" >/dev/null 2>&1 || true
  fi
  rm -f "${SYNC_PID_FILE}"
fi

mkdir -p "${OUTPUT_DIR}" "${MANIFEST_DIR}"
rm -f "${OUTPUT_DIR}/staticpod-rollout-status.txt"
rm -f "${MANIFEST_PATH}"
rm -f "${SYNC_SCRIPT}"

cat <<'EOF_MANIFEST' > "${MANIFEST_PATH}"
apiVersion: v1
kind: Pod
metadata:
  name: audit-agent
  namespace: staticpod-lab
  labels:
    app: audit-agent
spec:
  hostNetwork: false
  containers:
    - name: agent
      image: busybox:1.36
      command:
        - /bin/sh
        - -c
        - while true; do echo stale-audit; sleep 30; done
EOF_MANIFEST

cat <<'EOF_SYNC' > "${SYNC_SCRIPT}"
#!/usr/bin/env bash
set -euo pipefail

MANIFEST_PATH="/etc/kubernetes/manifests/audit-agent.yaml"
NAMESPACE="staticpod-lab"
MIRROR_POD_NAME="audit-agent-ckad9999"
LAST_HASH=""

build_manifest() {
  local output_path="$1"

  awk -v mirror_name="${MIRROR_POD_NAME}" '
    BEGIN {
      in_metadata = 0
    }
    /^metadata:[[:space:]]*$/ {
      in_metadata = 1
      print
      next
    }
    in_metadata && /^[[:space:]]+name:[[:space:]]+/ {
      sub(/name:[[:space:]]+.*/, "name: " mirror_name)
      print
      next
    }
    /^spec:[[:space:]]*$/ {
      in_metadata = 0
      print
      next
    }
    {
      print
    }
  ' "${MANIFEST_PATH}" > "${output_path}"
}

while true; do
  if [ -f "${MANIFEST_PATH}" ]; then
    CURRENT_HASH="$(sha256sum "${MANIFEST_PATH}" | awk '{print $1}')"
    if [ "${CURRENT_HASH}" != "${LAST_HASH}" ]; then
      TMP_MANIFEST="$(mktemp)"
      build_manifest "${TMP_MANIFEST}"

      if kubectl apply --dry-run=client -f "${TMP_MANIFEST}" >/dev/null 2>&1; then
        kubectl delete pod "${MIRROR_POD_NAME}" -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
        kubectl apply -f "${TMP_MANIFEST}" >/dev/null 2>&1 || true
        LAST_HASH="${CURRENT_HASH}"
      fi

      rm -f "${TMP_MANIFEST}"
    fi
  fi

  sleep 2
done
EOF_SYNC

chmod +x "${SYNC_SCRIPT}"
nohup "${SYNC_SCRIPT}" >/tmp/staticpod-sync-audit-agent.log 2>&1 &
echo "$!" > "${SYNC_PID_FILE}"

for _ in $(seq 1 60); do
  POD_NAME="$(kubectl get pods -n "${NAMESPACE}" -l app=audit-agent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "${POD_NAME}" ]; then
    exit 0
  fi
  sleep 2
done

echo "static pod mirror pod did not appear" >&2
exit 1
