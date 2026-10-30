#!/usr/bin/env bash
# audit.sh — vérifie le durcissement des conteneurs en cours
# AUDIT_NAME_PREFIX : préfixe des noms (défaut shop- ; geststock- pour TP10)
set -euo pipefail
FAIL=0
PREFIX="${AUDIT_NAME_PREFIX:-shop-}"

printf '%-28s %-12s %-6s %-10s %-10s %-8s %-10s %-8s %s\n' \
  CONTAINER USER PRIV CAP_DROP RO MEM PIDS NNP SOCKET

while read -r id name; do
  [[ -z "$id" ]] && continue
  user=$(docker inspect "$id" --format '{{.Config.User}}')
  [[ -z "$user" || "$user" == "0" || "$user" == "root" ]] && user="ROOT!"
  priv=$(docker inspect "$id" --format '{{.HostConfig.Privileged}}')
  capdrop=$(docker inspect "$id" --format '{{json .HostConfig.CapDrop}}')
  ro=$(docker inspect "$id" --format '{{.HostConfig.ReadonlyRootfs}}')
  mem=$(docker inspect "$id" --format '{{.HostConfig.Memory}}')
  pids=$(docker inspect "$id" --format '{{.HostConfig.PidsLimit}}')
  nnp=$(docker inspect "$id" --format '{{json .HostConfig.SecurityOpt}}')
  sock=$(docker inspect "$id" --format '{{range .Mounts}}{{.Source}} {{end}}' | grep -c docker.sock || true)

  printf '%-28s %-12s %-6s %-10s %-10s %-8s %-10s %-8s %s\n' \
    "$name" "${user:--}" "$priv" "${capdrop:--}" "$ro" "$mem" "${pids:--}" "$nnp" "sock=$sock"

  # Écarts : root, privileged, socket montée, pas de limite mémoire, pas de cap_drop
  # socket-proxy : exception documentée (seul accès RO à la socket)
  if [[ "$name" == *socket-proxy* ]]; then
    [[ "$sock" == "0" ]] && { echo "  FAIL socket-proxy sans sock" >&2; FAIL=1; }
    continue
  fi
  # db : Config.User vide mais process postgres/mysql non-root
  if [[ "$name" == *-db-* && "$user" == "ROOT!" ]]; then
    db_user=$(docker exec "$id" sh -c \
      "ps -eo user,comm 2>/dev/null | awk '/postgres|mariadbd|mysqld/{print \$1; exit}'" || true)
    if [[ -n "$db_user" && "$db_user" != "root" ]]; then
      user="db($db_user)"
    fi
  fi
  # apache officiel : master root, workers www-data (contrainte image)
  if [[ "$name" == *-app-* && "$user" == "ROOT!" ]]; then
    if docker exec "$id" ps aux 2>/dev/null | grep -q 'www-data.*apache'; then
      user="apache(www-data-workers)"
    fi
  fi
  if [[ "$user" == "ROOT!" ]]; then echo "  FAIL user root ($name)" >&2; FAIL=1; fi
  if [[ "$priv" == "true" ]]; then echo "  FAIL privileged ($name)" >&2; FAIL=1; fi
  if [[ "$sock" != "0" ]]; then
    echo "  FAIL docker.sock montée ($name)" >&2; FAIL=1
  fi
  if [[ "$mem" == "0" ]]; then echo "  FAIL no memory limit ($name)" >&2; FAIL=1; fi
  if [[ "$capdrop" == "null" || "$capdrop" == "[]" ]]; then
    echo "  FAIL no CapDrop ($name)" >&2; FAIL=1
  fi
  if ! echo "$nnp" | grep -q 'no-new-privileges'; then
    echo "  FAIL no-new-privileges absent ($name)" >&2; FAIL=1
  fi
done < <(docker ps --format '{{.ID}} {{.Names}}' | grep -E "$PREFIX" || true)

exit "$FAIL"
