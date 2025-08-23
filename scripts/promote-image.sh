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

TAGS_FILE=${TAGS_FILE:-final-tags.txt}
if [[ ! -f "${TAGS_FILE}" ]]; then
  echo "[promote-image] No tags file present (${TAGS_FILE}); nothing to do." >&2
  exit 0
fi

mapfile -t TAGS < <(grep -v '^$' "${TAGS_FILE}" || true)
if [[ ${#TAGS[@]} -eq 0 ]]; then
  echo "[promote-image] Tags file empty; nothing to promote." >&2
  exit 0
fi

echo "[promote-image] CI_IMAGE=${CI_IMAGE} MODE=${MODE} tag_count=${#TAGS[@]}" >&2

if [[ "${MODE}" == "local-act" || "${IS_LOCAL_ACT}" == "true" ]]; then
  if ! docker image inspect "${CI_IMAGE}" >/dev/null 2>&1; then
    echo "[promote-image] WARNING: CI image not present locally, cannot retag." >&2
    exit 0
  fi
  for tag in "${TAGS[@]}"; do
    echo "[promote-image] (local) docker tag ${CI_IMAGE} ${tag}" >&2
    docker tag "${CI_IMAGE}" "${tag}" || echo "[promote-image] WARN: failed to tag ${tag}" >&2
  done
else
  # CI mode: create remote manifest tags pointing to multi-arch image
  for tag in "${TAGS[@]}"; do
    echo "[promote-image] (ci) buildx imagetools create --tag ${tag} ${CI_IMAGE}" >&2
    docker buildx imagetools create --tag "${tag}" "${CI_IMAGE}"
  done
fi

echo "[promote-image] Promotion complete." >&2
