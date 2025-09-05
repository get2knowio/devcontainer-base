########################################################################
#  Unified Development Container - Python + TypeScript
#
#  Single image starting from the official DevContainers Python image
#  with additional common tooling, Node.js via nvm, global TypeScript 
#  tooling, AI CLIs, and Poetry installed in Dockerfile.
#
#  Docker is provided via the docker-in-docker feature in devcontainer.json
#
#  Highlights:
#    • Base: mcr.microsoft.com/devcontainers/python:3.12
#    • Common CLI tools: eza, bat, ripgrep, fd-find, jq, fzf
#    • Docker via docker-in-docker feature (not in Dockerfile)
#    • Starship prompt + zsh enhancements
#    • Node.js LTS via nvm (NOT a feature) + npm global tools
#    • AI CLIs: @google/gemini-cli, @anthropic-ai/claude-code
#    • TS tooling: typescript, ts-node, tsx, @types/node, nodemon, concurrently,
#                  vite, esbuild, prettier, eslint, @biomejs/biome, tsc-watch,
#                  pnpm, yarn, bun
#    • Poetry installed via Dockerfile (NOT a feature)
#
#  Workspace: /workspace
########################################################################

# syntax=docker/dockerfile:1.7-labs
FROM mcr.microsoft.com/devcontainers/python:3.12

LABEL maintainer="you@example.com"

# Build-time args (override with --build-arg) — only promote what we need.
ARG USERNAME=vscode
ARG USER_HOME=/home/vscode
ARG NVM_VERSION=0.40.3
ARG NVM_DIR=/home/vscode/.nvm
ARG POETRY_VERSION=1.8.3
ARG INSTALL_AI_CLIS=true
ARG EZA_VERSION=0.23.0
ARG ACT_VERSION=0.2.62
ARG ACTIONLINT_VERSION=1.7.1
ARG AST_GREP_VERSION=0.39.4
ARG ZELLIJ_VERSION=0.40.1
ARG CURL_CONNECT_TIMEOUT=60
ARG CURL_MAX_TIME=300
ARG DEBIAN_FRONTEND=noninteractive

# Promote only the ones needed at runtime
ENV USERNAME=${USERNAME} \
    USER_HOME=${USER_HOME} \
    NVM_DIR=${NVM_DIR}

# ------------------------------------------------------------------
# Essential system packages and modern CLI tools
# ------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "60";' > /etc/apt/apt.conf.d/80-timeouts && \
    echo 'Acquire::https::Timeout "60";' >> /etc/apt/apt.conf.d/80-timeouts && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        build-essential bat ripgrep fd-find jq fzf curl ca-certificates \
        python3-venv gnupg2 lsb-release neovim unzip tmux zoxide && \
    ln -sf /usr/bin/batcat /usr/bin/bat && \
    ln -sf /usr/bin/fdfind /usr/bin/fd && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
        amd64) EZA_ARCH="x86_64" ;; \
        arm64) EZA_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    EZA_TAR_URL="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_ARCH}-unknown-linux-gnu.tar.gz" && \
    curl -fsSL "$EZA_TAR_URL" | tar -xzf - -C /usr/local/bin/ && \
    echo "Installing act (GitHub Actions emulator) ${ACT_VERSION}" && \
    case "$ARCH" in \
        amd64) ACT_ARCH="x86_64" ;; \
        arm64) ACT_ARCH="arm64" ;; \
        *) echo "Unsupported architecture for act: $ARCH" && exit 1 ;; \
    esac && \
    ACT_URL="https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${ACT_ARCH}.tar.gz" && \
    curl -fsSL "$ACT_URL" | tar -xz -C /usr/local/bin act && \
    chmod +x /usr/local/bin/act && \
    echo "Installing actionlint ${ACTIONLINT_VERSION}" && \
    case "$ARCH" in \
        amd64) ACTIONLINT_ARCH="amd64" ;; \
        arm64) ACTIONLINT_ARCH="arm64" ;; \
        *) echo "Unsupported architecture for actionlint: $ARCH" && exit 1 ;; \
    esac && \
    ACTIONLINT_URL="https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_${ACTIONLINT_ARCH}.tar.gz" && \
    curl -fsSL "$ACTIONLINT_URL" | tar -xz -C /usr/local/bin actionlint && \
    chmod +x /usr/local/bin/actionlint && \
    echo "Installing ast-grep ${AST_GREP_VERSION}" && \
    case "$ARCH" in \
        amd64) SG_ARCH="x86_64" ;; \
        arm64) SG_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture for ast-grep: $ARCH" && exit 1 ;; \
    esac && \
    AST_GREP_URL="https://github.com/ast-grep/ast-grep/releases/download/${AST_GREP_VERSION}/app-${SG_ARCH}-unknown-linux-gnu.zip" && \
    curl -fsSL "$AST_GREP_URL" -o /tmp/ast-grep.zip && \
    unzip -q /tmp/ast-grep.zip -d /tmp/ast-grep && \
    install /tmp/ast-grep/sg /usr/local/bin/sg && \
    install /tmp/ast-grep/ast-grep /usr/local/bin/ast-grep || cp /tmp/ast-grep/sg /usr/local/bin/ast-grep && \
    rm -rf /tmp/ast-grep /tmp/ast-grep.zip && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Installing zellij ${ZELLIJ_VERSION}" && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
        amd64) ZELLIJ_ARCH="x86_64" ;; \
        arm64) ZELLIJ_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture for zellij: $ARCH" && exit 1 ;; \
    esac && \
    ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${ZELLIJ_ARCH}-unknown-linux-musl.tar.gz" && \
    curl -fsSL "$ZELLIJ_URL" -o /tmp/zellij.tgz && \
    tar -xzf /tmp/zellij.tgz -C /usr/local/bin zellij && \
    rm -f /tmp/zellij.tgz && \
    # Ensure zoxide present (fallback if package absent or outdated)
    if ! command -v zoxide >/dev/null 2>&1; then \
        echo "Installing latest zoxide via upstream script"; \
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -s -- -b /usr/local/bin; \
    fi

# ------------------------------------------------------------------
# Starship prompt and shell enhancements
# ------------------------------------------------------------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y && \
    mkdir -p ${USER_HOME}/.config && \
    printf 'command_timeout = 2000\n[container]\ndisabled = true\n[docker_context]\ndisabled = true\n' > ${USER_HOME}/.config/starship.toml && \
    echo 'eval "$(starship init zsh)"'                               >> ${USER_HOME}/.zshrc && \
    echo '# zoxide (smart cd) init'                                    >> ${USER_HOME}/.zshrc && \
    echo 'eval "$(zoxide init zsh)"'                                 >> ${USER_HOME}/.zshrc && \
    echo 'alias ls="eza --icons"'                                    >> ${USER_HOME}/.zshrc && \
    echo 'alias ll="eza -l --icons"'                                 >> ${USER_HOME}/.zshrc && \
    echo 'alias la="eza -la --icons"'                                >> ${USER_HOME}/.zshrc

# Basic nvm bootstrap (interactive shells will also run later 'nvm use')
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ${USER_HOME}/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ${USER_HOME}/.zshrc && \
    chown -R ${USERNAME}:${USERNAME} ${USER_HOME}

# ------------------------------------------------------------------
# Switch to non-root for language tool installs
# ------------------------------------------------------------------
USER ${USERNAME}

# Node.js LTS via nvm, then global tooling and AI CLIs
RUN --mount=type=cache,target=/home/vscode/.cache,uid=1000,gid=1000 \
    --mount=type=cache,target=/home/vscode/.npm,uid=1000,gid=1000 \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && nvm alias default 'lts/*' && \
    if [ "${INSTALL_AI_CLIS}" = "true" ]; then npm install -g @google/gemini-cli @anthropic-ai/claude-code @openai/codex; fi && \
    npm install -g pnpm yarn && \
    npm install -g typescript ts-node tsx @types/node nodemon concurrently && \
    npm install -g vite esbuild prettier eslint @biomejs/biome tsc-watch

# Add silent nvm use to interactive shells
RUN echo 'nvm use --silent default >/dev/null 2>&1 || nvm use --silent --lts >/dev/null 2>&1' >> ${USER_HOME}/.zshrc

# Install Bun (JavaScript runtime and package manager)
RUN curl -fsSL https://bun.sh/install | bash && \
    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ${USER_HOME}/.zshrc

# Make Bun available system-wide by adding to PATH
USER root
RUN echo 'export PATH="/home/vscode/.bun/bin:$PATH"' >> /etc/profile && \
    ln -sf /home/vscode/.bun/bin/bun /usr/local/bin/bun && \
    ln -sf /home/vscode/.bun/bin/bunx /usr/local/bin/bunx
USER ${USERNAME}

# Helpful TS aliases for zsh
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
    echo 'if command -v npm >/dev/null 2>&1; then eval "$(npm completion zsh)"; fi' >> ${USER_HOME}/.zshrc

# ------------------------------------------------------------------
# Poetry installation (Dockerfile, not a feature)
# ------------------------------------------------------------------
USER root
ENV POETRY_HOME=/opt/poetry
RUN --mount=type=cache,target=/root/.cache/pip \
    curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} && \
    ln -s ${POETRY_HOME}/bin/poetry /usr/local/bin/poetry

# Configure Poetry for vscode user (in-project virtualenvs)
USER ${USERNAME}
# Set global Poetry config (cannot use --local without a pyproject)
RUN poetry config virtualenvs.in-project true --global || true

# Set zsh as the default shell for the vscode user
USER root
RUN chsh -s /usr/bin/zsh ${USERNAME}
USER ${USERNAME}

# Final setup
WORKDIR /workspace

# Provide a long-lived default command suitable for devcontainer sessions and tests.
CMD ["sleep", "infinity"]