#!/bin/bash

## test.sh - Unified DevContainer image tests
#
# Validates the single unified image for tool availability and basic DinD.
#
set -e

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
IMAGE="${IMAGE:-devcontainer-unified:latest}"

verify_environment() {
    echo -e "${BLUE}🔍 Verifying testing environment...${NC}"
    command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker not found${NC}"; exit 1; }
    docker info >/dev/null 2>&1 || { echo -e "${RED}❌ Docker daemon unavailable${NC}"; exit 1; }
    echo -e "${GREEN}✅ Environment verified${NC}\n"
}

test_unified_image() {
    local image_name="$1"
    echo -e "${BLUE}🧪 Testing unified image: $image_name${NC}"
    if ! docker image inspect "$image_name" >/dev/null 2>&1; then
        echo -e "${BLUE}🔄 Pulling $image_name${NC}"; docker pull "$image_name" || true
    fi
    docker run --rm --privileged "$image_name" bash -c '
        set -e
        echo "=== Unified Image Tests ==="
        
        # Test Python and Poetry (available to root)
        command -v python3 >/dev/null 2>&1 && echo "✅ Python: $(python3 --version)" || { echo "❌ Python missing"; exit 1; }
        command -v poetry  >/dev/null 2>&1 && echo "✅ Poetry: $(poetry --version)" || { echo "❌ Poetry missing"; exit 1; }
        python3 - <<PY
print("✅ Python quick check OK")
PY
        command -v docker >/dev/null 2>&1 && echo "✅ Docker CLI present" || { echo "❌ Docker CLI missing"; exit 1; }
        touch /workspace/.write-test && rm /workspace/.write-test && echo "✅ Workspace writable"
        
        # Test Node.js tools as vscode user (where nvm is installed)
        su - vscode -c '\''
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" 2>/dev/null || true
            command -v node >/dev/null 2>&1 && echo "✅ Node: $(node --version)" || { echo "❌ Node missing"; exit 1; }
            command -v npm  >/dev/null 2>&1 && echo "✅ npm: $(npm --version)"   || { echo "❌ npm missing"; exit 1; }
            npx tsc --version >/dev/null 2>&1 && echo "✅ TypeScript: $(npx tsc --version)" || { echo "❌ TypeScript missing"; exit 1; }
            command -v pnpm >/dev/null 2>&1 && echo "✅ pnpm: $(pnpm --version)" || echo "ℹ️ pnpm not found"
            command -v yarn >/dev/null 2>&1 && echo "✅ yarn: $(yarn --version)" || echo "ℹ️ yarn not found"
            command -v gemini >/dev/null 2>&1 && echo "ℹ️ Gemini CLI present" || true
            command -v claude >/dev/null 2>&1 && echo "ℹ️ Claude CLI present" || true
        '\''
    '
}

test_docker_in_docker() {
    local image_name="$1"
    echo -e "${BLUE}🐳 DinD smoke test...${NC}"
    docker run --rm --privileged "$image_name" bash -c '
        set -e
        command -v docker >/dev/null 2>&1 || { echo "❌ Docker CLI missing"; exit 1; }
        if ! docker info >/dev/null 2>&1; then
            echo "ℹ️ Starting dockerd"
            sudo dockerd --host=unix:///var/run/docker.sock --pidfile=/var/run/docker.pid >/tmp/dockerd.log 2>&1 &
            for i in {1..25}; do docker info >/dev/null 2>&1 && break || sleep 1; done
        fi
        docker info >/dev/null 2>&1 && echo "✅ Docker daemon ready" || { echo "❌ dockerd failed"; exit 1; }
        timeout 60 docker pull alpine:latest >/dev/null 2>&1 && echo "✅ Pull alpine" || { echo "❌ Pull failed"; exit 1; }
        docker run --rm alpine:latest echo ok >/dev/null 2>&1 && echo "✅ Run alpine" || { echo "❌ Run failed"; exit 1; }
    '
}

main() {
    echo -e "${BLUE}🚀 Unified DevContainer Image Tests${NC}"
    verify_environment
    if test_unified_image "$IMAGE"; then
        echo -e "${GREEN}✅ Basic tests passed${NC}"
    else
        echo -e "${RED}❌ Basic tests failed${NC}"; exit 1
    fi
    if [[ "${DIND_TESTS:-true}" == "true" ]]; then
        if test_docker_in_docker "$IMAGE"; then
            echo -e "${GREEN}✅ DinD test passed${NC}"
        else
            echo -e "${YELLOW}⚠️ DinD test failed (non-fatal)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Skipping DinD tests (DIND_TESTS=false)${NC}"
    fi
    echo -e "\n${GREEN}🎉 All done${NC}"
}

main "$@"
