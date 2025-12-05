# TP1 – Découvrir Docker avec MySQL et phpMyAdmin

**Objectif du TP :**  
Installer une base de données MySQL et une interface phpMyAdmin avec Docker.  
À la fin du TP, tu auras vu :

- Comment créer un **réseau Docker**
- Comment créer des **volumes** pour les données
- Comment lancer des **conteneurs** à partir d’**images**
- Comment **exposer** des ports pour accéder à un service depuis l’extérieur
- Comment **lister** et **inspecter** images, conteneurs, réseaux, volumes

> Tous les blocs de commandes sont pensés pour être copiés/collés tels quels.
> Remplace seulement les mots de passe par les tiens si nécessaire.

---

## Prérequis

- Docker installé et fonctionnel (voir `Installation manuelle de Docker sur Ubuntu`).
- Une machine Linux (par exemple Oracle Cloud) avec un accès terminal.

Vérifie que Docker fonctionne :

```bash
docker version
docker run --rm hello-world
```

---

## Étape 1 – Créer un réseau Docker pour notre application

Nous allons créer un réseau nommé `tp1-network`.  
Tous les conteneurs de MySQL et phpMyAdmin seront connectés dessus.

**Commande :**

```bash
docker network create tp1-network
```

**Vérifier :**

```bash
docker network ls
```

Tu dois voir une ligne contenant `tp1-network`.

---

## Étape 2 – Créer des volumes pour persister les données

Nous allons créer deux volumes :

- `tp1-mysql-data` : stockera les données MySQL.
- `tp1-phpmyadmin-config` : optionnel, pour garder d’éventuelles configs.

**Commande :**

```bash
docker volume create tp1-mysql-data
docker volume create tp1-phpmyadmin-config
```

**Vérifier :**

```bash
docker volume ls
```

Tu dois voir `tp1-mysql-data` et `tp1-phpmyadmin-config`.

---

## Étape 3 – Lancer le conteneur MySQL

Nous allons lancer un conteneur MySQL :

- Nom du conteneur : `tp1-mysql`
- Image : `mysql:8.0` (version 8 de MySQL)
- Réseau : `tp1-network`
- Volume : `tp1-mysql-data` monté sur `/var/lib/mysql`
- Mot de passe root : `root_password` (à changer si tu veux)

**Commande :**

```bash
docker run -d \
  --name tp1-mysql \
  --network tp1-network \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_DATABASE=tp1db \
  -v tp1-mysql-data:/var/lib/mysql \
  mysql:8.0
```

**Explications rapides :**

- `-d` : démarre le conteneur en arrière-plan (détaché).
- `--name tp1-mysql` : donne un nom au conteneur.
- `--network tp1-network` : connecte le conteneur au réseau créé.
- `-e` : définit des variables d’environnement dans le conteneur.
- `-v volume:chemin` : monte un volume dans un répertoire du conteneur.

**Vérifier que le conteneur tourne :**

```bash
docker ps
```

Tu dois voir `tp1-mysql` dans la liste.

---

## Étape 4 – Lancer le conteneur phpMyAdmin

Maintenant, nous allons lancer phpMyAdmin pour administrer MySQL via le navigateur.

- Nom du conteneur : `tp1-phpmyadmin`
- Image : `phpmyadmin/phpmyadmin:latest`
- Réseau : `tp1-network`
- Port externe : `8080` (tu accèderas à http://IP_PUBLIC:8080)
- Variable `PMA_HOST` : nom du conteneur MySQL (`tp1-mysql`)

**Commande :**

```bash
docker run -d \
  --name tp1-phpmyadmin \
  --network tp1-network \
  -e PMA_HOST=tp1-mysql \
  -e PMA_USER=root \
  -e PMA_PASSWORD=root_password \
  -p 8080:80 \
  -v tp1-phpmyadmin-config:/etc/phpmyadmin \
  phpmyadmin/phpmyadmin:latest
```

**Explications :**

- `-p 8080:80` : mappe le port 80 du conteneur sur le port 8080 de la machine.
- `PMA_HOST=tp1-mysql` : indique à phpMyAdmin où est le serveur MySQL (par nom de conteneur).
- `PMA_USER` et `PMA_PASSWORD` : identifiants utilisés par défaut pour se connecter.

**Vérifier :**

```bash
docker ps
```

Tu dois voir `tp1-mysql` et `tp1-phpmyadmin` en cours d’exécution.

---

## Étape 5 – Accéder à phpMyAdmin depuis l’extérieur

Depuis ton navigateur (ton PC), ouvre l’URL :

```text
http://IP_PUBLIC_DE_TA_VM:8080
```

- Identifiant : `root`
- Mot de passe : `root_password` (ou celui que tu as choisi)

Tu dois voir l’interface phpMyAdmin, et la base `tp1db` créée à l’étape MySQL.

---

## Étape 6 – Découvrir les ressources Docker (images, volumes, conteneurs, réseaux)

### 6.1 – Lister les images

```bash
docker images
```

Tu dois voir au moins les images :

- `mysql:8.0`
- `phpmyadmin/phpmyadmin`

### 6.2 – Lister les conteneurs

```bash
docker ps          # conteneurs en cours d'exécution
docker ps -a       # tous les conteneurs, même arrêtés
```

### 6.3 – Lister les volumes

```bash
docker volume ls
```

Tu dois voir `tp1-mysql-data` et `tp1-phpmyadmin-config`.

### 6.4 – Lister les réseaux

```bash
docker network ls
```

Tu dois voir le réseau `tp1-network`.

### 6.5 – Inspecter un réseau

```bash
docker network inspect tp1-network
```

Observe les conteneurs connectés à ce réseau.

---

## Étape 7 – Tester rapidement MySQL depuis le conteneur phpMyAdmin

Tu peux aussi te connecter dans le conteneur phpMyAdmin pour tester la résolution du nom `tp1-mysql`.

```bash
docker exec -it tp1-phpmyadmin ping -c 3 tp1-mysql
```

Le ping doit répondre, car ils sont sur le même réseau Docker.

---

## Étape 8 – Arrêter et relancer les conteneurs

**Arrêter :**

```bash
docker stop tp1-phpmyadmin
docker stop tp1-mysql
```

**Relancer :**

```bash
docker start tp1-mysql
docker start tp1-phpmyadmin
```

Vérifie que les données MySQL sont toujours là (grâce au volume `tp1-mysql-data`).

---

## Étape 9 – Nettoyage (optionnel)

Si tu veux tout supprimer (conteneurs, volumes, réseau) :

```bash
docker stop tp1-phpmyadmin tp1-mysql
docker rm tp1-phpmyadmin tp1-mysql
docker volume rm tp1-mysql-data tp1-phpmyadmin-config
docker network rm tp1-network
```

---

## Récapitulatif du TP1

Dans ce TP, tu as appris à :

- Créer un **réseau Docker** (`docker network create`).
- Créer des **volumes** (`docker volume create`).
- Lancer des **conteneurs** à partir d’**images** (`docker run`).
- **Exposer** un service vers l’extérieur (`-p 8080:80`).
- Lister et inspecter **images, conteneurs, volumes, réseaux**.

Tu es maintenant prêt pour le TP2 où nous allons gérer **plusieurs réseaux** et **isoler** deux environnements MySQL + phpMyAdmin.
