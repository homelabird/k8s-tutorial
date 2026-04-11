#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COLLECTOR="$ROOT_DIR/scripts/verify/collect-cka-2026-diagnostics.sh"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
FIXTURE_DIR="$TMP_DIR/fixtures"
OUTPUT_DIR="$TMP_DIR/output"
EXAM_ID="11111111-1111-4111-8111-111111111111"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

mkdir -p "$FAKE_BIN" "$FIXTURE_DIR" "$OUTPUT_DIR"

cat >"$FIXTURE_DIR/facilitator.log" <<EOF
2026-04-10 21:00:00 [info]: Received request to create exam {"examId":"cka-fixture","service":"facilitator-service"}
2026-04-10 21:00:01 [info]: Exam created successfully with ID: ${EXAM_ID} {"service":"facilitator-service"}
2026-04-10 21:00:02 [info]: Executing command on jumphost shared-alpha: prepare-exam-env {"service":"facilitator-service"}
2026-04-10 21:00:03 [info]: Command : prepare-exam-env, result : {"host":"shared-alpha","exitCode":0} {"service":"facilitator-service"}
2026-04-10 21:00:04 [info]: Executing command on jumphost dns-east: prepare-exam-env {"service":"facilitator-service"}
2026-04-10 21:00:05 [info]: Command : prepare-exam-env, result : {"host":"dns-east","exitCode":0} {"service":"facilitator-service"}
2026-04-10 21:00:06 [info]: Executing command on jumphost metrics-west: prepare-exam-env {"service":"facilitator-service"}
2026-04-10 21:00:07 [info]: Command : prepare-exam-env, result : {"host":"metrics-west","exitCode":0} {"service":"facilitator-service"}
2026-04-10 21:00:10 [info]: Received request to evaluate exam {"examId":"${EXAM_ID}","service":"facilitator-service"}
2026-04-10 21:00:11 [info]: Evaluating question 1 {"service":"facilitator-service"}
2026-04-10 21:00:11 [info]: Verification ID: 1 {"service":"facilitator-service"}
2026-04-10 21:00:11 [info]: Description: shared api healthy {"service":"facilitator-service"}
2026-04-10 21:00:12 [info]: Verification 1 for question 1: PASSED {"host":"shared-alpha","service":"facilitator-service"}
2026-04-10 21:00:13 [info]: Evaluating question 2 {"service":"facilitator-service"}
2026-04-10 21:00:13 [info]: Verification ID: 2 {"service":"facilitator-service"}
2026-04-10 21:00:13 [info]: Description: dedicated dns restored {"service":"facilitator-service"}
2026-04-10 21:00:15 [info]: Verification 2 for question 2: FAILED {"host":"dns-east","stdout":"dns restore lag","service":"facilitator-service"}
2026-04-10 21:00:16 [info]: Evaluating question 3 {"service":"facilitator-service"}
2026-04-10 21:00:16 [info]: Verification ID: 3 {"service":"facilitator-service"}
2026-04-10 21:00:16 [info]: Description: metrics scrape ready {"service":"facilitator-service"}
2026-04-10 21:00:17 [info]: Verification 3 for question 3: PASSED {"host":"metrics-west","service":"facilitator-service"}
2026-04-10 21:00:18 [info]: Exam ${EXAM_ID} evaluation completed with score: 67% {"service":"facilitator-service"}
2026-04-10 21:00:19 [info]: Received request to evaluate exam {"examId":"${EXAM_ID}","service":"facilitator-service"}
2026-04-10 21:00:20 [info]: Evaluating question 1 {"service":"facilitator-service"}
2026-04-10 21:00:20 [info]: Verification ID: 1 {"service":"facilitator-service"}
2026-04-10 21:00:20 [info]: Description: shared api healthy {"service":"facilitator-service"}
2026-04-10 21:00:21 [info]: Verification 1 for question 1: PASSED {"host":"shared-alpha","service":"facilitator-service"}
2026-04-10 21:00:21 [info]: Evaluating question 2 {"service":"facilitator-service"}
2026-04-10 21:00:21 [info]: Verification ID: 2 {"service":"facilitator-service"}
2026-04-10 21:00:21 [info]: Description: dedicated dns restored {"service":"facilitator-service"}
2026-04-10 21:00:22 [info]: Verification 2 for question 2: PASSED {"host":"dns-east","service":"facilitator-service"}
2026-04-10 21:00:23 [info]: Evaluating question 3 {"service":"facilitator-service"}
2026-04-10 21:00:23 [info]: Verification ID: 3 {"service":"facilitator-service"}
2026-04-10 21:00:23 [info]: Description: metrics scrape ready {"service":"facilitator-service"}
2026-04-10 21:00:24 [info]: Verification 3 for question 3: PASSED {"host":"metrics-west","service":"facilitator-service"}
2026-04-10 21:00:25 [info]: Exam ${EXAM_ID} evaluation completed with score: 100% {"service":"facilitator-service"}
2026-04-10 21:00:26 [info]: Executing command on jumphost shared-alpha: cleanup-exam-env {"service":"facilitator-service"}
2026-04-10 21:00:27 [info]: Command : cleanup-exam-env, result : {"host":"shared-alpha","exitCode":0} {"service":"facilitator-service"}
2026-04-10 21:00:28 [info]: Executing command on jumphost dns-east: cleanup-exam-env {"service":"facilitator-service"}
2026-04-10 21:00:29 [info]: Command : cleanup-exam-env, result : {"host":"dns-east","exitCode":0} {"service":"facilitator-service"}
2026-04-10 21:00:30 [info]: Executing command on jumphost metrics-west: cleanup-exam-env {"service":"facilitator-service"}
2026-04-10 21:00:31 [info]: Command : cleanup-exam-env, result : {"host":"metrics-west","exitCode":0} {"service":"facilitator-service"}
EOF

cat >"$FIXTURE_DIR/jumphost.log" <<'EOF'
shared-host-placeholder
EOF

cat >"$FIXTURE_DIR/jumphost-dns.log" <<'EOF'
dns-host-placeholder
EOF

cat >"$FIXTURE_DIR/kind-cluster.log" <<'EOF'
kind-cluster-placeholder
EOF

cat >"$FIXTURE_DIR/kind-cluster-dns.log" <<'EOF'
kind-cluster-dns-placeholder
EOF

cat >"$FAKE_BIN/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

cat >"$FAKE_BIN/podman" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

fixture_dir="${PODMAN_FIXTURE_DIR:?}"

if [ "$#" -eq 0 ]; then
  exit 0
fi

case "$1" in
  ps)
    printf 'CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES\n'
    ;;
  images)
    printf 'REPOSITORY  TAG  IMAGE ID  CREATED  SIZE\n'
    ;;
  container)
    if [ "${2:-}" = "exists" ]; then
      exit 0
    fi
    ;;
  logs)
    case "${2:-}" in
      k8s-tutorial_facilitator_1) cat "$fixture_dir/facilitator.log" ;;
      k8s-tutorial_jumphost_1) cat "$fixture_dir/jumphost.log" ;;
      k8s-tutorial_jumphost-dns_1) cat "$fixture_dir/jumphost-dns.log" ;;
      kind-cluster) cat "$fixture_dir/kind-cluster.log" ;;
      kind-cluster-dns) cat "$fixture_dir/kind-cluster-dns.log" ;;
      *) printf 'unknown-container %s\n' "${2:-missing}" ;;
    esac
    ;;
  compose)
    shift
    while [ "${1:-}" = "-f" ]; do
      shift 2
    done
    case "${1:-}" in
      ps)
        printf 'NAME  IMAGE  COMMAND  SERVICE  STATUS  PORTS\n'
        ;;
      logs)
        printf 'compose-log-placeholder\n'
        ;;
      *)
        printf 'unsupported compose invocation: %s\n' "$*" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    printf 'unsupported podman invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF

cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

headers_file=""
body_file=""
url=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -D)
      headers_file="$2"
      shift 2
      ;;
    -o)
      body_file="$2"
      shift 2
      ;;
    -w|-s|-S|-sS)
      shift
      if [ "${1:-}" = "%{http_code}" ]; then
        shift
      fi
      ;;
    *)
      url="$1"
      shift
      ;;
  esac
done

status="404"
body='{"error":"no current exam"}'

if [ -n "$headers_file" ]; then
  printf 'HTTP/1.1 %s Fixture\nContent-Type: application/json\n\n' "$status" >"$headers_file"
fi

if [ -n "$body_file" ]; then
  printf '%s\n' "$body" >"$body_file"
fi

printf '%s' "$status"
EOF

chmod +x "$FAKE_BIN/sudo" "$FAKE_BIN/podman" "$FAKE_BIN/curl"

PATH="$FAKE_BIN:$PATH" \
PODMAN_FIXTURE_DIR="$FIXTURE_DIR" \
BASE_URL="http://fixture.invalid" \
bash "$COLLECTOR" "$OUTPUT_DIR"

expected_hosts="$TMP_DIR/expected-hosts.txt"
cat >"$expected_hosts" <<'EOF'
shared-alpha
dns-east
metrics-west
EOF

diff -u "$expected_hosts" "$OUTPUT_DIR/summary-hosts.txt"
grep -Fq 'Current exam HTTP status: 404' "$OUTPUT_DIR/summary.txt"
grep -Fq 'Current exam ID: no-active-exam-id' "$OUTPUT_DIR/summary.txt"
grep -Fq 'Summary suite ID: cka-fixture' "$OUTPUT_DIR/summary.txt"
grep -Fq 'Overall health: recovery verified after initial failures' "$OUTPUT_DIR/summary.txt"
grep -Fq 'Evaluation attempts: 2' "$OUTPUT_DIR/summary.txt"
grep -Fq 'Evaluation score history: 67%, 100%' "$OUTPUT_DIR/summary.txt"
grep -Fq '  2. shared-alpha-orchestration.log' "$OUTPUT_DIR/summary.txt"
grep -Fq '  3. dns-east-orchestration.log' "$OUTPUT_DIR/summary.txt"
grep -Fq '  4. metrics-west-orchestration.log' "$OUTPUT_DIR/summary.txt"
grep -Fq 'Host: dns-east' "$OUTPUT_DIR/summary.txt"
grep -Fq 'last failed verification: q2/v2 - dns restore lag' "$OUTPUT_DIR/summary.txt"
grep -Fq 'recovery: 2026-04-10 21:00:15 -> 2026-04-10 21:00:22 (7s)' "$OUTPUT_DIR/summary.txt"
grep -Fq 'q2: 1 passed / 1 failed, latest attempt PASSED, last failure q2/v2 - dns restore lag, recovery 2026-04-10 21:00:15 -> 2026-04-10 21:00:22 (7s)' "$OUTPUT_DIR/summary.txt"
grep -Fq '"host":"dns-east"' "$OUTPUT_DIR/dns-east-orchestration.log"
! grep -Fq '"host":"shared-alpha"' "$OUTPUT_DIR/dns-east-orchestration.log"

echo "cka-2026 diagnostics collector smoke passed"
