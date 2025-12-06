# TP6 – Passer de Docker Swarm à Kubernetes (cluster 1 master + 2 workers)

**Objectif du TP :**  
Désactiver Docker Swarm et mettre en place un **cluster Kubernetes** s’appuyant sur Docker comme runtime de conteneurs, avec :

- 1 nœud **master** Kubernetes (plan de contrôle)
- 2 nœuds **workers** :
  - `serveurA` → worker node 1
  - `serveurB` → worker node 2
- Un cluster fonctionnel sur lequel, dans un TP suivant, on déploiera **MySQL** et **phpMyAdmin** (comme on l’a fait avec Swarm).

Ce TP se concentre sur :

- Désactiver / quitter le cluster Docker Swarm
- Installer les composants Kubernetes (kubeadm, kubelet, kubectl) sur les 3 serveurs
- Initialiser un **master node** Kubernetes
- Joindre `serveurA` et `serveurB` comme **workers**
- Comprendre les principaux choix réseau (CNI, kubelet, ports à ouvrir)
- Vérifier que le cluster est **Ready** et prêt à recevoir des workloads

> Remarque : ici on considère encore Docker comme moteur de conteneurs. Sur les distributions récentes, on peut aussi utiliser containerd ou CRI-O, mais pour des débutants déjà familiers avec Docker, c’est plus simple de rester sur Docker.

---

## 0. Topologie et prérequis

Nous allons considérer 3 serveurs :

- `master` : nœud de contrôle Kubernetes (API server, scheduler, controller-manager, etcd)
- `serveurA` : worker node 1
- `serveurB` : worker node 2

**Conditions communes aux 3 serveurs :**

- OS : Ubuntu Server (par exemple 20.04 ou 22.04)
- Docker installé et fonctionnel
- Accès SSH aux 3 machines
- Même réseau privé (les 3 serveurs doivent pouvoir communiquer entre eux)

**Ports réseau à ouvrir / autoriser (entre les nœuds)** :

- Vers le **master** :
  - 6443/TCP : API server
  - 2379-2380/TCP : etcd (si multi-master, mais on reste ici sur un seul master)
  - 10250/TCP : kubelet
  - 10251/TCP : kube-scheduler
  - 10252/TCP : kube-controller-manager
- Vers les **workers** :
  - 10250/TCP : kubelet
  - 30000-32767/TCP : NodePort par défaut (services exposés à l’extérieur)
- Pour le **plugin réseau (CNI)** (par ex. Calico, Flannel), il peut y avoir des ports spécifiques, généralement en UDP/TCP sur le réseau interne (ex : 4789/UDP pour VXLAN, etc.).

> Conseil pédagogique : faire un schéma des 3 nœuds, avec les ports ouverts, et expliquer qui parle à qui.

---

## 1. Désactiver / quitter Docker Swarm

Si tes serveurs ont encore un cluster Docker Swarm actif (TP4), il est préférable de le **quitter** avant de mettre en place Kubernetes.

### 1.1 – Sur les workers Swarm (ex : `serveurB`, et éventuellement `serveurA` si plus manager)

```bash
docker swarm leave
```

### 1.2 – Sur le manager Swarm (ex : `serveurA`)

```bash
docker swarm leave --force
```

Vérifie qu’il n’y a plus de Swarm actif :

```bash
docker node ls
```

Cette commande doit maintenant échouer (normal), ce qui confirme que Swarm est désactivé.

---

## 2. Préparation système pour Kubernetes (sur les 3 serveurs)

> Les commandes de cette section sont à exécuter sur **master**, `serveurA` et `serveurB`.

### 2.1 – Désactiver le swap

Kubernetes nécessite que le **swap** soit désactivé.

```bash
sudo swapoff -a
```

Pour le désactiver de façon permanente, commente la ligne `swap` dans `/etc/fstab` (optionnel pour le TP, mais recommandé en production).

### 2.2 – Activer les modules noyau nécessaires

Sur Ubuntu, assure-toi que les modules liés à iptables/bridging sont actifs :

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo modprobe br_netfilter
```

Configurer les paramètres sysctl pour autoriser le trafic bridge dans iptables :

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 2.3 – Vérifier Docker comme runtime de conteneurs

Vérifie simplement que Docker fonctionne :

```bash
sudo docker version
```

> Selon les versions de Kubernetes, il peut être nécessaire de configurer `cri-dockerd` pour que kubelet parle à Docker (CRI). Pour ce TP d’initiation, tu peux préciser dans le commentaire que "Docker est utilisé comme runtime de conteneurs" et que d’autres runtimes existent.

---

## 3. Installer kubeadm, kubelet et kubectl (sur les 3 serveurs)

> Toujours sur **master**, `serveurA` et `serveurB`.

### 3.1 – Ajouter le dépôt Kubernetes

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### 3.2 – Installer les paquets Kubernetes

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Empêcher les mises à jour automatiques de ces paquets (optionnel mais recommandé)
sudo apt-mark hold kubelet kubeadm kubectl
```

Vérifie les versions :

```bash
kubeadm version
kubectl version --client
```

---

## 4. Initialiser le master Kubernetes

> À partir de maintenant, cette partie est à exécuter sur le serveur **master**.

Commence par récupérer l’IP privée du master :

```bash
ip a
```

Nous l’appellerons `IP_PRIVEE_MASTER`.

### 4.1 – Choisir le réseau des Pods (CIDR)

Pour le plugin réseau (CNI), il faut un **CIDR de Pods**, par exemple :

- `10.244.0.0/16` (souvent utilisé avec Flannel)
- `192.168.0.0/16` (souvent utilisé avec Calico)

Dans ce TP, on choisira **Flannel** avec `10.244.0.0/16`.

### 4.2 – Initialiser le cluster avec kubeadm

Sur le master :

```bash
sudo kubeadm init \
  --apiserver-advertise-address=IP_PRIVEE_MASTER \
  --pod-network-cidr=10.244.0.0/16
```

Exemple :

```bash
sudo kubeadm init --apiserver-advertise-address=10.0.0.10 --pod-network-cidr=10.244.0.0/16
```

À la fin, kubeadm affiche :

- Un résumé de la configuration
- Surtout, une commande `kubeadm join ...` que tu utiliseras sur les workers (`serveurA`, `serveurB`).

Copie cette commande et garde-la de côté.

### 4.3 – Configurer kubectl pour l’utilisateur courant

Toujours sur le master, pour utiliser `kubectl` sans sudo :

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Teste :

```bash
kubectl get nodes
```

Tu devrais voir le master en `NotReady` tant que le réseau CNI n’est pas installé.

---

## 5. Installer le plugin réseau (CNI)

Pour que les Pods puissent communiquer entre eux, il faut installer un **plugin réseau**.

Ici on utilise **Flannel** (simple pour débuter).

Sur le master :

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Attends quelques instants, puis vérifie :

```bash
kubectl get pods -n kube-system
```

Les Pods du CNI (flannel) doivent passer de `ContainerCreating` à `Running`.

Ensuite :

```bash
kubectl get nodes
```

Le master doit maintenant apparaître en `Ready`.

> Variante pédagogique : tu peux mentionner qu’il existe d’autres CNI comme **Calico**, **Weave Net**, etc., et que le choix dépend des besoins (NetworkPolicy, performances, etc.).

---

## 6. Joindre `serveurA` et `serveurB` comme workers

> Les commandes de cette section sont à exécuter sur **serveurA** et **serveurB**.

### 6.1 – Utiliser la commande `kubeadm join`

Sur chaque worker (`serveurA`, `serveurB`), colle la commande fournie par `kubeadm init`, par exemple :

```bash
sudo kubeadm join IP_PRIVEE_MASTER:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Si tu as perdu ce token, sur le master tu peux en recréer un :

```bash
kubeadm token create --print-join-command
```

Puis recoller la commande générée sur `serveurA` et `serveurB`.

### 6.2 – Vérifier côté master

Sur le master :

```bash
kubectl get nodes
```

Tu dois voir 3 nœuds :

- `master` : `Ready` (role `control-plane`)
- `serveurA` : `Ready` (role `worker`)
- `serveurB` : `Ready` (role `worker`)

Le cluster Kubernetes est maintenant **fonctionnel**.

---

## 7. Rappels : Docker comme runtime de conteneurs

Explique aux étudiants :

- Docker lance des **conteneurs**.
- Kubernetes lance des **Pods** qui contiennent (souvent) un ou plusieurs **conteneurs Docker**.
- kubelet (sur chaque nœud) parle à Docker pour créer/arrêter les conteneurs.
- On peut voir les conteneurs Docker sous-jacents :

Sur n’importe quel nœud :

```bash
docker ps
```

Tu verras des conteneurs créés par Kubernetes (pods système, CNI, etc.).

> Plus tard, sur ce même cluster, on déploiera un **MySQL** et un **phpMyAdmin** distribués (comme on l’a fait pour Swarm), mais cette fois avec des **manifests YAML** Kubernetes.

---

## 8. Commandes de base pour explorer le cluster

Sur le master (ou depuis n’importe quelle machine avec `kubectl` configuré) :

### 8.1 – Voir les nœuds

```bash
kubectl get nodes -o wide
```

### 8.2 – Voir les namespaces

```bash
kubectl get namespaces
```

### 8.3 – Voir les pods systèmes

```bash
kubectl get pods -n kube-system -o wide
```

### 8.4 – Tester un déploiement simple (optionnel)

Par exemple, déployer un Nginx de test :

```bash
kubectl create deployment nginx-test --image=nginx:latest
kubectl get pods
```

Puis exposer ce déploiement en NodePort (pour tester l’accès externe) :

```bash
kubectl expose deployment nginx-test \
  --type=NodePort \
  --port=80

kubectl get service nginx-test
```

Note le `NodePort` (par exemple 3xxxx).  
Tu peux ensuite accéder à `http://IP_PUBLIC_D_UN_WORKER:NodePort`.

Supprimer le test à la fin :

```bash
kubectl delete service nginx-test
kubectl delete deployment nginx-test
```

---

## 9. Nettoyage du cluster (optionnel pour le TP)

Si tu veux entièrement détruire le cluster Kubernetes (pour tout recommencer) :

### 9.1 – Sur les workers (`serveurA`, `serveurB`)

```bash
sudo kubeadm reset -f
sudo rm -rf ~/.kube
```

### 9.2 – Sur le master

```bash
sudo kubeadm reset -f
rm -rf ~/.kube
```

Tu peux ensuite supprimer les éventuels fichiers de config restants (optionnel).

---

## 10. Récapitulatif du TP6

Dans ce TP, tu as appris à :

- Quitter un cluster Docker Swarm pour repartir proprement.
- Préparer des serveurs pour Kubernetes (swap, modules noyau, iptables, IP forwarding).
- Installer `kubeadm`, `kubelet` et `kubectl` sur plusieurs nœuds.
- Initialiser un **master node** Kubernetes avec `kubeadm init`.
- Installer un plugin réseau (CNI) pour la communication entre Pods.
- Joindre deux nœuds workers (`serveurA`, `serveurB`) au cluster avec `kubeadm join`.
- Vérifier l’état du cluster (`kubectl get nodes`, `kubectl get pods -n kube-system`).

Le cluster est maintenant **prêt** pour le prochain TP où tu pourras :

- Déployer **MySQL** sur un worker spécifique (par ex. `serveurA`).
- Déployer **phpMyAdmin** répliqué sur les deux workers.
- Gérer des **Volumes**, des **Services**, des **Deployments**, etc., en YAML Kubernetes.
