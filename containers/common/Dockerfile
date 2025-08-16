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

# Set up user environment variables (using standard vscode user from base image)
ENV USERNAME=vscode
ENV USER_HOME=/home/$USERNAME
ENV NVM_DIR=$USER_HOME/.nvm

# ------------------------------------------------------------------
# Essential system packages and modern CLI tools
# ------------------------------------------------------------------
# Modern CLI replacements and tools (base image already has git, curl, etc.):
#   • eza - modern ls replacement with Git integration and colors
#   • fzf - command-line fuzzy finder for interactive searching
#   • bat - syntax-highlighted cat replacement
#   • ripgrep - ultra-fast text search (grep replacement)
#   • fd-find - intuitive find command replacement
#   • jq - command-line JSON processor
RUN apt update && apt upgrade -y && apt install -y --no-install-recommends \
        build-essential eza bat ripgrep fd-find jq fzf \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/batcat /usr/bin/bat \
    && ln -sf /usr/bin/fdfind /usr/bin/fd

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
#   • Enhanced tool completions
RUN echo 'eval "$(starship init zsh)"'                               >> $USER_HOME/.zshrc && \
    echo 'alias ls="eza --icons"'                                    >> $USER_HOME/.zshrc && \
    echo 'alias ll="eza -l --icons"'                                 >> $USER_HOME/.zshrc && \
    echo 'alias la="eza -la --icons"'                                >> $USER_HOME/.zshrc && \
    echo 'export NVM_DIR="$HOME/.nvm"'                               >> $USER_HOME/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'           >> $USER_HOME/.zshrc && \
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

CMD ["zsh"]
