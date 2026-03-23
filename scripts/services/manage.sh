#!/usr/bin/env bash

set -e

BASE_DIR="$HOME/homelab-docker"
LOG_FILE="$BASE_DIR/manage.log"

# Max log size before rotation (1 MB)
MAX_LOG_SIZE=1048576

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Ensure base directory exists
mkdir -p "$BASE_DIR"

# -------------------------------
# Log rotation
# -------------------------------
rotate_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        size=$(stat -c%s "$LOG_FILE")
        if (( size > MAX_LOG_SIZE )); then
            mv "$LOG_FILE" "$LOG_FILE.$(date +%Y%m%d-%H%M%S)"
            touch "$LOG_FILE"
            echo "Rotated manage.log" >> "$LOG_FILE"
        fi
    fi
}

log() {
    rotate_logs
    echo -e "$1" | tee -a "$LOG_FILE"
}

# -------------------------------
# List valid service categories
# -------------------------------
get_categories() {
    for category in "$BASE_DIR"/*; do
        [ -d "$category" ] || continue

        name="$(basename "$category")"

        # Skip hidden folders
        [[ "$name" == .* ]] && continue

        # Skip non-service folders
        case "$name" in
            scripts|docs|config|.git|.vscode)
                continue
                ;;
        esac

        # Only include if it contains at least one docker-compose.yml
        if find "$category" -maxdepth 2 -name "docker-compose.yml" | grep -q .; then
            echo "$name"
        fi
    done
}

# -------------------------------
# List apps inside a category
# -------------------------------
get_apps() {
    local CATEGORY_DIR="$BASE_DIR/$1"

    for app_dir in "$CATEGORY_DIR"/*; do
        [ -d "$app_dir" ] || continue

        app_name="$(basename "$app_dir")"

        # Skip disabled/hidden apps
        [[ "$app_name" == .* ]] && continue

        # Must contain docker-compose.yml
        if [[ -f "$app_dir/docker-compose.yml" ]]; then
            echo "$app_name"
        fi
    done
}

# -------------------------------
# Run action on a single app
# -------------------------------
run_action_on_app() {
    local CATEGORY="$1"
    local APP="$2"
    local ACTION="$3"

    local APP_DIR="$BASE_DIR/$CATEGORY/$APP"
    local COMPOSE="$APP_DIR/docker-compose.yml"

    log "  ${BLUE}Processing: $APP${RESET}"

    case "$ACTION" in
        start)
            (cd "$APP_DIR" && docker compose up -d)
            ;;
        stop)
            (cd "$APP_DIR" && docker compose down)
            ;;
        restart)
            (cd "$APP_DIR" && docker compose down && docker compose up -d)
            ;;
        update)
            (cd "$APP_DIR" && docker compose pull && docker compose up -d)
            ;;
        status)
            running=$(docker compose -f "$COMPOSE" ps --services --filter "status=running" | wc -l)
            total=$(docker compose -f "$COMPOSE" ps --services | wc -l)

            if (( running > 0 )); then
                log "  ${GREEN}$APP: $running/$total Running${RESET}"
            else
                log "  ${RED}$APP: Stopped${RESET}"
            fi
            ;;
    esac

    log "  ${GREEN}Done: $APP${RESET}"
}

# -------------------------------
# Run action on ALL or ONE app
# -------------------------------
run_action() {
    local CATEGORY="$1"
    local ACTION="$2"
    local APP="$3"   # may be "ALL"

    log "${CYAN}== Running '$ACTION' on Category: $CATEGORY ==${RESET}"

    if [[ "$APP" == "ALL" ]]; then
        apps=($(get_apps "$CATEGORY"))
        for app in "${apps[@]}"; do
            run_action_on_app "$CATEGORY" "$app" "$ACTION"
        done
    else
        run_action_on_app "$CATEGORY" "$APP" "$ACTION"
    fi

    log "${CYAN}Action '$ACTION' Completed.${RESET}"
    echo
}

# -------------------------------
# Interactive Menu
# -------------------------------
while true; do
    echo -e "${BLUE}Select a Service Category:${RESET}"
    echo

    categories=($(get_categories))
    index=1

    for cat in "${categories[@]}"; do
        echo "  $index) $cat"
        index=$((index + 1))
    done

    echo "  q) Quit"
    echo -n "Enter Choice: "
    read cat_choice

    if [[ "$cat_choice" == "q" ]]; then
        echo "Goodbye"
        exit 0
    fi

    if ! [[ "$cat_choice" =~ ^[0-9]+$ ]] || (( cat_choice < 1 || cat_choice > ${#categories[@]} )); then
        echo -e "${RED}Invalid Category Selection.${RESET}"
        echo
        continue
    fi

    CATEGORY="${categories[$((cat_choice - 1))]}"

    echo
    echo -e "${CYAN}Selected Category: $CATEGORY${RESET}"
    echo

    # -------------------------------
    # App Selection
    # -------------------------------
    apps=($(get_apps "$CATEGORY"))
    echo "Select an App:"
    index=1

    for app in "${apps[@]}"; do
        echo "  $index) $app"
        index=$((index + 1))
    done

    echo "  a) All Apps"
    echo "  b) Back"
    echo -n "Enter Choice: "
    read app_choice

    if [[ "$app_choice" == "b" ]]; then
        continue
    elif [[ "$app_choice" == "a" ]]; then
        APP="ALL"
    elif [[ "$app_choice" =~ ^[0-9]+$ ]] && (( app_choice >= 1 && app_choice <= ${#apps[@]} )); then
        APP="${apps[$((app_choice - 1))]}"
    else
        echo -e "${RED}Invalid App Selection.${RESET}"
        echo
        continue
    fi

    # -------------------------------
    # Action Selection
    # -------------------------------
    echo
    echo "Select an Action:"
    echo "  1) Start"
    echo "  2) Stop"
    echo "  3) Restart"
    echo "  4) Update (Pull + Up -d)"
    echo "  5) Status"
    echo "  b) Back"
    echo -n "Enter Choice: "
    read action_choice

    case "$action_choice" in
        1) run_action "$CATEGORY" start "$APP" ;;
        2) run_action "$CATEGORY" stop "$APP" ;;
        3) run_action "$CATEGORY" restart "$APP" ;;
        4) run_action "$CATEGORY" update "$APP" ;;
        5) run_action "$CATEGORY" status "$APP" ;;
        b) continue ;;
        *) echo -e "${RED}Invalid Action.${RESET}"; echo ;;
    esac

    echo
done
