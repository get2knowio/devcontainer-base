########################################################################
#  Development Container - Common Base Image
#  
#  A comprehensive development environment built on Microsoft's DevContainer
#  base Ubuntu image with modern development tools and configurations.
#  This base image contains all common functionality shared across language-
#  specific containers.
#  
#  🐚 Shell & Prompt:
#    • Zsh with Oh My Zsh (from base image)
#    • Starship - minimal, blazing-fast, infinitely customizable prompt
#    • Enhanced completions for all installed tools
#  
#  🐳 Docker Engine:
#    • Full Docker-in-Docker support with Docker Engine
#    • Docker Compose v2 for multi-container applications
#    • Docker Buildx for multi-platform image builds
#    • Automatic daemon startup and container management
#  
#  🌐 Node.js Ecosystem:
#    • Node.js LTS via nvm (Node Version Manager)
#    • Gemini CLI - Google's generative AI command line tool
#    • Claude Code - Anthropic's AI assistant for developers
#  
#  🛠️ Modern CLI Tools:
#    • eza - modern replacement for ls with colors and Git integration
#    • fzf - command-line fuzzy finder
#    • bat - syntax-highlighted file viewer (cat clone)
#    • ripgrep - ultra-fast text search tool
#    • fd-find - simple, fast alternative to find
#    • jq - lightweight command-line JSON processor
#  
#  📁 Workspace: /workspace
########################################################################

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

LABEL maintainer="you@example.com"

ENV DEBIAN_FRONTEND=noninteractive
ENV NVM_VERSION=0.40.3
# Add network resilience settings for feature installation
ENV CURL_CONNECT_TIMEOUT=60
ENV CURL_MAX_TIME=300

# Set up user environment variables (using standard vscode user from base image)
ENV USERNAME=vscode
ENV USER_HOME=/home/$USERNAME
ENV NVM_DIR=$USER_HOME/.nvm

# ------------------------------------------------------------------
# Essential system packages and modern CLI tools
# ------------------------------------------------------------------
# Update package manager configuration for better reliability
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "60";' > /etc/apt/apt.conf.d/80-timeouts && \
    echo 'Acquire::https::Timeout "60";' >> /etc/apt/apt.conf.d/80-timeouts

# Modern CLI replacements and tools (base image already has git, curl, etc.):
#   • eza - modern ls replacement with Git integration and colors
#   • fzf - command-line fuzzy finder for interactive searching
#   • bat - syntax-highlighted cat replacement
#   • ripgrep - ultra-fast text search (grep replacement)
#   • fd-find - intuitive find command replacement
#   • jq - command-line JSON processor
RUN apt update && apt upgrade -y && apt install -y --no-install-recommends \
        build-essential eza bat ripgrep fd-find jq fzf \
        # Docker prerequisites
        apt-transport-https ca-certificates gnupg lsb-release iptables \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/batcat /usr/bin/bat \
    && ln -sf /usr/bin/fdfind /usr/bin/fd

# ------------------------------------------------------------------
# Docker Engine installation (Docker-in-Docker setup)
# ------------------------------------------------------------------
# Install Docker Engine directly to avoid DevContainer feature SSL issues.
# This provides full Docker functionality including:
#   • Docker daemon (dockerd)
#   • Docker CLI client
#   • Docker Compose v2
#   • Docker Buildx for multi-platform builds
#
# Uses Docker's official Ubuntu repository for reliable installation
# and configures the docker group for non-root access.
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update && \
    apt install -y --no-install-recommends \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create docker group and add vscode user to it
RUN groupadd -f docker && usermod -aG docker $USERNAME

# Configure Docker daemon for development
# - Enable BuildKit for improved build performance
# - Set up default address pools for better network isolation
# - Configure storage driver for optimal performance
RUN mkdir -p /etc/docker && \
    echo '{\n\
  "features": { "buildkit": true },\n\
  "default-address-pools": [\n\
    { "base": "172.17.0.0/16", "size": 24 },\n\
    { "base": "172.18.0.0/16", "size": 24 }\n\
  ],\n\
  "storage-driver": "vfs",\n\
  "log-driver": "json-file",\n\
  "log-opts": {\n\
    "max-size": "10m",\n\
    "max-file": "3"\n\
  }\n\
}' > /etc/docker/daemon.json

# Create Docker init script for container startup
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Start Docker daemon in background if not already running\n\
if [ ! -S /var/run/docker.sock ]; then\n\
    echo "Starting Docker daemon..."\n\
    # Clean up any existing docker daemon processes\n\
    sudo pkill dockerd || true\n\
    \n\
    # Start Docker daemon in background\n\
    sudo nohup dockerd \\\n\
        --host=unix:///var/run/docker.sock \\\n\
        --host=tcp://0.0.0.0:2376 \\\n\
        --userland-proxy=false \\\n\
        --group docker \\\n\
        > /var/log/docker.log 2>&1 &\n\
    \n\
    # Wait for Docker to be ready\n\
    timeout=30\n\
    while [ $timeout -gt 0 ] && ! docker info >/dev/null 2>&1; do\n\
        sleep 1\n\
        timeout=$((timeout - 1))\n\
    done\n\
    \n\
    if ! docker info >/dev/null 2>&1; then\n\
        echo "Docker failed to start. Check /var/log/docker.log for details"\n\
        exit 1\n\
    fi\n\
    echo "Docker daemon started successfully"\n\
fi\n\
\n\
# Execute the main command\n\
exec "$@"' > /usr/local/bin/docker-init.sh && \
    chmod +x /usr/local/bin/docker-init.sh

# Create Docker log directory with proper permissions
RUN mkdir -p /var/log && \
    touch /var/log/docker.log && \
    chmod 666 /var/log/docker.log

# ------------------------------------------------------------------
# Starship - Cross-shell prompt (replacing Oh My Zsh theming)
# ------------------------------------------------------------------
# Starship is a minimal, blazing-fast, and infinitely customizable 
# prompt for any shell. It shows information you need while staying 
# sleek and minimal. Features include:
#   • Git status integration
#   • Package version detection
#   • Runtime environment indicators
#   • Custom theming support
#   • Language/framework detection
# 
# Configuration includes:
#   • 2000ms command timeout for better performance
#   • Disabled container and docker_context modules (redundant in containers)
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

RUN mkdir -p $USER_HOME/.config && \
    echo 'command_timeout = 2000\n' \
         '[container]\ndisabled = true\n' \
         '[docker_context]\ndisabled = true' \
    > $USER_HOME/.config/starship.toml

# ------------------------------------------------------------------
# Enhance Zsh configuration with modern tools
# ------------------------------------------------------------------
# Add Starship prompt and modern aliases to the existing Oh My Zsh setup
# Modern aliases:
#   • ls/ll/la - eza with colors and icons
#   • Docker convenience aliases
#   • Enhanced tool completions
RUN echo 'eval "$(starship init zsh)"'                               >> $USER_HOME/.zshrc && \
    echo 'alias ls="eza --icons"'                                    >> $USER_HOME/.zshrc && \
    echo 'alias ll="eza -l --icons"'                                 >> $USER_HOME/.zshrc && \
    echo 'alias la="eza -la --icons"'                                >> $USER_HOME/.zshrc && \
    echo 'export NVM_DIR="$HOME/.nvm"'                               >> $USER_HOME/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'           >> $USER_HOME/.zshrc && \
    echo ''                                                           >> $USER_HOME/.zshrc && \
    echo '# Docker aliases'                                          >> $USER_HOME/.zshrc && \
    echo 'alias dps="docker ps"'                                     >> $USER_HOME/.zshrc && \
    echo 'alias dpsa="docker ps -a"'                                 >> $USER_HOME/.zshrc && \
    echo 'alias di="docker images"'                                  >> $USER_HOME/.zshrc && \
    echo 'alias dlog="docker logs"'                                  >> $USER_HOME/.zshrc && \
    echo 'alias dexec="docker exec -it"'                             >> $USER_HOME/.zshrc && \
    echo 'alias dc="docker compose"'                                 >> $USER_HOME/.zshrc && \
    echo 'alias dcup="docker compose up"'                            >> $USER_HOME/.zshrc && \
    echo 'alias dcdown="docker compose down"'                        >> $USER_HOME/.zshrc && \
    echo ''                                                           >> $USER_HOME/.zshrc && \
    echo '# Tool completions'                                        >> $USER_HOME/.zshrc && \
    echo 'complete -C "/usr/local/bin/aws_completer" aws'            >> $USER_HOME/.zshrc && \
    echo 'if command -v npm >/dev/null 2>&1; then'                  >> $USER_HOME/.zshrc && \
    echo '    eval "$(npm completion zsh)"'                          >> $USER_HOME/.zshrc && \
    echo 'fi'                                                        >> $USER_HOME/.zshrc



# Set ownership of user files to vscode user (switching to non-root happens in child images)
RUN chown -R $USERNAME:$USERNAME $USER_HOME

# Switch to non-root user for remaining operations
USER $USERNAME

# ------------------------------------------------------------------------------
# Node.js LTS with AI development tools
# ------------------------------------------------------------------------------
# Node Version Manager (nvm) for flexible Node.js management:
#   • Installs and manages multiple Node.js versions
#   • Automatically switches versions per project
#   • Provides the latest LTS (Long Term Support) version
#
# AI-powered development tools:
#   • @google/gemini-cli - Google's Gemini AI assistant for development
#     Provides AI-powered code generation, explanation, and assistance
#   • @anthropic-ai/claude-code - Anthropic's Claude AI for development
#     Advanced AI assistant for coding, debugging, and technical tasks
#
# Both tools enable AI-assisted development workflows directly from the terminal
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && \
    nvm alias default 'lts/*' && \
    npm install -g @google/gemini-cli && \
    npm install -g @anthropic-ai/claude-code

# ------------------------------------------------------------------
# Configure shell environments for both bash and zsh
# ------------------------------------------------------------------
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/vscode/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> /home/vscode/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' >> /home/vscode/.bashrc

# ------------------------------------------------------------------
# Set up workspace
# ------------------------------------------------------------------
WORKDIR /workspace

# Set up entrypoint to start Docker daemon
ENTRYPOINT ["/usr/local/bin/docker-init.sh"]
CMD ["zsh"]
