# Secrets

Créer localement (non versionnés) :

```bash
mkdir -p secrets
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/db_password.txt
chmod 600 secrets/*.txt
```

Les images MariaDB et WordPress lisent les mots de passe via `*_PASSWORD_FILE` (montés par Docker Compose).
