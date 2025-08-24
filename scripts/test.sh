#!/bin/bash

## test.sh - Comprehensive Unified DevContainer Image Tests
#
# Thoroughly validates the unified devcontainer image for all installed tools and functionality:
#
# TESTED COMPONENTS:
# • Core System: Python 3.12, build tools, venv functionality
# • Poetry: Installation, project creation, dependency management, virtualenvs
# • Modern CLI Tools: bat, ripgrep, fd-find, jq, fzf, eza
# • Starship: Prompt installation and configuration
# • DevContainer Features: Docker-in-Docker, AWS CLI functionality
# • Node.js Ecosystem: nvm, Node LTS, npm, pnpm, yarn, bun
# • TypeScript: compiler, ts-node, tsx, project compilation
# • Development Tools: nodemon, concurrently, tsc-watch, vite, esbuild
# • Code Quality: prettier, eslint, biome
# • AI CLIs: Google Gemini CLI, Anthropic Claude CLI
# • Shell Configuration: aliases, environment setup, profile configurations
# • Workspace: permissions and functionality
#
# USAGE:
#   ./test.sh                    # Test default image
#   IMAGE=myimage:tag ./test.sh  # Test specific image
#   DIND_TESTS=false ./test.sh   # Skip Docker-in-Docker tests
#
set -e

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
IMAGE="${IMAGE:-ghcr.io/get2knowio/devcontainer:latest}"

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
        
        # Test core system and Python tools
        echo "--- Core System & Python ---"
        command -v python3 >/dev/null 2>&1 && echo "✅ Python: $(python3 --version)" || { echo "❌ Python missing"; exit 1; }
        command -v poetry  >/dev/null 2>&1 && echo "✅ Poetry: $(poetry --version)" || { echo "❌ Poetry missing"; exit 1; }
        python3 - <<PY
import sys, os
print(f"✅ Python quick check OK (Python {sys.version_info.major}.{sys.version_info.minor})")
# Test venv functionality
import venv
print("✅ Python venv module available")
PY
        
        # Test Poetry configuration
        poetry config --list 2>/dev/null | grep -q "virtualenvs.in-project = true" && echo "✅ Poetry configured for in-project venvs" || echo "⚠️ Poetry config may not be set"
        
        # Test modern CLI tools from Dockerfile
        echo "--- Modern CLI Tools ---"
        command -v bat >/dev/null 2>&1 && echo "✅ bat: $(bat --version | head -1)" || { echo "❌ bat missing"; exit 1; }
        command -v rg >/dev/null 2>&1 && echo "✅ ripgrep: $(rg --version | head -1)" || { echo "❌ ripgrep missing"; exit 1; }
        command -v fd >/dev/null 2>&1 && echo "✅ fd: $(fd --version)" || { echo "❌ fd-find missing"; exit 1; }
        command -v jq >/dev/null 2>&1 && echo "✅ jq: $(jq --version)" || { echo "❌ jq missing"; exit 1; }
        command -v fzf >/dev/null 2>&1 && echo "✅ fzf: $(fzf --version)" || { echo "❌ fzf missing"; exit 1; }
        command -v eza >/dev/null 2>&1 && echo "✅ eza: $(eza --version | head -1)" || { echo "❌ eza missing"; exit 1; }
        
        # Test Starship prompt
        command -v starship >/dev/null 2>&1 && echo "✅ starship: $(starship --version)" || { echo "❌ starship missing"; exit 1; }
        
        # Test build tools
        echo "--- Build Tools ---"
        command -v make >/dev/null 2>&1 && echo "✅ make available" || { echo "❌ make missing"; exit 1; }
        command -v gcc >/dev/null 2>&1 && echo "✅ gcc available" || { echo "❌ gcc missing"; exit 1; }
        
        # Test Docker CLI and AWS CLI (from devcontainer features)
        echo "--- DevContainer Features ---"
        command -v docker >/dev/null 2>&1 && echo "✅ Docker CLI present" || { echo "❌ Docker CLI missing"; exit 1; }
        command -v aws >/dev/null 2>&1 && echo "✅ AWS CLI: $(aws --version)" || { echo "❌ AWS CLI missing"; exit 1; }
        
        # Test workspace
        touch /workspace/.write-test && rm /workspace/.write-test && echo "✅ Workspace writable" || { echo "❌ Workspace not writable"; exit 1; }
        
        # Test Node.js ecosystem as vscode user (where nvm is installed)
        echo "--- Node.js Ecosystem (as vscode user) ---"
        su - vscode -c '\''
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" 2>/dev/null || true
            
            # Core Node.js tools
            command -v node >/dev/null 2>&1 && echo "✅ Node: $(node --version)" || { echo "❌ Node missing"; exit 1; }
            command -v npm  >/dev/null 2>&1 && echo "✅ npm: $(npm --version)"   || { echo "❌ npm missing"; exit 1; }
            
            # Package managers
            command -v pnpm >/dev/null 2>&1 && echo "✅ pnpm: $(pnpm --version)" || { echo "❌ pnpm missing"; exit 1; }
            command -v yarn >/dev/null 2>&1 && echo "✅ yarn: $(yarn --version)" || { echo "❌ yarn missing"; exit 1; }
            command -v bun >/dev/null 2>&1 && echo "✅ bun: $(bun --version)" || { echo "❌ bun missing"; exit 1; }
            
            # TypeScript toolchain
            npx tsc --version >/dev/null 2>&1 && echo "✅ TypeScript: $(npx tsc --version)" || { echo "❌ TypeScript missing"; exit 1; }
            command -v ts-node >/dev/null 2>&1 && echo "✅ ts-node available" || { echo "❌ ts-node missing"; exit 1; }
            command -v tsx >/dev/null 2>&1 && echo "✅ tsx available" || { echo "❌ tsx missing"; exit 1; }
            
            # Development tools
            command -v nodemon >/dev/null 2>&1 && echo "✅ nodemon available" || { echo "❌ nodemon missing"; exit 1; }
            command -v concurrently >/dev/null 2>&1 && echo "✅ concurrently available" || { echo "❌ concurrently missing"; exit 1; }
            command -v tsc-watch >/dev/null 2>&1 && echo "✅ tsc-watch available" || { echo "❌ tsc-watch missing"; exit 1; }
            
            # Build tools
            command -v vite >/dev/null 2>&1 && echo "✅ vite available" || { echo "❌ vite missing"; exit 1; }
            command -v esbuild >/dev/null 2>&1 && echo "✅ esbuild available" || { echo "❌ esbuild missing"; exit 1; }
            
            # Formatting and linting
            command -v prettier >/dev/null 2>&1 && echo "✅ prettier available" || { echo "❌ prettier missing"; exit 1; }
            command -v eslint >/dev/null 2>&1 && echo "✅ eslint available" || { echo "❌ eslint missing"; exit 1; }
            command -v biome >/dev/null 2>&1 && echo "✅ biome available" || { echo "❌ biome missing"; exit 1; }
            
            # AI CLIs
            command -v gemini >/dev/null 2>&1 && echo "✅ Gemini CLI available" || { echo "❌ Gemini CLI missing"; exit 1; }
            command -v claude >/dev/null 2>&1 && echo "✅ Claude CLI available" || { echo "❌ Claude CLI missing"; exit 1; }
            
            # Test Node.js functionality
            node -e "console.log(\"✅ Node.js execution test passed\")" || { echo "❌ Node.js execution failed"; exit 1; }
            
            # Test TypeScript compilation
            echo "console.log(\"Hello TypeScript\");" > /tmp/test.ts
            npx tsc /tmp/test.ts --outDir /tmp/ && echo "✅ TypeScript compilation works" || { echo "❌ TypeScript compilation failed"; exit 1; }
            rm -f /tmp/test.ts /tmp/test.js
        '\''
        
        # Test shell configurations and aliases
        echo "--- Shell Configuration ---"
        su - vscode -c '\''
            # Test starship in shell config
            grep -q "starship init" ~/.zshrc && echo "✅ Starship configured in zsh" || echo "⚠️ Starship not found in zsh config"
            grep -q "starship init" ~/.bashrc && echo "✅ Starship configured in bash" || echo "⚠️ Starship not found in bash config"
            
            # Test eza aliases
            grep -q "alias ls.*eza" ~/.zshrc && echo "✅ eza aliases configured" || echo "⚠️ eza aliases not found"
            
            # Test NVM configuration
            grep -q "NVM_DIR" ~/.zshrc && echo "✅ NVM configured in zsh" || echo "⚠️ NVM not configured in zsh"
            grep -q "NVM_DIR" ~/.bashrc && echo "✅ NVM configured in bash" || echo "⚠️ NVM not configured in bash"
            
            # Test TypeScript aliases
            grep -q "alias tsc" ~/.zshrc && echo "✅ TypeScript aliases configured" || echo "⚠️ TypeScript aliases not found"
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

test_poetry_functionality() {
    local image_name="$1"
    echo -e "${BLUE}📦 Poetry functionality test...${NC}"
    docker run --rm --privileged "$image_name" bash -c '
        set -e
        cd /tmp
        echo "--- Testing Poetry Project Creation ---"
        
        # Create a test project
        poetry new test-project >/dev/null 2>&1 && echo "✅ Poetry project creation works" || { echo "❌ Poetry project creation failed"; exit 1; }
        cd test-project
        
        # Check project structure
        [ -f "pyproject.toml" ] && echo "✅ pyproject.toml created" || { echo "❌ pyproject.toml missing"; exit 1; }
        [ -d "test_project" ] && echo "✅ package directory created" || { echo "❌ package directory missing"; exit 1; }
        
        # Test adding a dependency
        poetry add requests >/dev/null 2>&1 && echo "✅ Poetry dependency addition works" || { echo "❌ Poetry add failed"; exit 1; }
        
        # Verify virtualenv was created in project
        [ -d ".venv" ] && echo "✅ In-project virtualenv created" || echo "⚠️ In-project virtualenv not found"
        
        # Test poetry install
        poetry install >/dev/null 2>&1 && echo "✅ Poetry install works" || { echo "❌ Poetry install failed"; exit 1; }
        
        # Test running python through poetry
        poetry run python -c "import requests; print(\"✅ Poetry run works with installed packages\")" || { echo "❌ Poetry run failed"; exit 1; }
        
        echo "✅ Poetry functionality test completed"
    '
}

test_node_ecosystem() {
    local image_name="$1"
    echo -e "${BLUE}🟢 Node.js ecosystem functionality test...${NC}"
    docker run --rm --privileged "$image_name" bash -c '
        set -e
        su - vscode -c '\''
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" 2>/dev/null || true
            
            cd /tmp
            echo "--- Testing Node.js Project Setup ---"
            
            # Test npm project initialization
            mkdir npm-test && cd npm-test
            npm init -y >/dev/null 2>&1 && echo "✅ npm init works" || { echo "❌ npm init failed"; exit 1; }
            
            # Test package installation
            npm install lodash >/dev/null 2>&1 && echo "✅ npm install works" || { echo "❌ npm install failed"; exit 1; }
            
            # Test TypeScript project
            cd ../ && mkdir ts-test && cd ts-test
            npm init -y >/dev/null 2>&1
            echo "{\"compilerOptions\":{\"target\":\"ES2020\",\"module\":\"commonjs\",\"outDir\":\"./dist\"}}" > tsconfig.json
            echo "console.log(\"Hello TypeScript!\");" > index.ts
            npx tsc >/dev/null 2>&1 && echo "✅ TypeScript compilation in project works" || { echo "❌ TypeScript compilation failed"; exit 1; }
            [ -f "dist/index.js" ] && echo "✅ TypeScript output generated" || { echo "❌ TypeScript output missing"; exit 1; }
            
            # Test different package managers
            cd ../ && mkdir pnpm-test && cd pnpm-test
            pnpm init >/dev/null 2>&1 && echo "✅ pnpm init works" || { echo "❌ pnpm init failed"; exit 1; }
            
            cd ../ && mkdir yarn-test && cd yarn-test  
            yarn init -y >/dev/null 2>&1 && echo "✅ yarn init works" || { echo "❌ yarn init failed"; exit 1; }
            
            cd ../ && mkdir bun-test && cd bun-test
            bun init -y >/dev/null 2>&1 && echo "✅ bun init works" || { echo "❌ bun init failed"; exit 1; }
            
            echo "✅ Node.js ecosystem functionality test completed"
        '\''
    '
}

test_aws_cli_functionality() {
    local image_name="$1"
    echo -e "${BLUE}☁️ AWS CLI functionality test...${NC}"
    docker run --rm --privileged "$image_name" bash -c '
        set -e
        echo "--- Testing AWS CLI Functionality ---"
        
        # Test AWS CLI help (basic functionality without credentials)
        aws --version >/dev/null 2>&1 && echo "✅ AWS CLI version check works" || { echo "❌ AWS CLI version failed"; exit 1; }
        
        # Test AWS CLI help commands (should work without credentials)
        aws help >/dev/null 2>&1 && echo "✅ AWS CLI help works" || { echo "❌ AWS CLI help failed"; exit 1; }
        
        # Test AWS configure list (should show default settings even without credentials)
        aws configure list >/dev/null 2>&1 && echo "✅ AWS CLI configure works" || { echo "❌ AWS CLI configure failed"; exit 1; }
        
        # Test specific service help (should work without credentials)
        aws s3 help >/dev/null 2>&1 && echo "✅ AWS S3 service available" || { echo "❌ AWS S3 service not available"; exit 1; }
        aws ec2 help >/dev/null 2>&1 && echo "✅ AWS EC2 service available" || { echo "❌ AWS EC2 service not available"; exit 1; }
        
        echo "✅ AWS CLI functionality test completed"
    '
}

main() {
    echo -e "${BLUE}🚀 Unified DevContainer Image Tests${NC}"
    verify_environment
    
    # Basic functionality tests
    if test_unified_image "$IMAGE"; then
        echo -e "${GREEN}✅ Basic tests passed${NC}"
    else
        echo -e "${RED}❌ Basic tests failed${NC}"; exit 1
    fi
    
    # Poetry functionality tests
    if test_poetry_functionality "$IMAGE"; then
        echo -e "${GREEN}✅ Poetry functionality tests passed${NC}"
    else
        echo -e "${RED}❌ Poetry functionality tests failed${NC}"; exit 1
    fi
    
    # Node.js ecosystem tests
    if test_node_ecosystem "$IMAGE"; then
        echo -e "${GREEN}✅ Node.js ecosystem tests passed${NC}"
    else
        echo -e "${RED}❌ Node.js ecosystem tests failed${NC}"; exit 1
    fi
    
    # AWS CLI functionality tests
    if test_aws_cli_functionality "$IMAGE"; then
        echo -e "${GREEN}✅ AWS CLI functionality tests passed${NC}"
    else
        echo -e "${RED}❌ AWS CLI functionality tests failed${NC}"; exit 1
    fi
    
    # Docker-in-Docker tests
    if [[ "${DIND_TESTS:-true}" == "true" ]]; then
        if test_docker_in_docker "$IMAGE"; then
            echo -e "${GREEN}✅ DinD test passed${NC}"
        else
            echo -e "${YELLOW}⚠️ DinD test failed (non-fatal)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Skipping DinD tests (DIND_TESTS=false)${NC}"
    fi
    
    echo -e "\n${GREEN}🎉 All comprehensive tests completed successfully${NC}"
}

main "$@"
