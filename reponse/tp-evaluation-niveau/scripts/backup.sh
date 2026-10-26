#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="${BACKUP_DIR}/${STAMP}"

mkdir -p "${TARGET}"

docker compose -f "${ROOT_DIR}/compose.yaml" exec -T mariadb \
  sh -c 'mariadb-dump -u root -p"$(cat /run/secrets/db_root_password)" --all-databases' \
  > "${TARGET}/mariadb-all.sql"

docker run --rm \
  -v wp_infra_wp_data:/data:ro \
  -v "${TARGET}:/backup" \
  alpine:3.21 \
  tar czf /backup/wordpress-html.tar.gz -C /data .

echo "Sauvegarde créée : ${TARGET}"
