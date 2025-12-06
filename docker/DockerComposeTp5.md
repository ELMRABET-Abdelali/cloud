# TP5 – Découvrir YAML avec Docker Compose et Docker Swarm (pont vers Kubernetes)

**Objectif du TP :**  
Reprendre l’architecture du **TP4** (MySQL + phpMyAdmin sur 2 nœuds) mais cette fois :

- D’abord avec **Docker Compose** en mode local (sans Swarm) pour lancer les deux services sur une seule machine.
- Puis avec **Docker Swarm** en utilisant un **fichier YAML de stack** basé sur le même Compose.
- Et enfin faire le lien avec l’utilisation de YAML dans **Kubernetes**.

Tu vas apprendre à :

- Lire et écrire un fichier **YAML** de type `docker-compose.yml`.
- Lancer des services avec `docker compose up` (mode classique).
- Utiliser **le même fichier YAML (adapté)** pour déployer une stack Swarm avec `docker stack deploy`.
- Comprendre comment ces concepts se retrouvent ensuite dans les manifests YAML Kubernetes.

---

## 0. Prérequis

- Docker installé et fonctionnel sur ta machine (par exemple `serveurA`).
- Docker Swarm initialisé pour la partie stack (TP4) :
  - `serveurA` : manager
  - `serveurB` : worker
- Connaître l’architecture MySQL + phpMyAdmin des TP1/TP2/TP4.

Vérifie :

```bash
docker version
```

Pour la partie Swarm (sur `serveurA`) :

```bash
docker info | grep Swarm
```

Tu dois voir `Swarm: active`.

---

## 1. Rappel rapide sur YAML

YAML est un format texte utilisé pour décrire des configurations.

Principes :

- Indentation **par espaces** (pas de tabulations).
- Clés/valeurs sous forme `clé: valeur`.
- Listes avec `-`.

Exemple simple :

```yaml
service:
  nom: "demo"
  ports:
    - 80
    - 443
```

Nous allons maintenant écrire un `docker-compose.yml` pour MySQL + phpMyAdmin.

---

## 2. Docker Compose : lancer MySQL + phpMyAdmin en local

Dans cette première partie, on utilise **Docker Compose** (sans Swarm) pour lancer les deux conteneurs sur une seule machine (par exemple `serveurA`).

### 2.1 – Créer le projet Compose

Sur `serveurA` :

```bash
mkdir -p ~/tp5-compose
cd ~/tp5-compose
```

Crée un fichier `docker-compose.yml` :

```yaml
version: "3.8"

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: "root_tp5"
      MYSQL_DATABASE: "tp5db"
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - tp5-net

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    environment:
      PMA_HOST: "mysql"
      PMA_USER: "root"
      PMA_PASSWORD: "root_tp5"
    ports:
      - "8080:80"  # accès depuis l'extérieur
    networks:
      - tp5-net

networks:
  tp5-net:
    driver: bridge

volumes:
  mysql-data:
```

Commentaires :

- `services.mysql` et `services.phpmyadmin` sont les deux conteneurs.
- Les deux **partagent le même réseau** `tp5-net` (driver `bridge`).
- MySQL utilise un volume nommé `mysql-data`.
- phpMyAdmin expose le port `8080` de la machine vers le port `80` du conteneur.

### 2.2 – Lancer la stack en mode Compose

Toujours dans `~/tp5-compose` :

```bash
docker compose up -d
```

Vérifie :

```bash
docker ps
```

Tu dois voir :

- Un conteneur `tp5-compose-mysql-1` (nom similaire)
- Un conteneur `tp5-compose-phpmyadmin-1`

### 2.3 – Tester phpMyAdmin

Récupère l’IP publique de la machine :

```bash
curl ifconfig.me
```

Dans ton navigateur :

```text
http://IP_PUBLIC:8080
```

Connexion :

- Utilisateur : `root`
- Mot de passe : `root_tp5`

Tu dois voir la base `tp5db`.

### 2.4 – Arrêter et nettoyer (Compose)

Pour arrêter et supprimer les conteneurs :

```bash
cd ~/tp5-compose
docker compose down
```

Le volume `mysql-data` reste (persistance des données). Tu peux le lister :

```bash
docker volume ls
```

---

## 3. De Docker Compose à Docker Swarm : même YAML, autre commande

Docker Swarm peut lire un fichier **compatbile Compose v3** comme une **stack**.

Différences :

- Mode Compose :
  - Commande : `docker compose up`
  - Tout tourne sur **une seule machine**.
- Mode Swarm (stack) :
  - Commande : `docker stack deploy` avec `-c`.
  - Les services sont répartis sur plusieurs **nœuds** (manager + workers).

Nous allons adapter légèrement notre `docker-compose.yml` pour Swarm.

> Astuce : tu peux garder le même fichier et y ajouter des sections `deploy` qui ne sont prises en compte **que** par Swarm.

---

## 4. Adapter le YAML pour Swarm (déploiement multi-nœuds)

Sur `serveurA` (manager), crée un nouveau dossier :

```bash
mkdir -p ~/tp5-swarm
cd ~/tp5-swarm
```

Crée un fichier `docker-compose-swarm.yml` :

```yaml
version: "3.8"

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: "root_swarm"
      MYSQL_DATABASE: "swarmdb"
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - swarm-net
    deploy:
      placement:
        constraints:
          - node.role == manager

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    environment:
      PMA_HOST: "mysql"
      PMA_USER: "root"
      PMA_PASSWORD: "root_swarm"
    networks:
      - swarm-net
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.role == worker
    ports:
      - "8080:80"  # publié sur tout le cluster

networks:
  swarm-net:
    driver: overlay

volumes:
  mysql-data:
```

Points clés :

- `driver: overlay` : réseau multi-nœuds pour Swarm.
- `deploy.replicas` : nombre de réplicas gérés par Swarm.
- `deploy.placement.constraints` : où placer les tâches (manager/worker).
- Le port `8080` est exposé en ingress sur tous les nœuds.

---

## 5. Déployer la stack YAML sur Docker Swarm

Toujours sur `serveurA` :

```bash
cd ~/tp5-swarm
docker stack deploy -c docker-compose-swarm.yml tp5stack
```

Vérifie :

```bash
docker stack ls
```

```bash
docker stack services tp5stack
```

```bash
docker stack ps tp5stack
```

Tu dois voir :

- Un service `tp5stack_mysql` (réplica 1) sur le manager.
- Un service `tp5stack_phpmyadmin` avec `2/2` réplicas, planifiés sur les workers.

Teste dans le navigateur (IP du manager ou du worker) :

```text
http://IP_PUBLIC_A:8080
http://IP_PUBLIC_B:8080
```

Tu accèdes dans les deux cas à phpMyAdmin connecté à la base `swarmdb`.

---

## 6. Lien avec Kubernetes : même logique, API différente

Ce que tu viens de faire :

- **Décrire** une architecture (services, réseaux, volumes, placement) dans un fichier YAML.
- **Appliquer** cette description avec une commande (`docker compose up` ou `docker stack deploy`).

En Kubernetes, c’est la même philosophie :

- Tu écris des fichiers YAML (souvent plusieurs) :
  - `Deployment` pour décrire les Pods et réplicas.
  - `Service` pour exposer les Pods.
  - `PersistentVolume` et `PersistentVolumeClaim` pour le stockage.
  - `Namespace`, `Ingress`, etc.
- Tu appliques avec :

```bash
kubectl apply -f mon-fichier.yaml
```

- Kubernetes lit ces fichiers YAML via son **API server** et crée les objets demandés.

Comparaison rapide :

- **Compose/Swarm** :
  - Fichier YAML unique `docker-compose*.yml` avec `services`, `networks`, `volumes`.
  - Commandes : `docker compose up`, `docker stack deploy`.
- **Kubernetes** :
  - Plusieurs fichiers YAML : `mysql-deployment.yaml`, `phpmyadmin-service.yaml`, `namespace.yaml`, etc.
  - Commande : `kubectl apply -f ...`.

> Idée pédagogique : montrer un `service` décrit dans Compose et un `Deployment` + `Service` K8s pour la même appli.

---

## 7. Nettoyage des environnements TP5

### 7.1 – Nettoyer la stack Swarm

Sur `serveurA` :

```bash
cd ~/tp5-swarm
docker stack rm tp5stack
```

Attends quelques instants, puis vérifie :

```bash
docker stack ls
```

Les services doivent avoir disparu.

Tu peux également supprimer le volume créé :

```bash
docker volume ls
# repère tp5stack_mysql-data
docker volume rm tp5stack_mysql-data
```

### 7.2 – Nettoyer le projet Compose local

Sur la machine où tu as lancé Compose :

```bash
cd ~/tp5-compose
docker compose down
# et éventuellement :
docker volume rm tp5-compose_mysql-data 2>/dev/null || true
```

---

## 8. Récapitulatif du TP5

Dans ce TP, tu as appris à :

- Écrire un fichier **`docker-compose.yml`** pour lancer MySQL + phpMyAdmin en local avec `docker compose up`.
- Adapter ce même fichier vers une **stack Swarm** (`docker-compose-swarm.yml`) et le déployer avec `docker stack deploy`.
- Comprendre que YAML est un format de description commun à :
  - Docker Compose (local, mono-hôte),
  - Docker Swarm (multi-nœuds, via stack),
  - Kubernetes (manifests d’objets).
- Faire le lien conceptuel entre :
  - `services` + `deploy` dans le YAML Swarm,
  - et `Deployment` + `Service` + `PV/PVC` dans Kubernetes (voir TP6/TP7).

Ce TP sert de **pont** entre le monde Docker (Compose/Swarm) et le monde Kubernetes, tout en te rendant à l’aise avec les fichiers YAML qui sont au cœur des deux univers.
