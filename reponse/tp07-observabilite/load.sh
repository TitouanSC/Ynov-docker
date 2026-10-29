#!/usr/bin/env bash
# Génère de la charge HTTP sur l'API Shop
set -euo pipefail
N="${1:-200}"
BASE="${BASE_URL:-http://api.localhost}"
echo "load $N requests → $BASE"
for i in $(seq 1 "$N"); do
  curl -sf "$BASE/products" >/dev/null || true
  curl -sf -X POST "$BASE/orders" -H 'Content-Type: application/json' \
    -d "{\"productId\":1,\"quantity\":$((i % 5 + 1))}" >/dev/null || true
done
echo "done"
