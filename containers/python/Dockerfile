########################################################################################################
#  Development Container - Python Base Image
#  
#  Inherits from the common devcontainer base and adds Python-specific
#  development tools and configurations.
#  
#  🐍 Python Ecosystem:
#    • Python 3.12 and Poetry installed via DevContainer features
#    • Python-specific aliases and configurations
#  
#  📁 Workspace: /workspace (inherited)
########################################################################

ARG BASE_IMAGE=devcontainer-base-common:latest
FROM ${BASE_IMAGE}

LABEL maintainer="you@example.com"

USER vscode

# ------------------------------------------------------------------
# Ready for Python development!
# ------------------------------------------------------------------
WORKDIR /workspace

CMD ["zsh"]
