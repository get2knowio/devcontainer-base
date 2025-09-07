# Contributing / Internal Documentation

This document explains how the unified devcontainer image is structured, built, and tested. The README focuses on **using** the environment; this file focuses on **maintaining** it.

## Contents
- Overview
- Build & Tags
- Multi-arch Strategy
- Version Overrides
- Test Workflow
- CI Workflow Details
- Development Scripts
- Adding / Updating Tools
- Node & nvm Strategy
- Troubleshooting (advanced)
- Migration History

---
## Overview
Source lives under `containers/default/`:
- `Dockerfile` – installs system tooling, Node via nvm, global TS/AI CLIs, poetry, aliases
- `.devcontainer/devcontainer.json` – adds features (docker-in-docker, aws-cli, jq-likes, uv)

Goals:
- Single image for Python + TypeScript work
- Minimal repeated logic (feature-first approach where possible)
- Fast local single-arch builds; CI multi-arch publication

## Build & Tags
Wrapper script: `./build`
Environment knobs:
- `PLATFORM` – e.g. `linux/amd64`, `linux/arm64`, or multi via CI buildx
- `NO_CACHE=true` – disable build cache
- `PUSH=true` with `IMAGE_TAG` – push after build (CI normally)

## Multi-arch Strategy
GitHub Actions workflow builds `linux/amd64,linux/arm64` using buildx and QEMU. Local builds default to host arch for speed. Tag promotion logic handled in workflow helper scripts.

## Version Overrides
Overridable Docker build args (see Dockerfile):
- `ACT_VERSION`
- `ACTIONLINT_VERSION`
- `AST_GREP_VERSION`
- `EZA_VERSION`
- `NVM_VERSION`
- `POETRY_VERSION`

Example:
```
docker build --build-arg ACT_VERSION=v0.2.69 -t devcontainer:test containers/default
```

## Test Workflow
`scripts/test.sh` validates core expectations:
- CLI presence (node, npm, poetry, docker, act, actionlint, ast-grep, neovim)
- AI CLIs (if enabled)
- PID1 is one of allowed list (sleep etc.)
- DinD optional smoke (can be skipped with `DIND_TESTS=false`)

`./test` wrapper runs it against the freshly built (or provided) image.

## CI Workflow Details
Workflow file: `.github/workflows/docker-build-push.yml`
Modes:
- `ci` (in Actions): multi-arch, push, tag+promote
- `local-act` (via `./run-local`): single-arch, no push

Helpers orchestrate these phases:
- `./ci-env` – sets MODE and writes cache file
- `./build-image` – performs buildx build if MODE=ci
- `./test-image` – runs validation
- `./promote-image` – tags & manifest creation (noop outside real CI)

## Development Scripts
All real scripts live in `scripts/` with thin root wrappers (see `copilot-instructions.md`).
Add new automation there to keep root clean and consistent.

## Adding / Updating Tools
Preference order:
1. Devcontainer feature (if one exists & mature)
2. Apt package (if stable and recent enough)
3. Direct release download (pin via ARG)

When adding a release download:
- Add ARG for version
- Handle `amd64` vs `arm64` naming differences
- Place binary in `/usr/local/bin`
- Add minimal verification in `scripts/test.sh`

## Node & nvm Strategy
We rely on interactive zsh shells for `nvm` environment initialization:
- `.zshrc` exports `NVM_DIR`, sources `nvm.sh`, runs a silent `nvm use` line
- No `/etc/profile.d` hacks; non-interactive shells must bootstrap manually

Testing patterns (examples):
```
# Interactive (preferred)
docker run -it --rm IMAGE zsh -lic 'node -v && which eslint'
# Explicit bootstrap (bash)
docker run --rm IMAGE bash -lc 'export NVM_DIR=$HOME/.nvm; . "$NVM_DIR/nvm.sh"; nvm use --silent default; node -v'
```

## Troubleshooting (advanced)
See README for user-facing guidance. Internal tips:
- Asset 404: verify release naming pattern for both arches
- Node global binary missing: confirm shell is interactive login
- Docker feature flakiness: rerun; network often transient

## Migration History
- v2.0 Unified architecture: merged language-specific images into single base
- Introduced multi-arch build + act local workflow path

## License
See `LICENSE`.
