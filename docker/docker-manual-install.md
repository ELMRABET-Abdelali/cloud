
# Installation manuelle de Docker sur Ubuntu

Ce guide détaille étape par étape comment installer Docker Engine et son plugin Compose sur Ubuntu. Chaque étape est accompagnée d'explications et d'un bloc de commande facilement copiable.

---

## ÉTAPE 1 : Préparation du système

Avant toute installation, il est conseillé de mettre à jour votre système et d’installer les pré-requis.

**Explication :**  
Nous mettons à jour les paquets existants puis installons les outils nécessaires à la gestion des dépôts et certificats.

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install ca-certificates curl gnupg lsb-release -y
```

---

## ÉTAPE 2 : Ajout du dépôt officiel Docker

Pour obtenir la dernière version stable, nous allons configurer le dépôt officiel.

**Explication :**  
- Création du dossier clé.
- Téléchargement et ajout de la clé GPG de Docker.
- Ajout du dépôt stable correspondant à votre version Ubuntu.

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

---

## ÉTAPE 3 : Installation de Docker Engine et du Plugin Compose V2

Nous allons installer Docker et ses composants nécessaires.

**Explication :**  
On installe les paquets principaux de Docker, ainsi que les plugins utiles pour la construction et la composition des images.

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

---

## ÉTAPE 4 : Configuration post-installation

Pour utiliser Docker sans `sudo`, il est nécessaire d’ajouter votre utilisateur au groupe `docker`.

**Explication :**  
- Création du groupe s’il n’existe pas.
- Ajout de l’utilisateur courant au groupe Docker.

```bash
sudo groupadd docker 2>/dev/null
sudo usermod -aG docker "$USER"
```

> **⚠️ IMPORTANT :**  
> Vous devez vous déconnecter puis vous reconnecter pour que les changements de groupe prennent effet.  
> Après cela, vous pourrez exécuter la commande `docker` sans utiliser `sudo`.

---

## ÉTAPE 5 : Vérification de l’installation

Vérifiez que Docker et Compose sont correctement installés.

**Explication :**  
Ces commandes affichent les versions installées. Cela permet de vérifier le bon déroulement de l’installation.

```bash
docker --version
docker compose version
```

---

## Test final

Après reconnexion, vérifiez le bon fonctionnement avec :

```bash
docker run hello-world
```

Si le message "Hello from Docker!" s'affiche, l'installation est réussie 🎉.

---
