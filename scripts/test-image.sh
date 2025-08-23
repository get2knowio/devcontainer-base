#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." &>/dev/null && pwd)"

if [[ -f "${ROOT_DIR}/.ci-env.cache" ]]; then
  # shellcheck disable=SC1090
  source "${ROOT_DIR}/.ci-env.cache"
else
  "${SCRIPT_DIR}/ci-env.sh"
  # shellcheck disable=SC1090
  source "${ROOT_DIR}/.ci-env.cache"
fi

IMAGE="${CI_IMAGE}"
export IMAGE
echo "[test-image] Testing image: ${IMAGE}" >&2

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "[test-image] ERROR: Image not found locally: ${IMAGE}" >&2
  docker images | head -n 50 >&2 || true
  exit 1
fi

chmod +x "${ROOT_DIR}/scripts"/*.sh || true

if [[ ! -x "${ROOT_DIR}/scripts/test.sh" ]]; then
  echo "[test-image] ERROR: scripts/test.sh missing or not executable" >&2
  exit 1
fi

set +e
"${ROOT_DIR}/scripts/test.sh"
code=$?
set -e

if [[ $code -ne 0 ]]; then
  echo "[test-image] Tests FAILED with exit code $code" >&2
  exit $code
fi

echo "[test-image] Tests passed." >&2
