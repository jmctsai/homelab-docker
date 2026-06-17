# Start all services in a group, or a specific app
[group('services')]
up group app="":
    #!/usr/bin/env bash
    if [[ -n "{{app}}" ]]; then
        (cd {{SERVICES_DIR}}/{{group}}/{{app}} && docker compose up -d)
    else
        for d in {{SERVICES_DIR}}/{{group}}/*/; do
            echo "==> Starting $d"
            (cd "$d" && docker compose up -d)
        done
    fi

# Stop all services in a group, or a specific app
[group('services')]
down group app="":
    #!/usr/bin/env bash
    if [[ -n "{{app}}" ]]; then
        (cd {{SERVICES_DIR}}/{{group}}/{{app}} && docker compose down)
    else
        for d in {{SERVICES_DIR}}/{{group}}/*/; do
            echo "==> Stopping $d"
            (cd "$d" && docker compose down)
        done
    fi

# Restart all services in a group, or a specific app
[group('services')]
restart group app="":
    just down {{group}} {{app}}
    just up {{group}} {{app}}

# Update a group or specific app (pull + restart)
[group('services')]
update group app="":
    just pull {{group}} {{app}}
    just restart {{group}} {{app}}

# Pull latest images for a group or specific app
[group('services')]
pull group app="":
    #!/usr/bin/env bash
    if [[ -n "{{app}}" ]]; then
        (cd {{SERVICES_DIR}}/{{group}}/{{app}} && docker compose pull)
    else
        for d in {{SERVICES_DIR}}/{{group}}/*/; do
            echo "==> Pulling $d"
            (cd "$d" && docker compose pull)
        done
    fi

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