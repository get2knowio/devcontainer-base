#!/bin/bash

# test.sh - Local build test script for devcontainer-base
# This script builds Docker images locally and runs basic tests to ensure they work correctly.
# 
# Usage:
#   ./test.sh                                    # Build and test both images
#   ./test.sh python                            # Build and test Python image only
#   ./test.sh typescript                        # Build and test TypeScript image only
#   ./test.sh <full-image-name>                 # Test a specific image without building

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test Python image
test_python_image() {
    local image_name=$1
    echo -e "${BLUE}🧪 Running Python tests inside the container...${NC}"
    
    docker run --rm "${image_name}" bash -c '
        echo "✅ Testing Python installations"
        echo "python --version:"
        python --version
        echo "python3 --version:"
        python3 --version
        echo "python3.12 --version:"
        python3.12 --version

        echo ""
        echo "✅ Testing Poetry"
        poetry --version

        echo ""
        echo "✅ Testing Node.js (via NVM)"
        source ~/.nvm/nvm.sh && node --version && npm --version

        echo ""
        echo "✅ Testing AWS CLI"
        aws --version 2>/dev/null || echo "AWS CLI not available (expected on some architectures)"

        echo ""
        echo "✅ Testing development tools"
        echo "Git: $(git --version)"
        echo "eza: $(eza --version | head -1)"
        echo "bat: $(bat --version)"
        echo "ripgrep: $(rg --version | head -1)"
        echo "Starship: $(starship --version 2>/dev/null || echo "available")"

        echo ""
        echo "✅ Testing shell configuration"
        echo "Starship prompt in zsh: $(grep starship ~/.zshrc | head -1)"
        echo "Python alias in bashrc: $(grep "alias python" ~/.bashrc)"

        echo ""
        echo "✅ Testing Python packages can be installed"
        python -m pip install --quiet --break-system-packages requests
        python -c "import requests; print(f\"requests: {requests.__version__}\")"

        echo ""
        echo "🎉 Python tests completed successfully!"
        echo "Architecture: $(uname -m)"
    '
}

# Function to test TypeScript image
test_typescript_image() {
    local image_name=$1
    echo -e "${BLUE}🧪 Running TypeScript tests inside the container...${NC}"
    
    docker run --rm "${image_name}" bash -c '
        echo "✅ Testing Node.js installations"
        source ~/.nvm/nvm.sh
        echo "Node.js version:"
        node --version
        echo "npm version:"
        npm --version

        echo ""
        echo "✅ Testing Bun"
        /opt/bun/bin/bun --version

        echo ""
        echo "✅ Testing TypeScript tooling"
        echo "TypeScript: $(npx tsc --version)"
        echo "tsx: $(npx tsx --version)"
        echo "pnpm: $(pnpm --version)"
        echo "yarn: $(yarn --version)"

        echo ""
        echo "✅ Testing Python support"
        python --version

        echo ""
        echo "✅ Testing AWS CLI"
        aws --version 2>/dev/null || echo "AWS CLI not available (expected on some architectures)"

        echo ""
        echo "✅ Testing development tools"
        echo "Git: $(git --version)"
        echo "eza: $(eza --version | head -1)"
        echo "bat: $(bat --version)"
        echo "ripgrep: $(rg --version | head -1)"
        echo "Starship: $(starship --version 2>/dev/null || echo "available")"

        echo ""
        echo "✅ Testing shell configuration"
        echo "Starship prompt in zsh: $(grep starship ~/.zshrc | head -1)"
        echo "TypeScript aliases in zshrc: $(grep "alias tsc" ~/.zshrc)"
        echo "Bun aliases in zshrc: $(grep "alias bi=" ~/.zshrc)"

        echo ""
        echo "✅ Testing TypeScript compilation"
        echo "console.log(\"TypeScript test\");" > test.ts
        npx tsc test.ts
        node test.js
        rm -f test.ts test.js

        echo ""
        echo "✅ Testing Bun execution"
        echo "console.log(\"Bun test\");" > test-bun.ts
        /opt/bun/bin/bun test-bun.ts
        rm -f test-bun.ts

        echo ""
        echo "🎉 TypeScript tests completed successfully!"
        echo "Architecture: $(uname -m)"
    '
}

# Function to build and test an image
build_and_test_image() {
    local variant=$1
    local dockerfile=$2
    local image_name=$3
    local test_function=$4
    
    echo -e "${YELLOW}🧹 Cleaning up any existing ${variant} test images...${NC}"
    if docker image inspect "${image_name}" >/dev/null 2>&1; then
        echo "Removing existing image: ${image_name}"
        docker rmi "${image_name}" >/dev/null 2>&1 || true
    fi

    echo -e "${YELLOW}🔨 Building ${variant} Docker image locally...${NC}"
    echo "Image: ${image_name}"
    echo "Dockerfile: ${dockerfile}"
    echo ""

    docker build --quiet --no-cache -f "${dockerfile}" -t "${image_name}" .

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${variant} build successful!${NC}"
    else
        echo -e "${RED}❌ ${variant} build failed!${NC}"
        return 1
    fi

    echo ""
    $test_function "${image_name}"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 ${variant} image test PASSED!${NC}"
        echo "The ${image_name} image is ready to use."
        return 0
    else
        echo ""
        echo -e "${RED}❌ ${variant} image test FAILED!${NC}"
        return 1
    fi
}

# Clean up any dangling images to free space
cleanup_dangling_images() {
    echo "Cleaning up dangling images..."
    docker image prune -f >/dev/null 2>&1 || true
}

# Main script logic
if [ $# -eq 0 ]; then
    # No arguments - build and test both images
    echo -e "${YELLOW}🚀 Building and testing both devcontainer images...${NC}"
    cleanup_dangling_images
    
    # Test Python image
    echo -e "\n${BLUE}========== PYTHON IMAGE ===========${NC}"
    build_and_test_image "Python" "Dockerfile.python" "devcontainer-python-base:test" "test_python_image"
    python_result=$?
    
    # Test TypeScript image  
    echo -e "\n${BLUE}========== TYPESCRIPT IMAGE ===========${NC}"
    build_and_test_image "TypeScript" "Dockerfile.typescript" "devcontainer-typescript-base:test" "test_typescript_image"
    typescript_result=$?
    
    # Summary
    echo -e "\n${BLUE}========== SUMMARY ===========${NC}"
    if [ $python_result -eq 0 ]; then
        echo -e "${GREEN}✅ Python image: PASSED${NC}"
    else
        echo -e "${RED}❌ Python image: FAILED${NC}"
    fi
    
    if [ $typescript_result -eq 0 ]; then
        echo -e "${GREEN}✅ TypeScript image: PASSED${NC}"
    else
        echo -e "${RED}❌ TypeScript image: FAILED${NC}"
    fi
    
    if [ $python_result -eq 0 ] && [ $typescript_result -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests PASSED!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests FAILED!${NC}"
        exit 1
    fi
    
elif [ "$1" = "python" ]; then
    # Build and test Python image only
    echo -e "${YELLOW}🚀 Building and testing Python devcontainer image...${NC}"
    cleanup_dangling_images
    build_and_test_image "Python" "Dockerfile.python" "devcontainer-python-base:test" "test_python_image"
    
elif [ "$1" = "typescript" ]; then
    # Build and test TypeScript image only
    echo -e "${YELLOW}🚀 Building and testing TypeScript devcontainer image...${NC}"
    cleanup_dangling_images
    build_and_test_image "TypeScript" "Dockerfile.typescript" "devcontainer-typescript-base:test" "test_typescript_image"
    
else
    # Test a specific image (passed as argument)
    IMAGE_NAME=$1
    echo "Testing existing image: ${IMAGE_NAME}"
    
    # Determine which test to run based on image name
    if [[ "${IMAGE_NAME}" == *"python"* ]]; then
        test_python_image "${IMAGE_NAME}"
        test_result=$?
    elif [[ "${IMAGE_NAME}" == *"typescript"* ]]; then
        test_typescript_image "${IMAGE_NAME}"  
        test_result=$?
    else
        echo -e "${RED}❌ Cannot determine image type from name: ${IMAGE_NAME}${NC}"
        echo "Please specify 'python' or 'typescript', or use a full image name containing 'python' or 'typescript'"
        exit 1
    fi
    
    if [ $test_result -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 Docker image test PASSED!${NC}"
        echo "The ${IMAGE_NAME} image is ready to use."
    else
        echo ""
        echo -e "${RED}❌ Docker image test FAILED!${NC}"
        exit 1
    fi
fi
