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
IMAGE_NAME="devcontainer-python-base"
TAG="test"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

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
docker build --no-cache -f Dockerfile.python -t "${FULL_IMAGE_NAME}" .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🧪 Running basic tests...${NC}"

# Test 1: Check if the image runs
echo "Test 1: Container starts successfully..."
if docker run --rm "${FULL_IMAGE_NAME}" echo "Container started successfully" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Container starts successfully${NC}"
else
    echo -e "${RED}❌ Container failed to start${NC}"
    exit 1
fi

# Test 2: Check Python installation
echo "Test 2: Python 3.12 is installed..."
PYTHON_VERSION=$(docker run --rm "${FULL_IMAGE_NAME}" python3.12 --version 2>/dev/null | grep "Python 3.12" || echo "")
if [ -n "$PYTHON_VERSION" ]; then
    echo -e "${GREEN}✅ Python 3.12 is installed: ${PYTHON_VERSION}${NC}"
else
    echo -e "${RED}❌ Python 3.12 not found${NC}"
    exit 1
fi

# Test 3: Check Poetry installation
echo "Test 3: Poetry is installed..."
POETRY_VERSION=$(docker run --rm "${FULL_IMAGE_NAME}" poetry --version 2>/dev/null || echo "")
if [ -n "$POETRY_VERSION" ]; then
    echo -e "${GREEN}✅ Poetry is installed: ${POETRY_VERSION}${NC}"
else
    echo -e "${RED}❌ Poetry not found${NC}"
    exit 1
fi

# Test 4: Check if devuser exists
echo "Test 4: Non-root user 'devuser' exists..."
USER_EXISTS=$(docker run --rm "${FULL_IMAGE_NAME}" id devuser 2>/dev/null || echo "")
if [ -n "$USER_EXISTS" ]; then
    echo -e "${GREEN}✅ User 'devuser' exists: ${USER_EXISTS}${NC}"
else
    echo -e "${RED}❌ User 'devuser' not found${NC}"
    exit 1
fi

# Test 5: Check if zsh is available
echo "Test 5: Zsh shell is available..."
ZSH_VERSION=$(docker run --rm "${FULL_IMAGE_NAME}" zsh --version 2>/dev/null || echo "")
if [ -n "$ZSH_VERSION" ]; then
    echo -e "${GREEN}✅ Zsh is available: ${ZSH_VERSION}${NC}"
else
    echo -e "${RED}❌ Zsh not found${NC}"
    exit 1
fi

# Test 6: Check if essential tools are installed
echo "Test 6: Essential CLI tools are installed..."
TOOLS=("git" "curl" "jq" "rg")
for tool in "${TOOLS[@]}"; do
    if docker run --rm "${FULL_IMAGE_NAME}" which "$tool" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ${tool} is installed${NC}"
    else
        echo -e "${RED}❌ ${tool} not found${NC}"
        exit 1
    fi
done

# Special check for bat (which might be installed as batcat in Ubuntu)
echo -n "Test 6b: bat (syntax highlighter) is available... "
if docker run --rm "${FULL_IMAGE_NAME}" which bat > /dev/null 2>&1; then
    echo -e "${GREEN}✅ bat is installed${NC}"
elif docker run --rm "${FULL_IMAGE_NAME}" which batcat > /dev/null 2>&1; then
    echo -e "${GREEN}✅ bat is installed (as batcat)${NC}"
else
    echo -e "${RED}❌ bat not found${NC}"
    exit 1
fi

# Special check for fd (which might be installed as fdfind in Ubuntu)
echo -n "Test 6c: fd (find alternative) is available... "
if docker run --rm "${FULL_IMAGE_NAME}" which fd > /dev/null 2>&1; then
    echo -e "${GREEN}✅ fd is installed${NC}"
elif docker run --rm "${FULL_IMAGE_NAME}" which fdfind > /dev/null 2>&1; then
    echo -e "${GREEN}✅ fd is installed (as fdfind)${NC}"
else
    echo -e "${RED}❌ fd not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All tests passed! The image is ready for use.${NC}"
echo ""
echo "To use this image in your devcontainer:"
echo "  \"image\": \"${FULL_IMAGE_NAME}\""
echo ""
echo "To clean up the test image:"
echo "  docker rmi ${FULL_IMAGE_NAME}"
