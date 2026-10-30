# Expériences de durcissement (conteneurs alpine jetables)

| Mesure | Commande / preuve | Observation |
|--------|-------------------|-------------|
| `--read-only` | `docker run --rm --read-only alpine touch /x` → Read-only file system ; avec `--tmpfs /tmp` : `touch /tmp/x` OK | Rootfs immuable, écriture seulement sur tmpfs/volumes |
| `--cap-drop ALL` | `ping` échoue (NET_RAW) ; `apk add` peut échouer ; réajouter `NET_RAW` / `CHOWN` au besoin | Capabilités = privilèges fins |
| `no-new-privileges` | Empêche un binaire setuid d'élever les privilèges | Bloque escalation via setuid |
| `--pids-limit 50` | Boucle de `sleep &` → fork refusés au-delà de 50 | Anti fork-bomb |
| `--memory 32m` | Alloc Python 100 Mo → `OOMKilled: true` | Isolation mémoire |
| `--user 1000` | `id` → uid=1000 ; volumes host doivent être accessibles à cet uid | Non-root + droits volumes |
| seccomp | `unshare --user` bloqué par défaut ; OK avec `seccomp=unconfined` | ~300+ syscalls filtrés par le profil Docker |

## CIS / docker-bench

Sur Docker Desktop, plusieurs contrôles hôte ne s'appliquent pas (VM). Priorités typiques : conteneurs root, socket Docker montée, pas de limites mémoire, Privileged, CapAdd excessifs.
