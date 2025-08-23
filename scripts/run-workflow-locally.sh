#!/usr/bin/env bash
set -euo pipefail

# Convenience helper to run the single-job GitHub Actions workflow locally with act.
# The workflow now derives MODE internally (local-act outside GitHub). You can force MODE=ci.
# Usage:
#   ./run-local [options] [-- additional act args]
# Options:
#   -w, --workflow <file>   Path to workflow file (default .github/workflows/docker-build-push.yml)
#   -j, --job <id>          Job ID (default build-test-publish)
#       --ci                Force MODE=ci (multi-arch setup, login, tags)
#       --local             Force MODE=local-act
#   -h, --help              Show help
# Anything after '--' is passed verbatim to act.

WORKFLOW_FILE=".github/workflows/docker-build-push.yml"
JOB_NAME="build-test-publish"
FORCED_MODE=""
EXTRA_ARGS=()
PASSTHRU=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--workflow)
      WORKFLOW_FILE="$2"; shift 2;;
    -j|--job)
      JOB_NAME="$2"; shift 2;;
    --ci)
      FORCED_MODE="ci"; shift;;
    --local)
      FORCED_MODE="local-act"; shift;;
    -h|--help)
      sed -n '1,40p' "$0" | sed -n '/Usage:/,/^$/p'; exit 0;;
    --)
      shift; PASSTHRU+=("$@"); break;;
    *)
      EXTRA_ARGS+=("$1"); shift;;
  esac
done

if ! command -v act >/dev/null 2>&1; then
  echo "[run-local] ERROR: 'act' not found on PATH. Install: https://github.com/nektos/act" >&2
  exit 1
fi

echo "[run-local] workflow=${WORKFLOW_FILE} job=${JOB_NAME} forced_mode=${FORCED_MODE:-auto}" >&2
echo "[run-local] Extra args: ${EXTRA_ARGS[*]:-(none)}" >&2
echo "[run-local] Passthru: ${PASSTHRU[*]:-(none)}" >&2

if [[ -n "${FORCED_MODE}" ]]; then
  ACT_CMD=(env MODE="${FORCED_MODE}" act -W "${WORKFLOW_FILE}" -j "${JOB_NAME}" "${EXTRA_ARGS[@]}" "${PASSTHRU[@]}")
else
  ACT_CMD=(act -W "${WORKFLOW_FILE}" -j "${JOB_NAME}" "${EXTRA_ARGS[@]}" "${PASSTHRU[@]}")
fi
echo "[run-local] Command: ${ACT_CMD[*]}" >&2

"${ACT_CMD[@]}"
