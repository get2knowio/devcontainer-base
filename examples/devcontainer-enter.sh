#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# devcontainer-enter.sh
#
# Bring up (if needed) a Dev Container for the current workspace, open an
# interactive zsh shell inside it. On exit, if we started the container this
# session, we only stop it (do NOT remove) so it can be quickly restarted.
#
# Requirements:
#   - "devcontainer" CLI on PATH (https://github.com/devcontainers/cli)
#   - Docker daemon available
#   - A .devcontainer/ directory in the current working directory
#
# Usage:
#   ./examples/devcontainer-enter.sh [id]
#     id  (optional) A simple identifier to label & find the container.
#         If provided, the container is labeled with:
#             devcontainer-example.id=<id>
#
# Behavior:
#   1. If a container for this workspace (and optional id) is running, exec into zsh.
#   2. If a stopped container exists, start it, then exec into zsh.
#   3. Otherwise, create it ("devcontainer up"), then exec into zsh.
#   4. On shell exit: if this script created the container, stop (not remove) it.
#   5. Pre-existing containers are left in whatever state they were (running or stopped after you exit zsh manually).
#
# Notes:
#   - We rely on the label devcontainer.local_folder=<abs_path> which the
#     devcontainer CLI applies, plus an optional custom label.
#   - We avoid parsing fragile stdout from "devcontainer up"; instead we use
#     docker ps label queries to discover the container ID.
# -----------------------------------------------------------------------------
set -euo pipefail

WORKSPACE_DIR=$(pwd)
DEVCONTAINER_CLI=${DEVCONTAINER_CLI:-devcontainer}
ID_LABEL_KEY="devcontainer-example.id"
USER_ID_ARG="${1:-}"  # optional id param

if [[ ! -d "${WORKSPACE_DIR}/.devcontainer" ]]; then
  echo "[error] No .devcontainer directory found in ${WORKSPACE_DIR}" >&2
  exit 1
fi

if ! command -v "${DEVCONTAINER_CLI}" >/dev/null 2>&1; then
  echo "[error] devcontainer CLI not found on PATH" >&2
  exit 1
fi

label_filters() {
  echo --filter "label=devcontainer.local_folder=${WORKSPACE_DIR}" $( [[ -n "${USER_ID_ARG}" ]] && echo --filter "label=${ID_LABEL_KEY}=${USER_ID_ARG}" )
}

find_running_container() {
  # shellcheck disable=SC2046
  docker ps -q $(label_filters) | head -n1
}

find_stopped_container() {
  # shellcheck disable=SC2046
  docker ps -aq -f status=exited $(label_filters) | head -n1
}

running_before=$(find_running_container || true)
stopped_existing=$(find_stopped_container || true)
started_by_script=false

if [[ -n "${running_before}" ]]; then
  container_id="${running_before}"
  echo "[info] Reusing running devcontainer ${container_id}"
elif [[ -n "${stopped_existing}" ]]; then
  container_id="${stopped_existing}"
  echo "[info] Found stopped devcontainer ${container_id}; starting..."
  docker start "${container_id}" >/dev/null
else
  echo "[info] No existing devcontainer (running or stopped) found; creating..."
  up_cmd=("${DEVCONTAINER_CLI}" up --workspace-folder "${WORKSPACE_DIR}")
  if [[ -n "${USER_ID_ARG}" ]]; then
    up_cmd+=(--id-label "${ID_LABEL_KEY}=${USER_ID_ARG}")
  fi
  up_cmd+=(--log-format json)
  if ! "${up_cmd[@]}" >/dev/null; then
    echo "[error] devcontainer up failed" >&2
    exit 1
  fi
  container_id=$(find_running_container || true)
  if [[ -z "${container_id}" ]]; then
    echo "[error] Failed to locate container after up" >&2
    exit 1
  fi
  started_by_script=true
fi

cleanup() {
  local exit_code=$?
  if [[ "${started_by_script}" == true ]]; then
    echo "[info] Stopping devcontainer ${container_id} (started by this session)"
    docker stop "${container_id}" >/dev/null 2>&1 || true
  else
    echo "[info] Leaving container state as-is (${container_id})"
  fi
  exit ${exit_code}
}
trap cleanup EXIT INT TERM

echo "[info] Opening interactive zsh inside devcontainer (container: ${container_id})"
"${DEVCONTAINER_CLI}" exec --workspace-folder "${WORKSPACE_DIR}" zsh -l || true

# Shell exit triggers trap -> cleanup
