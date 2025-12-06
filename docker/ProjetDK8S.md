# Projet final – Cluster Kubernetes haute disponibilité (AMD) avec WordPress, PXC MySQL, NFS et RBAC

> **Contexte :**
> Tu disposes de **3 instances AMD** sur Oracle Cloud :
> - 1 master (node de contrôle, fera aussi serveur NFS)
> - 2 workers (worker1, worker2)
> Toutes sont accessibles en **SSH (root ou sudo)** via PuTTY.
>
> **Objectif global :**
> - Installer **Docker (runtime + daemon + compose)** sur les 3 nœuds.
> - Préparer les **ports Oracle Cloud** nécessaires.
> - Créer un **cluster Kubernetes** (kubeadm) : 1 master, 2 workers.
> - Configurer sur le **master** un **serveur NFS** et un **PV/PVC** partagé pour WordPress.
> - Mettre en place **RBAC + namespace dédié**.
> - Déployer **Percona XtraDB Cluster (PXC)** MySQL (1 Pod sur worker1, 1 sur worker2) via StatefulSet.
> - Déployer **WordPress** (Pods sur worker1 et worker2) utilisant le même **volume NFS**.
> - Déployer **phpMyAdmin** (Pods sur worker1 et worker2) connectés au cluster PXC.
> - Exposer WordPress et phpMyAdmin vers l’extérieur via **Services de type NodePort / LoadBalancer logique**.
>
> **Très important :**
> - Avant **chaque bloc de commande**, regarde bien **sur quelle machine** tu dois exécuter (master, worker1, worker2).
> - Toutes les commandes sont **prêtes à copier-coller**.

---

## Chapitre 1 – Préparation des machines (master, worker1, worker2)

### 1.1 – Mise à jour système et outils de base

> **Sur les 3 machines : `master`, `worker1`, `worker2`**

```bash
sudo su
apt update
apt upgrade -y
apt install -y curl wget vim net-tools gnupg lsb-release ca-certificates
```

### 1.2 – Désactivation de swap (requis pour kubeadm)

> **Sur les 3 machines : `master`, `worker1`, `worker2`**

```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```

Vérifie qu’il n’y a plus de swap :

```bash
free -h
```

---

## Chapitre 2 – Installation de Docker (runtime + daemon + compose)

### 2.1 – Installation Docker CE

> **Sur les 3 machines : `master`, `worker1`, `worker2`**

```bash
sudo su
apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH=$(dpkg --print-architecture)
. /etc/os-release
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
```

Teste Docker :

```bash
docker run --rm hello-world
```

### 2.2 – Configuration de Docker pour Kubernetes

> **Sur les 3 machines : `master`, `worker1`, `worker2`**

On configure le runtime `systemd` pour `containerd` :

```bash
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl status containerd --no-pager
```

---

## Chapitre 3 – Ouverture des ports Oracle Cloud (réseau)

Dans la **console Oracle Cloud**, pour le **subnet** (ou la security list) associé à tes 3 VMs, ouvre les ports **ingress** suivants :

- **SSH** : TCP 22 (déjà ouvert normalement).
- **Kubernetes API** (master) : TCP 6443.
- **Etcd / kubelet (interne)** :
  - TCP 2379–2380, 10250–10259, 30000–32767 (NodePort range).
- **NFS** (master vers workers) :
  - TCP/UDP 111, 2049, 2000–2050 (ports dynamiques RPC – à ajuster selon ta conf).
- **NodePort applicatifs** :
  - Pour WordPress : ex. TCP 30081.
  - Pour phpMyAdmin : ex. TCP 30082.

> **Recommandation :**
> - Limite l’accès **SSH** et **NodePort** à ton IP publique si possible.

---

## Chapitre 4 – Installation Kubernetes (kubeadm, kubelet, kubectl)

### 4.1 – Préparation réseau (modules kernel)

> **Sur les 3 machines : `master`, `worker1`, `worker2`**

```bash
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

modprobe br_netfilter
modprobe overlay

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```

### 4.2 – Installation kubeadm/kubelet/kubectl

> **Sur les 3 machines : `master`, `worker1`, `worker2`**

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet
```

---

## Chapitre 5 – Initialisation du cluster Kubernetes

### 5.1 – kubeadm init sur le master

> **Sur : `master` uniquement**

Choisis un CIDR de pod network (ex : `10.244.0.0/16` pour Flannel) :

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16
```

A la fin, note bien la **commande `kubeadm join ...`** affichée (elle servira pour `worker1` et `worker2`).

Configure `kubectl` pour l’utilisateur root :

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

Teste :

```bash
kubectl get nodes
```

### 5.2 – Installation du plugin réseau (Flannel)

> **Sur : `master`**

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Attends quelques minutes puis :

```bash
kubectl get pods -n kube-system
kubectl get nodes
```

### 5.3 – Join des workers au cluster

> **Sur : `worker1` et `worker2`**

Utilise la commande fournie par `kubeadm init`, par exemple :

```bash
kubeadm join IP_MASTER:6443 --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

Sur le master, vérifie :

```bash
kubectl get nodes -o wide
```

Tu dois voir `master`, `worker1`, `worker2` en `Ready`.

---

## Chapitre 6 – NFS serveur sur master + PV/PVC partagé

### 6.1 – Installation et configuration serveur NFS

> **Sur : `master` uniquement**

```bash
apt install -y nfs-kernel-server

mkdir -p /srv/nfs/wp-share
chown -R nobody:nogroup /srv/nfs/wp-share
chmod 777 /srv/nfs/wp-share
```

Édite `/etc/exports` :

```bash
echo "/srv/nfs/wp-share  10.0.0.0/16(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

exportfs -ra
systemctl restart nfs-kernel-server
systemctl status nfs-kernel-server --no-pager
```

> **Remplace** `10.0.0.0/16` par le **CIDR** de ton réseau privé (subnet Oracle) qui contient `master`, `worker1`, `worker2`.

### 6.2 – Test client NFS

> **Sur : `worker1` et `worker2`**

Installe le client NFS :

```bash
apt install -y nfs-common
mkdir -p /mnt/test-nfs
mount IP_INTERNE_MASTER:/srv/nfs/wp-share /mnt/test-nfs
```

Crée un fichier test sur worker1 :

```bash
touch /mnt/test-nfs/from-worker1.txt
ls -l /mnt/test-nfs
```

Sur worker2 :

```bash
ls -l /mnt/test-nfs
```

Puis démonte :

```bash
umount /mnt/test-nfs
```

### 6.3 – PV/PVC NFS pour WordPress

> **Sur : `master` (avec `kubectl`)**

Crée un fichier `nfs-pv-pvc-wordpress.yaml` :

```bash
cat <<EOF > nfs-pv-pvc-wordpress.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wp-nfs-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  nfs:
    server: IP_INTERNE_MASTER
    path: "/srv/nfs/wp-share"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-nfs-pvc
  namespace: wp-ha
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 20Gi
EOF

kubectl apply -f nfs-pv-pvc-wordpress.yaml
kubectl get pv
kubectl -n wp-ha get pvc
```

Remplace `IP_INTERNE_MASTER` par l’IP privée du master.

---

## Chapitre 7 – Namespace et RBAC pour le projet

### 7.1 – Namespace dédié

> **Sur : `master`**

```bash
cat <<EOF > namespace-rbac.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: wp-ha
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: wp-ha-sa
  namespace: wp-ha
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: wp-ha-role
  namespace: wp-ha
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
  name: wp-ha-rolebinding
  namespace: wp-ha
subjects:
  - kind: ServiceAccount
    name: wp-ha-sa
    namespace: wp-ha
roleRef:
  kind: Role
  name: wp-ha-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f namespace-rbac.yaml
kubectl get ns
kubectl -n wp-ha get sa,role,rolebinding
```

---

## Chapitre 8 – Cluster MySQL haute dispo avec Percona XtraDB (PXC)

On va utiliser une image Percona XtraDB Cluster simplifiée (PXC) pour avoir 2 Pods répartis sur `worker1` et `worker2`.

### 8.1 – StatefulSet PXC (2 Pods)

> **Sur : `master`**

Crée un fichier `pxc-mysql-statefulset.yaml` :

```bash
cat <<EOF > pxc-mysql-statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: pxc-mysql
  namespace: wp-ha
spec:
  ports:
    - name: mysql
      port: 3306
  clusterIP: None
  selector:
    app: pxc-mysql
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pxc-mysql
  namespace: wp-ha
spec:
  serviceName: pxc-mysql
  replicas: 2
  selector:
    matchLabels:
      app: pxc-mysql
  template:
    metadata:
      labels:
        app: pxc-mysql
    spec:
      serviceAccountName: wp-ha-sa
      containers:
        - name: pxc
          image: percona/percona-xtradb-cluster:8.0
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: "RootP@ss123"
            - name: CLUSTER_NAME
              value: "pxc-cluster"
            - name: XTRABACKUP_PASSWORD
              value: "Xtr@bckp123"
          ports:
            - containerPort: 3306
              name: mysql
          volumeMounts:
            - name: datadir
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: datadir
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ""
        resources:
          requests:
            storage: 10Gi
EOF

kubectl apply -f pxc-mysql-statefulset.yaml
kubectl -n wp-ha get pods -l app=pxc-mysql -o wide
kubectl -n wp-ha get svc pxc-mysql
```

> Selon le scheduler, les 2 Pods PXC seront dispatchés entre `worker1` et `worker2`. Tu peux vérifier la colonne **NODE**.

---

## Chapitre 9 – WordPress HA utilisant NFS et PXC

### 9.1 – Déploiement WordPress (2 replicas)

> **Sur : `master`**

Crée un fichier `wordpress-ha.yaml` :

```bash
cat <<EOF > wordpress-ha.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-ha
  namespace: wp-ha
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress-ha
  template:
    metadata:
      labels:
        app: wordpress-ha
    spec:
      serviceAccountName: wp-ha-sa
      containers:
        - name: wordpress
          image: wordpress:latest
          env:
            - name: WORDPRESS_DB_HOST
              value: "pxc-mysql"
            - name: WORDPRESS_DB_USER
              value: "root"
            - name: WORDPRESS_DB_PASSWORD
              value: "RootP@ss123"
            - name: WORDPRESS_DB_NAME
              value: "wordpress_ha"
          ports:
            - containerPort: 80
          volumeMounts:
            - name: wp-content
              mountPath: /var/www/html/wp-content
      volumes:
        - name: wp-content
          persistentVolumeClaim:
            claimName: wp-nfs-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-ha
  namespace: wp-ha
spec:
  type: NodePort
  selector:
    app: wordpress-ha
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30081
EOF

kubectl apply -f wordpress-ha.yaml
kubectl -n wp-ha get pods -l app=wordpress-ha -o wide
kubectl -n wp-ha get svc wordpress-ha
```

Les 2 Pods WordPress doivent être répartis sur `worker1` et `worker2`. Les 2 utilisent le **même volume NFS** donc les fichiers (uploads, thèmes) sont partagés.

---

## Chapitre 10 – phpMyAdmin sur les deux workers

### 10.1 – Déploiement phpMyAdmin (2 replicas)

> **Sur : `master`**

Crée un fichier `phpmyadmin-ha.yaml` :

```bash
cat <<EOF > phpmyadmin-ha.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpmyadmin-ha
  namespace: wp-ha
spec:
  replicas: 2
  selector:
    matchLabels:
      app: phpmyadmin-ha
  template:
    metadata:
      labels:
        app: phpmyadmin-ha
    spec:
      serviceAccountName: wp-ha-sa
      containers:
        - name: phpmyadmin
          image: phpmyadmin/phpmyadmin:latest
          env:
            - name: PMA_HOST
              value: "pxc-mysql"
            - name: PMA_USER
              value: "root"
            - name: PMA_PASSWORD
              value: "RootP@ss123"
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: phpmyadmin-ha
  namespace: wp-ha
spec:
  type: NodePort
  selector:
    app: phpmyadmin-ha
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30082
EOF

kubectl apply -f phpmyadmin-ha.yaml
kubectl -n wp-ha get pods -l app=phpmyadmin-ha -o wide
kubectl -n wp-ha get svc phpmyadmin-ha
```

---

## Chapitre 11 – Tests, haute disponibilité et load-balancer logique

### 11.1 – Accès depuis l’extérieur (navigateur)

Récupère les **IP publiques** de `worker1` et `worker2` dans Oracle Cloud.

Dans ton navigateur :

- WordPress (via NodePort 30081) :
  - `http://IP_PUBLIC_WORKER1:30081`
  - `http://IP_PUBLIC_WORKER2:30081`
- phpMyAdmin (via NodePort 30082) :
  - `http://IP_PUBLIC_WORKER1:30082`
  - `http://IP_PUBLIC_WORKER2:30082`

Installe WordPress (création base, admin). Les 2 adresses doivent montrer **le même site**, grâce au **NFS partagé** et au **cluster PXC**.

### 11.2 – Test de tolérance de panne (HA)

> **Sur : `master`**

Supprime un Pod WordPress :

```bash
kubectl -n wp-ha delete pod -l app=wordpress-ha --field-selector=status.phase=Running --limit=1
kubectl -n wp-ha get pods -l app=wordpress-ha
```

Kubernetes va recréer automatiquement un Pod. Recharge les pages WordPress sur `worker1` et `worker2`: le site doit rester disponible.

Supprime un Pod PXC :

```bash
kubectl -n wp-ha delete pod pxc-mysql-0
kubectl -n wp-ha get pods -l app=pxc-mysql
```

Le cluster PXC garde un Pod disponible; WordPress et phpMyAdmin doivent continuer à fonctionner (selon la logique interne PXC).

### 11.3 – Load balancer logique

Ici, on utilise **deux NodePort** (un sur chaque worker). Pour un vrai **Load Balancer** :

- Tu peux configurer un **reverse proxy NGINX** (VM externe ou Pod Ingress) qui répartit la charge entre les 2 workers.
- Ou utiliser le **Load Balancer managé** d’Oracle (si disponible) pointant vers les NodePorts.

---

## Chapitre 12 – Nettoyage (optionnel)

> **Sur : `master`**

```bash
kubectl -n wp-ha delete deployment wordpress-ha phpmyadmin-ha
kubectl -n wp-ha delete statefulset pxc-mysql
kubectl -n wp-ha delete svc wordpress-ha phpmyadmin-ha pxc-mysql
kubectl delete -f nfs-pv-pvc-wordpress.yaml
kubectl delete -f namespace-rbac.yaml
kubectl get ns
kubectl get pv,pvc
```

> **Sur : `master`, `worker1`, `worker2` (pour reset kubeadm uniquement si tu veux détruire le cluster)**

```bash
kubeadm reset -f
rm -rf ~/.kube
```

---

## Récapitulatif

- Tu as installé **Docker** + **containerd** et **Kubernetes** sur 3 VMs AMD.
- Tu as créé un **cluster kubeadm** (1 master + 2 workers).
- Tu as mis en place un **NFS serveur** sur le master et un **PV/PVC RWMany**.
- Tu as créé un **namespace** et le **RBAC** associé.
- Tu as déployé un **cluster PXC** MySQL (StatefulSet, 2 Pods) pour la base.
- Tu as déployé **WordPress** et **phpMyAdmin** en **haute disponibilité**, avec accès externe.

Tu peux maintenant utiliser ce TP comme **projet complet** pour tes étudiants, en leur faisant suivre chapitre par chapitre, directement dans PuTTY sur `master`, `worker1` et `worker2`.
