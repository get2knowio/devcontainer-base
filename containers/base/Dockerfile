########################################################################
#  Unified Development Container - Python + TypeScript
#
#  Single image starting from the official DevContainers Python image
#  with additional common tooling, Docker Engine (DinD), Node.js via nvm,
#  global TypeScript tooling, AI CLIs, and Poetry installed in Dockerfile.
#
#  Highlights:
#    • Base: mcr.microsoft.com/devcontainers/python:3.12
#    • Common CLI tools: eza, bat, ripgrep, fd-find, jq, fzf
#    • Docker Engine + CLI + Buildx + Compose v2 (DinD capable)
#    • Starship prompt + zsh enhancements
#    • Node.js LTS via nvm (NOT a feature) + npm global tools
#    • AI CLIs: @google/gemini-cli, @anthropic-ai/claude-code
#    • TS tooling: typescript, ts-node, tsx, @types/node, nodemon, concurrently,
#                  vite, esbuild, prettier, eslint, @biomejs/biome, tsc-watch,
#                  pnpm, yarn
#    • Poetry installed via Dockerfile (NOT a feature)
#
#  Workspace: /workspace
########################################################################

FROM mcr.microsoft.com/devcontainers/python:3.12

LABEL maintainer="you@example.com"

ENV DEBIAN_FRONTEND=noninteractive \
    USERNAME=vscode \
    USER_HOME=/home/vscode \
    NVM_VERSION=0.40.3 \
    NVM_DIR=/home/vscode/.nvm \
    CURL_CONNECT_TIMEOUT=60 \
    CURL_MAX_TIME=300

# ------------------------------------------------------------------
# Essential system packages and modern CLI tools
# ------------------------------------------------------------------
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "60";' > /etc/apt/apt.conf.d/80-timeouts && \
    echo 'Acquire::https::Timeout "60";' >> /etc/apt/apt.conf.d/80-timeouts && \
    apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        build-essential bat ripgrep fd-find jq fzf curl ca-certificates \
        python3-venv && \
    ln -sf /usr/bin/batcat /usr/bin/bat && \
    ln -sf /usr/bin/fdfind /usr/bin/fd && \
    # Install eza (not in Debian repos) via GitHub release
    ARCH=$(dpkg --print-architecture) && \
    EZA_DEB_URL="https://github.com/eza-community/eza/releases/download/v0.18.18/eza_${ARCH}.deb" && \
    curl -fsSL -o /tmp/eza.deb "$EZA_DEB_URL" && \
    apt-get install -y /tmp/eza.deb || echo 'eza install failed; continuing' && \
    rm -f /tmp/eza.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# Docker Engine installation (DinD setup) - COMMENTED OUT - now using devcontainer feature
# ------------------------------------------------------------------
# RUN set -e; \
#     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
#     . /etc/os-release; \
#     if [ "$ID" = "debian" ]; then DOCKER_DISTRO="debian"; else DOCKER_DISTRO="ubuntu"; fi; \
#     echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${DOCKER_DISTRO} ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends \
#         docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
#     apt-get clean && rm -rf /var/lib/apt/lists/* && \
#     groupadd -f docker && usermod -aG docker ${USERNAME}

# Docker daemon configuration and helper entrypoint - COMMENTED OUT - now using devcontainer feature
# RUN mkdir -p /etc/docker && \
#     printf '{\n  "features": { "buildkit": true },\n  "default-address-pools": [\n    { "base": "172.17.0.0/16", "size": 24 },\n    { "base": "172.18.0.0/16", "size": 24 }\n  ],\n  "storage-driver": "vfs",\n  "log-driver": "json-file",\n  "log-opts": {"max-size": "10m", "max-file": "3"}\n}\n' > /etc/docker/daemon.json && \
#     printf '#!/bin/bash\nset -e\nLOG=/var/log/docker.log\n# Expose nvm-installed node in non-login shells\nexport NVM_DIR="/home/vscode/.nvm"\nif [ -s "$NVM_DIR/nvm.sh" ]; then . "$NVM_DIR/nvm.sh" >/dev/null 2>&1; fi\nif [ -d "$NVM_DIR/versions/node" ]; then export PATH="$NVM_DIR/versions/node/$(ls -1 $NVM_DIR/versions/node | grep -v current | head -n1)/bin:$PATH"; fi\nmkdir -p /var/run || true\nif [ "$SKIP_DOCKER_INIT" = "true" ]; then\n  echo "[docker-init] SKIP_DOCKER_INIT=true; skipping dockerd"\nelse\n  if ! docker info >/dev/null 2>&1; then\n    echo "[docker-init] Starting dockerd..."\n    sudo pkill dockerd || true\n    (sudo dockerd --host=unix:///var/run/docker.sock --group=docker > "$LOG" 2>&1 &)\n    for i in $(seq 1 25); do docker info >/dev/null 2>&1 && break || sleep 1; done\n    if ! docker info >/dev/null 2>&1; then\n      echo "[docker-init] WARNING: dockerd failed to start (continuing without DinD)"\n    fi\n  fi\nfi\nexec "$@"\n' > /usr/local/bin/docker-init.sh && \
#     chmod +x /usr/local/bin/docker-init.sh && \
#     mkdir -p /var/log && touch /var/log/docker.log && chmod 666 /var/log/docker.log

# ------------------------------------------------------------------
# Starship prompt and zsh enhancements
# ------------------------------------------------------------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y && \
    mkdir -p ${USER_HOME}/.config && \
    printf 'command_timeout = 2000\n[container]\ndisabled = true\n[docker_context]\ndisabled = true\n' > ${USER_HOME}/.config/starship.toml && \
    echo 'eval "$(starship init zsh)"'                               >> ${USER_HOME}/.zshrc && \
    echo 'alias ls="eza --icons"'                                    >> ${USER_HOME}/.zshrc && \
    echo 'alias ll="eza -l --icons"'                                 >> ${USER_HOME}/.zshrc && \
    echo 'alias la="eza -la --icons"'                                >> ${USER_HOME}/.zshrc && \
    echo 'alias dps="docker ps"'                                     >> ${USER_HOME}/.zshrc && \
    echo 'alias dpsa="docker ps -a"'                                 >> ${USER_HOME}/.zshrc && \
    echo 'alias di="docker images"'                                  >> ${USER_HOME}/.zshrc && \
    echo 'alias dlog="docker logs"'                                  >> ${USER_HOME}/.zshrc && \
    echo 'alias dexec="docker exec -it"'                             >> ${USER_HOME}/.zshrc && \
    echo 'alias dc="docker compose"'                                 >> ${USER_HOME}/.zshrc && \
    echo 'alias dcup="docker compose up"'                            >> ${USER_HOME}/.zshrc && \
    echo 'alias dcdown="docker compose down"'                        >> ${USER_HOME}/.zshrc

# Prepare for Node (nvm) in shell profiles
RUN echo 'export NVM_DIR="$HOME/.nvm"'                         >> ${USER_HOME}/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'   >> ${USER_HOME}/.zshrc && \
    echo 'export NVM_DIR="$HOME/.nvm"'                         >> ${USER_HOME}/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'   >> ${USER_HOME}/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' >> ${USER_HOME}/.bashrc && \
    chown -R ${USERNAME}:${USERNAME} ${USER_HOME}

# ------------------------------------------------------------------
# Switch to non-root for language tool installs
# ------------------------------------------------------------------
USER ${USERNAME}

# Node.js LTS via nvm, then global tooling and AI CLIs
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && nvm alias default 'lts/*' && \
    npm install -g @google/gemini-cli @anthropic-ai/claude-code && \
    npm install -g pnpm yarn && \
    npm install -g typescript ts-node tsx @types/node nodemon concurrently && \
    npm install -g vite esbuild prettier eslint @biomejs/biome tsc-watch

# Helpful TS aliases
RUN echo '# TypeScript development aliases' >> ${USER_HOME}/.zshrc && \
    echo 'alias tsc="npx tsc"' >> ${USER_HOME}/.zshrc && \
    echo 'alias tsx="npx tsx"' >> ${USER_HOME}/.zshrc && \
    echo 'alias tsw="npx tsc-watch"' >> ${USER_HOME}/.zshrc && \
    echo 'alias dev="npm run dev"' >> ${USER_HOME}/.zshrc && \
    echo 'alias build="npm run build"' >> ${USER_HOME}/.zshrc && \
    echo 'alias test="npm test"' >> ${USER_HOME}/.zshrc && \
    echo 'alias lint="npm run lint"' >> ${USER_HOME}/.zshrc && \
    echo 'alias format="npm run format"' >> ${USER_HOME}/.zshrc && \
    echo '# Add npm completion if available' >> ${USER_HOME}/.zshrc && \
    echo 'if command -v npm >/dev/null 2>&1; then eval "$(npm completion zsh)"; fi' >> ${USER_HOME}/.zshrc && \
    cp ${USER_HOME}/.zshrc ${USER_HOME}/.bashrc

# ------------------------------------------------------------------
# Poetry installation (Dockerfile, not a feature)
# ------------------------------------------------------------------
USER root
ENV POETRY_HOME=/opt/poetry \
    POETRY_VERSION=1.8.3
RUN curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} && \
    ln -s ${POETRY_HOME}/bin/poetry /usr/local/bin/poetry

# Configure Poetry for vscode user (in-project virtualenvs)
USER ${USERNAME}
RUN poetry config virtualenvs.in-project true --local || true

# Final setup
WORKDIR /workspace
CMD ["zsh"]
