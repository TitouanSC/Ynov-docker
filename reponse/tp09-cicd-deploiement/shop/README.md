# TP04 — Stack Compose entreprise (réponse)

## Démarrage (dev)

```bash
cp secrets/db_password.txt.example secrets/db_password.txt
make up          # build + up -d --wait
make test        # smoke-test via http://api.localhost
```

## Fichiers

- `CRITIQUE.md` — problèmes du starter
- `compose.yml` / `compose.override.yml` / `compose.prod.yml`
- `Makefile`, `scripts/smoke-test.sh`, `.env.example`
