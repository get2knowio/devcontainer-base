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

**Rule: Use a common/specific merge pattern for devcontainer.json files.**

- **Common Config**: Shared configuration in `containers/common/devcontainer.json`
- **Specific Config**: Image-specific configuration in `containers/<type>/devcontainer.json` (only contains overrides/additions)
- **Merge Process**: Use `scripts/merge-devcontainer.sh` to combine common and specific configurations during build

**Rule: Prefer DevContainer Features over Dockerfile installations.**

- **Features First**: Always use DevContainer features when available instead of manual Dockerfile installations
- **Cleaner Maintenance**: Features are more maintainable, standardized, and less error-prone than custom Dockerfile commands
- **Examples**: Use `ghcr.io/devcontainers/features/python:1` instead of `apt install python3`, use `ghcr.io/devcontainers-extra/features/poetry:2` instead of `curl -sSL https://install.python-poetry.org`
- **Dockerfile Only**: Reserve Dockerfile for tools that don't have official DevContainer features
- **Language-Specific Priority**: For language-specific containers (Python, TypeScript, etc.), prefer adding language tools via features in the devcontainer.json rather than manual Dockerfile installations

**Example Structure:**
```
containers/
  common/
    devcontainer.json          # Shared configuration
  typescript/
    devcontainer.json          # TypeScript-specific overrides
    Dockerfile
  python/
    devcontainer.json          # Python-specific overrides  
    Dockerfile
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
   - Ensure changes work with the merge-devcontainer functionality

3. **DevContainer Changes**:
   - Update common config in `containers/common/devcontainer.json` for shared changes
   - Update specific config in `containers/<type>/devcontainer.json` for type-specific changes
   - Test merge process with `scripts/merge-devcontainer.sh`
