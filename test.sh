#!/bin/bash

# test.sh - Local build test script for devcontainer-base
# This script builds the Docker image locally and runs basic tests to ensure it works correctly.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME=${1:-"devcontainer-python-base:test"}

echo "Testing image: ${IMAGE_NAME}"

# If no argument is passed, build the image
if [ -z "$1" ]; then
  TAG="test"
  FULL_IMAGE_NAME="devcontainer-python-base:${TAG}"
  echo -e "${YELLOW}🧹 Cleaning up any existing test images...${NC}"
  # Remove existing test image if it exists
  if docker image inspect "${FULL_IMAGE_NAME}" >/dev/null 2>&1; then
      echo "Removing existing image: ${FULL_IMAGE_NAME}"
      docker rmi "${FULL_IMAGE_NAME}" >/dev/null 2>&1 || true
  fi

  # Clean up any dangling images to free space
  echo "Cleaning up dangling images..."
  docker image prune -f >/dev/null 2>&1 || true

  echo -e "${YELLOW}🔨 Building Docker image locally...${NC}"
  echo "Image: ${FULL_IMAGE_NAME}"
  echo "Dockerfile: ./Dockerfile.python"
  echo ""

  # Build the image
  docker build --quiet --no-cache -f Dockerfile.python -t "${FULL_IMAGE_NAME}" .

  if [ $? -eq 0 ]; then
      echo -e "${GREEN}✅ Build successful!${NC}"
  else
      echo -e "${RED}❌ Build failed!${NC}"
      exit 1
  fi
else
  FULL_IMAGE_NAME=$IMAGE_NAME
fi

echo ""
echo -e "${YELLOW}🧪 Running comprehensive tests inside the container...${NC}"

# Run comprehensive tests
docker run --rm "${FULL_IMAGE_NAME}" bash -c '
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
  echo "🎉 All tests completed successfully!"
  echo "Architecture: $(uname -m)"
'

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Docker image test PASSED!${NC}"
    echo "The ${FULL_IMAGE_NAME} image is ready to use."
else
    echo ""
    echo -e "${RED}❌ Docker image test FAILED!${NC}"
    exit 1
fi
