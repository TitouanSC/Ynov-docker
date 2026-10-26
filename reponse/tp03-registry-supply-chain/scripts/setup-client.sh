#!/usr/bin/env bash
# Configure le client Docker local pour registry.local:5000 (TLS + /etc/hosts).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CA="$ROOT/registry/certs/ca.crt"

echo "→ /etc/hosts : registry.local"
if ! grep -q 'registry.local' /etc/hosts; then
  echo '127.0.0.1 registry.local' | sudo tee -a /etc/hosts >/dev/null
else
  echo "  déjà présent"
fi

for host in "registry.local:5500" "localhost:5500"; do
  CERT_DIR="$HOME/.docker/certs.d/$host"
  mkdir -p "$CERT_DIR"
  cp "$CA" "$CERT_DIR/ca.crt"
  echo "→ CA installée dans $CERT_DIR/ca.crt"
done

echo "→ suggestion daemon.json (Docker Desktop → Settings → Docker Engine) :"
cat <<'EOF'
{
  "registry-mirrors": ["http://localhost:5501"]
}
EOF
echo "Note: le registre écoute sur le port hôte 5500 (5000 souvent pris par AirPlay macOS)."
echo "Redémarrez Docker Desktop après modification du daemon.json."
