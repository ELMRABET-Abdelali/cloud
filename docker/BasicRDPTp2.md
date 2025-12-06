# Basic TP2 – Accès graphique à une VM via RDP (Remote Desktop)

**Objectif du TP :**  
Apprendre à se connecter en **bureau à distance (RDP)** sur une machine Linux ou Windows dans le cloud, pour disposer d’une interface graphique en plus du terminal SSH.

Ce TP est utile pour :
- les étudiants qui préfèrent un environnement graphique,
- l’utilisation d’outils comme navigateurs, éditeurs graphiques, etc.

---

## 0. Prérequis

- Un compte cloud (Oracle Cloud par exemple).
- Une VM :
  - Soit **Windows Server/Desktop** (RDP natif),
  - Soit **Ubuntu Desktop** (ou Ubuntu Server + environnement graphique + xrdp).
- Ports ouverts dans les règles de sécurité :
  - **3389/TCP** pour RDP.
- Sur ton PC :
  - Windows : application "Connexion Bureau à distance" (`mstsc`).
  - Linux / macOS : client RDP (ex : Remmina, Microsoft Remote Desktop, etc.).

---

## 1. Cas 1 – VM Windows (plus simple)

Si ta VM est une machine Windows (ex. Windows Server 2019) :

1. Vérifie que le Bureau à distance est activé (généralement déjà configuré sur les images cloud).
2. Note l’IP publique de ta VM : `IP_PUBLIC_WIN`.

### 1.1 – Depuis Windows (PC local)

1. Ouvre **Connexion Bureau à distance** (`mstsc`).
2. Dans "Ordinateur", entre :

```text
IP_PUBLIC_WIN
```

3. Clique sur "Connecter".
4. Entre les identifiants fournis (ex : `Administrator` + mot de passe).

Tu dois voir le bureau Windows de la VM.

### 1.2 – Depuis Linux / macOS

Avec `xfreerdp` ou Remmina (selon l’environnement) :

```bash
xfreerdp /u:Administrator /p:MON_MOT_DE_PASSE /v:IP_PUBLIC_WIN
```

---

## 2. Cas 2 – VM Ubuntu avec environnement graphique + xrdp

Si ta VM est une **Ubuntu Server**, tu peux lui ajouter un environnement graphique + serveur RDP.

> Attention : cela consomme plus de ressources. À utiliser sur des VM avec au moins 2 vCPU et 4 Go de RAM.

### 2.1 – Installer un environnement graphique (Ubuntu)

Sur la VM (via SSH) :

```bash
sudo apt update
sudo apt install -y ubuntu-desktop
```

(ou une variante plus légère comme `xfce4` selon les besoins.)

### 2.2 – Installer xrdp

Toujours sur la VM :

```bash
sudo apt install -y xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp
```

Vérifie le statut :

```bash
sudo systemctl status xrdp
```

### 2.3 – Ouvrir le port RDP dans les règles de sécurité

Dans la console de ton cloud (Oracle Cloud, etc.) :

- Ajoute une règle **ingress** autorisant :
  - Port **3389/TCP**,
  - Depuis ton IP publique ou un range d’adresses approprié.

### 2.4 – Connexion depuis ton PC

1. Récupère l’IP publique de la VM :

```bash
curl ifconfig.me
```

Appelons-la `IP_PUBLIC_UBUNTU`.

2. Sous Windows, lance `mstsc` et tape :

```text
IP_PUBLIC_UBUNTU
```

3. Identifiants :
   - Utilisateur : `ubuntu` (ou autre utilisateur créé).
   - Mot de passe : celui de l’utilisateur.

Tu dois voir un bureau Ubuntu (GNOME, Xfce, etc.) apparaître.

---

## 3. Bonnes pratiques de sécurité

- Restreindre l’accès RDP à **ton IP** (ou à un VPN), pas à "0.0.0.0/0".
- Changer le mot de passe par défaut de l’utilisateur.
- Désactiver RDP quand tu n’en as plus besoin.
- Préférer **SSH** pour l’administration système, utiliser RDP seulement pour des besoins graphiques précis.

---

## 4. Récapitulatif

Dans ce TP, tu as appris à :

- Te connecter en RDP sur une VM Windows.
- Installer un environnement graphique et xrdp sur Ubuntu.
- Accéder à une VM Linux via un client RDP.
- Comprendre les implications de sécurité liées à l’ouverture du port 3389.

RDP est complémentaire au SSH :
- SSH pour les tâches techniques (scripts, Docker, K8s).
- RDP pour l’interface graphique (navigateur, IDE graphique, etc.).
