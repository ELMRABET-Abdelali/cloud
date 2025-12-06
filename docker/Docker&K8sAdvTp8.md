# TP8 – Haute disponibilité WordPress sur Kubernetes (RBAC, NFS, MySQL répliqué)

**Objectif du TP :**  
Mettre en place, sur le cluster Kubernetes (TP6/TP7), un **scénario complet de haute disponibilité** :

- Un **namespace sécurisé** avec **RBAC** dédié au projet.
- Un **stockage NFS partagé** utilisé sur les **deux workers** pour les fichiers WordPress.
- Une base **MySQL** en **mode répliqué** (StatefulSet avec plusieurs Pods) pour limiter les points uniques de panne.
- Un **phpMyAdmin** et un **WordPress** répliqués (plusieurs Pods) pouvant tourner sur n’importe quel worker.
- L’ensemble accessible depuis l’extérieur, avec des mots de passe configurés et des Services adaptés.

L’objectif pédagogique : montrer un exemple réaliste de **haute disponibilité** applicative dans Kubernetes, tout en réutilisant Docker comme runtime de conteneurs.

---

## 0. Architecture cible

Nous allons construire l’architecture suivante :

- **Cluster K8s** :
  - `master` : nœud de contrôle
  - `serveurA` : worker node 1
  - `serveurB` : worker node 2
- **Namespace** : `tp8-ha-wordpress`
- **RBAC** : ServiceAccount + Role + RoleBinding limités à ce namespace.
- **Stockage NFS** :
  - Serveur NFS externe (ou un des nœuds) : `IP_NFS`
  - Export `/srv/nfs/wp-tp8` monté dans le cluster via PV/PVC `ReadWriteMany`.
- **MySQL** :
  - StatefulSet `mysql-tp8` avec 2 réplicas (master/replica simplifiés)
  - Stockage persistant par Pod (PV/PVC `ReadWriteOnce`).
- **WordPress** :
  - Deployment `wordpress-tp8` avec 2 Pods (répartis sur les 2 workers).
  - Volume NFS partagé pour `/var/www/html/wp-content`.
- **phpMyAdmin** :
  - Deployment `phpmyadmin-tp8` avec 2 Pods.
- **Services** :
  - `mysql-tp8` (ClusterIP, utilisé par WP et phpMyAdmin).
  - `wordpress-tp8` (NodePort, ex: 30081).
  - `phpmyadmin-tp8` (NodePort, ex: 30082).

> Remarque : la vraie haute disponibilité MySQL est un sujet complexe (réplication, failover automatique…). Ici, nous montrons une **base répliquée de manière pédagogique** avec StatefulSet, pour introduire l’idée sans viser une solution complète de production.

---

## 1. Namespace et RBAC

### 1.1 – Namespace dédié

`namespace-tp8.yaml` :

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tp8-ha-wordpress
```

```bash
kubectl apply -f namespace-tp8.yaml
kubectl get ns
```

### 1.2 – RBAC : ServiceAccount + Role + RoleBinding

`rbac-tp8.yaml` :

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tp8-ha-sa
  namespace: tp8-ha-wordpress
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tp8-ha-role
  namespace: tp8-ha-wordpress
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tp8-ha-rolebinding
  namespace: tp8-ha-wordpress
subjects:
  - kind: ServiceAccount
    name: tp8-ha-sa
    namespace: tp8-ha-wordpress
roleRef:
  kind: Role
  name: tp8-ha-role
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f rbac-tp8.yaml
kubectl -n tp8-ha-wordpress get sa,role,rolebinding
```

---

## 2. Serveur NFS et PV/PVC ReadWriteMany

### 2.1 – Configuration du serveur NFS (hors K8s)

Sur le serveur NFS (`IP_NFS`) :

```bash
sudo apt update
sudo apt install -y nfs-kernel-server

sudo mkdir -p /srv/nfs/wp-tp8
sudo chown -R nobody:nogroup /srv/nfs/wp-tp8
sudo chmod 777 /srv/nfs/wp-tp8

echo "/srv/nfs/wp-tp8  10.0.0.0/16(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

Adapte le CIDR (`10.0.0.0/16`) à ton réseau.

### 2.2 – PV/PVC NFS pour WordPress

`wp-nfs-pv-pvc-tp8.yaml` :

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wp-nfs-pv-tp8
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  nfs:
    server: IP_NFS
    path: "/srv/nfs/wp-tp8"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-nfs-pvc-tp8
  namespace: tp8-ha-wordpress
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 20Gi
```

Remplace `IP_NFS` par l’IP réelle.

```bash
kubectl apply -f wp-nfs-pv-pvc-tp8.yaml
kubectl get pv
kubectl -n tp8-ha-wordpress get pvc
```

PVC `wp-nfs-pvc-tp8` doit être `Bound`.

---

## 3. MySQL répliqué avec StatefulSet (simplifié)

Nous allons déployer un **StatefulSet** MySQL avec 2 Pods :

- `mysql-tp8-0` et `mysql-tp8-1`.
- Chacun avec son propre PVC (stockage local par Pod).
- Service `Headless` pour la résolution DNS.

> Pour rester simple, nous ne configurons pas une vraie réplication MySQL maître/replica complète, mais nous introduisons le pattern **StatefulSet** et la possibilité de plusieurs Pods MySQL. Tu pourras enrichir plus tard avec une image MySQL déjà configurée pour la réplication.

`mysql-statefulset-tp8.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-tp8
  namespace: tp8-ha-wordpress
spec:
  ports:
    - port: 3306
      name: mysql
  clusterIP: None
  selector:
    app: mysql-tp8
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-tp8
  namespace: tp8-ha-wordpress
spec:
  serviceName: mysql-tp8
  replicas: 2
  selector:
    matchLabels:
      app: mysql-tp8
  template:
    metadata:
      labels:
        app: mysql-tp8
    spec:
      containers:
        - name: mysql
          image: mysql:8.0
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: "root_tp8"
            - name: MYSQL_DATABASE
              value: "wordpress_tp8"
          ports:
            - containerPort: 3306
              name: mysql
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: mysql-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ""
        resources:
          requests:
            storage: 10Gi
```

```bash
kubectl apply -f mysql-statefulset-tp8.yaml
kubectl -n tp8-ha-wordpress get pods -l app=mysql-tp8 -o wide
kubectl -n tp8-ha-wordpress get svc mysql-tp8
```

Remarques :

- Les Pods auront des DNS comme : `mysql-tp8-0.mysql-tp8.tp8-ha-wordpress.svc.cluster.local`.
- Les applications clientes (WordPress, phpMyAdmin) peuvent utiliser le nom `mysql-tp8` (Service Headless) ou `mysql-tp8-0` si tu veux cibler un Pod particulier.

---

## 4. WordPress hautement disponible avec NFS

WordPress sera déployé avec 2 réplicas, répartis sur les deux workers, et tous les Pods utiliseront le **même PVC NFS** pour `/var/www/html/wp-content`.

`wordpress-tp8.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-tp8
  namespace: tp8-ha-wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress-tp8
  template:
    metadata:
      labels:
        app: wordpress-tp8
    spec:
      containers:
        - name: wordpress
          image: wordpress:latest
          env:
            - name: WORDPRESS_DB_HOST
              value: "mysql-tp8"         # Service MySQL
            - name: WORDPRESS_DB_USER
              value: "root"
            - name: WORDPRESS_DB_PASSWORD
              value: "root_tp8"
            - name: WORDPRESS_DB_NAME
              value: "wordpress_tp8"
          ports:
            - containerPort: 80
          volumeMounts:
            - name: wp-content
              mountPath: /var/www/html/wp-content
      volumes:
        - name: wp-content
          persistentVolumeClaim:
            claimName: wp-nfs-pvc-tp8
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-tp8
  namespace: tp8-ha-wordpress
spec:
  type: NodePort
  selector:
    app: wordpress-tp8
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30081
```

```bash
kubectl apply -f wordpress-tp8.yaml
kubectl -n tp8-ha-wordpress get pods -l app=wordpress-tp8 -o wide
kubectl -n tp8-ha-wordpress get svc wordpress-tp8
```

Les Pods doivent être répartis entre `serveurA` et `serveurB`.

---

## 5. phpMyAdmin répliqué sur les deux workers

`phpmyadmin-tp8.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpmyadmin-tp8
  namespace: tp8-ha-wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: phpmyadmin-tp8
  template:
    metadata:
      labels:
        app: phpmyadmin-tp8
    spec:
      containers:
        - name: phpmyadmin
          image: phpmyadmin/phpmyadmin:latest
          env:
            - name: PMA_HOST
              value: "mysql-tp8"
            - name: PMA_USER
              value: "root"
            - name: PMA_PASSWORD
              value: "root_tp8"
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: phpmyadmin-tp8
  namespace: tp8-ha-wordpress
spec:
  type: NodePort
  selector:
    app: phpmyadmin-tp8
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30082
```

```bash
kubectl apply -f phpmyadmin-tp8.yaml
kubectl -n tp8-ha-wordpress get pods -l app=phpmyadmin-tp8 -o wide
kubectl -n tp8-ha-wordpress get svc phpmyadmin-tp8
```

---

## 6. Tests de haute disponibilité

### 6.1 – Accès WordPress depuis les deux workers

Récupère les IP publiques :

- `IP_PUBLIC_A` pour `serveurA`
- `IP_PUBLIC_B` pour `serveurB`

Dans ton navigateur :

```text
http://IP_PUBLIC_A:30081
http://IP_PUBLIC_B:30081
```

- Configure WordPress (création du site, admin, etc.).
- Upload une image dans un article.

Vérifie sur le serveur NFS :

```bash
ls -R /srv/nfs/wp-tp8
```

Tu dois voir les fichiers `wp-content` générés.

### 6.2 – Accès phpMyAdmin

```text
http://IP_PUBLIC_A:30082
http://IP_PUBLIC_B:30082
```

Connecte-toi avec :

- Utilisateur : `root`
- Mot de passe : `root_tp8`

Vérifie la base `wordpress_tp8` et les tables WordPress (`wp_posts`, etc.).

### 6.3 – Simulation de panne d’un Pod WordPress

Supprime un Pod WordPress :

```bash
kubectl -n tp8-ha-wordpress delete pod <nom-pod-wordpress>
```

- Kubernetes recrée automatiquement un nouveau Pod.
- Accède de nouveau à `http://IP_PUBLIC_A:30081` et `http://IP_PUBLIC_B:30081` :
  - Le site doit rester accessible.
  - Les images et contenus doivent être présents (stockage NFS partagé).

### 6.4 – Simulation de panne d’un Pod MySQL

Supprime `mysql-tp8-0` :

```bash
kubectl -n tp8-ha-wordpress delete pod mysql-tp8-0
```

- StatefulSet recrée le Pod.
- WordPress et phpMyAdmin doivent retrouver la connexion après la recréation.

> Pour une vraie haute dispo MySQL, il faut ajouter une configuration de réplication entre les Pods, ce qui est au-delà de ce TP d’initiation mais tu peux en parler théoriquement.

---

## 7. Nettoyage du TP8

```bash
kubectl delete -f phpmyadmin-tp8.yaml
kubectl delete -f wordpress-tp8.yaml
kubectl delete -f mysql-statefulset-tp8.yaml
kubectl delete -f wp-nfs-pv-pvc-tp8.yaml
kubectl delete -f rbac-tp8.yaml
kubectl delete -f namespace-tp8.yaml
```

Sur le serveur NFS (optionnel) :

```bash
sudo rm -rf /srv/nfs/wp-tp8/*
```

---

## 8. Récapitulatif

Dans ce dernier TP, tu as :

- Créé un **namespace** dédié avec **RBAC** pour contrôler l’accès.
- Utilisé un **NFS partagé** (PV/PVC `ReadWriteMany`) accessible depuis les deux workers.
- Déployé **MySQL** via un **StatefulSet** (plus adapté que Deployment pour les bases).
- Déployé **WordPress** et **phpMyAdmin** en **réplicas** répartis sur les workers.
- Vérifié le comportement en cas de suppression de Pods (auto-récupération, persistance des données).

Tu termines ainsi une progression complète :

- Docker simple → Swarm → Compose/Stacks → Kubernetes de base → Kubernetes avec stockage, RBAC, NFS et haute disponibilité applicative.
