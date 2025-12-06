# TP7 – Déployer MySQL + phpMyAdmin sur Kubernetes (1 master + 2 workers)

**Objectif du TP :**  
Sur le cluster Kubernetes créé au TP6 (1 master, 2 workers, Docker comme runtime), déployer :

- Une base de données **MySQL** hébergée sur `serveurA` (worker node 1) avec **stockage persistant** (PV/PVC).
- Un **phpMyAdmin** répliqué (plusieurs Pods) pouvant tourner sur n’importe quel worker (`serveurA` ou `serveurB`).
- Un **namespace** dédié pour séparer ce TP du reste (`tp7-mysql-phpmyadmin`).

Tu vas apprendre à :

- Créer un **namespace** Kubernetes.
- Définir un **PersistentVolume** (PV) et un **PersistentVolumeClaim** (PVC) pour MySQL.
- Créer un **Deployment** MySQL et l’attacher au PVC.
- Créer un **Service** interne pour MySQL.
- Créer un **Deployment** phpMyAdmin répliqué.
- Créer un **Service** de type `NodePort` pour accéder à phpMyAdmin depuis l’extérieur.
- Vérifier la répartition des Pods sur les workers et le fonctionnement global.

> Dans ce TP, nous utiliserons des fichiers **YAML** de manifest Kubernetes. Tous les exemples sont pensés pour être copiés/collés dans des fichiers `.yaml`.

---

## 0. Prérequis

- Avoir terminé le **TP6** :
  - 1 master (`master`)
  - 2 workers (`serveurA`, `serveurB`)
  - `kubectl` fonctionnel sur le master et pointant vers ce cluster.
  - Plugin réseau (CNI) déjà installé (ex : Flannel).
- Docker toujours installé et utilisé comme runtime de conteneurs.
- Ports NodePort ouverts (par défaut 30000–32767/TCP) vers les workers.

Vérifie sur le master :

```bash
kubectl get nodes -o wide
```

Les 3 nœuds doivent être `Ready`.

---

## 1. Créer un namespace dédié

Nous allons regrouper toutes les ressources de ce TP dans un namespace `tp7-mysql-phpmyadmin`.

Crée un fichier `namespace-tp7.yaml` avec le contenu suivant :

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tp7-mysql-phpmyadmin
```

Applique le manifest :

```bash
kubectl apply -f namespace-tp7.yaml
```

Vérifie :

```bash
kubectl get namespaces
```

Tu dois voir `tp7-mysql-phpmyadmin` dans la liste.

> Pour la suite du TP, nous préciserons toujours `-n tp7-mysql-phpmyadmin` dans les commandes `kubectl`.

---

## 2. Définir le stockage persistant pour MySQL (PV + PVC)

Nous allons créer :

- Un **PersistentVolume** (PV) de type `hostPath` pour simplifier le TP (stocké sur un nœud).
- Un **PersistentVolumeClaim** (PVC) dans le namespace `tp7-mysql-phpmyadmin`.

> En production, on utiliserait plutôt un stockage réseau (NFS, CSI, cloud storage…). Ici, `hostPath` sert juste pour l’apprentissage.

Crée un fichier `mysql-pv-pvc.yaml` :

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-tp7
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  hostPath:
    path: "/var/lib/mysql-tp7"  # dossier créé sur le nœud où tournera MySQL
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc-tp7
  namespace: tp7-mysql-phpmyadmin
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 5Gi
```

Applique :

```bash
kubectl apply -f mysql-pv-pvc.yaml
```

Vérifie :

```bash
kubectl get pv
kubectl get pvc -n tp7-mysql-phpmyadmin
```

Le PVC `mysql-pvc-tp7` doit être en état `Bound`.

> Le `hostPath` sera réellement utilisé sur le nœud où tourne le Pod MySQL (souvent un worker). Pour forcer l’utilisation de `serveurA`, on utilisera un **nodeSelector** dans le Deployment MySQL.

---

## 3. Déployer MySQL sur le worker `serveurA`

Nous allons créer un **Deployment** MySQL qui :

- Utilise l’image `mysql:8.0`.
- Lit le mot de passe root dans une variable d’environnement.
- Monte le PVC `mysql-pvc-tp7` sur `/var/lib/mysql`.
- Est **forcé** à tourner sur le nœud `serveurA` via un `nodeSelector` (en supposant que le label du nœud convient, voir ci-dessous).

### 3.1 – Ajouter un label au nœud `serveurA`

Sur le master, liste les nœuds :

```bash
kubectl get nodes
```

Ensuite, ajoute un label au nœud `serveurA` (remplace `nom-du-noeud-serveurA` par le vrai nom retourné) :

```bash
kubectl label node nom-du-noeud-serveurA role=mysql-node
```

Vérifie :

```bash
kubectl get nodes --show-labels
```

Tu dois voir `role=mysql-node` sur `serveurA`.

### 3.2 – Créer le Deployment MySQL + Service interne

Crée un fichier `mysql-deployment-service.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-tp7
  namespace: tp7-mysql-phpmyadmin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql-tp7
  template:
    metadata:
      labels:
        app: mysql-tp7
    spec:
      nodeSelector:
        role: mysql-node   # pour cibler serveurA
      containers:
        - name: mysql
          image: mysql:8.0
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: "root_tp7"
            - name: MYSQL_DATABASE
              value: "tp7db"
          ports:
            - containerPort: 3306
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-data
          persistentVolumeClaim:
            claimName: mysql-pvc-tp7
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-tp7
  namespace: tp7-mysql-phpmyadmin
spec:
  selector:
    app: mysql-tp7
  ports:
    - name: mysql
      port: 3306
      targetPort: 3306
  clusterIP: None # optionnel, tu peux aussi laisser un ClusterIP normal
```

Applique :

```bash
kubectl apply -f mysql-deployment-service.yaml
```

Vérifie :

```bash
kubectl get pods -n tp7-mysql-phpmyadmin -o wide
kubectl get svc -n tp7-mysql-phpmyadmin
```

Le Pod `mysql-tp7-...` doit être `Running` et planifié sur le nœud labelisé `role=mysql-node` (normalement `serveurA`).

---

## 4. Déployer phpMyAdmin répliqué sur les workers

Nous allons créer un **Deployment** phpMyAdmin :

- Image : `phpmyadmin/phpmyadmin:latest`.
- Réplicas : 2 (Pods répartis sur les workers selon le scheduler).
- Variable `PMA_HOST` pointant vers le Service MySQL `mysql-tp7`.
- Accès via un **Service** de type `NodePort` pour l’extérieur.

Crée un fichier `phpmyadmin-deployment-service.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpmyadmin-tp7
  namespace: tp7-mysql-phpmyadmin
spec:
  replicas: 2
  selector:
    matchLabels:
      app: phpmyadmin-tp7
  template:
    metadata:
      labels:
        app: phpmyadmin-tp7
    spec:
      containers:
        - name: phpmyadmin
          image: phpmyadmin/phpmyadmin:latest
          env:
            - name: PMA_HOST
              value: "mysql-tp7"
            - name: PMA_USER
              value: "root"
            - name: PMA_PASSWORD
              value: "root_tp7"
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: phpmyadmin-tp7
  namespace: tp7-mysql-phpmyadmin
spec:
  type: NodePort
  selector:
    app: phpmyadmin-tp7
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30080  # NodePort choisi dans la plage 30000-32767
```

Applique :

```bash
kubectl apply -f phpmyadmin-deployment-service.yaml
```

Vérifie :

```bash
kubectl get pods -n tp7-mysql-phpmyadmin -o wide
kubectl get svc -n tp7-mysql-phpmyadmin
```

Tu dois voir :

- 2 Pods `phpmyadmin-tp7-...` en `Running` (probablement répartis entre `serveurA` et `serveurB`).
- Le Service `phpmyadmin-tp7` avec un `NodePort` fixé à `30080`.

---

## 5. Accéder à phpMyAdmin depuis l’extérieur

Nous utilisons le Service `NodePort` exposé sur le port `30080`.

Récupère les IP publiques de `serveurA` et `serveurB` (comme dans les TP précédents) :

```bash
curl ifconfig.me
```

Appelle-les :

- `IP_PUBLIC_A` pour `serveurA`
- `IP_PUBLIC_B` pour `serveurB`

Dans ton navigateur :

- `http://IP_PUBLIC_A:30080`
- ou `http://IP_PUBLIC_B:30080`

Tu dois voir l’interface **phpMyAdmin**.

Identifiants MySQL :

- Utilisateur : `root`
- Mot de passe : `root_tp7`
- Serveur : il est déjà préconfiguré (`mysql-tp7`), car `PMA_HOST` pointe vers le Service Kubernetes.

> Idée pédagogique :
> 
> - Demande aux étudiants de créer une table dans la base `tp7db` via phpMyAdmin.
> - Rafraîchissez depuis différents workers (`IP_PUBLIC_A` / `IP_PUBLIC_B`).
> - Montrez que les données sont **les mêmes**, car toutes les instances phpMyAdmin se connectent au même Service MySQL (`mysql-tp7`), qui pointe vers le Pod MySQL tournant sur `serveurA`.

---

## 6. Visualiser l’architecture et la répartition

Utilise `kubectl` pour vérifier où tournent les Pods :

```bash
kubectl get pods -n tp7-mysql-phpmyadmin -o wide
```

Observe :

- Le Pod `mysql-tp7-...` doit être sur le nœud labelisé `role=mysql-node` (`serveurA`).
- Les Pods `phpmyadmin-tp7-...` doivent être répartis sur un ou plusieurs nœuds (`serveurA`, `serveurB`).

Tu peux aussi décrire en classe :

- Le **namespace** isole les ressources.
- Le **PV** + **PVC** fournissent un stockage persistant pour MySQL.
- Le **Deployment** MySQL gère le Pod de base de données.
- Le **Service** MySQL fournit un nom DNS stable `mysql-tp7.tp7-mysql-phpmyadmin.svc.cluster.local`.
- Le **Deployment** phpMyAdmin gère plusieurs Pods (réplicas).
- Le **Service NodePort** expose phpMyAdmin vers l’extérieur.

---

## 7. Nettoyage du TP7

Quand tu as terminé les tests et que tu veux tout supprimer :

### 7.1 – Supprimer les ressources applicatives

```bash
kubectl delete -f phpmyadmin-deployment-service.yaml
kubectl delete -f mysql-deployment-service.yaml
```

Vérifie :

```bash
kubectl get pods -n tp7-mysql-phpmyadmin
kubectl get svc -n tp7-mysql-phpmyadmin
```

### 7.2 – Supprimer le PVC et le PV

```bash
kubectl delete -f mysql-pv-pvc.yaml
```

Vérifie :

```bash
kubectl get pvc -n tp7-mysql-phpmyadmin
kubectl get pv
```

### 7.3 – Supprimer le namespace

```bash
kubectl delete -f namespace-tp7.yaml
```

Ou :

```bash
kubectl delete namespace tp7-mysql-phpmyadmin
```

### 7.4 – (Optionnel) Nettoyer le répertoire hostPath sur `serveurA`

Sur le nœud `serveurA`, tu peux supprimer les données MySQL du répertoire `/var/lib/mysql-tp7` :

```bash
sudo rm -rf /var/lib/mysql-tp7
```

> Attention : cette action supprime définitivement les données de la base.

---

## 8. Récapitulatif du TP7

Dans ce TP, tu as appris à :

- Créer un **namespace** dédié pour isoler un projet.
- Définir un **PersistentVolume** et un **PersistentVolumeClaim** pour MySQL.
- Utiliser un **Deployment** MySQL avec **nodeSelector** pour cibler un worker spécifique.
- Exposer MySQL via un **Service** interne.
- Déployer phpMyAdmin en plusieurs **réplicas** via un Deployment.
- Exposer phpMyAdmin à l’extérieur via un **Service NodePort**.
- Vérifier la distribution des Pods sur les nœuds du cluster.
- Nettoyer proprement toutes les ressources du TP.

Tu disposes maintenant d’un exemple complet d’architecture **Kubernetes sur Docker** :

- Une base de données persistante sur un nœud précis.
- Une application web répliquée sur plusieurs nœuds.
- Une séparation claire des responsabilités grâce aux namespaces, PV/PVC, Deployments et Services.
