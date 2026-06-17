# homelab-docker

A collection of Docker-based services and helper scripts for managing a homelab environment.
Includes interactive tools for initializing git config, managing NFS mounts, and starting/stopping services for this repository.

---

## Initial Environment Setup

Before anything else, run the bootstrap script. This installs required packages (`nfs-common`, `cifs-utils`), installs [`just`](https://github.com/casey/just), and sets up shell aliases from `scripts/aliases.txt`.

```sh
chmod +x ~/homelab-docker/scripts/init_environment.sh
~/homelab-docker/scripts/init_environment.sh
```

> **Note:** This must be run directly as a script — it cannot be run via `just init` since `just` itself may not be installed yet (chicken/egg problem).

After it completes, activate the new aliases in your current shell:
```sh
source ~/.bashrc
```

### ⚙️ Initial Git Config Setup

Script to apply Git settings for this repository defined in `/scripts/gitconfig/.gitconfig`
```sh
chmod +x ~/homelab-docker/scripts/gitconfig/setup.sh
~/homelab-docker/scripts/gitconfig/setup.sh
```

### 📁 NFS Mount Manager

Interactive script to mount, unmount, remount, or list NFS shares defined in scripts `/scripts/nfs/.env`.
```sh
chmod +x ~/homelab-docker/scripts/nfs/mount.sh
~/homelab-docker/scripts/nfs/mount.sh
```

---

## Using `.env.template`

Some scripts in this repository include a `.env.template` file.
This file contains example variables and serves as a starting point for your own configuration.

To use it, copy the template file:
```sh
cp .env.template .env
```

## Using `just`

This repo includes a `justfile` for managing Docker services declaratively. Run `just` (or `just --list`) to see all available recipes, grouped by category.

```sh
just up arr              # start all services in the arr group
just up arr sonarr       # start a specific app
just down core           # stop all services in the core group
just restart arr radarr  # restart a specific app
just update arr          # pull latest images + restart for the arr group
just status              # show running containers
just status all          # show all containers, including stopped
just logs sonarr         # show logs for an app (searches all groups)
```
