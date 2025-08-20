########################################################################################################
#  Development Container - Python Base Image
#  
#  Inherits from the common devcontainer base and adds Python-specific
#  development tools and configurations.
#  
#  🐍 Python Ecosystem:
#    • Python 3.12 via apt (fast installation)
#    • Poetry for dependency management
#    • Python development headers and tools
#  
#  📁 Workspace: /workspace (inherited)
########################################################################

ARG BASE_IMAGE=devcontainer-base-common:latest
FROM ${BASE_IMAGE}

LABEL maintainer="you@example.com"

# ------------------------------------------------------------------
# Python Development Environment
# ------------------------------------------------------------------
USER root

# Install Python 3.12 and development tools via apt (much faster than building from source)
RUN apt update && apt install -y --no-install-recommends \
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3-pip \
        python3-setuptools \
        python3-wheel \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create python3 symlink for convenience
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.12 /usr/bin/python

# Note: Skip pip upgrade due to PEP 668 (externally-managed-environment)
# The system pip from Ubuntu 24.04 is sufficient for DevContainer features

# Switch back to vscode user
USER vscode

# Add Python-specific aliases and PATH updates
RUN echo '# Python development aliases and configurations' >> /home/vscode/.zshrc && \
    echo 'export PATH="/usr/local/py-utils/bin:$PATH"' >> /home/vscode/.zshrc && \
    echo 'alias py="python3"' >> /home/vscode/.zshrc && \
    echo 'alias pip="python3 -m pip"' >> /home/vscode/.zshrc && \
    echo 'alias venv="python3 -m venv"' >> /home/vscode/.zshrc

# ------------------------------------------------------------------
# Ready for Python development!
# ------------------------------------------------------------------
WORKDIR /workspace

CMD ["zsh"]
