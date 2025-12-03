#!/bin/bash

# --- ÉTAPE 1: Préparation du système ---
echo "Mise à jour du système et installation des pré-requis..."
sudo apt update
sudo apt upgrade -y
sudo apt install ca-certificates curl gnupg lsb-release -y

# --- ÉTAPE 2: Ajout du dépôt officiel de Docker ---
echo "Ajout de la clé GPG et du dépôt Docker..."
# Créer le dossier pour les clés GPG
sudo mkdir -p /etc/apt/keyrings
# Télécharger et ajouter la clé GPG
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# Configurer le dépôt stable pour Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# --- ÉTAPE 3: Installation de Docker Engine et du Plugin Compose V2 ---
echo "Installation de Docker Engine (docker-ce) et du Compose Plugin..."
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# --- ÉTAPE 4: Configuration post-installation (Optionnel: pour éviter d'utiliser 'sudo') ---
echo "Ajout de l'utilisateur actuel au groupe 'docker' (nécessite de se reconnecter)..."
# Créer le groupe 'docker' s'il n'existe pas
sudo groupadd docker 2>/dev/null
# Ajouter l'utilisateur courant ($USER) au groupe 'docker'
sudo usermod -aG docker $USER

# --- ÉTAPE 5: Vérification de l'installation ---
echo "--- Vérification ---"
echo "Docker Engine Version:"
docker --version
echo "Docker Compose Version:"
docker compose version
echo ""
echo "!!! ATTENTION : Vous devez vous déconnecter et vous reconnecter pour pouvoir utiliser les commandes 'docker' sans 'sudo' !!!"
echo "Une fois reconnecté, exécutez 'docker run hello-world' pour tester."
