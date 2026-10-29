#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <dossier-backup>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$(cd "$1" && pwd)"

if [ ! -f "${SOURCE}/mariadb-all.sql" ] || [ ! -f "${SOURCE}/wordpress-html.tar.gz" ]; then
  echo "Backup invalide (mariadb-all.sql et wordpress-html.tar.gz requis)" >&2
  exit 1
fi

docker compose -f "${ROOT_DIR}/compose.yaml" up -d mariadb wordpress nginx

docker compose -f "${ROOT_DIR}/compose.yaml" exec -T mariadb \
  sh -c 'mariadb -u root -p"$(cat /run/secrets/db_root_password)"' \
  < "${SOURCE}/mariadb-all.sql"

docker run --rm \
  -v wp_infra_wp_data:/data \
  -v "${SOURCE}:/backup:ro" \
  alpine:3.21 \
  sh -c "rm -rf /data/* && tar xzf /backup/wordpress-html.tar.gz -C /data"

docker compose -f "${ROOT_DIR}/compose.yaml" restart wordpress nginx

echo "Restauration terminée depuis ${SOURCE}"
