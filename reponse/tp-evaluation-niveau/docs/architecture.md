# Architecture

## Topologie réseau

| Réseau | Services | Rôle |
|--------|----------|------|
| `wp_net_edge` | nginx | Exposition HTTP vers l'hôte (8080) |
| `wp_net_front` | nginx, wordpress | Reverse proxy vers l'application |
| `wp_net_data` | wordpress, mariadb | Accès base de données |

MariaDB n'est pas publié sur l'hôte. WordPress n'a pas de port mappé : seul Nginx est accessible depuis la machine locale.

## Volumes

| Volume | Montage | Données |
|--------|---------|---------|
| `wp_infra_db_data` | `/var/lib/mysql` | Base MariaDB |
| `wp_infra_wp_data` | `/var/www/html` | Fichiers WordPress |

## Sécurité

- Mots de passe via secrets Compose (`*_PASSWORD_FILE`), absents du `compose.yaml` versionné.
- Nginx : filesystem read-only, `cap_drop: ALL`, limites CPU/RAM.
- Aucun service en `privileged: true`.
- MariaDB/WordPress : images officielles nécessitant des droits élevés au démarrage (entrypoint) ; limites de ressources appliquées.

## Santé et dépendances

MariaDB et WordPress exposent des healthchecks. Nginx attend WordPress `healthy` avant d'être considéré opérationnel.

Un conteneur `running` n'implique pas un service prêt : les healthchecks valident la disponibilité réelle (connexion BDD, page WordPress).

## Profil admin (bonus)

`docker compose --profile admin up -d` démarre phpMyAdmin sur le port 8081, joignable uniquement sur le réseau data.
