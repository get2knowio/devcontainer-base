#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." &>/dev/null && pwd)"

# Source cached env (or regenerate)
if [[ -f "${ROOT_DIR}/.ci-env.cache" ]]; then
  # shellcheck disable=SC1090
  source "${ROOT_DIR}/.ci-env.cache"
else
  "${SCRIPT_DIR}/ci-env.sh"
  # shellcheck disable=SC1090
  source "${ROOT_DIR}/.ci-env.cache"
fi

echo "[build-image] MODE=${MODE} IS_LOCAL_ACT=${IS_LOCAL_ACT} PLATFORMS=${PLATFORMS} CI_IMAGE=${CI_IMAGE}" >&2

CONTEXT_DIR="${ROOT_DIR}/containers/base"

if [[ ! -d "${CONTEXT_DIR}" ]]; then
  echo "[build-image] ERROR: Context directory not found: ${CONTEXT_DIR}" >&2
  exit 1
fi

# Decide whether to push; only push in ci mode
PUSH_FLAG="--load"
if [[ "${MODE}" == "ci" ]]; then
  # For multi-arch we will use buildx with --push to create manifest if supported
  PUSH_FLAG="--push"
  # Detect if running outside GitHub (manual local invocation) -> degrade to local mode semantics
  if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
    echo "[build-image] Not in GitHub Actions; forcing single-arch local build semantics." >&2
    MODE="local-act"
    PUSH_FLAG="--load"
  fi
fi

# Build command strategy: prefer devcontainers CLI for parity if available, else docker buildx
if command -v devcontainer >/dev/null 2>&1 || command -v devcontainers >/dev/null 2>&1; then
  # Use devcontainers/cli build which handles features, etc.
  CLI_BIN=$(command -v devcontainer || command -v devcontainers)
  echo "[build-image] Using devcontainer CLI: ${CLI_BIN}" >&2
  if [[ "${MODE}" == "ci" ]]; then
    # Multi-arch build via buildx manually (devcontainer cli multi-arch support limited), fall back to docker buildx
    echo "[build-image] Performing multi-arch build via docker buildx (ci mode)" >&2
    if ! docker buildx build \
      --platform "${PLATFORMS}" \
      -t "${CI_IMAGE}" \
      ${PUSH_FLAG} \
      "${CONTEXT_DIR}"; then
        echo "[build-image] Multi-arch build failed; retrying single-arch local load." >&2
        docker build -t "${CI_IMAGE}" "${CONTEXT_DIR}" || exit 1
    fi
  else
    # Local: single arch build, load into docker
    if ! "${CLI_BIN}" build --workspace-folder "${CONTEXT_DIR}" --image-name "${CI_IMAGE}"; then
      echo "[build-image] devcontainer cli build failed, attempting docker build fallback" >&2
      docker build -t "${CI_IMAGE}" "${CONTEXT_DIR}" || exit 1
    fi
    if ! docker image inspect "${CI_IMAGE}" >/dev/null 2>&1; then
      echo "[build-image] Expected image tag not found after devcontainer build; performing docker build fallback" >&2
      docker build -t "${CI_IMAGE}" "${CONTEXT_DIR}" || exit 1
    fi
  fi
else
  echo "[build-image] devcontainer CLI not found, using docker buildx directly" >&2
  if ! docker buildx build \
    --platform "${PLATFORMS}" \
    -t "${CI_IMAGE}" \
    ${PUSH_FLAG} \
    "${CONTEXT_DIR}"; then
      echo "[build-image] buildx build failed; attempting docker build fallback (single arch)." >&2
      docker build -t "${CI_IMAGE}" "${CONTEXT_DIR}" || exit 1
  fi
fi

echo "[build-image] Build complete: ${CI_IMAGE}" >&2
if [[ "${MODE}" != "ci" ]]; then
  docker image inspect "${CI_IMAGE}" >/dev/null 2>&1 && echo "[build-image] Image loaded locally." >&2
fi
