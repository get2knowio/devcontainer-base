#!/bin/bash

# merge-devcontainer.sh
# Merges common devcontainer.json with image-specific devcontainer.json

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <image-type> <output-file>"
    echo "Example: $0 typescript /tmp/devcontainer.json"
    echo "Example: $0 python /tmp/devcontainer.json"
    exit 1
fi

IMAGE_TYPE="$1"
OUTPUT_FILE="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINERS_DIR="$(dirname "$SCRIPT_DIR")/containers"

COMMON_CONFIG="$CONTAINERS_DIR/common/devcontainer.json"
IMAGE_CONFIG="$CONTAINERS_DIR/$IMAGE_TYPE/devcontainer.json"

# Check if files exist
if [ ! -f "$COMMON_CONFIG" ]; then
    echo "Error: Common config file not found: $COMMON_CONFIG"
    exit 1
fi

if [ ! -f "$IMAGE_CONFIG" ]; then
    echo "Error: Image-specific config file not found: $IMAGE_CONFIG"
    exit 1
fi

# Check if jq is installed
if ! command -v /usr/bin/jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Merge the configurations
# The image-specific config takes precedence over common config
/usr/bin/jq -s '.[0] * .[1]' "$COMMON_CONFIG" "$IMAGE_CONFIG" > "$OUTPUT_FILE"

echo "Merged devcontainer.json created at: $OUTPUT_FILE"
