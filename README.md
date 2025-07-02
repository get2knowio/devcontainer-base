# devcontainer-base

This repository provides a base Docker image for use with Visual Studio Code's Dev Containers feature. The image is designed to simplify the setup of development environments by providing a pre-configured container with essential tools and dependencies.

## Features
- Built on the official Microsoft Dev Containers base image for stability and compatibility.
- Ready-to-use Python development environment.
- Pre-configured non-root user (`vscode`) with sudo access.
- Supports Visual Studio Code customizations (extensions, settings, etc.).
- Multi-platform compatibility (linux/amd64, linux/arm64).
- Simplifies dependency management with Poetry.

## How to Use
To leverage this base image in your own project, you can create a `.devcontainer` configuration in your repository. Below is an example configuration:

### Sample `.devcontainer/devcontainer.json`
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

## User Expectations
- **Docker Installed**: Ensure Docker is installed and running on your machine.
- **VS Code Dev Containers Extension**: Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) in Visual Studio Code.
- **Poetry**: This image assumes that you are using [Poetry](https://python-poetry.org/) for dependency management. Ensure your project is configured with a `pyproject.toml` file.

## Local Testing
To test the image locally before pushing changes, you can use the provided test script:

```bash
./test.sh
```

This script will:
- Build the Docker image locally
- Run a series of tests to verify the image works correctly
- Check that all essential tools and dependencies are properly installed

## Build and Push Workflow
This repository includes a GitHub Actions workflow (`.github/workflows/docker-build-push.yml`) to automatically build and push the Docker image to GHCR on changes to the `main` or `develop` branches, or when a new tag is created.
