# Procédure de diagnostic

1. Vérifier l'état : `docker compose ps` et colonne `HEALTH`.
2. Logs par service : `docker compose logs nginx|wordpress|mariadb --tail=100`.
3. Ressources : `docker stats --no-stream`.
4. DNS inter-conteneurs :
   - `docker compose exec wordpress getent hosts mariadb`
   - `docker compose exec nginx getent hosts wordpress`
5. Connexion WordPress → MariaDB :
   - `docker compose exec wordpress bash -lc 'apt-get update -qq && apt-get install -y -qq default-mysql-client >/dev/null && mysql -h mariadb -u"$WORDPRESS_DB_USER" -p"$(cat /run/secrets/db_password)" -e "SELECT 1"'`
6. Pannes simulées :
   - `docker stop tp-mariadb` puis observer WordPress/nginx (health `unhealthy`).
   - `docker start tp-mariadb` puis attendre le retour à `healthy`.

Conteneur défaillant : service avec `STATUS` exited ou health `unhealthy` + logs corrélés.
