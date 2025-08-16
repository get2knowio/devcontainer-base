#!/bin/bash

# Fix Docker socket permissions
if [ -S /var/run/docker.sock ]; then
    echo "Setting up Docker socket permissions..."
    
    # Get the group ID of the Docker socket
    gid="$(stat -c '%g' /var/run/docker.sock)"
    
    # Get or create the group name
    grp="$(getent group "$gid" | cut -d: -f1 || echo docker-host)"
    
    # Create the group if it doesn't exist
    sudo groupadd -f -g "$gid" "$grp"
    
    # Add current user to the group
    sudo usermod -aG "$grp" "$USER"
    
    echo "Docker socket permissions configured for group: $grp (gid: $gid)"
else
    echo "Docker socket not found at /var/run/docker.sock"
fi

# Execute the original command or default
exec "$@"