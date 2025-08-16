#!/bin/bash

# test.sh - Build and test DevContainer images
# - Builds images via ./build (unless skipped)
# - Tests language-specific images (python, typescript) in parallel

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Image names (must match scripts/build.sh defaults)
TYPESCRIPT_IMAGE="devcontainer-typescript-base:latest"
PYTHON_IMAGE="devcontainer-python-base:latest"

verify_environment() {
    echo -e "${BLUE}🔍 Verifying testing environment...${NC}"
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker not found. This script requires Docker.${NC}"
        exit 1
    fi
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Cannot access Docker daemon. Ensure Docker is running.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Environment verified!${NC}"
    echo "Docker: $(docker --version)"
    echo ""
}

build_images() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        echo -e "${BLUE}⏭️  Skipping build (SKIP_BUILD=true)${NC}"
        return 0
    fi
    echo -e "${BLUE}🏗️  Building images with ./build all...${NC}"
    if ./build all; then
        echo -e "${GREEN}✅ Build completed${NC}"
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
}

test_typescript_image() {
    local image_name="$1"
    echo -e "${BLUE}🧪 Testing TypeScript image: $image_name${NC}"
    if ! docker image inspect "$image_name" >/dev/null 2>&1; then
        echo -e "${RED}❌ Image $image_name not found${NC}"
        return 1
    fi
    if docker run --rm "$image_name" bash -c '
        set -e
        echo "=== TypeScript Image Tests ==="
        echo "User: $(whoami)"
        echo "Home: $HOME"

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

        command -v node >/dev/null 2>&1 && echo "✅ Node: $(node --version)" || { echo "❌ Node missing"; exit 1; }
        command -v npm  >/dev/null 2>&1 && echo "✅ npm: $(npm --version)"   || { echo "❌ npm missing"; exit 1; }
        npx tsc --version >/dev/null 2>&1 && echo "✅ TypeScript: $(npx tsc --version)" || { echo "❌ TypeScript missing"; exit 1; }
        command -v bun  >/dev/null 2>&1 && echo "✅ Bun: $(bun --version)"   || { echo "❌ Bun missing"; exit 1; }
        command -v pnpm >/dev/null 2>&1 && echo "✅ pnpm: $(pnpm --version)" || echo "ℹ️  pnpm not found"
        command -v yarn >/dev/null 2>&1 && echo "✅ yarn: $(yarn --version)" || echo "ℹ️  yarn not found"

        command -v docker >/dev/null 2>&1 && echo "✅ Docker CLI present" || { echo "❌ Docker CLI missing"; exit 1; }

        touch /workspace/.write-test && rm /workspace/.write-test && echo "✅ Workspace writable"
    '; then
        echo -e "${GREEN}✅ TypeScript basic tests passed${NC}"
        return 0
    else
        echo -e "${RED}❌ TypeScript tests failed${NC}"
        return 1
    fi
}

test_python_image() {
    local image_name="$1"
    echo -e "${BLUE}🧪 Testing Python image: $image_name${NC}"
    if ! docker image inspect "$image_name" >/dev/null 2>&1; then
        echo -e "${RED}❌ Image $image_name not found${NC}"
        return 1
    fi
    if docker run --rm "$image_name" bash -c '
        set -e
        echo "=== Python Image Tests ==="
        echo "User: $(whoami)"
        echo "Home: $HOME"

        command -v python3 >/dev/null 2>&1 && echo "✅ Python: $(python3 --version)" || { echo "❌ Python missing"; exit 1; }
        command -v pip3    >/dev/null 2>&1 && echo "✅ pip: $(pip3 --version)"      || { echo "❌ pip missing"; exit 1; }
        command -v poetry  >/dev/null 2>&1 && echo "✅ Poetry: $(poetry --version)" || { echo "❌ Poetry missing"; exit 1; }

        python3 - <<PY
print("✅ Python quick check OK")
PY

        command -v docker >/dev/null 2>&1 && echo "✅ Docker CLI present" || { echo "❌ Docker CLI missing"; exit 1; }

        touch /workspace/.write-test && rm /workspace/.write-test && echo "✅ Workspace writable"
    '; then
        echo -e "${GREEN}✅ Python basic tests passed${NC}"
        return 0
    else
        echo -e "${RED}❌ Python tests failed${NC}"
        return 1
    fi
}

test_docker_in_docker() {
    local image_name="$1"
    echo -e "${BLUE}🐳 Docker-in-Docker smoke test (TypeScript image)...${NC}"
    if docker run --rm --privileged "$image_name" bash -c '
        set -e
        command -v docker >/dev/null 2>&1 || { echo "❌ Docker CLI missing"; exit 1; }
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker daemon accessible"
        else
            echo "ℹ️  Starting Docker daemon"
            sudo dockerd --host=unix:///var/run/docker.sock --pidfile=/var/run/docker.pid >/tmp/dockerd.log 2>&1 &
            for i in {1..20}; do docker info >/dev/null 2>&1 && break || sleep 2; done
            docker info >/dev/null 2>&1 && echo "✅ Docker daemon started" || { echo "❌ Docker daemon failed"; exit 1; }
        fi
        timeout 60 docker pull alpine:latest >/dev/null 2>&1 && echo "✅ Pull works" || { echo "❌ Pull failed"; exit 1; }
        docker run --rm alpine:latest echo ok >/dev/null 2>&1 && echo "✅ Run works" || { echo "❌ Run failed"; exit 1; }
    '; then
        echo -e "${GREEN}✅ Docker-in-Docker tests passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Docker-in-Docker tests failed (non-fatal)${NC}"
        return 1
    fi
}

show_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./test.sh [both|python|typescript] [--build|--skip-build]"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./test.sh --build                 # Build all, then test both in parallel"
    echo "  ./test.sh typescript --skip-build # Test only TypeScript"
    echo ""
}

main() {
    echo -e "${BLUE}🚀 DevContainer Image Tests${NC}"
    verify_environment

    local target="both"
    local do_build="true"

    # Env overrides
    if [[ -n "$TEST_IMAGE" ]]; then target="$TEST_IMAGE"; fi
    if [[ "$SKIP_BUILD" == "true" ]]; then do_build="false"; fi

    # Args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            python|typescript|both) target="$1"; shift ;;
            --build) do_build="true"; shift ;;
            --skip-build) do_build="false"; shift ;;
            -h|--help|help) show_usage; exit 0 ;;
            *) echo -e "${RED}❌ Unknown arg: $1${NC}"; show_usage; exit 1 ;;
        esac
    done

    # Build first (always builds common, then children)
    if [[ "$do_build" == "true" ]]; then
        build_images
    else
        echo -e "${YELLOW}⚠️  Skipping build; testing existing images${NC}"
    fi

    # Select tests
    local run_py=false run_ts=false
    case "$target" in
        python) run_py=true ;;
        typescript) run_ts=true ;;
        both|all) run_py=true; run_ts=true ;;
        *) echo -e "${RED}❌ Invalid target: $target${NC}"; exit 1 ;;
    esac

    # Run tests in parallel
    echo -e "${BLUE}🏃 Running tests in parallel...${NC}"
    local p_pid=0 t_pid=0
    local p_res=0 t_res=0

    if $run_py; then
        ( test_python_image "$PYTHON_IMAGE" ) & p_pid=$!
    fi
    if $run_ts; then
        ( test_typescript_image "$TYPESCRIPT_IMAGE" ) & t_pid=$!
    fi

    # Wait and collect
    if [[ $p_pid -ne 0 ]]; then
        wait $p_pid || p_res=$?
    fi
    if [[ $t_pid -ne 0 ]]; then
        wait $t_pid || t_res=$?
    fi

    # Run Docker-in-Docker tests for selected images (only if basic tests passed)
    local pd_pid=0 td_pid=0
    local pd_res=0 td_res=0
    if $run_py && [[ $p_res -eq 0 ]]; then
        ( test_docker_in_docker "$PYTHON_IMAGE" ) & pd_pid=$!
    fi
    if $run_ts && [[ $t_res -eq 0 ]]; then
        ( test_docker_in_docker "$TYPESCRIPT_IMAGE" ) & td_pid=$!
    fi

    if [[ $pd_pid -ne 0 ]]; then
        wait $pd_pid || pd_res=$?
    fi
    if [[ $td_pid -ne 0 ]]; then
        wait $td_pid || td_res=$?
    fi

    echo -e "\n${BLUE}=== Test Results ===${NC}"
    if $run_py; then
        [[ $p_res -eq 0 ]] && echo -e "${GREEN}✅ Python basic: PASSED${NC}" || echo -e "${RED}❌ Python basic: FAILED${NC}"
        if [[ $p_res -eq 0 ]]; then
            [[ $pd_res -eq 0 ]] && echo -e "${GREEN}✅ Python DinD: PASSED${NC}" || echo -e "${RED}❌ Python DinD: FAILED${NC}"
        fi
    fi
    if $run_ts; then
        [[ $t_res -eq 0 ]] && echo -e "${GREEN}✅ TypeScript basic: PASSED${NC}" || echo -e "${RED}❌ TypeScript basic: FAILED${NC}"
        if [[ $t_res -eq 0 ]]; then
            [[ $td_res -eq 0 ]] && echo -e "${GREEN}✅ TypeScript DinD: PASSED${NC}" || echo -e "${RED}❌ TypeScript DinD: FAILED${NC}"
        fi
    fi

    # Overall status requires both basic and DinD (when run) to pass
    local overall_ok=true
    if $run_py; then
        if [[ $p_res -ne 0 || $pd_res -ne 0 ]]; then overall_ok=false; fi
    fi
    if $run_ts; then
        if [[ $t_res -ne 0 || $td_res -ne 0 ]]; then overall_ok=false; fi
    fi

    if $overall_ok; then
        echo -e "\n${GREEN}🎉 All tests passed${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
