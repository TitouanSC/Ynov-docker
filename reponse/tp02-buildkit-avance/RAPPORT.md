# RAPPORT — TP02 BuildKit avancé (shop-worker)

## 1. Fuite via `ARG PIP_INDEX_URL`

Build legacy avec secret dans l'URL :

```text
Looking in indexes: https://svc-ci:****@pypi.internal.example.com/simple
ERROR: No matching distribution found for redis==5.0.8
```

Même si Docker masque parfois le mot de passe dans les logs récents, le secret serait visible dans **au moins 3 endroits** si le `RUN` réussissait :

1. **`docker history --no-trunc`** — la couche `RUN` / `ENV` conserve la commande ou la variable.
2. **`docker inspect`** — `Config.Env` si l'`ARG` est promu en `ENV`.
3. **Couche intermédiaire / cache BuildKit** — extrayable tant que le blob existe (outil type `dive`, export de couche).

Le secret mount (`--mount=type=secret`) n'écrit jamais le fichier dans une couche : il n'existe que pendant le `RUN`.

## 2. Secret mount — vérification

```bash
docker build --secret id=pipconf,src=pip.conf -t worker:1.0 .
docker history worker:1.0 --no-trunc | grep -iE 'secret|Tr3s|pip.conf'  # vide
docker run --rm --user 0 worker:1.0 cat /etc/pip.conf                   # No such file
```

Alternatives : `--mount=type=ssh` (deps git privées), `--secret id=TOKEN,env=TOKEN` (token CI sans fichier).

## 3. Cache mount vs cache de couches

| Mécanisme | Invalidé par | Survit à `docker builder prune` (sans `-a` / filtres cache mount) |
|-----------|--------------|-------------------------------------------------------------------|
| Cache de couches | Changement d'instruction / checksum `COPY` | Non (prune le retire) |
| Cache mount `/root/.cache/pip` | Manuel / prune ciblé | Oui (monté à part, id `pip-${TARGETARCH}`) |

Mesure : après `builder prune` + ajout `requests==2.32.3` + rebuild `--no-cache` des couches, pip affiche **`Using cached`** pour redis/psycopg2/etc. → le cache mount accélère le re-téléchargement.

Avec `docker build --no-cache` : les couches sont rejouées, mais le cache mount reste utilisable. Sans cache mount, chaque rebuild re-télécharge tout depuis PyPI.

`TARGETARCH` isole le cache pip par architecture (wheels amd64 ≠ arm64).

## 4. Multi-architecture

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  --secret id=pipconf,src=pip.conf -o type=oci,dest=/tmp/worker-multi.tar .
# ~12 s ici (arm64 natif + amd64 via QEMU)
```

- **`--push` ou `-o` obligatoire** : le driver docker classique ne charge qu'une seule plateforme locale ; un *manifest list* multi-arch doit être poussé ou exporté.
- Le **manifest list** référence un manifeste par architecture (+ attestations éventuelles).
- arm64 plus lent sur amd64 car **émulation QEMU** ; alternative : builders natifs distants (un nœud arm, un nœud amd) avec `buildx create --append`.

## 5. Cache distant / bake

- `mode=min` : cache de l'étape finale ; `mode=max` : toutes les étapes intermédiaires (meilleur hit CI, plus gros volume).
- Variantes CI : `type=gha`, `type=s3`, `type=registry`.

```bash
docker buildx bake --print
VERSION=1.0 GIT_SHA=$(git rev-parse --short HEAD) docker buildx bake worker-test
VERSION=1.0 docker buildx bake --allow=fs.read=../tp01-optimisation-image/shopapi \
  --set "*.platform=linux/$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" --load
```

Images produites : `shopapi:1.0`, `shop-worker:1.0`. Tests pytest : **2 passed**.
