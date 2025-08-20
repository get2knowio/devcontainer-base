# Local GitHub Actions Testing with Act

This project includes [act](https://github.com/nektos/act) for running GitHub Actions workflows locally during development and testing.

## Installation

Run the installation script:

```bash
./install-act
```

This will download and install act to `/usr/local/bin/act`.

## Usage

### List Available Workflows
```bash
act -l
```

### Run Specific Jobs
```bash
# Run the build-common job (builds the base DevContainer image)
act -j build-common

# Run with environment variables
act -j build-common --env CI=true

# Run with custom secrets (create a .secrets file first)
act -j build-common --secret-file .secrets
```

### Test Full Workflow
```bash
# Run all jobs in the workflow (may take a long time)
act push

# Run with dry-run to see what would execute
act -n push
```

### Debug Mode
```bash
# Run with verbose output for debugging
act -v -j build-common

# Reuse containers to maintain state between runs
act -r -j build-common
```

## Configuration

The project includes a `.actrc` file with platform configurations to use appropriate container images.

## Secrets

For jobs that require secrets (like container registry authentication), create a `.secrets` file:

```bash
# .secrets (don't commit this file!)
GITHUB_TOKEN=your_github_token_here
```

## Limitations

- Some GitHub-specific features may not work exactly the same locally
- Multi-architecture builds (`linux/amd64,linux/arm64`) may not work on all local systems
- Registry push operations will fail without proper authentication
- Act uses Docker-in-Docker, so performance may be slower than GitHub Actions

## Useful Commands

```bash
# Test just the DevContainer build step to debug SSL issues
act -j build-common --env CI=true

# See what containers are running
docker ps

# Clean up after failed runs
docker system prune
```

## Benefits

- **Fast Feedback**: Test workflow changes without pushing to GitHub
- **Debug Locally**: Use verbose mode and local debugging tools
- **Cost Savings**: Avoid using GitHub Actions minutes during development
- **Offline Development**: Work on workflows without internet connectivity (after initial setup)

## Integration with DevContainer

Since this project uses DevContainers and act requires Docker, act works well within this DevContainer environment where Docker-outside-of-Docker is already configured.
