#!/bin/bash

# test-docker-feature.sh
# Test script to debug Docker-in-Docker feature installation issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Testing Docker-in-Docker Feature Installation${NC}"
echo "=================================================="
echo ""

# Test network connectivity
echo -e "${BLUE}Testing network connectivity...${NC}"
echo -n "packages.microsoft.com: "
if curl -fsSL --connect-timeout 10 --max-time 30 https://packages.microsoft.com > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo -n "docker.io: "
if curl -fsSL --connect-timeout 10 --max-time 30 https://registry-1.docker.io > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo -n "github.com: "
if curl -fsSL --connect-timeout 10 --max-time 30 https://github.com > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo ""

# Test Docker build with Docker-in-Docker feature directly
echo -e "${BLUE}Testing minimal Docker-in-Docker feature build...${NC}"

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create .devcontainer directory
mkdir -p "$TEMP_DIR/.devcontainer"

cat > "$TEMP_DIR/.devcontainer/devcontainer.json" << 'EOF'
{
  "name": "Docker-in-Docker Test",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {
      "version": "24.0",
      "enableNonRootDocker": "true",
      "moby": "true",
      "dockerDashComposeVersion": "v2"
    }
  },
  "remoteUser": "vscode"
}
EOF

cd "$TEMP_DIR"

echo "Building test container..."
if devcontainer build --workspace-folder . --image-name docker-test:latest; then
    echo -e "${GREEN}✅ Docker-in-Docker feature test passed!${NC}"
    
    # Test that Docker works inside the container
    echo -e "${BLUE}Testing Docker functionality inside container...${NC}"
    if docker run --rm --privileged docker-test:latest docker --version; then
        echo -e "${GREEN}✅ Docker command works inside container!${NC}"
    else
        echo -e "${RED}❌ Docker command failed inside container${NC}"
    fi
    
    # Cleanup test image
    docker rmi docker-test:latest || true
else
    echo -e "${RED}❌ Docker-in-Docker feature test failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All tests completed!${NC}"
