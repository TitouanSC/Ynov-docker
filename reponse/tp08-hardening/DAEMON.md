# daemon.json — justifications

| Option | Effet | Effet de bord |
|--------|-------|---------------|
| `no-new-privileges` | Défaut daemon : pas d'élévation setuid | Apps légitimes setuid cassées |
| `icc: false` | Pas de com. inter-conteneurs sur le bridge **par défaut** | Les réseaux user-defined (shop_front/back) restent OK |
| `live-restore` | Conteneurs survivent au restart du daemon | Déploiements / upgrades daemon plus sûrs |
| logs rotatifs | Évite disque plein | — |
| `userns-remap` | Root conteneur ≠ root hôte | **UID remappés** : volumes existants changent de propriétaire → `chown` massif |

Proposition rootless : alternative plus forte ; ports <1024 et certains outils (cAdvisor) plus complexes.
