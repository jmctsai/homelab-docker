#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Ensure packages are installed
# -----------------------------
for pkg in nfs-common cifs-utils; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    else
        echo "OK: $pkg"
    fi
done


USER_HOME="${HOME:-/root}"
RC_FILE="$USER_HOME/.bashrc"
ALIASES_FILE="$USER_HOME/.aliases"

# -----------------------------
# Ensure alias file exists
# -----------------------------
if [[ ! -f "$ALIASES_FILE" ]]; then
    echo "# User aliases" > "$ALIASES_FILE"
fi

# -----------------------------
# Add or update alias (declarative)
# -----------------------------
set_alias() {
    local name="$1"
    local value="$2"

    if grep -qE "^alias ${name}=" "$ALIASES_FILE"; then
        # Replace only if different
        if ! grep -qE "^alias ${name}='${value//\//\\/}'" "$ALIASES_FILE"; then
            sed -i "s|^alias ${name}=.*|alias ${name}='${value}'|" "$ALIASES_FILE"
            echo "Updated alias: ${name}"
        fi
    else
        echo "alias ${name}='${value}'" >> "$ALIASES_FILE"
        echo "Added alias: ${name}"
    fi
}

# -----------------------------
# Your aliases
# -----------------------------
set_alias dcd    "docker compose down"
set_alias dcpull "docker compose pull"
set_alias dcu    "docker compose up -d"
set_alias dps    "docker ps"

# -----------------------------
# Ensure .bashrc sources aliases
# -----------------------------
if ! grep -qF "source ~/.aliases" "$RC_FILE"; then
    {
        echo ""
        echo "# Load user aliases"
        echo "source ~/.aliases"
    } >> "$RC_FILE"
    echo "Linked ~/.aliases into .bashrc"
fi

# -----------------------------
# Final message
# -----------------------------
echo "bashrc initialized, aliases applied, and filesystem clients verified."
echo "NOTE: To activate aliases in this shell, run:"
echo "  source ~/.bashrc"
