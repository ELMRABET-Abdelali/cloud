# TP3 – Installer et utiliser Portainer pour gérer Docker

**Objectif du TP :**  
Installer **Portainer Community Edition** pour administrer Docker via une interface web.  
À la fin du TP, tu sauras :

- Créer un volume pour les données de Portainer
- Lancer Portainer avec `docker run`
- Accéder à l’interface web via l’IP de ta machine
- Faire un premier tour de l’interface pour voir conteneurs, images, volumes, réseaux

> Tous les blocs de commandes sont copiables directement dans le terminal.

---

## Prérequis

- Docker installé et fonctionnel sur ta machine (voir le fichier d’installation).
- Accès à ta machine (par exemple VM Oracle Cloud) en SSH.
- Avoir déjà fait les TP précédents est un plus, mais pas obligatoire.

Vérifie que Docker fonctionne :

```bash
docker version
```

---

## Étape 1 – Créer un volume pour Portainer

Portainer a besoin de stocker ses données (utilisateurs, mot de passe admin, paramètres…).  
Nous allons créer un volume nommé `portainer_data`.

**Commande :**

```bash
docker volume create portainer_data
```

**Vérifier :**

```bash
docker volume ls
```

Tu dois voir une ligne avec `portainer_data`.

---

## Étape 2 – Lancer le conteneur Portainer

Nous allons utiliser l’image officielle `portainer/portainer-ce` (Community Edition).

- Conteneur : `portainer`
- Image : `portainer/portainer-ce:latest`
- Volume : `portainer_data` monté sur `/data`
- Accès au socket Docker : `/var/run/docker.sock`
- Port externe : `9443` (HTTPS)

**Commande :**

```bash
docker run -d \
  --name portainer \
  -p 9443:9443 \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

**Explications :**

- `-p 9443:9443` : expose l’interface web sécurisée (HTTPS) de Portainer sur le port 9443 de ta machine.
- `--restart=always` : redémarre Portainer automatiquement au reboot de la machine.
- `-v /var/run/docker.sock:/var/run/docker.sock` : donne à Portainer accès à ton moteur Docker local.
- `-v portainer_data:/data` : stocke la configuration de Portainer dans un volume persistant.

**Vérifier que le conteneur tourne :**

```bash
docker ps
```

Tu dois voir une ligne `portainer/portainer-ce:latest` avec le nom `portainer`.

---

## Étape 3 – Récupérer l’IP de ta machine

Pour accéder à Portainer depuis ton navigateur, tu as besoin de l’IP publique de ta VM.

Sur Oracle Cloud (ou autre fournisseur), tu peux trouver :

- soit l’IP publique dans la console web du fournisseur,
- soit en ligne de commande, par exemple :

```bash
curl ifconfig.me
```

Note cette IP, nous l’appellerons `IP_PUBLIC`.

> N’oublie pas d’ouvrir le port **9443** dans les règles de sécurité (firewall / security list / security group) de ta VM si nécessaire.

---

## Étape 4 – Premier accès à l’interface Portainer

Dans ton navigateur (sur ton PC), ouvre l’URL :

```text
https://IP_PUBLIC:9443
```

Exemples :

- Si ton IP est `1.2.3.4` → `https://1.2.3.4:9443`

Il est possible que ton navigateur affiche un **avertissement de certificat non sécurisé** (certificat auto-signé).  
Accepte l’exception de sécurité pour continuer (pour un environnement de test, c’est acceptable).

---

## Étape 5 – Création du compte administrateur Portainer

Lors du premier accès, Portainer te demande de créer un utilisateur **admin**.

1. Choisis un **nom d’utilisateur** (par défaut `admin`).
2. Choisis un **mot de passe fort** (note-le !).
3. Valide la création du compte.

Ensuite, Portainer te demandera quel type d’environnement tu veux gérer.

- Choisis **Docker local** (ou "Get Started" / "Local environment").
- Portainer se connecte à ton moteur Docker via `/var/run/docker.sock`.

Tu arrives maintenant sur le tableau de bord (Dashboard) de ton environnement Docker local.

---

## Étape 6 – Découvrir l’interface Portainer

Voici quelques éléments à explorer avec tes étudiants :

### 6.1 – Les conteneurs

Menu **Containers** :

- Tu vois la liste des conteneurs en cours d’exécution ou arrêtés.
- Tu peux **démarrer**, **arrêter**, **redémarrer** ou **supprimer** un conteneur.
- Tu peux voir les **logs** et les **détails** (ports, volumes, variables d’environnement, etc.).

### 6.2 – Les images

Menu **Images** :

- Liste les images présentes sur la machine.
- Permet de **télécharger (pull)** de nouvelles images depuis Docker Hub.
- Permet de **supprimer** les images inutiles.

### 6.3 – Les volumes

Menu **Volumes** :

- Liste les volumes Docker, par exemple `portainer_data`, `tp1-mysql-data`, etc.
- Permet de visualiser et de supprimer des volumes (attention à la perte de données).

### 6.4 – Les réseaux

Menu **Networks** :

- Liste les réseaux Docker (`bridge`, `host`, `tp1-network`, `tp2-net-a`, `tp2-net-b`, ...).
- Permet d’inspecter quels conteneurs sont connectés à quel réseau.

> Exercice possible :
> 
> - Lancer les TP1 et TP2 (MySQL + phpMyAdmin).
> - Revenir dans Portainer et observer les conteneurs, volumes et réseaux créés.

---

## Étape 7 – Redémarrage automatique de Portainer

Grâce à l’option `--restart=always`, Portainer se relance automatiquement au redémarrage de la machine.

Tu peux tester :

1. Redémarrer la VM (ou simplement arrêter puis démarrer le conteneur).
2. Vérifier :

```bash
docker ps
```

3. Revenir sur :

```text
https://IP_PUBLIC:9443
```

Portainer doit être de nouveau accessible, avec le même compte admin.

---

## Étape 8 – Arrêter ou supprimer Portainer (optionnel)

Si tu veux **juste arrêter** Portainer temporairement :

```bash
docker stop portainer
```

Pour le **relancer** :

```bash
docker start portainer
```

Si tu veux **tout supprimer** (contenteur + volume + image) :

```bash
docker stop portainer
```

```bash
docker rm portainer
```

```bash
docker volume rm portainer_data
```

Tu peux ensuite (optionnel) supprimer l’image si tu veux libérer de l’espace :

```bash
docker images
```

Repère la ligne `portainer/portainer-ce` puis :

```bash
docker rmi portainer/portainer-ce:latest
```

---

## Récapitulatif du TP3

Dans ce TP, tu as appris à :

- Créer un volume Docker pour stocker les données de Portainer.
- Lancer Portainer avec `docker run` et les bons volumes/ports.
- Accéder à l’interface web de Portainer via `https://IP_PUBLIC:9443`.
- Utiliser Portainer pour voir conteneurs, images, volumes et réseaux.

Portainer sera très utile pour la suite, notamment pour :

- Visualiser ce qui se passe quand on déploie plusieurs services.
- Préparer la transition vers **Docker Swarm** et ensuite **Kubernetes**.
