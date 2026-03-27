#!/bin/bash

echo "Now Updating all Docker Containers"
export TZ=America/Vancouver

# --- Dependency Auto‑Install ------------------------------------------------

APT_UPDATED=0

ensure_pkg() {
    local pkg="$1"
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        if [ "$APT_UPDATED" -eq 0 ]; then
            apt update -y
            APT_UPDATED=1
        fi
        apt install -y "$pkg"
    fi
}

# Required packages
ensure_pkg jq

# --- Prechecks --------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker still not available after install."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "Error: docker compose still not available after install."
    exit 1
fi

JQ_AVAILABLE=1

# --- Timestamp for restart detection ----------------------------------------

printf -v start_date_epoch '%(%s)T'
printf -v start_date_iso8601 '%(%Y-%m-%dT%H:%M:%S+00:00)T' "$start_date_epoch"

# --- Locate repo root by searching upward for "services" directory ----------

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

# --- Discover compose.yaml services ----------------------------------------

mapfile -t compose_dirs < <(
    find "$SERVICES_DIR" \
        -maxdepth 1 -mindepth 1 -type d \
        -not -name '.*' \
        -exec test -f "{}/compose.yaml" \; \
        -print
)

# --- Update each service ----------------------------------------------------

for dir in "${compose_dirs[@]}"; do
    service_name=$(basename "$dir")
    echo "Now Updating $service_name"

    (
        cd "$dir" || exit
        docker compose pull
        docker compose up -d --no-recreate
    )
done

# --- Detect restarted containers --------------------------------------------

while IFS= read -r -d '' name; do
    names+=( "$name" )
done < <(
    docker container ls --format="{{.Names}}" \
    | xargs -n1 docker container inspect \
    | jq -j --arg start_date "$start_date_iso8601" \
        '.[] | select(.State.StartedAt > $start_date) | (.Name, "\u0000")'
)

echo "Updated these containers:"
printf '%s\n' "${names[@]}"

# --- Reboot notice ----------------------------------------------------------

if [ -f /var/run/reboot-required ]; then
    echo "[*** Hello $USER, you must reboot your machine ***]"
fi
