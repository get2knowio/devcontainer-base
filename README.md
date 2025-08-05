# devcontainer-base

This repository provides base Docker images for use with Visual Studio Code's Dev Containers feature. The images are designed to simplify the setup of development environments by providing pre-configured containers with essential tools and dependencies for different development stacks.

## Available Images

### Python Development Environment
- **Image**: `ghcr.io/get2knowio/devcontainer-python-base:latest`
- **Focus**: Python development with modern tooling
- **Key Tools**: Python 3.12, Poetry, pip, AWS CLI, AI development tools

### TypeScript/Node.js Development Environment  
- **Image**: `ghcr.io/get2knowio/devcontainer-typescript-base:latest`
- **Focus**: TypeScript/JavaScript development with modern runtime
- **Key Tools**: Node.js LTS, Bun, TypeScript, npm/yarn/pnpm, AWS CLI, AI development tools

## Common Features
- Built on the official Microsoft Dev Containers base image for stability and compatibility.
- Pre-configured non-root user (`vscode`) with sudo access.
- Supports Visual Studio Code customizations (extensions, settings, etc.).
- Multi-platform compatibility (linux/amd64, linux/arm64).
- Modern CLI tools (eza, fzf, bat, ripgrep, fd, jq).
- Starship prompt for enhanced shell experience.
- AWS CLI v2 for cloud development.
- AI-powered development tools (Gemini CLI, Claude Code).

## How to Use
To leverage these base images in your own project, you can create a `.devcontainer` configuration in your repository. Below are example configurations for each image:

### Python Development Container
```json
{
  "name": "Python Dev Container",
  "image": "ghcr.io/get2knowio/devcontainer-python-base:latest",
  "remoteUser": "vscode",
  "features": {},
  "postCreateCommand": "poetry install",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  }
}
```

### TypeScript/Node.js Development Container
```json
{
  "name": "TypeScript Dev Container",
  "image": "ghcr.io/get2knowio/devcontainer-typescript-base:latest",
  "remoteUser": "vscode",
  "features": {},
  "postCreateCommand": "npm install",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint"
      ]
    }
  }
}
```

## User Expectations
- **Docker Installed**: Ensure Docker is installed and running on your machine.
- **VS Code Dev Containers Extension**: Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) in Visual Studio Code.

### For Python Development
- **Poetry**: The Python image assumes you are using [Poetry](https://python-poetry.org/) for dependency management. Ensure your project is configured with a `pyproject.toml` file.

### For TypeScript Development  
- **Package Manager**: The TypeScript image supports npm, yarn, pnpm, and Bun. Choose your preferred package manager and ensure your project has the appropriate configuration file (`package.json`, `yarn.lock`, `pnpm-lock.yaml`, etc.).

## Local Testing
To test the images locally before pushing changes, you can use the provided test script:

```bash
# Test the Python image
./test.sh ghcr.io/get2knowio/devcontainer-python-base:latest

# Test the TypeScript image  
./test.sh ghcr.io/get2knowio/devcontainer-typescript-base:latest
```

This script will:
- Build the Docker image locally (if needed)
- Run a series of tests to verify the image works correctly
- Check that all essential tools and dependencies are properly installed

## Build and Push Workflow
This repository includes a GitHub Actions workflow (`.github/workflows/docker-build-push.yml`) to automatically build and push both Docker images to GHCR on changes to the `main` or `develop` branches, or when a new tag is created. The workflow uses a matrix strategy to build both Python and TypeScript variants in parallel.
