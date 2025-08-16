########################################################################
#  Development Container - TypeScript Base Image
#  
#  Inherits from the common devcontainer base and adds TypeScript-specific
#  development tools and configurations.
#  
#  🚀 Added TypeScript/JavaScript Ecosystem:
#    • Bun - fast all-in-one JavaScript runtime
#    • TypeScript - typed superset of JavaScript
#    • pnpm - fast, disk space efficient package manager
#    • Yarn - alternative package manager
#    • Enhanced TypeScript tooling and aliases
#  
#  🛠️ Added Development Tools:
#    • Build tools (vite, esbuild)
#    • Code quality (prettier, eslint, biome)
#    • TypeScript execution (ts-node, tsx, tsc-watch)
#  
#  📁 Workspace: /workspace (inherited)
########################################################################

ARG BASE_IMAGE=devcontainer-base-common:latest
FROM ${BASE_IMAGE}

LABEL maintainer="you@example.com"

ENV DEBIAN_FRONTEND=noninteractive

USER vscode

# ------------------------------------------------------------------
# Enhanced shell configuration for TypeScript development
# ------------------------------------------------------------------
RUN echo 'if command -v bun >/dev/null 2>&1; then'                  >> /home/vscode/.zshrc && \
    echo '    eval "$(bun completions zsh)"'                         >> /home/vscode/.zshrc && \
    echo 'fi'                                                        >> /home/vscode/.zshrc

# ------------------------------------------------------------------
# TypeScript ecosystem and development tools
# ------------------------------------------------------------------
# TypeScript ecosystem:
#   • typescript - TypeScript compiler and language server
#   • ts-node - TypeScript execution environment for Node.js
#   • tsx - enhanced TypeScript execution with ESM support
#   • @types/node - TypeScript definitions for Node.js APIs
#   • nodemon - development server with auto-restart
#   • concurrently - run multiple commands concurrently
#
# Package managers:
#   • pnpm - fast, disk space efficient package manager
#   • yarn - popular alternative package manager
#
# Build and development tools:
#   • vite - next generation frontend build tool
#   • esbuild - extremely fast JavaScript bundler
#   • prettier - opinionated code formatter
#   • eslint - pluggable JavaScript/TypeScript linter
RUN export NVM_DIR="$HOME/.nvm" && \
    . "$NVM_DIR/nvm.sh" && \
    npm install -g pnpm yarn && \
    npm install -g typescript ts-node tsx @types/node && \
    npm install -g nodemon concurrently && \
    npm install -g vite esbuild && \
    npm install -g prettier eslint

RUN export NVM_DIR="$HOME/.nvm" && \
    . "$NVM_DIR/nvm.sh" && \
    npm install -g @biomejs/biome tsc-watch

# ------------------------------------------------------------------
# Configure shell environments for both bash and zsh
# ------------------------------------------------------------------
RUN echo 'if command -v bun >/dev/null 2>&1; then eval "$(bun completions bash)"; fi' >> /home/vscode/.bashrc

# ------------------------------------------------------------------
# Create useful TypeScript aliases and shortcuts
# ------------------------------------------------------------------
RUN echo '# TypeScript development aliases' >> /home/vscode/.zshrc && \
    echo 'alias tsc="npx tsc"' >> /home/vscode/.zshrc && \
    echo 'alias tsx="npx tsx"' >> /home/vscode/.zshrc && \
    echo 'alias tsw="npx tsc-watch"' >> /home/vscode/.zshrc && \
    echo 'alias dev="npm run dev"' >> /home/vscode/.zshrc && \
    echo 'alias build="npm run build"' >> /home/vscode/.zshrc && \
    echo 'alias test="npm test"' >> /home/vscode/.zshrc && \
    echo 'alias lint="npm run lint"' >> /home/vscode/.zshrc && \
    echo 'alias format="npm run format"' >> /home/vscode/.zshrc && \
    echo '' >> /home/vscode/.zshrc && \
    echo '# Bun aliases' >> /home/vscode/.zshrc && \
    echo 'alias bi="bun install"' >> /home/vscode/.zshrc && \
    echo 'alias br="bun run"' >> /home/vscode/.zshrc && \
    echo 'alias bt="bun test"' >> /home/vscode/.zshrc && \
    echo 'alias bd="bun run dev"' >> /home/vscode/.zshrc

# Add same aliases to bash
RUN echo '# TypeScript development aliases' >> /home/vscode/.bashrc && \
    echo 'alias tsc="npx tsc"' >> /home/vscode/.bashrc && \
    echo 'alias tsx="npx tsx"' >> /home/vscode/.bashrc && \
    echo 'alias tsw="npx tsc-watch"' >> /home/vscode/.bashrc && \
    echo 'alias dev="npm run dev"' >> /home/vscode/.bashrc && \
    echo 'alias build="npm run build"' >> /home/vscode/.bashrc && \
    echo 'alias test="npm test"' >> /home/vscode/.bashrc && \
    echo 'alias lint="npm run lint"' >> /home/vscode/.bashrc && \
    echo 'alias format="npm run format"' >> /home/vscode/.bashrc && \
    echo 'alias bi="bun install"' >> /home/vscode/.bashrc && \
    echo 'alias br="bun run"' >> /home/vscode/.bashrc && \
    echo 'alias bt="bun test"' >> /home/vscode/.bashrc && \
    echo 'alias bd="bun run dev"' >> /home/vscode/.bashrc

# Switch to vscode user for remaining operations
USER vscode

# ------------------------------------------------------------------
# Ready for Typescript development!
# ------------------------------------------------------------------
WORKDIR /workspace

CMD ["zsh"]
