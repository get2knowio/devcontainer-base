# Copilot Instructions

This document contains instructions and conventions for GitHub Copilot when working on this project.

## Project Structure Conventions

### Shell Scripts Organization

**Rule: All shell scripts must be stored in the `scripts/` directory with wrapper files in the project root.**

- **Location**: All actual shell scripts (`.sh` files) should be placed in the `scripts/` directory
- **Root Wrappers**: Create convenience wrapper files in the project root (without `.sh` extension) that execute the corresponding script in `scripts/`
- **Wrapper Pattern**: Use this template for root wrapper files:

```zsh
#!/usr/bin/env zsh
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

### Shell Support

**Rule: Target zsh as the primary shell environment.**

- **Primary Shell**: All shell-specific configurations, completions, and scripts should target zsh
- **No Bash Support**: Don't worry about bash compatibility - focus solely on zsh functionality
- **Configuration Files**: Use zsh-specific syntax and features in configuration files
- **Completions**: Create zsh completions (`.zsh` files) instead of bash completions
- **Shell Scripts**: While scripts should remain POSIX-compatible when possible, shell-specific features should use zsh syntax

**Examples:**
- Use `~/.zshrc` for shell configuration
- Create `_command` completion files for zsh
- Leverage zsh arrays, parameter expansion, and other zsh-specific features
- Test scripts and configurations in zsh environment only

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

## Testing Global npm-installed CLIs (nvm + zsh)

Our Node toolchain is installed via `nvm` and activated in `~/.zshrc`. Non-interactive shells (e.g. `docker run ... zsh -lc`) do NOT source `~/.zshrc`, so global npm binaries (e.g. `codex`, `eslint`) may appear missing if you test incorrectly.

Use one of these patterns:

1. Recommended (interactive login + .zshrc):
   ```bash
   docker run -it --rm devcontainer-base:test zsh -lic 'which node && node -v && which codex'
   ```
2. Explicit nvm bootstrap (works for bash too):
   ```bash
   docker run --rm devcontainer-base:test bash -lc 'export NVM_DIR=$HOME/.nvm; . "$NVM_DIR/nvm.sh"; nvm use --silent default; which node; which codex'
   ```
3. One-off command without TTY (still need -i if using zsh):
   ```bash
   docker run --rm devcontainer-base:test zsh -lic 'codex --version'
   ```

Avoid:
- `docker run --rm devcontainer-base:test zsh -lc 'which codex'` (misses `.zshrc` because shell is not interactive).

Rule of thumb:
- Include `-i` for zsh when you need environment from `.zshrc`.
- Or source nvm manually inside the command.

When writing automated tests/scripts, prefer the explicit bootstrap (option 2) for determinism.
