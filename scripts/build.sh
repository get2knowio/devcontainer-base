#!/bin/bash

# build.sh - DevContainer CLI Docker Image Builder
# 
# This script uses the DevContainer CLI to build a Docker image based on our
# devcontainer.json configuration and Dockerfile for each container type.
# This approach allows us to leverage devcontainer features (like Docker-in-Docker)
# while still producing a standalone Docker image that can be published and reused.
#
# Features:
#   • Uses devcontainer CLI to build based on devcontainer.json + Dockerfile
#   • Includes Docker-in-Docker feature automatically
#   • Produces a tagged Docker image suitable for publishing
#   • Supports multi-architecture builds
#   • Validates the built image
#   • Single unified polyglot container (Python + TypeScript)
#
# Usage:
#   ./build.sh                                         # Build unified image with default tag
#   ./build.sh my-custom-tag                           # Build with custom tag
#   ./build.sh ghcr.io/owner/repo:tag                  # Build with full registry path
#
# Container Types:
#   unified    - Unified Python + TypeScript container (default/only)
#
# Environment Variables:
#   IMAGE_TAG - Override the default image tag
#   PLATFORM - Target platform (default: current platform)
#   NO_CACHE - Set to "true" to disable build cache
#   PUSH - Set to "true" to push the image after building

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
DEFAULT_IMAGE_TAG_PREFIX="devcontainer-unified"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR=""
CONTAINER_TYPE="unified"
SUPPORTED_CONTAINERS=("unified")

# Function to display script header
show_header() {
    echo -e "${BLUE}🏗️  DevContainer CLI Docker Image Builder${NC}"
    echo -e "${CYAN}Building Docker images using devcontainer.json + Dockerfile per container type${NC}"
    echo ""
}

# Function to display usage information
show_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./build.sh                                         # Build unified image"
    echo "  ./build.sh my-custom-tag                           # Build with custom tag"
    echo "  ./build.sh ghcr.io/owner/repo:tag                  # Build with full registry path"
    echo ""
    echo -e "${BLUE}Container Types:${NC}"
    echo "  unified    - Unified Python + TypeScript container"
    echo ""
    echo -e "${BLUE}Environment Variables:${NC}"
    echo "  IMAGE_TAG=my-tag ./build.sh <type>          # Override the default image tag"
    echo "  PLATFORM=linux/amd64 ./build.sh <type>     # Target specific platform"
    echo "  NO_CACHE=true ./build.sh <type>             # Disable build cache"
    echo "  PUSH=true ./build.sh <type>                 # Push image after building"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./build.sh                                  # Basic build"
    echo "  ./build.sh ghcr.io/org/img:dev              # Custom tag"
    echo "  IMAGE_TAG=my-app:v1.0 ./build.sh            # Custom tag via env var"
    echo "  PLATFORM=linux/arm64 ./build.sh             # ARM64 build"
    echo "  NO_CACHE=true PUSH=true ./build.sh          # No cache, auto-push"
}

# Function to verify prerequisites
verify_prerequisites() {
    echo -e "${BLUE}🔍 Verifying prerequisites...${NC}"
    
    # Check if devcontainer CLI is available
    if ! command -v devcontainer >/dev/null 2>&1; then
        echo -e "${RED}❌ DevContainer CLI not found.${NC}"
        echo "Please install it first:"
        echo "  npm install -g @devcontainers/cli"
        echo "Or see: https://github.com/devcontainers/cli"
        exit 1
    fi
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker not found. Please install Docker to build images.${NC}"
        exit 1
    fi
    
    # Verify Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker daemon is not running. Please start Docker.${NC}"
        exit 1
    fi
    
    # Check required files exist for the specified container type
    local container_dir="$SCRIPT_DIR/containers/base"
    if [[ ! -d "$container_dir" ]]; then
        echo -e "${RED}❌ Container directory not found: $container_dir${NC}"
        exit 1
    fi
    
    if [[ ! -f "$container_dir/.devcontainer/devcontainer.json" ]]; then
        echo -e "${RED}❌ devcontainer config not found: $container_dir/.devcontainer/devcontainer.json${NC}"
        exit 1
    fi
    
    if [[ ! -f "$container_dir/Dockerfile" ]]; then
        echo -e "${RED}❌ Dockerfile not found in $container_dir${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites verified!${NC}"
    echo "Container type: $CONTAINER_TYPE"
    echo "DevContainer CLI version: $(devcontainer --version)"
    echo "Docker version: $(docker --version)"
    echo ""
}

# Function to determine image tag
determine_image_tag() {
    local custom_tag="$1"
    
    # Priority: command line argument > environment variable > default
    if [[ -n "$custom_tag" ]]; then
        echo "$custom_tag"
    elif [[ -n "$IMAGE_TAG" ]]; then
        echo "$IMAGE_TAG"
    else
    echo "${DEFAULT_IMAGE_TAG_PREFIX}:latest"
    fi
}

# Function to create temporary workspace for building
create_temp_workspace() {
    echo -e "${BLUE}📁 Creating temporary build workspace...${NC}"
    
    TEMP_DIR=$(mktemp -d)
    echo "Temporary workspace: $TEMP_DIR"
    
    # Create .devcontainer directory
    mkdir -p "$TEMP_DIR/.devcontainer"
    
    # Use the container's devcontainer.json directly (inheritance handled by Dockerfiles)
    local container_dir="$SCRIPT_DIR/containers/base"
    echo -e "${BLUE}📄 Using $CONTAINER_TYPE devcontainer.json directly...${NC}"
    # Copy canonical devcontainer.json from .devcontainer directory
    cp "$container_dir/.devcontainer/devcontainer.json" "$TEMP_DIR/.devcontainer/devcontainer.json"
    
    # Copy Dockerfile to the temporary workspace root so relative paths like
    # "../Dockerfile" from .devcontainer/devcontainer.json resolve to $TEMP_DIR/Dockerfile
    cp "$container_dir/Dockerfile" "$TEMP_DIR/"
    
    # Copy any other files that might be referenced in the Dockerfile
    if [[ -f "$SCRIPT_DIR/.dockerignore" ]]; then
        cp "$SCRIPT_DIR/.dockerignore" "$TEMP_DIR/"
    fi
    
    echo -e "${GREEN}✅ Temporary workspace created${NC}"
    echo ""
}

# Function to build the image using devcontainer CLI
build_with_devcontainer() {
    local image_tag="$1"
    
    echo -e "${BLUE}🏗️  Building Docker image using DevContainer CLI...${NC}"
    echo "Image tag: $image_tag"
    echo "Build context: $TEMP_DIR"
    echo ""
    
    cd "$TEMP_DIR"
    
    # Prepare devcontainer build command
    local build_cmd="devcontainer build --workspace-folder . --image-name $image_tag"
    
    # Add platform if specified
    if [[ -n "$PLATFORM" ]]; then
        build_cmd="$build_cmd --platform $PLATFORM"
        echo "Target platform: $PLATFORM"
    fi
    
    # Add no-cache flag if specified
    if [[ "$NO_CACHE" == "true" ]]; then
        build_cmd="$build_cmd --no-cache"
        echo "Cache disabled"
    fi
    
    # Add verbose logging
    build_cmd="$build_cmd --log-level info"
    
    echo -e "${YELLOW}Running: $build_cmd${NC}"
    echo ""
    
    # Execute the build
    if eval "$build_cmd"; then
        echo -e "${GREEN}✅ Docker image built successfully!${NC}"
        echo "Image: $image_tag"
        return 0
    else
        echo -e "${RED}❌ Docker image build failed!${NC}"
        return 1
    fi
}

# Function to validate the built image
validate_image() {
    local image_tag="$1"
    
    echo -e "${BLUE}🧪 Validating built image...${NC}"
    
    # Check if image exists
    if ! docker image inspect "$image_tag" >/dev/null 2>&1; then
        echo -e "${RED}❌ Image $image_tag not found after build${NC}"
        return 1
    fi
    
    # Get image info
    local image_size=$(docker image inspect "$image_tag" --format '{{.Size}}' | numfmt --to=iec)
    local image_id=$(docker image inspect "$image_tag" --format '{{.Id}}' | cut -d: -f2 | head -c 12)
    local created=$(docker image inspect "$image_tag" --format '{{.Created}}')
    
    echo -e "${GREEN}✅ Image validation passed!${NC}"
    echo "Image ID: $image_id"
    echo "Size: $image_size"
    echo "Created: $created"
    
    # Basic functionality test
    echo -e "${YELLOW}🧪 Running basic functionality test...${NC}"
    
    if docker run --rm --privileged "$image_tag" bash -c 'echo "Container startup test: OK" && docker --version'; then
        echo -e "${GREEN}✅ Basic functionality test passed!${NC}"
    else
        echo -e "${RED}❌ Basic functionality test failed!${NC}"
        return 1
    fi
    
    echo ""
    return 0
}

# Function to push image if requested
push_image() {
    local image_tag="$1"
    
    if [[ "$PUSH" == "true" ]]; then
        echo -e "${BLUE}📤 Pushing image to registry...${NC}"
        echo "Image: $image_tag"
        
        if docker push "$image_tag"; then
            echo -e "${GREEN}✅ Image pushed successfully!${NC}"
        else
            echo -e "${RED}❌ Image push failed!${NC}"
            return 1
        fi
        echo ""
    fi
    
    return 0
}

# Function to cleanup temporary files
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        echo -e "${BLUE}🧹 Cleaning up temporary files...${NC}"
        cd "$SCRIPT_DIR"  # Make sure we're not in the temp directory
        rm -rf "$TEMP_DIR"
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    fi
}

# Function to display build summary
show_summary() {
    local image_tag="$1"
    local build_result="$2"
    
    echo -e "${BLUE}📋 Build Summary${NC}"
    echo "=================="
    echo "Image tag: $image_tag"
    echo "Build result: $([[ $build_result -eq 0 ]] && echo -e "${GREEN}SUCCESS${NC}" || echo -e "${RED}FAILED${NC}")"
    
    if [[ $build_result -eq 0 ]]; then
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo "• Test the image: docker run -it --rm $image_tag"
        echo "• Push to registry: docker push $image_tag"
        echo "• Use in docker-compose or Kubernetes"
        
        if [[ "$PUSH" != "true" ]]; then
            echo ""
            echo -e "${YELLOW}💡 Tip: Use PUSH=true to automatically push after building${NC}"
        fi
    fi
    
    echo ""
}

# Build a single container type end-to-end
build_single() {
    local target_type="$1"
    local custom_tag="$2"

    CONTAINER_TYPE="$target_type"
    TEMP_DIR=""

    verify_prerequisites
    local image_tag
    image_tag=$(determine_image_tag "$custom_tag")

    echo -e "${CYAN}Building unified container with tag: $image_tag${NC}"
    echo ""

    create_temp_workspace

    local build_result=0
    if ! build_with_devcontainer "$image_tag"; then
        build_result=1
    fi

    if [[ $build_result -eq 0 ]]; then
        if ! validate_image "$image_tag"; then
            build_result=1
        fi
    fi

    if [[ $build_result -eq 0 ]]; then
        if ! push_image "$image_tag"; then
            build_result=1
        fi
    fi

    show_summary "$image_tag" $build_result
    return $build_result
}

# Main function
main() {
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Show header
    show_header
    
    # Handle help request
    if [[ "$1" == "help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
        # Parse arguments (default to building all if omitted)
        local custom_tag
        if [[ -z "$1" ]]; then
            custom_tag=""
        else
            custom_tag="$1"
        fi

    # Optional dry run: verify prerequisites for all
    if [[ "$custom_tag" == "--dry-run" ]]; then
        echo -e "${YELLOW}🧪 Dry run mode - verifying prerequisites for unified${NC}"
        verify_prerequisites
        echo -e "${GREEN}✅ Dry run completed successfully!${NC}"
        exit 0
    fi

    build_single unified "$custom_tag" || exit 1
}

# Run main function with all arguments
main "$@"
