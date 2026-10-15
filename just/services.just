# Keep your existing SERVICES_DIR definition at the top of the file, e.g.:
# SERVICES_DIR := "/path/to/services"

# Start all services in a group, or a specific app
[group('services')]
up group app="":
    #!/usr/bin/env bash
    shopt -s nullglob
    if [[ -n "{{app}}" ]]; then
        dirs=("{{SERVICES_DIR}}/{{group}}/{{app}}")
    else
        dirs=({{SERVICES_DIR}}/{{group}}/*/)
    fi
    for d in "${dirs[@]}"; do
        echo "==> Starting $d"
        (cd "$d" && docker compose up -d) || echo "!! Failed: $d"
    done

# Stop all services in a group, or a specific app
[group('services')]
down group app="":
    #!/usr/bin/env bash
    shopt -s nullglob
    if [[ -n "{{app}}" ]]; then
        dirs=("{{SERVICES_DIR}}/{{group}}/{{app}}")
    else
        dirs=({{SERVICES_DIR}}/{{group}}/*/)
    fi
    for d in "${dirs[@]}"; do
        echo "==> Stopping $d"
        (cd "$d" && docker compose down) || echo "!! Failed: $d"
    done

# Restart a group or specific app (down, then up, one app at a time)
[group('services')]
restart group app="":
    #!/usr/bin/env bash
    shopt -s nullglob
    if [[ -n "{{app}}" ]]; then
        dirs=("{{SERVICES_DIR}}/{{group}}/{{app}}")
    else
        dirs=({{SERVICES_DIR}}/{{group}}/*/)
    fi
    for d in "${dirs[@]}"; do
        echo "==> Restarting $d"
        (cd "$d" && docker compose down && docker compose up -d) || echo "!! Failed: $d"
    done

# Update a group or specific app (pull, then recreate only what changed, one app at a time)
[group('services')]
update group app="":
    #!/usr/bin/env bash
    shopt -s nullglob
    if [[ -n "{{app}}" ]]; then
        dirs=("{{SERVICES_DIR}}/{{group}}/{{app}}")
    else
        dirs=({{SERVICES_DIR}}/{{group}}/*/)
    fi
    for d in "${dirs[@]}"; do
        echo "==> Updating $d"
        (cd "$d" && docker compose pull && docker compose up -d --remove-orphans) || echo "!! Failed: $d"
    done

# Pull latest images for a group or specific app (no restart)
[group('services')]
pull group app="":
    #!/usr/bin/env bash
    shopt -s nullglob
    if [[ -n "{{app}}" ]]; then
        dirs=("{{SERVICES_DIR}}/{{group}}/{{app}}")
    else
        dirs=({{SERVICES_DIR}}/{{group}}/*/)
    fi
    for d in "${dirs[@]}"; do
        echo "==> Pulling $d"
        (cd "$d" && docker compose pull) || echo "!! Failed: $d"
    done

# Show containers (just status / just status all)
[group('docker')]
status all="":
    #!/usr/bin/env bash
    if [[ -n "{{all}}" ]]; then
        docker ps -a --format 'table {{{{.Names}}\t{{{{.Status}}\t{{{{.Ports}}'
    else
        docker ps --format 'table {{{{.Names}}\t{{{{.Status}}\t{{{{.Ports}}'
    fi

# Show logs for a specific app
[group('docker')]
logs app:
    #!/usr/bin/env bash
    match=$(find {{SERVICES_DIR}} -maxdepth 2 -mindepth 2 -type d -name "*{{app}}*")
    if [[ -z "$match" ]]; then
        echo "App '{{app}}' not found"
        exit 1
    fi
    count=$(echo "$match" | wc -l)
    if [[ "$count" -gt 1 ]]; then
        echo "Multiple matches:"
        echo "$match"
        exit 1
    fi
    (cd "$match" && docker compose logs -f)

# Remove dangling images left behind by updates
[group('docker')]
prune:
    docker image prune -af
