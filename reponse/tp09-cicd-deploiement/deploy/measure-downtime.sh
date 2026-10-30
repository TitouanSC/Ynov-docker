#!/usr/bin/env bash
# Mesure les échecs HTTP pendant un déploiement (ex. 100 req/s sur /health)
set -euo pipefail
URL="${1:-http://api.localhost/health}"
DURATION="${DURATION:-30}"
FAIL=0
OK=0
END=$((SECONDS + DURATION))
echo "measure $URL during ${DURATION}s"
while (( SECONDS < END )); do
  if curl -sf -o /dev/null --max-time 1 "$URL"; then
    OK=$((OK + 1))
  else
    FAIL=$((FAIL + 1))
  fi
  sleep 0.01
done
echo "OK=$OK FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
