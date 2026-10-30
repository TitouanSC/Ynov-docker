#!/usr/bin/env bash
# release-gate.sh IMAGE [--push REGISTRY_IMAGE]
# Porte de release Shop SAS : labels OCI, non-root, HEALTHCHECK, scan CVE/secrets.
set -euo pipefail

IMAGE="${1:?usage: release-gate.sh IMAGE [--push REGISTRY_IMAGE]}"
PUSH_REF=""
if [[ "${2:-}" == "--push" ]]; then
  PUSH_REF="${3:?usage: release-gate.sh IMAGE --push REGISTRY_IMAGE}"
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="${TMPDIR:-/tmp}/release-gate-$$"
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

echo "== release-gate : $IMAGE =="

# --- Labels OCI ---
labels=$(docker inspect "$IMAGE" --format '{{json .Config.Labels}}')
echo "$labels" | jq -e '."org.opencontainers.image.version" and ."org.opencontainers.image.revision" and ."org.opencontainers.image.source"' >/dev/null \
  || fail "labels OCI version/revision/source absents"
ok "labels OCI présents"

# --- Non-root ---
user=$(docker inspect "$IMAGE" --format '{{.Config.User}}')
if [[ -z "$user" || "$user" == "0" || "$user" == "root" || "$user" == "0:0" ]]; then
  fail "utilisateur root (Config.User='$user')"
fi
ok "utilisateur non-root ($user)"

# --- HEALTHCHECK ---
hc=$(docker inspect "$IMAGE" --format '{{json .Config.Healthcheck}}')
[[ "$hc" != "null" && -n "$hc" ]] || fail "pas de HEALTHCHECK"
ok "HEALTHCHECK défini"

# --- Scan secrets (trivy) ---
echo "→ scan secrets (trivy)..."
if ! docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.56.2 image --quiet --scanners secret --exit-code 1 "$IMAGE"; then
  fail "secret détecté dans l'image"
fi
ok "pas de secret détecté"

# --- Scan CVE HIGH/CRITICAL fixables ---
echo "→ scan CVE HIGH/CRITICAL (trivy)..."
if ! docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.56.2 image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$IMAGE"; then
  fail "CVE HIGH/CRITICAL corrigeables présentes"
fi
ok "pas de CVE HIGH/CRITICAL corrigeables"

# --- SBOM ---
echo "→ SBOM (syft)..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$WORKDIR:/out" anchore/syft:v1.14.0 \
  "$IMAGE" -o spdx-json=/out/sbom.json >/dev/null
pkg_count=$(jq '.packages | length' "$WORKDIR/sbom.json")
ok "SBOM généré ($pkg_count packages)"

if [[ -z "$PUSH_REF" ]]; then
  echo "== porte OK (pas de push demandé) =="
  exit 0
fi

# --- Push + signature + attestation ---
echo "→ docker push $PUSH_REF"
docker tag "$IMAGE" "$PUSH_REF"
docker push "$PUSH_REF"

COSIGN_KEY="${COSIGN_KEY:-$ROOT/cosign.key}"
COSIGN_PUB="${COSIGN_PUB:-$ROOT/cosign.pub}"
if [[ ! -f "$COSIGN_KEY" ]]; then
  fail "clé cosign absente ($COSIGN_KEY) — générez avec: COSIGN_PASSWORD='' cosign generate-key-pair"
fi

COSIGN_BIN="${COSIGN_BIN:-$(command -v cosign || true)}"
[[ -x "${COSIGN_BIN:-}" ]] || COSIGN_BIN="/tmp/cosign"
[[ -x "$COSIGN_BIN" ]] || fail "cosign introuvable (installez le binaire hôte : https://github.com/sigstore/cosign/releases)"

# Digest préféré (signature liée au digest, pas au tag)
DIGEST_REF=$(docker inspect --format='{{index .RepoDigests 0}}' "$PUSH_REF" 2>/dev/null || true)
if [[ -z "$DIGEST_REF" ]]; then
  DIGEST_REF="$PUSH_REF"
fi
INSECURE=()
if [[ "$PUSH_REF" == localhost:* || "$PUSH_REF" == registry.local:* ]]; then
  INSECURE=(--allow-insecure-registry)
fi

echo "→ cosign sign ($DIGEST_REF)"
COSIGN_PASSWORD="${COSIGN_PASSWORD:-}" "$COSIGN_BIN" sign --key "$COSIGN_KEY" --yes "${INSECURE[@]}" "$DIGEST_REF"

echo "→ cosign attest SBOM"
COSIGN_PASSWORD="${COSIGN_PASSWORD:-}" "$COSIGN_BIN" attest --key "$COSIGN_KEY" --type spdxjson \
  --predicate "$WORKDIR/sbom.json" --yes "${INSECURE[@]}" "$DIGEST_REF"

echo "→ cosign verify"
"$COSIGN_BIN" verify --key "$COSIGN_PUB" "${INSECURE[@]}" "$DIGEST_REF" | jq '.[0].critical'

echo "== porte OK : $PUSH_REF publié, signé, attesté =="
