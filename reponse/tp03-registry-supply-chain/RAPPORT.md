# RAPPORT — TP03 Registre & supply chain

## Registre

- Stack : `registry/compose.yml` (TLS, htpasswd `ci`/`dev`, volume, delete, healthcheck, UI `:8080`, mirror `:5501`).
- Port hôte **5500** (le 5000 est pris par AirPlay / ControlCenter sur macOS).
- Certs : `registry/certs/` (CA + SAN `registry.local`, `localhost`).
- Client Docker : `~/.docker/certs.d/localhost:5500/ca.crt`.
- `/etc/hosts` : nécessite `sudo` (`scripts/setup-client.sh`) — tests validés via `localhost:5500`.

### Validation

| Check | Résultat |
|-------|----------|
| `curl -sk https://localhost:5500/v2/` | **401** |
| `curl -sk -u dev:dev-pull-2024 …/_catalog` | OK |
| `docker login` + push `shopapi:1.4.2` | OK |
| Tags après cosign | `1.4.2`, `sha256-….sig`, `sha256-….att` |

### API (curl)

```bash
# digest (Accept OCI index)
curl -skI -u ci:ci-push-2024 \
  -H 'Accept: application/vnd.oci.image.index.v1+json,…' \
  https://localhost:5500/v2/shopapi/manifests/1.4.2
# → docker-content-digest: sha256:133a1750…
```

`htpasswd` vs Harbor/ECR : voir `TAGGING.md` — RBAC, scan, réplication, immutabilité manquent avec htpasswd seul.

## Signature & SBOM

- Clés : `cosign.key` / `cosign.pub` (gitignored pour la clé privée).
- Signature liée au **digest** ; retagger ne déplace pas la signature (le tag `.sig` référence le digest).
- Trivy secrets sur `shopapi:legacy` : retrouve `AWS_SECRET_ACCESS_KEY` dans `/app/.env`.

## release-gate.sh

| Image | Résultat |
|-------|----------|
| `shopapi:legacy` | **exit 1** (labels OCI absents) |
| `shopapi:1.4.2` | **exit 0** (labels, non-root, HEALTHCHECK, 0 secret, 0 CVE HIGH/CRITICAL fixables, SBOM 137 pkgs) |

```bash
./release-gate.sh shopapi:legacy          # refuse
./release-gate.sh shopapi:1.4.2           # accepte
./release-gate.sh shopapi:1.4.2 --push localhost:5500/shopapi:1.4.2
```

## Mirror

Service `registry-mirror` sur `5501`. Pour l'activer côté daemon Docker Desktop :

```json
{ "registry-mirrors": ["http://localhost:5501"] }
```

Puis redémarrer Docker et comparer les logs au 2ᵉ `docker pull alpine:3.20`.
