# get2know.io DevContainer

Single multi-language development container with modern tooling for Python and TypeScript. One image. One workflow. Less maintenance.

## 🧰 Tooling & Features Inventory
Comprehensive list of what the image bakes in (multi-arch: linux/amd64 & linux/arm64). Items sourced either from the upstream base, devcontainer features, or the Dockerfile.

Language & Runtimes:
- Python 3.12 (base image) + `pip`, `venv`, `poetry` (installed globally; in-project virtualenvs enabled)
- Node (via `nvm` LTS) + global package managers: `npm`, `pnpm`, `yarn`, `bun`
- UV (Python package manager) via feature: `ghcr.io/jsburckhardt/devcontainer-features/uv:1`

TypeScript / JS Toolchain (globally installed):
- `typescript`, `ts-node`, `tsx`, `@types/node`, `nodemon`, `concurrently`, `vite`, `esbuild`, `prettier`, `eslint`, `@biomejs/biome`, `tsc-watch`

AI / LLM CLIs:
- `@google/gemini-cli`
- `@anthropic-ai/claude-code`
- `@openai/codex` (Codex CLI)

Dev & CI Utilities:
- Docker CLI (with in-container daemon from feature) + Buildx
- AWS CLI (feature: `ghcr.io/devcontainers/features/aws-cli:1`)
- `act` (GitHub Actions local runner)
- `actionlint` (GitHub Actions workflow linter)
- `ast-grep` + `sg` binaries (structural code search / rewriting)
- `neovim` (apt)
- `gh` (GitHub CLI for PRs/issues/releases)
- `lazygit` (terminal UI for advanced git workflows)

Modern Terminal UX:
- `zsh` (default) + `starship` prompt
- Terminal multiplexers: `tmux`, `zellij` (zellij fetched from GitHub release for amd64/arm64)
- Smart directory jumper: `zoxide`
- `eza` (ls replacement), `fzf`, `bat`, `ripgrep (rg)`, `fd`, `jq`

Other Tools / Helpers:
- `git` (up-to-date; may be source-built by base)
- `curl`, `wget`, `unzip`, `ca-certificates` (bundled / apt)

### Why include both `ast-grep` and `sg`?
Some distributions provide a smaller `sg` wrapper binary. The image installs **both** to ensure parity with official docs and avoid unexpected tool differences.

---

## ⚡ Shell Aliases
Convenience aliases injected into the default `zsh` environment (see Dockerfile). Use `which <name>` or `type <name>` to inspect. All are simple wrappers; adjust or extend in your own dotfiles as needed.

File / Directory Listing:
- `ls` → `eza --icons`
- `ll` → `eza -l --icons`
- `la` → `eza -la --icons`

TypeScript / Node Workflow:
- `tsc` → `npx tsc` (ensures local project version if present)
- `tsx` → `npx tsx`
- `tsw` → `npx tsc-watch`
- `dev` → `npm run dev`
- `build` → `npm run build`
- `test` → `npm test`
- `lint` → `npm run lint`
- `format` → `npm run format`

Notes:
- Aliases prefer project-local binaries via `npx` when applicable.
- Safe to override in your own `.zshrc` or extend with additional project automation.

---

## 📦 Example devcontainer.json
```jsonc
{
  "name": "get2know.io devcontainer",
  "image": "ghcr.io/get2knowio/devcontainer:latest",
  "remoteUser": "vscode",
  "features": {},
//   "postCreateCommand": "npm install",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint"
      ]
    }
  },
  "initializeCommand": "docker pull ghcr.io/get2knowio/devcontainer:latest"
}
```

---

## 🚀 Quick Interactive Dev Container Shell

An example helper script is provided at `examples/devcontainer-enter.sh` to drop you into an interactive `zsh` inside a Dev Container for the current directory.

Usage:
```
./examples/devcontainer-enter.sh [id]
```
Where:
- `id` (optional) adds a label `devcontainer-example.id=<id>` so multiple sessions can coexist or be targeted.

Behavior:
- If a matching container is running (workspace + optional id) it just opens `zsh`.
- If a stopped matching container exists, it starts it, then opens `zsh`.
- If none exists, it performs `devcontainer up` to create one.
- On shell exit: if the script created the container this session, it stops (does not remove) the container for fast reuse; otherwise leaves it as-is.

Requirements:
- `devcontainer` CLI on PATH
- Docker daemon available
- `.devcontainer/` directory present in the workspace

This offers a repeatable "jump in / jump out" workflow that preserves the container (stopped) for rapid restart while avoiding resource use when idle.

---

## 📚 Further Reading / Contributing
Looking for build internals, CI, migration history, troubleshooting, or how to extend the image? See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## 📄 License
See LICENSE file.
