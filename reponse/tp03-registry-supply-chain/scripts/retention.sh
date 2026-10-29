#!/usr/bin/env bash
# retention.sh REGISTRY REPO KEEP
# Garde les N tags les plus récents hors semver (ex. sha-*, build-*, tmp-*).
set -euo pipefail
REGISTRY="${1:?usage: retention.sh REGISTRY REPO KEEP}"
REPO="${2:?}"
KEEP="${3:?}"
USER="${REGISTRY_USER:-ci}"
PASS="${REGISTRY_PASS:-ci-push-2024}"

AUTH=(-u "$USER:$PASS")
ACCEPT='Accept: application/vnd.docker.distribution.manifest.v2+json'

tags=$(curl -sk "${AUTH[@]}" "https://${REGISTRY}/v2/${REPO}/tags/list" | jq -r '.tags[]?' | sort -u)
non_semver=$(echo "$tags" | grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+(-.+)?$' || true)
to_delete=$(echo "$non_semver" | sort | head -n "-${KEEP}" || true)

if [[ -z "${to_delete}" ]]; then
  echo "Rien à supprimer (keep=${KEEP})"
  exit 0
fi

while IFS= read -r tag; do
  [[ -z "$tag" ]] && continue
  digest=$(curl -skI "${AUTH[@]}" -H "$ACCEPT" \
    "https://${REGISTRY}/v2/${REPO}/manifests/${tag}" \
    | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}')
  if [[ -n "$digest" ]]; then
    echo "delete ${REPO}:${tag} ($digest)"
    curl -sk -X DELETE "${AUTH[@]}" "https://${REGISTRY}/v2/${REPO}/manifests/${digest}" -o /dev/null -w "%{http_code}\n"
  fi
done <<< "$to_delete"

echo "Exécutez garbage-collect dans le conteneur registry ensuite."
