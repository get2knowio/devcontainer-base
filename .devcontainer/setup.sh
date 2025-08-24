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

# Make test scripts executable
chmod +x scripts/test.sh

# Verify Docker access
echo "🐳 Verifying Docker access..."
docker version
docker info

echo "🎉 DevContainer testing environment setup complete!"
echo ""
echo "Available commands:"
echo "  devcontainer --help    # DevContainer CLI help"
echo "  build                  # Build the containers"
echo "  test                   # Run container tests"
echo "  docker version         # Verify Docker access"
