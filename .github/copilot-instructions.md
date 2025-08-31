# Copilot Instructions

**ALWAYS FOLLOW THESE INSTRUCTIONS FIRST.** Only search for additional context or run bash commands if the information in these instructions is incomplete or found to be in error.

This repository creates a unified DevContainer base image supporting Python and TypeScript development with modern tooling.

## Working Effectively

### Bootstrap and Validate Environment
**CRITICAL SETUP - Run these commands in order:**

```bash
# Install DevContainer CLI (required for building)
npm install -g @devcontainers/cli

# Validate environment - NEVER CANCEL: Takes 1-2 minutes. Set timeout to 5+ minutes.
./test
```

**Expected Result:** Comprehensive validation of Python, TypeScript, Node.js, Poetry, CLI tools, and AI tools. Some warnings are normal (in-project virtualenv, npm install issues).

### Build Process - CURRENT LIMITATIONS

**WARNING:** Local DevContainer builds currently fail due to network connectivity issues downloading packages (eza, apt packages). This is a known limitation documented in README troubleshooting.

**DO NOT ATTEMPT:** 
```bash
# THIS FAILS - Network connectivity issues
devcontainer build --workspace-folder containers/base --image-name test:latest
```

**INSTEAD USE:** Pre-built registry image for testing:
```bash
# Test with existing registry image
IMAGE=ghcr.io/get2knowio/devcontainer:latest ./test
```

### Validation Scenarios - ALWAYS RUN THESE

**After making any changes, ALWAYS run these validation steps:**

1. **Basic Validation:** 
   ```bash
   ./test  # Takes 1m19s - NEVER CANCEL. Set timeout to 5+ minutes.
   ```

2. **TypeScript Development Workflow:**
   ```bash
   mkdir -p /tmp/ts-test && cd /tmp/ts-test
   # Test TypeScript compilation in container
   docker run --rm --user $(id -u):$(id -g) -v $(pwd):/workspace \
     ghcr.io/get2knowio/devcontainer:latest bash -c '
     export NVM_DIR="/home/vscode/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && 
     cd /workspace && 
     echo "console.log(\"Hello TypeScript\");" > test.ts && 
     /home/vscode/.nvm/versions/node/v22.19.0/bin/npx tsc test.ts && 
     /home/vscode/.nvm/versions/node/v22.19.0/bin/node test.js'
   ```

3. **Python Development Workflow:**
   ```bash
   # Poetry workflow validation included in ./test script
   # Manual test if needed:
   docker run --rm --user vscode ghcr.io/get2knowio/devcontainer:latest \
     bash -c 'cd /tmp && poetry init --no-interaction && poetry add requests'
   ```

### Timing Expectations - NEVER CANCEL

**CRITICAL:** Always set appropriate timeouts and wait for completion:

- **Test Suite:** 1m19s - Set timeout to 300+ seconds (5+ minutes)
- **Image Pull:** 30-60s for first time - Set timeout to 180+ seconds (3+ minutes)  
- **Container Operations:** 10-30s - Set timeout to 120+ seconds (2+ minutes)
- **DevContainer Build:** Currently fails (~43s) due to network issues

**NEVER CANCEL any of these operations.** If they appear to hang, wait the full timeout period.

## Current Working Commands

### Available Scripts
```bash
./test                           # Comprehensive validation (wrapper for scripts/test.sh)
DIND_TESTS=false ./test         # Skip Docker-in-Docker tests
IMAGE=custom:tag ./test         # Test specific image
```

### Missing Scripts (Referenced in README but don't exist yet)
**DO NOT USE - These scripts don't exist:**
- `./build` (no scripts/build.sh exists)
- `./run-local`
- `./install-act` 
- `./ci-env`
- `./build-image`
- `./test-image` 
- `./promote-image`

**If you need to implement any of these, follow the Shell Scripts Organization pattern below.**

### Container Testing Commands
```bash
# Quick Node.js test
docker run --rm --user vscode ghcr.io/get2knowio/devcontainer:latest \
  bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && node --version'

# Quick Python test  
docker run --rm ghcr.io/get2knowio/devcontainer:latest poetry --version

# Quick TypeScript test
docker run --rm --user vscode ghcr.io/get2knowio/devcontainer:latest \
  bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && npx tsc --version'
```

## Troubleshooting

### Network/Build Issues
- **DevContainer Build Failures:** Known issue with network connectivity (eza download, apt packages)
- **npm install Failures:** Permission/network issues in some container scenarios - this is normal
- **Solution:** Use pre-built registry image `ghcr.io/get2knowio/devcontainer:latest` for testing

### Container Permission Issues
When mounting volumes for testing:
```bash
# Use proper user mapping
docker run --rm --user $(id -u):$(id -g) -v $(pwd):/workspace ...
```

### Docker-in-Docker Issues
- DinD tests may fail in some environments - use `DIND_TESTS=false ./test`
- This is non-fatal for most development scenarios

## Project Structure Conventions

### Shell Scripts Organization

**Rule: All shell scripts must be stored in the `scripts/` directory with wrapper files in the project root.**

- **Location**: All actual shell scripts (`.sh` files) should be placed in the `scripts/` directory
- **Root Wrappers**: Create convenience wrapper files in the project root (without `.sh` extension) that execute the corresponding script in `scripts/`
- **Wrapper Pattern**: Use this template for root wrapper files:

```bash
#!/bin/bash
# Convenience wrapper for scripts/<script-name>.sh
exec "$(dirname "$0")/scripts/<script-name>.sh" "$@"
```

**Examples:**
- Actual script: `scripts/test.sh` (exists)
- Root wrapper: `test` (exists, calls `scripts/test.sh`)
- Missing: `scripts/build.sh` and `build` wrapper

### DevContainer Configuration

**Rule: Use a unified container approach with devcontainer features.**

- **Unified Container**: Single container in `containers/base/` that includes all development tools (Python, TypeScript, Docker-in-Docker, etc.)
- **Features-Based**: Use DevContainer features instead of manual Dockerfile installations for better maintainability
- **Clean Architecture**: Dockerfile focuses on core tools, devcontainer.json handles language-specific features

**Current Structure:**
```
containers/base/
  .devcontainer/devcontainer.json    # Unified configuration with features  
  Dockerfile                         # Core system setup and custom tools
```

### CI/CD Process

**GitHub Actions Workflow:** `.github/workflows/docker-build-push.yml`
- Builds multi-arch DevContainer images (linux/amd64, linux/arm64)
- Tests with `scripts/test.sh`
- Publishes to `ghcr.io/get2knowio/devcontainer:latest`
- **Build Time:** Not measurable locally due to network issues

## Repository Layout
```
containers/base/           # DevContainer configuration
scripts/test.sh           # Comprehensive validation script
test                      # Wrapper for scripts/test.sh
.github/workflows/        # CI/CD pipeline
docs/ACT_USAGE.md        # Local GitHub Actions testing docs
```

## Key Components Validated by Tests

**The test script validates all of these - don't skip validation:**
- Core System: Python 3.12, build tools, venv functionality
- Poetry: Installation, project creation, dependency management
- Modern CLI Tools: bat, ripgrep, fd-find, jq, fzf, eza
- Starship: Prompt installation and configuration  
- DevContainer Features: Docker CLI, AWS CLI
- Node.js Ecosystem: nvm, Node LTS (v22.19.0), npm, pnpm, yarn, bun
- TypeScript: compiler, ts-node, tsx, project compilation
- Development Tools: nodemon, concurrently, tsc-watch, vite, esbuild
- Code Quality: prettier, eslint, biome
- AI CLIs: Google Gemini CLI, Anthropic Claude CLI
