# Politique de tags — Shop SAS

## Tags autorisés

| Tag | Immuable ? | Usage |
|-----|------------|--------|
| `X.Y.Z` (semver) | **Oui** | Release prod / staging |
| `X.Y.Z-rc.N` | Oui | Release candidate |
| `sha-<git-short>` | Oui | Traçabilité commit |
| `build-<ci-id>` | Non (rétention) | Artefact CI temporaire |
| `dev-<user>` | Non | Bac à sable développeur |

## Interdits en production

- **`latest`** : mutable, non reproductible, cause classique d'incident (« vendredi soir »).
- Tags flottants (`stable`, `prod`) sans digest associé.

## Référencer par digest

Dans un `compose.yml` / manifeste K8s, préférer le digest plutôt que le tag :

```yaml
services:
  api:
    image: registry.local:5000/shopapi@sha256:abcdef...
```

Le digest est immuable : retagger ou écraser un tag ne change pas ce que le cluster tire.

## Retag sans pull

Avec `crane` (conteneur) :

```bash
docker run --rm gcr.io/go-containerregistry/crane:v0.20.2 \
  tag registry.local:5000/shopapi:1.4.2 registry.local:5000/shopapi:sha-$(git rev-parse --short HEAD)
```

Avec `skopeo` :

```bash
skopeo copy --src-tls-verify=false --dest-tls-verify=false \
  docker://registry.local:5000/shopapi:1.4.2 \
  docker://registry.local:5000/shopapi:1.4.2-promoted
```

## Question entreprise — htpasswd

`htpasswd` suffit pour un lab / petite équipe. En entreprise, Harbor / Nexus / Artifactory / ECR / ACR / GAR apportent : **RBAC**, scan intégré, réplication, quotas, **immutabilité des tags**, SSO, audit.
