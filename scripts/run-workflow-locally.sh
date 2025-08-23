#!/usr/bin/env bash
set -euo pipefail

# Convenience helper to run the GitHub Actions workflow locally with act using matrix mode selection.
# Default runs the local variant (matrix.mode=local-act) of job 'build-test-publish'.
# Usage:
#   ./run-local [options] [-- additional act args]
# Options:
#   -w, --workflow <file>   Path to workflow file (default .github/workflows/docker-build-push.yml)
#   -j, --job <id>          Job ID (default build-test-publish)
#   -m, --mode <mode>       Matrix mode value (ci|local-act) default local-act
#       --ci                Shortcut for --mode ci
#       --local             Shortcut for --mode local-act
#   -h, --help              Show help
# Anything after '--' is passed verbatim to act.

WORKFLOW_FILE=".github/workflows/docker-build-push.yml"
JOB_NAME="build-test-publish"
MATRIX_MODE="local-act"
EXTRA_ARGS=()
PASSTHRU=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--workflow)
      WORKFLOW_FILE="$2"; shift 2;;
    -j|--job)
      JOB_NAME="$2"; shift 2;;
    -m|--mode)
      MATRIX_MODE="$2"; shift 2;;
    --ci)
      MATRIX_MODE="ci"; shift;;
    --local)
      MATRIX_MODE="local-act"; shift;;
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

echo "[run-local] workflow=${WORKFLOW_FILE} job=${JOB_NAME} matrix.mode=${MATRIX_MODE}" >&2
echo "[run-local] Extra args: ${EXTRA_ARGS[*]:-(none)}" >&2
echo "[run-local] Passthru: ${PASSTHRU[*]:-(none)}" >&2

ACT_CMD=(act -W "${WORKFLOW_FILE}" -j "${JOB_NAME}" --matrix "mode:${MATRIX_MODE}" "${EXTRA_ARGS[@]}" "${PASSTHRU[@]}")
echo "[run-local] Command: ${ACT_CMD[*]}" >&2

if ! "${ACT_CMD[@]}"; then
  echo "[run-local] First attempt failed. If this act version doesn't support --matrix flag syntax, try manually:" >&2
  echo "  act -W ${WORKFLOW_FILE} -j ${JOB_NAME} --matrix mode:${MATRIX_MODE}" >&2
  exit 1
fi
