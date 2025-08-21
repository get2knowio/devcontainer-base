# Unified DevContainer Base (Python + TypeScript)

Single multi-language development container with modern tooling for Python and TypeScript. One image. One workflow. Less maintenance.

## 🚀 Quick start
Build, test, run:
```bash
./build                 # Build (devcontainer-unified:latest)
./test                  # Validate toolchain + DinD
./build ghcr.io/you/img:dev   # Custom tag
IMAGE=ghcr.io/you/img:dev ./test  # Test remote tag
```

## 🔧 Stack
Core:
- Base: mcr.microsoft.com/devcontainers/python:3.12
- Docker Engine + Buildx + Compose v2 (DinD-ready)
- Node (nvm LTS) + npm + yarn + pnpm
- TypeScript toolchain: typescript, ts-node, tsx, @types/node, nodemon, concurrently, vite, esbuild, prettier, eslint, @biomejs/biome, tsc-watch
- Python: Poetry (Dockerfile install), venv-in-project support
- AI CLIs: @google/gemini-cli, @anthropic-ai/claude-code
- Modern CLIs: eza, fzf, bat, ripgrep, fd, jq
- Shell: zsh + starship

## 🏗️ Build variants
Multi-arch and knobs via env vars:
```bash
PLATFORM=linux/arm64 ./build                # Alt arch
NO_CACHE=true ./build                       # Fresh build
PUSH=true IMAGE_TAG=ghcr.io/you/img:edge ./build
```

## 🧪 Test coverage
The test script asserts:
- Node, npm, TypeScript compiler
- Python + Poetry
- Docker CLI (and optional DinD smoke)
- Workspace write perms
- Presence (if installed) of AI CLIs

Skip DinD:
```bash
DIND_TESTS=false ./test
```

## � Layout
```
containers/base/ (devcontainer.json + Dockerfile)
scripts/build.sh  (devcontainer CLI build wrapper)
scripts/test.sh   (image validation + DinD smoke)
build / test      (thin wrappers)
```

## 🛠️ CI
Workflow: `.github/workflows/docker-build-push.yml`
Single job builds multi-arch image, runs tests, promotes CI tag to canonical tags.

## 🧰 Usage patterns
Python project:
```bash
poetry init  # then poetry install
```
TypeScript project:
```bash
npm init -y && npm install typescript
npx tsc --init
```

## 🔐 Notes
- User: vscode (sudo)
- Multi-arch: linux/amd64, linux/arm64
- Node installed in Dockerfile (needed for AI CLIs)

## 🧹 Migration
Legacy separate python/typescript images have been removed; everything lives in `containers/base/`.

## 📄 License
See LICENSE file.
 
## 🔧 Troubleshooting

### Docker-in-Docker Issues

If you encounter issues with Docker-in-Docker feature installation during CI builds, the project includes several resilience improvements:

#### Network Connectivity Issues
If you see errors like:
```
OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to packages.microsoft.com:443
gpg: no valid OpenPGP data found.
ERROR: Feature "Docker (Docker-in-Docker)" failed to install!
```

**Troubleshooting steps:**

1. **Test connectivity locally:**
   ```bash
   ./test-docker-feature
   ```

2. **Check the CI warm-up step** in GitHub Actions logs - this pre-tests connectivity

3. **Retry the workflow** - networking issues are often transient

#### Configuration Improvements

The project includes several improvements to handle networking issues:

- **Docker-in-Docker Feature**: Uses specific version (`24.0`) instead of `latest` for stability
- **APT Configuration**: Automatic retries (3x) and extended timeouts (60s) for package downloads
- **Curl Settings**: Extended timeout settings for feature installations
- **CI Environment Variables**: Network resilience settings for multi-arch builds

#### Local Development

For local development issues:

```bash
# Test the build locally
./build typescript

# Test with Docker feature specifically
./test-docker-feature

# Build without cache to ensure fresh installation
NO_CACHE=true ./build typescript
```

### General DevContainer Issues

- **VS Code Extension**: Ensure you have the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed
- **Docker Requirements**: Docker Desktop must be running and accessible
- **Memory Requirements**: Multi-arch builds require sufficient memory (recommend 4GB+ available)
