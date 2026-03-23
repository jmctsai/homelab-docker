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
: "${NFS_MOUNTS:?NFS_MOUNTS is not set in .env}"

# Ensure NFS client exists
if ! dpkg -s nfs-common >/dev/null 2>&1; then
    echo "Installing nfs-common..."
    sudo apt update && sudo apt install -y nfs-common
fi

mount_one() {
    local entry="$1"
    EXPORT="${entry%%:*}"
    MOUNTPOINT="${entry##*:}"

    echo "→ Mounting $EXPORT → $MOUNTPOINT"
    sudo mkdir -p "$MOUNTPOINT"

    sudo mount -t nfs "$NFS_SERVER:$EXPORT" "$MOUNTPOINT" \
        -o "${NFS_OPTIONS:-defaults}"

    echo "  Mounted at $MOUNTPOINT"
}

unmount_one() {
    local entry="$1"
    MOUNTPOINT="${entry##*:}"

    if mount | grep -q "on $MOUNTPOINT "; then
        echo "→ Unmounting $MOUNTPOINT"
        sudo umount "$MOUNTPOINT" || sudo umount -l "$MOUNTPOINT"
    else
        echo "→ $MOUNTPOINT is not mounted"
    fi
}

mount_all() {
    echo "Mounting all NFS volumes from $NFS_SERVER..."
    for entry in "${NFS_MOUNTS[@]}"; do
        mount_one "$entry"
    done
    echo "All NFS mounts completed."
}

unmount_all() {
    echo "Unmounting all NFS volumes from $NFS_SERVER..."
    for entry in "${NFS_MOUNTS[@]}"; do
        unmount_one "$entry"
    done
}

remount_all() {
    echo "Remounting all NFS volumes..."
    unmount_all
    mount_all
}

list_mounts() {
    echo "Mounted NFS volumes from $NFS_SERVER:"
    mount | grep "$NFS_SERVER" || echo "None mounted"
}

# -------------------------------
# Interactive Menu
# -------------------------------
while true; do
    echo
    echo "=== NFS Manager ($NFS_SERVER) ==="
    echo "1) Mount ALL"
    echo "2) Unmount ALL"
    echo "3) Remount ALL"
    echo "4) List mounted"
    echo "5) Mount single"
    echo "6) Unmount single"
    echo "q) Quit"
    echo -n "Choose an option: "
    read choice

    case "$choice" in
        1) mount_all ;;
        2) unmount_all ;;
        3) remount_all ;;
        4) list_mounts ;;
        5)
            echo "Select a mount to mount:"
            index=1
            for entry in "${NFS_MOUNTS[@]}"; do
                echo "  $index) ${entry%%:*} → ${entry##*:}"
                index=$((index+1))
            done
            read -p "Enter number: " sel
            mount_one "${NFS_MOUNTS[$((sel-1))]}"
            ;;
        6)
            echo "Select a mount to unmount:"
            index=1
            for entry in "${NFS_MOUNTS[@]}"; do
                echo "  $index) ${entry##*:}"
                index=$((index+1))
            done
            read -p "Enter number: " sel
            unmount_one "${NFS_MOUNTS[$((sel-1))]}"
            ;;
        q)
            echo "Goodbye"
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
