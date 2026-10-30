# TP08 — Hardening

```bash
# depuis reponse/tp04-compose-entreprise
../tp08-hardening/audit.sh || true   # avant
docker compose -f compose.yml -f ../tp08-hardening/compose.hardened.yml up -d --wait
../tp08-hardening/audit.sh           # après (services app)
./scripts/smoke-test.sh
```
