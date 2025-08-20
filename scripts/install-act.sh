#!/bin/bash
# Install act for local GitHub Actions testing
# https://github.com/nektos/act

set -e

echo "Installing act (GitHub Actions local runner)..."

# Check if act is already installed
if command -v act &> /dev/null; then
    echo "act is already installed at $(which act)"
    act --version
    exit 0
fi

# Download and install act using the official install script
curl -sSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash

# Move to system path if installed locally
if [ -f "./bin/act" ] && [ ! -f "/usr/local/bin/act" ]; then
    echo "Moving act to system path..."
    sudo mv ./bin/act /usr/local/bin/act
fi

# Verify installation
if command -v act &> /dev/null; then
    echo "✅ act installed successfully!"
    act --version
else
    echo "❌ Failed to install act"
    exit 1
fi

echo ""
echo "Usage examples:"
echo "  act                    # Run the default workflow"
echo "  act -l                 # List available workflows"
echo "  act push               # Run workflows triggered by 'push' event"
echo "  act --dry-run          # Show what would be run without executing"
echo "  act -W .github/workflows/docker-build-push.yml  # Run specific workflow"
echo ""
echo "Note: act requires Docker to be running to execute workflows locally."
