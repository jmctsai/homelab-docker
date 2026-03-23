#!/usr/bin/env bash

set -e

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Load .env file
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
else
    echo "Missing env file: $ENV_FILE"
    exit 1
fi

# Required variables
: "${NFS_SERVER:?NFS_SERVER is not set in .env}"
: "${NFS_EXPORT:?NFS_EXPORT is not set in .env}"
: "${NFS_MOUNTPOINT:?NFS_MOUNTPOINT is not set in .env}"

# Ensure NFS client exists
if ! dpkg -s nfs-common >/dev/null 2>&1; then
    echo "Installing nfs-common..."
    sudo apt update && sudo apt install -y nfs-common
fi

# Create mountpoint if missing
sudo mkdir -p "$NFS_MOUNTPOINT"

# Mount
echo "Mounting NFS share..."
sudo mount -t nfs "$NFS_SERVER:$NFS_EXPORT" "$NFS_MOUNTPOINT" -o "${NFS_OPTIONS:-defaults}"

echo "Mounted at $NFS_MOUNTPOINT"
