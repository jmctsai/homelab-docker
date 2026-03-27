#!/bin/bash

# --- Locate repo root by searching upward for "services" directory -----------

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SEARCH_DIR="$SCRIPT_DIR"

while [ "$SEARCH_DIR" != "/" ]; do
    if [ -d "$SEARCH_DIR/services" ]; then
        BASE_DIR="$SEARCH_DIR"
        break
    fi
    SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [ -z "$BASE_DIR" ]; then
    echo "Error: Could not locate 'services' directory above script location."
    exit 1
fi

SERVICES_DIR="$BASE_DIR/services"

echo "Using services directory: $SERVICES_DIR"
echo "Starting all active services..."

# --- Discover active compose.yaml services ----------------------------------

mapfile -t compose_dirs < <(
    find "$SERVICES_DIR" \
        -maxdepth 1 -mindepth 1 -type d \
        -not -name '.*' \
        -exec test -f "{}/compose.yaml" \; \
        -print
)

# --- Start each service ------------------------------------------------------

for dir in "${compose_dirs[@]}"; do
    service_name=$(basename "$dir")
    echo "Starting $service_name"

    (
        cd "$dir" || exit
        docker compose up -d
    )
done

echo "All active services started."
