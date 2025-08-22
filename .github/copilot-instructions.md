# Copilot Instructions

This document contains instructions and conventions for GitHub Copilot when working on this project.

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
- Actual script: `scripts/build.sh`
- Root wrapper: `build` (executable, calls `scripts/build.sh`)
- Actual script: `scripts/test.sh` 
- Root wrapper: `test` (executable, calls `scripts/test.sh`)

**Benefits:**
- Centralized script management in `scripts/` directory
- Clean project root with convenience access
- Consistent execution regardless of current working directory
- Easy maintenance and organization

### DevContainer Configuration

**Rule: Use a unified container approach with devcontainer features.**

- **Unified Container**: Single container in `containers/base/` that includes all development tools (Python, TypeScript, Docker-in-Docker, etc.)
- **Features-Based**: Use DevContainer features instead of manual Dockerfile installations for better maintainability
- **Clean Architecture**: Dockerfile focuses on core tools, devcontainer.json handles language-specific features

**Rule: Prefer DevContainer Features over Dockerfile installations.**

- **Features First**: Always use DevContainer features when available instead of manual Dockerfile installations
- **Cleaner Maintenance**: Features are more maintainable, standardized, and less error-prone than custom Dockerfile commands
- **Examples**: Use `ghcr.io/devcontainers/features/docker-in-docker:2` instead of manual Docker installation, use `ghcr.io/devcontainers/features/aws-cli:1` instead of manual AWS CLI setup
- **Dockerfile Only**: Reserve Dockerfile for tools that don't have official DevContainer features (like custom CLI tools, specific language versions, etc.)

**Current Structure:**
```
containers/
  base/
    devcontainer.json          # Unified configuration with features
    Dockerfile                 # Core system setup and custom tools
```

## File Naming Conventions

- Shell scripts: Use `.sh` extension for actual scripts in `scripts/`
- Root wrappers: No extension, same name as the script (without `.sh`)
- Configuration files: Use descriptive names with appropriate extensions

## When Making Changes

1. **Adding New Shell Scripts**: 
   - Create the script in `scripts/` with `.sh` extension
   - Create a wrapper in root without extension
   - Make both executable (`chmod +x`)

2. **Modifying Build Process**:
   - Update `scripts/build.sh` 
   - Test with the unified container in `containers/base/`

3. **DevContainer Changes**:
   - Update configuration in `containers/base/devcontainer.json`
   - Modify Dockerfile in `containers/base/Dockerfile` for custom tools only
   - Use DevContainer features for language tools and standard services
   - Test with `./build` command
