#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/.gitconfig"
TARGET_FILE="$HOME/.gitconfig"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Template file not found: $SOURCE_FILE"
    exit 1
fi

cp "$SOURCE_FILE" "$TARGET_FILE"

echo "Installed gitconfig to $TARGET_FILE"
