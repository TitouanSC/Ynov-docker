#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASE="${BASE_URL:-http://api.localhost}"
echo "== smoke-test against $BASE =="

echo "→ /ready"
curl -sf "$BASE/ready" | tee /tmp/shop-ready.json | grep -q '"status":"ready"'

echo "→ /products (MISS puis HIT cache)"
curl -sf -D /tmp/shop-h1.txt -o /tmp/shop-products.json "$BASE/products" >/dev/null
grep -qi 'X-Cache: MISS' /tmp/shop-h1.txt || grep -qi 'x-cache: miss' /tmp/shop-h1.txt || true
curl -sf -D /tmp/shop-h2.txt -o /tmp/shop-products2.json "$BASE/products" >/dev/null
grep -qi 'X-Cache: HIT' /tmp/shop-h2.txt || grep -qi 'x-cache: hit' /tmp/shop-h2.txt

echo "→ POST /orders"
ORDER=$(curl -sf -X POST "$BASE/orders" -H 'Content-Type: application/json' \
  -d '{"productId":1,"quantity":2}')
echo "$ORDER" | tee /tmp/shop-order.json | grep -q pending

echo "→ attente confirmation worker"
ok=0
for i in $(seq 1 30); do
  status=$(docker compose exec -T db \
    sh -c 'PGPASSWORD=$(cat /run/secrets/db_password) psql -U shop -d shop -Atc "SELECT status FROM orders ORDER BY id DESC LIMIT 1"' \
    2>/dev/null || true)
  if [[ "$status" == "confirmed" || "$status" == "rejected" ]]; then
    echo "order status=$status"
    ok=1
    break
  fi
  sleep 1
done
[[ "$ok" == "1" ]] || { echo "FAIL: worker n'a pas confirmé la commande"; exit 1; }

echo "OK smoke-test"
