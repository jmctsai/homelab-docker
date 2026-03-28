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

# --- Validate arguments ------------------------------------------------------

ACTION="$1"
CATEGORY="$2"

if [[ -z "$ACTION" || -z "$CATEGORY" ]]; then
    echo "Usage: $0 <start|stop|restart|update> <category|all>"
    exit 1
fi

# Normalize category (lowercase, remove trailing dash)
CATEGORY=$(echo "$CATEGORY" | tr '[:upper:]' '[:lower:]')
CATEGORY="${CATEGORY%-}"

# --- Handle "all" category ---------------------------------------------------

if [[ "$CATEGORY" == "all" ]]; then
    echo "Action: $ACTION"
    echo "Category: all (all services)"
    echo "Using services directory: $SERVICES_DIR"

    mapfile -t compose_dirs < <(
        find "$SERVICES_DIR" \
            -maxdepth 1 -mindepth 1 -type d \
            -exec test -f "{}/compose.yaml" \; \
            -print
    )

    if [ ${#compose_dirs[@]} -eq 0 ]; then
        echo "No services found."
        exit 0
    fi

    for dir in "${compose_dirs[@]}"; do
        service_name=$(basename "$dir")
        echo "$ACTION $service_name"

        (
            cd "$dir" || exit
            case "$ACTION" in
                start)   docker compose up -d ;;
                stop)    docker compose down ;;
                restart) docker compose down && docker compose up -d ;;
                update)  docker compose pull && docker compose up -d ;;
            esac
        )
    done

    echo "Completed: $ACTION for ALL services"
    exit 0
fi

# --- Auto-detect valid categories -------------------------------------------

mapfile -t VALID_CATEGORIES < <(
    find "$SERVICES_DIR" -maxdepth 1 -mindepth 1 -type d \
    -printf "%f\n" | cut -d'-' -f1 | sort -u
)

# Check if category is valid
if [[ ! " ${VALID_CATEGORIES[*]} " =~ " ${CATEGORY} " ]]; then
    echo "Invalid category: $CATEGORY"
    echo "Valid categories are: ${VALID_CATEGORIES[*]}"
    exit 1
fi

PREFIX="${CATEGORY}-"

echo "Action: $ACTION"
echo "Category: $CATEGORY"
echo "Prefix: $PREFIX"
echo "Detected categories: ${VALID_CATEGORIES[*]}"
echo "Using services directory: $SERVICES_DIR"

# --- Discover matching services ---------------------------------------------

mapfile -t compose_dirs < <(
    find "$SERVICES_DIR" \
        -maxdepth 1 -mindepth 1 -type d \
        -name "${PREFIX}*" \
        -exec test -f "{}/compose.yaml" \; \
        -print
)

if [ ${#compose_dirs[@]} -eq 0 ]; then
    echo "No services found for category: $CATEGORY"
    exit 0
fi

# --- Execute action ----------------------------------------------------------

for dir in "${compose_dirs[@]}"; do
    service_name=$(basename "$dir")
    echo "$ACTION $service_name"

    (
        cd "$dir" || exit
        case "$ACTION" in
            start)   docker compose up -d ;;
            stop)    docker compose down ;;
            restart) docker compose down && docker compose up -d ;;
            update)  docker compose pull && docker compose up -d ;;
        esac
    )
done

echo "Completed: $ACTION for category '$CATEGORY'"
