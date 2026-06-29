# PC-Free

Run Windows in Docker with the `dockur/windows` project layout.

This repository now contains only the Compose configuration and helper scripts needed to start the Windows container.

## Files

- `windows10.yml` - Docker Compose configuration
- `.env.example` - Example environment file
- `scripts/pc-free.sh` - Helper script for setup and lifecycle commands
- `scripts/README.zh-CN.md` - Chinese script usage notes

## Quick Start

Generate `.env` and start the container:

```bash
bash scripts/pc-free.sh
```

The script asks for the Windows username and password, then auto-detects host RAM and CPU cores and writes them to `.env`.

Open forwarded port `8006` in the browser to access the Windows desktop.

## Manual Start

Create `.env`:

```bash
cp .env.example .env
```

Edit `.env`:

```ini
WINDOWS_USERNAME=pcfree
WINDOWS_PASSWORD=change-me
WINDOWS_STORAGE=./windows
RAM_SIZE=8G
CPU_CORES=4
```

Start:

```bash
docker compose -f windows10.yml up -d
```

## Configuration

`windows10.yml` uses the official Docker image published by `dockur/windows`:

```yaml
image: dockurr/windows
```

Persistent Windows data is stored through:

```yaml
volumes:
  - ${WINDOWS_STORAGE:-./windows}:/storage
```

The helper script writes these automatically:

```ini
RAM_SIZE=<detected host RAM>
CPU_CORES=<detected host CPU cores>
```

To force resource re-detection:

```bash
bash scripts/pc-free.sh config
```

To rebuild `.env` and `windows10.yml`:

```bash
bash scripts/pc-free.sh config --force
```

## Commands

```bash
bash scripts/pc-free.sh start
bash scripts/pc-free.sh stop
bash scripts/pc-free.sh restart
bash scripts/pc-free.sh logs
bash scripts/pc-free.sh status
bash scripts/pc-free.sh remove
```

`remove` deletes the Compose container and volumes after confirmation.

## Requirements

- Docker Engine with Docker Compose
- KVM support on Linux or a compatible Codespaces environment
- Enough disk space for the Windows image and persistent storage

## Notes

- The GitHub project is `dockur/windows`.
- The Docker image name is `dockurr/windows`.
- `.env` and `windows/` are ignored by git.
