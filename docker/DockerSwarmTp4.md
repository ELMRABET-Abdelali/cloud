# TP4 – Premier cluster Docker Swarm (2 serveurs, MySQL partagé, phpMyAdmin dupliqué)

**Objectif du TP :**  
Mettre en place un **cluster Docker Swarm** avec deux machines :

- `serveurA` : manager Swarm + service MySQL (base de données)
- `serveurB` : worker Swarm
- Un service **phpMyAdmin** répliqué sur le cluster
- Les deux instances phpMyAdmin accèdent **à la même base MySQL** située sur `serveurA`

Tu vas apprendre à :

- Initialiser un cluster **Docker Swarm**
- Joindre un second nœud au cluster
- Créer un **réseau overlay** pour les services
- Déployer MySQL comme service Swarm
- Déployer phpMyAdmin en **réplicas** sur plusieurs nœuds
- Vérifier que les deux phpMyAdmin accèdent à la même base MySQL

> Important : dans ce TP, certaines commandes sont à exécuter sur `serveurA`, d’autres sur `serveurB`. C’est indiqué clairement à chaque fois.

---

## 0. Prérequis

- Deux machines Linux (par exemple Oracle Cloud) :
  - `serveurA` (futur **manager** Swarm)
  - `serveurB` (futur **worker** Swarm)
- Docker installé et fonctionnel sur les deux serveurs.
- Accès SSH aux deux serveurs (par exemple avec `ssh ubuntu@IP` ou `ssh opc@IP`).
- Ports ouverts dans les règles de sécurité (entre `serveurA` et `serveurB`) :
  - 2377/TCP (gestion Swarm)
  - 7946/TCP et 7946/UDP (communication interne)
  - 4789/UDP (overlay network)
- Port externe choisi pour phpMyAdmin, par exemple **8080**.

Sur chaque serveur, vérifie Docker :

```bash
docker version
```

---

## 1. Initialiser Docker Swarm sur `serveurA`

> Toutes les commandes de cette section sont à exécuter sur **serveurA**.

Commence par récupérer l’adresse IP privée de `serveurA` (celle qui est joignable par `serveurB`). Par exemple :

```bash
ip a
```

Repère une IP du type `10.x.x.x` ou `192.168.x.x`.  
Nous l’appellerons `IP_PRIVEE_A`.

### 1.1 – Initialiser le Swarm

```bash
docker swarm init --advertise-addr IP_PRIVEE_A
```

Exemple :

```bash
docker swarm init --advertise-addr 10.0.0.5
```

En sortie, Docker t’affiche une commande `docker swarm join ...`.  
**Copie-la**, elle sera utilisée sur `serveurB`.

Exemple de sortie :

```text
Swarm initialized: current node (xxxx) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-... 10.0.0.5:2377
```

Tu peux vérifier le statut du Swarm :

```bash
docker node ls
```

Tu dois voir `serveurA` en tant que `Leader` (manager).

---

## 2. Joindre `serveurB` au Swarm

> Cette partie est à exécuter sur **serveurB**.

Sur `serveurB`, colle la commande `docker swarm join` fournie par `serveurA`. Par exemple :

```bash
docker swarm join --token SWMTKN-1-xxxxxxxxxxxxxxxx 10.0.0.5:2377
```

Si tout se passe bien, tu verras un message du style :

```text
This node joined a swarm as a worker.
```

Pour vérifier, retourne sur `serveurA` et tape :

```bash
docker node ls
```

Tu dois voir :

- `serveurA` : `Leader` (manager)
- `serveurB` : `Reachable` ou `Active` en tant que `Worker`

---

## 3. Créer un réseau overlay pour les services

> Cette partie est à exécuter sur **serveurA** (manager).

Nous allons créer un réseau Docker **overlay** pour que les services MySQL et phpMyAdmin puissent communiquer **entre les deux machines**.

```bash
docker network create \
  --driver overlay \
  --attachable \
  swarm-net
```

- `--driver overlay` : réseau multi-nœuds pour Swarm.
- `--attachable` : permet à d’autres conteneurs de s’y connecter si besoin.

Vérifie :

```bash
docker network ls
```

Tu dois voir une ligne `swarm-net` avec le driver `overlay`.

---

## 4. Déployer MySQL comme service Swarm (sur `serveurA`)

L’idée :

- Service MySQL nommé `mysql-svc`
- Attaché au réseau `swarm-net`
- Volume local sur `serveurA` pour persister les données
- Une base `swarmdb` avec mot de passe root

> MySQL sera planifié par Swarm, mais dans un TP débutant, on peut conseiller de créer le volume sur `serveurA` uniquement et accepter que le service s’exécute sur ce nœud (à préciser en explication pédagogique).

### 4.1 – Créer un volume pour MySQL (sur `serveurA`)

Sur `serveurA` :

```bash
docker volume create swarm-mysql-data
```

### 4.2 – Créer le service MySQL

Toujours sur `serveurA` :

```bash
docker service create \
  --name mysql-svc \
  --network swarm-net \
  --replicas 1 \
  --mount type=volume,source=swarm-mysql-data,target=/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=root_swarm \
  -e MYSQL_DATABASE=swarmdb \
  mysql:8.0
```

Explications :

- `docker service create` : crée un service Swarm (pas un simple conteneur).
- `--replicas 1` : une seule instance MySQL (une base centrale).
- `--mount type=volume,...` : attache le volume `swarm-mysql-data` à `/var/lib/mysql`.
- `MYSQL_DATABASE=swarmdb` : crée la base `swarmdb` automatiquement.

### 4.3 – Vérifier l’état du service

Toujours sur `serveurA` :

```bash
docker service ls
```

Puis :

```bash
docker service ps mysql-svc
```

Tu dois voir une tâche `Running` sur un des nœuds (idéalement `serveurA`).

---

## 5. Déployer phpMyAdmin en service répliqué

Nous allons maintenant déployer un service `phpmyadmin-svc` :

- Connecté au même réseau `swarm-net`
- Avec plusieurs réplicas (par ex. 2)
- Exposé sur le port externe `8080`
- `PMA_HOST` pointe vers **le nom du service MySQL** : `mysql-svc`

> Commandes à exécuter sur **serveurA** (manager).

### 5.1 – Créer le service phpMyAdmin

```bash
docker service create \
  --name phpmyadmin-svc \
  --network swarm-net \
  --replicas 2 \
  -e PMA_HOST=mysql-svc \
  -e PMA_USER=root \
  -e PMA_PASSWORD=root_swarm \
  -p 8080:80 \
  phpmyadmin/phpmyadmin:latest
```

Explications :

- `--replicas 2` : deux instances phpMyAdmin réparties dans le cluster (par exemple une sur `serveurA`, une sur `serveurB`).
- `-p 8080:80` : publie le service sur le port 8080 du cluster (ingress Swarm).  
  Tu pourras y accéder via l’IP de `serveurA` **ou** de `serveurB`.
- `PMA_HOST=mysql-svc` : phpMyAdmin se connecte au service MySQL grâce à la résolution de nom Swarm.

### 5.2 – Vérifier l’état du service phpMyAdmin

Toujours sur `serveurA` :

```bash
docker service ls
```

Tu dois voir `phpmyadmin-svc` avec `2/2` réplicas.

Pour voir sur quels nœuds tournent les tâches :

```bash
docker service ps phpmyadmin-svc
```

Tu devrais voir les 2 tâches réparties entre `serveurA` et `serveurB` (selon le scheduler).

---

## 6. Accéder à phpMyAdmin depuis le navigateur

Nous allons utiliser l’IP publique de `serveurA` ou `serveurB`.  
Grâce à l’ingress Swarm, le port `8080` est routé vers les réplicas du service.

### 6.1 – Récupérer les IP publiques

Sur chaque serveur, tu peux faire :

```bash
curl ifconfig.me
```

Supposons :

- IP publique de `serveurA` : `IP_PUBLIC_A`
- IP publique de `serveurB` : `IP_PUBLIC_B`

### 6.2 – Tester l’accès

Dans ton navigateur :

- `http://IP_PUBLIC_A:8080`
- `http://IP_PUBLIC_B:8080`

Dans les deux cas, tu dois voir l’interface **phpMyAdmin**.

Identifiants :

- Utilisateur : `root`
- Mot de passe : `root_swarm`

La base par défaut : `swarmdb`.

> Idée pédagogique :
> 
> - Demande aux étudiants de créer une table et quelques données via phpMyAdmin.
> - Rafraîchis la page plusieurs fois et/ou accède via l’autre IP (A ou B).
> - Montre que **peu importe l’instance phpMyAdmin utilisée**, les données affichées sont les mêmes, car toutes pointent vers **le même MySQL**.

---

## 7. Vérifier et explorer le cluster Swarm

Depuis `serveurA` (manager) :

### 7.1 – Voir les nœuds

```bash
docker node ls
```

### 7.2 – Voir les services

```bash
docker service ls
```

### 7.3 – Voir le détail d’un service

```bash
docker service ps mysql-svc

docker service ps phpmyadmin-svc
```

Observe :

- Sur quels nœuds tournent les tâches.
- Leur statut (`Running`, `Preparing`, etc.).

### 7.4 – Scanner via Portainer (si présent)

Si tu as installé Portainer sur `serveurA` (TP3) et que tu l’as attaché au Swarm :

- Connecte-toi à Portainer.
- Sélectionne ton environnement **Swarm**.
- Dans l’interface, explore :
  - les **Nodes**,
  - les **Services**,
  - les **Tasks**,
  - le réseau `swarm-net`.

---

## 8. Nettoyage du TP

Quand tu as terminé le TP et que tu veux tout supprimer :

> Nettoyage à faire depuis **serveurA** (manager).

### 8.1 – Supprimer les services

```bash
docker service rm phpmyadmin-svc
```

```bash
docker service rm mysql-svc
```

### 8.2 – Supprimer le réseau overlay

```bash
docker network rm swarm-net
```

### 8.3 – Supprimer le volume MySQL (sur `serveurA`)

```bash
docker volume rm swarm-mysql-data
```

### 8.4 – Sortir du Swarm

Sur `serveurB` (worker) :

```bash
docker swarm leave
```

Sur `serveurA` (manager) :

```bash
docker swarm leave --force
```

Vérifie ensuite :

```bash
docker node ls
```

Cette commande doit échouer (normal), car le Swarm n’existe plus.

---

## 9. Récapitulatif du TP4

Dans ce TP, tu as appris à :

- Initialiser un **cluster Docker Swarm** avec deux serveurs.
- Ajouter un nœud worker au cluster.
- Créer un **réseau overlay** pour les services distribués.
- Déployer MySQL comme **service Swarm** avec stockage persistant.
- Déployer phpMyAdmin en **service répliqué** accessible via les deux serveurs.
- Vérifier que plusieurs instances phpMyAdmin accèdent à **la même base de données MySQL**.
- Nettoyer proprement services, réseaux, volumes et Swarm.

Ce TP introduit les concepts de base de Swarm (nodes, services, tasks, overlay network) et prépare la suite pour des déploiements plus complexes ou une transition vers **Kubernetes**.
