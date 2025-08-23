#!/usr/bin/env bash
set -euo pipefail

# Central environment bootstrap for CI and local act runs.
# Detects mode, exports standardized variables, and writes a cache file for sourcing.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." &>/dev/null && pwd)"

# Detect if running under act (ACT env var commonly injected by act)
if [[ "${ACT:-}" == "true" ]]; then
  IS_LOCAL_ACT=true
else
  IS_LOCAL_ACT=false
fi

# MODE can be overridden externally (e.g., matrix) but default based on environment context
MODE=${MODE:-}
if [[ -z "${MODE}" ]]; then
  if [[ "$IS_LOCAL_ACT" == "true" ]]; then
    MODE=local-act
  elif [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    MODE=ci
  else
    # Plain local shell invocation: treat as local-act behavior (single arch, no push)
    MODE=local-act
  fi
fi

GITHUB_SHA_SAFE=${GITHUB_SHA:-local}
REGISTRY=${REGISTRY:-ghcr.io}
IMAGE_REPO=${IMAGE_REPO:-get2knowio/devcontainer}
CI_IMAGE="${REGISTRY}/${IMAGE_REPO}:ci-${GITHUB_SHA_SAFE}"

# Determine platforms
if [[ "$MODE" == "ci" ]]; then
  PLATFORMS=${PLATFORMS:-linux/amd64,linux/arm64}
else
  # Single arch (host) for speed locally
  host_platform=$(docker info --format '{{.OSType}}/{{.Architecture}}' 2>/dev/null || echo linux/amd64)
  # Normalize architecture naming
  if [[ "$host_platform" == *aarch64 ]]; then
    host_platform="linux/arm64"
  fi
  PLATFORMS=${PLATFORMS:-$host_platform}
fi

# Tags file (will be populated later in workflow for promotion step)
TAGS_FILE=${TAGS_FILE:-final-tags.txt}

export IS_LOCAL_ACT MODE REGISTRY IMAGE_REPO CI_IMAGE PLATFORMS TAGS_FILE

# Write cache file for other scripts to source quickly
CACHE_FILE="${ROOT_DIR}/.ci-env.cache"
cat >"${CACHE_FILE}" <<EOF
export IS_LOCAL_ACT=${IS_LOCAL_ACT}
export MODE=${MODE}
export REGISTRY=${REGISTRY}
export IMAGE_REPO=${IMAGE_REPO}
export CI_IMAGE=${CI_IMAGE}
export PLATFORMS=${PLATFORMS}
export TAGS_FILE=${TAGS_FILE}
EOF

echo "[ci-env] IS_LOCAL_ACT=${IS_LOCAL_ACT} MODE=${MODE} PLATFORMS=${PLATFORMS} CI_IMAGE=${CI_IMAGE}" >&2
echo "[ci-env] Environment cache written to ${CACHE_FILE}" >&2
