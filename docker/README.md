# Installation de Docker Engine et Docker Compose V2

Ce répertoire contient le script `docker-install.sh` qui installe la dernière version de **Docker Engine** et du **plugin Docker Compose V2** à partir des dépôts officiels sur les systèmes basés sur Debian/Ubuntu.

---

## Méthode d'Installation Recommandée (Une seule ligne)

Cette commande est la méthode la plus efficace pour automatiser l'installation. L'opérateur **`&&`** garantit que l'exécution (`./docker-install.sh`) ne se fera **que si** le téléchargement (`curl`) et l'attribution des permissions (`chmod`) réussissent.

Copiez et collez la ligne ci-dessous dans votre terminal (nécessite les droits `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/ELMRABET-Abdelali/cloud/main/docker/docker-install.sh -o docker-install.sh && chmod +x docker-install.sh && ./docker-install.sh
