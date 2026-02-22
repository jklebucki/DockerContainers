#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.yml"
DATA_ROOT="/srv/docker/postgres"
DB_DATA_DIR="$DATA_ROOT/data"
PGADMIN_DATA_DIR="$DATA_ROOT/pgadmin"
POSTGRES_UID="${POSTGRES_UID:-999}"
POSTGRES_GID="${POSTGRES_GID:-999}"
PGADMIN_UID="${PGADMIN_UID:-5050}"
PGADMIN_GID="${PGADMIN_GID:-5050}"

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not available in PATH." >&2
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "Docker Compose is not available (docker compose / docker-compose)." >&2
  exit 1
fi

echo "Creating persistent directories under $DATA_ROOT ..."
run_as_root mkdir -p "$DB_DATA_DIR" "$PGADMIN_DATA_DIR"
run_as_root chown -R "$POSTGRES_UID:$POSTGRES_GID" "$DB_DATA_DIR"
run_as_root chmod 700 "$DB_DATA_DIR"
run_as_root chown -R "$PGADMIN_UID:$PGADMIN_GID" "$PGADMIN_DATA_DIR"
run_as_root chmod 700 "$PGADMIN_DATA_DIR"

echo "Pulling latest images ..."
"${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" pull

echo "Starting containers ..."
"${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" up -d

echo "Stack status:"
"${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" ps
