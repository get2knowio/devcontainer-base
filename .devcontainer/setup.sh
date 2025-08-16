#!/bin/bash

# Setup script for DevContainer Base Testing Environment
# This script installs the DevContainer CLI and other testing tools

set -e

echo "🔧 Setting up DevContainer testing environment..."

# Install DevContainer CLI globally
echo "📦 Installing DevContainer CLI..."
npm install -g @devcontainers/cli

# Verify DevContainer CLI installation
echo "✅ DevContainer CLI version:"
devcontainer --version

# Install additional testing tools
echo "📦 Installing additional testing tools..."
npm install -g jq

# Make test scripts executable
chmod +x test.sh
if [ -f docker-setup.sh ]; then
    chmod +x docker-setup.sh
fi

# Verify Docker access
echo "🐳 Verifying Docker access..."
docker version
docker info

echo "🎉 DevContainer testing environment setup complete!"
echo ""
echo "Available commands:"
echo "  devcontainer --help    # DevContainer CLI help"
echo "  ./test.sh              # Run container tests"
echo "  docker version         # Verify Docker access"
