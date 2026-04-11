#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

OUTPUT_DIR="${1:-.artifacts/cka-2026-pack}"
ARCHIVE_PATH="${2:-${OUTPUT_DIR%/}.tar.gz}"
SKIP_COLLECT="${SKIP_COLLECT:-0}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

if [ "${SKIP_COLLECT}" != "1" ]; then
  log "Collecting diagnostics into ${OUTPUT_DIR}"
  BASE_URL="${BASE_URL:-http://127.0.0.1:30080}" \
    "${SCRIPT_DIR}/collect-cka-2026-diagnostics.sh" "${OUTPUT_DIR}"
fi

if [ ! -d "${OUTPUT_DIR}" ]; then
  printf 'Diagnostics directory not found: %s\n' "${OUTPUT_DIR}" >&2
  exit 1
fi

mkdir -p "$(dirname "${ARCHIVE_PATH}")"
rm -f "${ARCHIVE_PATH}"

relative_output_dir="${OUTPUT_DIR#./}"
relative_archive_path="${ARCHIVE_PATH#./}"

log "Packing diagnostics directory ${relative_output_dir} into ${relative_archive_path}"
(
  cd "${REPO_ROOT}"
  tar -czf "${relative_archive_path}" "${relative_output_dir}"
)

log "Diagnostics archive created at ${ARCHIVE_PATH}"
