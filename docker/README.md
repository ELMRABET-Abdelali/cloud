# Installation de Docker Engine et Docker Compose V2

Ce répertoire contient le script `docker-install.sh` qui installe la dernière version de **Docker Engine** et du **plugin Docker Compose V2** à partir des dépôts officiels sur les systèmes basés sur Debian/Ubuntu.

---

## Méthode d'Installation Recommandée (Une seule ligne)

La meilleure pratique pour l'installation rapide est d'enchaîner le téléchargement, l'attribution des permissions et l'exécution en une seule commande sécurisée. L'opérateur `&&` garantit que l'exécution ne se fera **que si** le téléchargement et le `chmod` réussissent.

Copiez et collez la ligne ci-dessous dans votre terminal (nécessite les droits `sudo`):

```bash
curl -fsSL [https://raw.githubusercontent.com/ELMRABET-Abdelali/cloud/main/docker/docker-install.sh](https://raw.githubusercontent.com/ELMRABET-Abdelali/cloud/main/docker/docker-install.sh) -o docker-install.sh && chmod +x docker-install.sh && ./docker-install.sh
