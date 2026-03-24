#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Load .env
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
else
    echo "Missing env file: $ENV_FILE"
    exit 1
fi

# Ensure clients exist
dpkg -s nfs-common >/dev/null 2>&1 || sudo apt install -y nfs-common
dpkg -s cifs-utils >/dev/null 2>&1 || sudo apt install -y cifs-utils

# -------------------------
# Helper functions
# -------------------------

list_mounts() {
    echo "=== NFS Mounts ==="
    for entry in "${NFS_MOUNTS[@]}"; do
        local mountpoint="${entry##*:}"
        mount | grep -E "on ${mountpoint} type nfs" || echo "Not mounted: $mountpoint"
    done

    echo ""
    echo "=== CIFS Mounts ==="
    for entry in "${CIFS_MOUNTS[@]}"; do
        local mountpoint="${entry##*:}"
        mount | grep -E "on ${mountpoint} type cifs" || echo "Not mounted: $mountpoint"
    done
}

unmount_all() {
    echo "=== Unmounting NFS ==="
    for entry in "${NFS_MOUNTS[@]}"; do
        local mountpoint="${entry##*:}"
        if mountpoint -q "$mountpoint"; then
            echo "→ Unmounting $mountpoint"
            sudo umount "$mountpoint"
        else
            echo "→ Not mounted: $mountpoint"
        fi
    done

    echo ""
    echo "=== Unmounting CIFS ==="
    for entry in "${CIFS_MOUNTS[@]}"; do
        local mountpoint="${entry##*:}"
        if mountpoint -q "$mountpoint"; then
            echo "→ Unmounting $mountpoint"
            sudo umount "$mountpoint"
        else
            echo "→ Not mounted: $mountpoint"
        fi
    done
}

add_nfs_entry() {
    local entry="$1"
    local export="${entry%%:*}"
    local mountpoint="${entry##*:}"

    sudo mkdir -p "$mountpoint"

    local line="$NFS_SERVER:$export $mountpoint nfs ${NFS_OPTIONS:-defaults} 0 0"

    if grep -qs "^$NFS_SERVER:$export[[:space:]]" /etc/fstab; then
        echo "→ NFS already in fstab: $export"
    else
        echo "→ Adding NFS: $export → $mountpoint"
        echo "$line" | sudo tee -a /etc/fstab >/dev/null
    fi
}

add_cifs_entry() {
    local entry="$1"
    local share="${entry%%:*}"
    local mountpoint="${entry##*:}"

    sudo mkdir -p "$mountpoint"

    local line="//$CIFS_SERVER/$share $mountpoint cifs username=$CIFS_USERNAME,password=$CIFS_PASSWORD,${CIFS_OPTIONS} 0 0"

    if grep -qs "^//$CIFS_SERVER/$share[[:space:]]" /etc/fstab; then
        echo "→ CIFS already in fstab: $share"
    else
        echo "→ Adding CIFS: $share → $mountpoint"
        echo "$line" | sudo tee -a /etc/fstab >/dev/null
    fi
}

mount_all() {
    echo "=== Configuring NFS mounts ==="
    for entry in "${NFS_MOUNTS[@]}"; do
        add_nfs_entry "$entry"
    done

    echo ""
    echo "=== Configuring CIFS mounts ==="
    for entry in "${CIFS_MOUNTS[@]}"; do
        add_cifs_entry "$entry"
    done

    echo ""
    echo "Running mount -a..."
    sudo mount -a
}

# -------------------------
# Interactive Menu
# -------------------------

echo ""
echo "Select an option:"
echo "1) Mount all"
echo "2) Unmount all"
echo "3) List mounts"
echo "4) Remount"
echo ""

read -rp "Enter choice: " choice

case "$choice" in
    1)
        mount_all
        ;;
    2)
        unmount_all
        ;;
    3)
        list_mounts
        ;;
    4)
        unmount_all
        mount_all
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
