# homelab-docker

A collection of Docker-based services and helper scripts for managing a homelab environment.
Includes interactive tools for initializing git config, managing NFS mounts, and starting/stopping services for this repository.

---

## Using `.env.template`

Some scripts in this repository include a `.env.template` file.
This file contains example variables and serves as a starting point for your own configuration.

To use it, copy the template file:
```sh
cp .env.template .env
```

## Helper Scripts

### ⚙️ Initial Git Config Setup

Script to apply Git settings for this repository defined in `/scripts/gitconfig/.gitconfig`
```sh
chmod +x ~/homelab-docker/scripts/git/setup-gitconfig.sh
~/homelab-docker/scripts/git/setup-gitconfig.sh
```

### 📁 NFS Mount Manager

Interactive script to mount, unmount, remount, or list NFS shares defined in scripts `/scripts/nfs/.env`.
```sh
chmod +x ~/homelab-docker/scripts/nfs/setup.sh
~/homelab-docker/scripts/nfs/setup.sh
```

### 🧰 Service Manager

Interactive script to start, stop, restart, update, or check the status of Docker services using Docker Compose.
```sh
chmod +x ~/homelab-docker/scripts/services/manage.sh
~/homelab-docker/scripts/services/manage.sh
```