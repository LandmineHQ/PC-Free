#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$PROJECT_DIR/windows10.yml"
ENV_FILE="$PROJECT_DIR/.env"
GITIGNORE_FILE="$PROJECT_DIR/.gitignore"
DOCKER_DATA_ROOT="${DOCKER_DATA_ROOT:-/tmp/docker-data}"
WINDOWS_STORAGE="${WINDOWS_STORAGE:-./windows}"
CONTAINER_NAME="${CONTAINER_NAME:-windows}"

FORCE=0
YES=0

log() {
  printf '[pc-free] %s\n' "$*"
}

warn() {
  printf '[pc-free] warning: %s\n' "$*" >&2
}

die() {
  printf '[pc-free] error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
PC-Free helper script

Usage:
  bash scripts/pc-free.sh [command] [options]

Default command:
  install        Generate config files and start Windows with dockur/windows

Commands:
  install        Run config + start
  storage        Optional: configure Docker daemon data-root
  config         Generate .env, .gitignore, and windows10.yml
  start          Start Windows container in the background
  stop           Stop Windows container
  restart        Restart Windows container
  logs           Follow Windows container logs
  status         Show Windows container status and Docker root
  remove         Remove container and Docker Compose volumes
  help           Show this help message

Options:
  --storage PATH     Host storage path mounted to /storage, default: ./windows
  --data-root PATH   Optional Docker daemon data-root path, default: /tmp/docker-data
  --force            Overwrite generated .env and windows10.yml
  -y, --yes          Skip confirmation prompts for destructive commands

Examples:
  bash scripts/pc-free.sh
  bash scripts/pc-free.sh install
  bash scripts/pc-free.sh start
  bash scripts/pc-free.sh logs
  bash scripts/pc-free.sh remove
EOF
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || die "sudo is required for this command"
    sudo "$@"
  fi
}

need_docker() {
  command -v docker >/dev/null 2>&1 || die "docker is not installed or not in PATH"
}

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    die "Docker Compose is not available. Install docker compose or docker-compose."
  fi
}

restart_docker() {
  log "Restarting Docker so data-root changes can take effect..."

  if command -v systemctl >/dev/null 2>&1 && as_root systemctl restart docker >/dev/null 2>&1; then
    return 0
  fi

  if command -v service >/dev/null 2>&1 && as_root service docker restart >/dev/null 2>&1; then
    return 0
  fi

  warn "Could not restart Docker automatically. Restart the Codespace or Docker service before starting Windows."
  return 0
}

write_daemon_json() {
  local daemon_dir="/etc/docker"
  local daemon_json="$daemon_dir/daemon.json"
  local current_json
  local tmp
  current_json="$(mktemp)"
  tmp="$(mktemp)"

  if [[ -f "$daemon_json" ]]; then
    if [[ -r "$daemon_json" ]]; then
      cp "$daemon_json" "$current_json"
    else
      as_root cat "$daemon_json" > "$current_json"
    fi
  fi

  if [[ -s "$current_json" && "$(command -v python3 || true)" ]]; then
    PY_DAEMON_JSON="$current_json" PY_DOCKER_DATA_ROOT="$DOCKER_DATA_ROOT" python3 - <<'PY' > "$tmp"
import json
import os
from pathlib import Path

path = Path(os.environ["PY_DAEMON_JSON"])
data_root = os.environ["PY_DOCKER_DATA_ROOT"]

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except json.JSONDecodeError as exc:
    raise SystemExit(f"Invalid JSON in {path}: {exc}") from exc

if not isinstance(data, dict):
    raise SystemExit(f"{path} must contain a JSON object")

data["data-root"] = data_root
print(json.dumps(data, indent=2, ensure_ascii=True))
PY
  else
    cat > "$tmp" <<EOF
{
  "data-root": "$DOCKER_DATA_ROOT"
}
EOF
  fi

  as_root mkdir -p "$daemon_dir"

  if [[ -s "$current_json" ]] && cmp -s "$tmp" "$current_json"; then
    log "Docker daemon config already uses data-root: $DOCKER_DATA_ROOT"
    rm -f "$current_json" "$tmp"
    return 0
  fi

  if [[ -f "$daemon_json" ]]; then
    local backup="$daemon_json.bak.$(date +%Y%m%d%H%M%S)"
    as_root cp "$daemon_json" "$backup"
    log "Backed up existing Docker daemon config to $backup"
  fi

  as_root install -m 0644 "$tmp" "$daemon_json"
  rm -f "$current_json" "$tmp"
  log "Wrote Docker daemon config: $daemon_json"
}

setup_storage() {
  need_docker

  log "Current disk usage:"
  df -h

  log "Creating Docker data root: $DOCKER_DATA_ROOT"
  as_root mkdir -p "$DOCKER_DATA_ROOT"

  write_daemon_json
  restart_docker

  if docker info >/dev/null 2>&1; then
    local current_root
    current_root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || true)"
    log "Docker Root Dir: ${current_root:-unknown}"
    if [[ -n "$current_root" && "$current_root" != "$DOCKER_DATA_ROOT" ]]; then
      warn "Docker is still using '$current_root'. Restart the Codespace if you need it to use '$DOCKER_DATA_ROOT'."
    fi
  else
    warn "Docker is not responding yet. Restart the Codespace or Docker service, then run: bash scripts/pc-free.sh start"
  fi
}

append_gitignore() {
  touch "$GITIGNORE_FILE"
  if ! grep -qxF ".env" "$GITIGNORE_FILE"; then
    printf '\n.env\n' >> "$GITIGNORE_FILE"
    log "Added .env to .gitignore"
  fi
  if ! grep -qxF "windows/" "$GITIGNORE_FILE"; then
    printf 'windows/\n' >> "$GITIGNORE_FILE"
    log "Added windows/ to .gitignore"
  fi
}

validate_env_value() {
  local name="$1"
  local value="$2"
  [[ "$value" != *$'\n'* ]] || die "$name cannot contain a newline"
  [[ "$value" != *$'\r'* ]] || die "$name cannot contain a carriage return"
}

dotenv_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//\$/\\\$}"
  printf '"%s"' "$value"
}

write_env_var() {
  local name="$1"
  local value="$2"
  printf '%s=%s\n' "$name" "$(dotenv_quote "$value")"
}

prompt_env_value() {
  local var_name="$1"
  local prompt="$2"
  local default_value="${3:-}"
  local secret="${4:-0}"
  local value="${!var_name:-}"

  if [[ -n "$value" ]]; then
    printf '%s' "$value"
    return 0
  fi

  if [[ ! -t 0 ]]; then
    [[ -n "$default_value" ]] || die "$var_name is required in non-interactive mode"
    printf '%s' "$default_value"
    return 0
  fi

  if [[ "$secret" == "1" ]]; then
    read -r -s -p "$prompt" value
    printf '\n' >&2
  else
    if [[ -n "$default_value" ]]; then
      read -r -p "$prompt [$default_value]: " value
      value="${value:-$default_value}"
    else
      read -r -p "$prompt: " value
    fi
  fi

  printf '%s' "$value"
}

detect_cpu_cores() {
  local cores=""

  if command -v nproc >/dev/null 2>&1; then
    cores="$(nproc 2>/dev/null || true)"
  elif command -v getconf >/dev/null 2>&1; then
    cores="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  elif [[ -r /proc/cpuinfo ]]; then
    cores="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || true)"
  fi

  if [[ "$cores" =~ ^[0-9]+$ && "$cores" -gt 0 ]]; then
    printf '%s' "$cores"
  else
    printf '2'
  fi
}

detect_ram_size() {
  local mem_kb=""
  local mem_bytes=""
  local cgroup_bytes=""
  local mem_gb=""

  if [[ -r /proc/meminfo ]]; then
    mem_kb="$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo 2>/dev/null || true)"
  fi

  if [[ "$mem_kb" =~ ^[0-9]+$ && "$mem_kb" -gt 0 ]]; then
    mem_bytes="$((mem_kb * 1024))"
  fi

  if [[ -r /sys/fs/cgroup/memory.max ]]; then
    cgroup_bytes="$(cat /sys/fs/cgroup/memory.max 2>/dev/null || true)"
  elif [[ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]]; then
    cgroup_bytes="$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || true)"
  fi

  if [[ "$cgroup_bytes" =~ ^[0-9]+$ && "$cgroup_bytes" -gt 0 ]]; then
    if [[ -z "$mem_bytes" || "$cgroup_bytes" -lt "$mem_bytes" ]]; then
      mem_bytes="$cgroup_bytes"
    fi
  fi

  if [[ "$mem_bytes" =~ ^[0-9]+$ && "$mem_bytes" -gt 0 ]]; then
    mem_gb="$((mem_bytes / 1024 / 1024 / 1024))"
    if [[ "$mem_gb" -lt 1 ]]; then
      mem_gb=1
    fi
    printf '%sG' "$mem_gb"
  else
    printf '6G'
  fi
}

refresh_env_resources() {
  local ram_size="${RAM_SIZE:-$(detect_ram_size)}"
  local cpu_cores="${CPU_CORES:-$(detect_cpu_cores)}"
  local tmp

  [[ "$ram_size" =~ ^[0-9]+[GgMm]$ ]] || die "RAM_SIZE must look like 8G or 8192M"
  [[ "$cpu_cores" =~ ^[0-9]+$ && "$cpu_cores" -gt 0 ]] || die "CPU_CORES must be a positive integer"

  tmp="$(mktemp)"
  if [[ -s "$ENV_FILE" ]]; then
    grep -vE '^(RAM_SIZE|CPU_CORES)=' "$ENV_FILE" > "$tmp" || true
  fi

  {
    write_env_var RAM_SIZE "$ram_size"
    write_env_var CPU_CORES "$cpu_cores"
  } >> "$tmp"

  mv "$tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE" 2>/dev/null || true
  log "Refreshed host resources in $ENV_FILE: RAM_SIZE=$ram_size CPU_CORES=$cpu_cores"
}

write_env_file() {
  if [[ -f "$ENV_FILE" && "$FORCE" != "1" ]]; then
    refresh_env_resources
    return 0
  fi

  local windows_username
  local windows_password
  local ram_size
  local cpu_cores

  windows_username="$(prompt_env_value WINDOWS_USERNAME "Windows username" "pcfree")"
  windows_password="$(prompt_env_value WINDOWS_PASSWORD "Windows password" "" "1")"
  ram_size="${RAM_SIZE:-$(detect_ram_size)}"
  cpu_cores="${CPU_CORES:-$(detect_cpu_cores)}"

  [[ -n "$windows_username" ]] || die "WINDOWS_USERNAME cannot be empty"
  [[ -n "$windows_password" ]] || die "WINDOWS_PASSWORD cannot be empty"
  [[ "$ram_size" =~ ^[0-9]+[GgMm]$ ]] || die "RAM_SIZE must look like 8G or 8192M"
  [[ "$cpu_cores" =~ ^[0-9]+$ && "$cpu_cores" -gt 0 ]] || die "CPU_CORES must be a positive integer"

  validate_env_value WINDOWS_USERNAME "$windows_username"
  validate_env_value WINDOWS_PASSWORD "$windows_password"
  validate_env_value WINDOWS_STORAGE "$WINDOWS_STORAGE"
  validate_env_value RAM_SIZE "$ram_size"
  validate_env_value CPU_CORES "$cpu_cores"

  if [[ "$windows_username" =~ [[:space:]] || "$WINDOWS_STORAGE" =~ [[:space:]] ]]; then
    die "WINDOWS_USERNAME and WINDOWS_STORAGE cannot contain whitespace"
  fi

  {
    write_env_var WINDOWS_USERNAME "$windows_username"
    write_env_var WINDOWS_PASSWORD "$windows_password"
    write_env_var WINDOWS_STORAGE "$WINDOWS_STORAGE"
    write_env_var RAM_SIZE "$ram_size"
    write_env_var CPU_CORES "$cpu_cores"
  } > "$ENV_FILE"
  chmod 600 "$ENV_FILE" 2>/dev/null || true
  log "Wrote $ENV_FILE with RAM_SIZE=$ram_size and CPU_CORES=$cpu_cores"
}

write_compose_file() {
  if [[ -f "$COMPOSE_FILE" && "$FORCE" != "1" ]]; then
    log "windows10.yml already exists. Use --force to regenerate it."
    return 0
  fi

  cat > "$COMPOSE_FILE" <<'YAML'
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "10"
      USERNAME: ${WINDOWS_USERNAME}
      PASSWORD: ${WINDOWS_PASSWORD}
      RAM_SIZE: ${RAM_SIZE}
      CPU_CORES: ${CPU_CORES}
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    volumes:
      - ${WINDOWS_STORAGE:-./windows}:/storage
    devices:
      - "/dev/kvm:/dev/kvm"
      - "/dev/net/tun:/dev/net/tun"
    stop_grace_period: 2m
    restart: always
YAML
  log "Wrote $COMPOSE_FILE"
}

generate_config() {
  append_gitignore
  write_env_file
  write_compose_file
}

runtime_checks() {
  if [[ ! -e /dev/kvm ]]; then
    warn "/dev/kvm was not found. The Windows container may fail to start without KVM."
  fi

  if [[ ! -e /dev/net/tun ]]; then
    warn "/dev/net/tun was not found. The Windows container may fail to start without TUN."
  fi

  if docker info >/dev/null 2>&1; then
    local current_root
    current_root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || true)"
    log "Docker Root Dir: ${current_root:-unknown}"
  fi
}

start_windows() {
  need_docker
  generate_config

  if ! docker info >/dev/null 2>&1; then
    die "Docker is not running. Start Docker or restart the Codespace, then run this command again."
  fi

  runtime_checks
  log "Starting Windows container..."
  (cd "$PROJECT_DIR" && compose -f "$COMPOSE_FILE" up -d)
  log "Started. In GitHub Codespaces, open the forwarded port 8006 in a browser."
  log "Use logs with: bash scripts/pc-free.sh logs"
}

stop_windows() {
  need_docker
  log "Stopping Windows container..."
  docker stop "$CONTAINER_NAME"
}

restart_windows() {
  need_docker
  log "Restarting Windows container..."
  docker restart "$CONTAINER_NAME"
}

show_logs() {
  need_docker
  docker logs -f "$CONTAINER_NAME"
}

show_status() {
  need_docker

  if docker info >/dev/null 2>&1; then
    docker info --format 'Docker Root Dir: {{.DockerRootDir}}'
  else
    warn "Docker is not responding"
  fi

  docker ps -a --filter "name=^/${CONTAINER_NAME}$"
}

remove_windows() {
  need_docker
  [[ -f "$COMPOSE_FILE" ]] || die "Missing $COMPOSE_FILE"

  if [[ "$YES" != "1" ]]; then
    local answer
    read -r -p "This removes the Windows container and Compose volumes. Type DELETE to continue: " answer
    [[ "$answer" == "DELETE" ]] || die "Remove cancelled"
  fi

  log "Removing Windows container and Compose volumes..."
  (cd "$PROJECT_DIR" && compose -f "$COMPOSE_FILE" down -v)
}

run_install() {
  generate_config
  start_windows
}

COMMAND="install"
COMMAND_SET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    install|storage|config|start|stop|restart|logs|status|remove|help)
      [[ "$COMMAND_SET" == "0" ]] || die "Only one command can be provided"
      COMMAND="$1"
      COMMAND_SET=1
      shift
      ;;
    --data-root)
      [[ $# -ge 2 ]] || die "--data-root requires a path"
      DOCKER_DATA_ROOT="$2"
      shift 2
      ;;
    --data-root=*)
      DOCKER_DATA_ROOT="${1#*=}"
      shift
      ;;
    --storage)
      [[ $# -ge 2 ]] || die "--storage requires a path"
      WINDOWS_STORAGE="$2"
      shift 2
      ;;
    --storage=*)
      WINDOWS_STORAGE="${1#*=}"
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -y|--yes)
      YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

case "$COMMAND" in
  install)
    run_install
    ;;
  storage)
    setup_storage
    ;;
  config)
    generate_config
    ;;
  start)
    start_windows
    ;;
  stop)
    stop_windows
    ;;
  restart)
    restart_windows
    ;;
  logs)
    show_logs
    ;;
  status)
    show_status
    ;;
  remove)
    remove_windows
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage
    die "Unknown command: $COMMAND"
    ;;
esac
