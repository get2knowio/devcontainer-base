#!/bin/bash
# Convenience wrapper for scripts/build.sh
exec "$(dirname "$0")/scripts/build.sh" "$@"
