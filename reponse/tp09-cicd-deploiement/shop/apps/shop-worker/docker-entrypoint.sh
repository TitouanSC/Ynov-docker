#!/bin/sh
set -eu
if [ -f /run/secrets/db_password ]; then
  PASS=$(cat /run/secrets/db_password)
  export DATABASE_URL="${DATABASE_URL_TEMPLATE:-postgres://shop:${PASS}@db:5432/shop}"
fi
exec "$@"
