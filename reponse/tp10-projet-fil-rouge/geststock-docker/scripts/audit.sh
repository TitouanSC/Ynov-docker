#!/usr/bin/env bash
# Réutilise l'audit TP08, limité aux conteneurs geststock-*
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
AUDIT="$ROOT/tp08-hardening/audit.sh"
if [[ ! -x "$AUDIT" ]]; then
  echo "audit TP08 introuvable: $AUDIT" >&2
  exit 1
fi
export AUDIT_NAME_PREFIX="${AUDIT_NAME_PREFIX:-geststock-}"
exec "$AUDIT" "$@"
