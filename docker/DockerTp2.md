# TP2 – Isolation de services avec plusieurs réseaux Docker

**Objectif du TP :**  
Créer **deux environnements séparés** :

- Environnement A : `mysql-a` + `phpmyadmin-a` sur le réseau `tp2-net-a`
- Environnement B : `mysql-b` + `phpmyadmin-b` sur le réseau `tp2-net-b`

Nous allons :

- Créer **deux réseaux distincts**
- Créer **quatre conteneurs** (2 MySQL, 2 phpMyAdmin)
- Ouvrir des ports différents pour chaque phpMyAdmin
- Vérifier que **les environnements sont isolés** (on ne voit pas la base de l’autre)
- Puis **tout supprimer proprement**

---

## Étape 0 – Préparation

Comme dans le TP1, vérifie que Docker fonctionne :

```bash
docker version
```

---

## Étape 1 – Créer deux réseaux séparés

Nous créons deux réseaux :

- `tp2-net-a` pour l’environnement A
- `tp2-net-b` pour l’environnement B

**Commande :**

```bash
docker network create tp2-net-a
docker network create tp2-net-b
```

**Vérifier :**

```bash
docker network ls
```

Tu dois voir `tp2-net-a` et `tp2-net-b`.

---

## Étape 2 – Créer les volumes pour chaque base de données

Nous voulons que chaque base de données ait ses propres fichiers de données.

- Volume A : `tp2-mysql-a-data`
- Volume B : `tp2-mysql-b-data`

**Commande :**

```bash
docker volume create tp2-mysql-a-data
docker volume create tp2-mysql-b-data
```

**Vérifier :**

```bash
docker volume ls
```

---

## Étape 3 – Lancer MySQL pour chaque environnement

### 3.1 – MySQL A

```bash
docker run -d \
  --name tp2-mysql-a \
  --network tp2-net-a \
  -e MYSQL_ROOT_PASSWORD=root_a \
  -e MYSQL_DATABASE=db_a \
  -v tp2-mysql-a-data:/var/lib/mysql \
  mysql:8.0
```

### 3.2 – MySQL B

```bash
docker run -d \
  --name tp2-mysql-b \
  --network tp2-net-b \
  -e MYSQL_ROOT_PASSWORD=root_b \
  -e MYSQL_DATABASE=db_b \
  -v tp2-mysql-b-data:/var/lib/mysql \
  mysql:8.0
```

**Vérifier :**

```bash
docker ps
```

Tu dois voir `tp2-mysql-a` et `tp2-mysql-b` en cours d’exécution.

---

## Étape 4 – Lancer phpMyAdmin pour chaque environnement

### 4.1 – phpMyAdmin A

- Nom : `tp2-phpmyadmin-a`
- Réseau : `tp2-net-a`
- MySQL cible : `tp2-mysql-a`
- Port externe : `8081` (accès : `http://IP_PUBLIC:8081`)

```bash
docker run -d \
  --name tp2-phpmyadmin-a \
  --network tp2-net-a \
  -e PMA_HOST=tp2-mysql-a \
  -e PMA_USER=root \
  -e PMA_PASSWORD=root_a \
  -p 8081:80 \
  phpmyadmin/phpmyadmin:latest
```

### 4.2 – phpMyAdmin B

- Nom : `tp2-phpmyadmin-b`
- Réseau : `tp2-net-b`
- MySQL cible : `tp2-mysql-b`
- Port externe : `8082` (accès : `http://IP_PUBLIC:8082`)

```bash
docker run -d \
  --name tp2-phpmyadmin-b \
  --network tp2-net-b \
  -e PMA_HOST=tp2-mysql-b \
  -e PMA_USER=root \
  -e PMA_PASSWORD=root_b \
  -p 8082:80 \
  phpmyadmin/phpmyadmin:latest
```

**Vérifier :**

```bash
docker ps
```

Tu dois voir 4 conteneurs :

- `tp2-mysql-a`
- `tp2-phpmyadmin-a`
- `tp2-mysql-b`
- `tp2-phpmyadmin-b`

---

## Étape 5 – Tester l’accès à chaque environnement

### 5.1 – Accès à A

Dans ton navigateur :

```text
http://IP_PUBLIC_DE_TA_VM:8081
```

Connexion :

- User : `root`
- Mot de passe : `root_a`

Tu dois voir la base `db_a`.

### 5.2 – Accès à B

Dans ton navigateur :

```text
http://IP_PUBLIC_DE_TA_VM:8082
```

Connexion :

- User : `root`
- Mot de passe : `root_b`

Tu dois voir la base `db_b`.

---

## Étape 6 – Vérifier l’isolement réseau

### 6.1 – Inspecter les réseaux

```bash
docker network inspect tp2-net-a
docker network inspect tp2-net-b
```

Observe dans la section **Containers** :

- `tp2-net-a` contient seulement `tp2-mysql-a` et `tp2-phpmyadmin-a`
- `tp2-net-b` contient seulement `tp2-mysql-b` et `tp2-phpmyadmin-b`

### 6.2 – Tester la communication interdite

Depuis `tp2-phpmyadmin-a`, on essaye d’atteindre le MySQL B :

```bash
docker exec -it tp2-phpmyadmin-a ping -c 3 tp2-mysql-b
```

Normalement, cela **ne doit pas** répondre (pas de résolution / pas de route), car les deux conteneurs ne partagent **aucun réseau**.

De même, depuis `tp2-phpmyadmin-b` :

```bash
docker exec -it tp2-phpmyadmin-b ping -c 3 tp2-mysql-a
```

Là aussi, la communication ne devrait pas fonctionner.

> Idée pédagogique :  
> Demande aux étudiants de décrire pourquoi les deux environnements sont isolés
> en se basant sur les réseaux Docker.

---

## Étape 7 – Créer des tables différentes dans chaque environnement

Pour bien montrer l’isolement logique et réseau :

### 7.1 – Dans l’environnement A

Depuis phpMyAdmin A (`http://IP_PUBLIC_DE_TA_VM:8081`), exécute la requête SQL :

```sql
CREATE TABLE users_a (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);
INSERT INTO users_a (name) VALUES ('Alice A'), ('Bob A');
```

### 7.2 – Dans l’environnement B

Depuis phpMyAdmin B (`http://IP_PUBLIC_DE_TA_VM:8082`), exécute :

```sql
CREATE TABLE users_b (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);
INSERT INTO users_b (name) VALUES ('Charlie B'), ('Diana B');
```

Observe que :

- Dans A, tu as seulement `users_a`.
- Dans B, tu as seulement `users_b`.
- Chacun a sa propre base (`db_a`, `db_b`) et son propre réseau.

---

## Étape 8 – Nettoyer tout l’environnement

Quand les tests sont terminés, nous allons :

1. Arrêter les 4 conteneurs.
2. Les supprimer.
3. Supprimer les volumes.
4. Supprimer les réseaux.

**Arrêter les conteneurs :**

```bash
docker stop tp2-phpmyadmin-a tp2-phpmyadmin-b tp2-mysql-a tp2-mysql-b
```

**Supprimer les conteneurs :**

```bash
docker rm tp2-phpmyadmin-a tp2-phpmyadmin-b tp2-mysql-a tp2-mysql-b
```

**Supprimer les volumes :**

```bash
docker volume rm tp2-mysql-a-data tp2-mysql-b-data
```

**Supprimer les réseaux :**

```bash
docker network rm tp2-net-a tp2-net-b
```

---

## Récapitulatif du TP2

Dans ce TP, tu as appris à :

- Créer **plusieurs réseaux Docker** indépendants.
- Lancer **plusieurs paires de services** (MySQL + phpMyAdmin).
- **Exposer** chaque service sur un port différent.
- Vérifier l'**isolement réseau** entre deux environnements.
- Nettoyer proprement **conteneurs**, **volumes** et **réseaux**.

Ces notions sont essentielles pour comprendre comment Docker permet d’isoler
et d’organiser des applications complexes avant de passer à **Docker Swarm**
ou **Kubernetes**.
