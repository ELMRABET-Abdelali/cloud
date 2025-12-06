# Basic TP3 – FTP et FTP sécurisé (FTPS/SFTP) pour transférer des fichiers

**Objectif du TP :**  
Découvrir comment transférer des fichiers entre ton PC et une VM Linux en utilisant :

- **FTP classique** (à éviter en production car non chiffré),
- **FTPS** (FTP sécurisé par TLS),
- **SFTP** (recommandé, via SSH).

Ce TP est fondamental pour envoyer des scripts, fichiers de configuration, pages web, etc., vers tes VMs.

---

## 0. Prérequis

- Une VM Linux accessible :
  - IP publique : `IP_PUBLIC_VM`
  - Accès SSH fonctionnel (Basic TP1).
- Sur ton PC :
  - Un client FTP graphique (ex : **FileZilla**, **WinSCP**) ou en ligne de commande.
- Ports ouverts (selon le protocole) :
  - FTP : 21/TCP (+ ports passifs),
  - FTPS : 21/TCP + TLS,
  - SFTP : 22/TCP (même port que SSH).

> Pour un usage pédagogique et sécurisé, **SFTP** est généralement le meilleur choix.

---

## 1. SFTP – La méthode recommandée (via SSH)

SFTP ne nécessite **aucune installation supplémentaire** si SSH est déjà en place.

### 1.1 – Connexion avec un client graphique (FileZilla)

1. Installe **FileZilla Client** sur ton PC.
2. Ouvre FileZilla.
3. En haut, remplis :
   - **Hôte** : `sftp://IP_PUBLIC_VM`
   - **Identifiant** : `ubuntu` (par exemple)
   - **Mot de passe** : mot de passe de l’utilisateur (ou utilise une clé SSH si configurée).
   - **Port** : `22`
4. Clique sur "Connexion rapide".

Tu verras :
- À gauche : ton système de fichiers local.
- À droite : le système de fichiers de la VM.

Tu peux alors **glisser-déposer** des fichiers pour les transférer.

### 1.2 – Connexion en ligne de commande (Linux / macOS / Windows avec OpenSSH)

```bash
sftp ubuntu@IP_PUBLIC_VM
```

Exemples de commandes SFTP :

```text
ls          # liste des fichiers distants
lcd         # affiche/règle le répertoire local
cd /var/www # changer de dossier distant
put fichier.txt   # upload vers le serveur
get fichier.log   # download vers ton PC
bye         # quitter
```

---

## 2. FTP/FTPS – Mise en place avec vsftpd (optionnel, pour compréhension)

> Partie plus "théorique" : FTP/FTPS est moins utilisé aujourd’hui que SFTP, mais encore présent.

### 2.1 – Installer vsftpd

Sur ta VM Ubuntu :

```bash
sudo apt update
sudo apt install -y vsftpd
```

### 2.2 – Sauvegarder la configuration par défaut

```bash
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
```

### 2.3 – Exemple de configuration de base (FTP + FTPS)

Édite `/etc/vsftpd.conf` (avec `sudo nano /etc/vsftpd.conf`) et assure-toi d’avoir des options du type :

```conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES

# Pour FTPS (TLS)
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
rsa_cert_file=/etc/ssl/certs/vsftpd.pem
```

Génère un certificat auto-signé pour FTPS :

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/vsftpd.key \
  -out /etc/ssl/certs/vsftpd.pem
```

Vérifie que `rsa_cert_file` dans `vsftpd.conf` pointe bien sur le certificat.

Redémarre le service :

```bash
sudo systemctl restart vsftpd
sudo systemctl status vsftpd
```

### 2.4 – Ouvrir le port 21 (et passif) dans le cloud

Dans la console (Oracle Cloud, etc.) :

- Autorise le port **21/TCP**.
- Configure éventuellement une plage de ports passifs et ouvre-les (par ex. 40000-40100/TCP) si tu utilises le mode passif.

Dans `/etc/vsftpd.conf`, tu peux ajouter :

```conf
pasv_min_port=40000
pasv_max_port=40100
```

Puis :

```bash
sudo systemctl restart vsftpd
```

### 2.5 – Connexion FTP/FTPS avec FileZilla

Dans FileZilla :

1. "Gestionnaire de sites" → Nouveau site.
2. Protocole :
   - **FTP - Protocole de transfert de fichiers** ou
   - **FTP sur TLS explicite (FTPS)**.
3. Hôte : `IP_PUBLIC_VM`.
4. Type de chiffrement :
   - "Requérir FTP explicite sur TLS" pour FTPS.
5. Identifiant/mot de passe : utilisateur Linux.
6. Port : `21`.

Connecte-toi et teste l’upload/download.

> Rappelle bien aux étudiants que **FTP simple (sans TLS)** expose les mots de passe en clair et est à proscrire en production.

---

## 3. Comparaison FTP / FTPS / SFTP

- **FTP** :
  - Port 21, non chiffré.
  - Nécessite souvent la configuration des ports passifs.
  - À éviter sauf en environnement de test très contrôlé.

- **FTPS** :
  - FTP + chiffrement TLS.
  - Mieux que FTP, mais plus compliqué à configurer (certificats, pare-feu, passif...).

- **SFTP** :
  - Protocole différent (sur SSH), port 22.
  - Simple à mettre en place si SSH existe déjà.
  - Recommandé pour la **plupart des cas modernes**.

---

## 4. Récapitulatif

Dans ce TP, tu as appris à :

- Utiliser **SFTP** (via SSH) pour transférer des fichiers en toute sécurité.
- Mettre en place un serveur **FTP/FTPS** basique avec `vsftpd`.
- Te connecter en FTP/FTPS/SFTP avec un client comme FileZilla.
- Comprendre les différences de sécurité entre FTP, FTPS et SFTP.

Pour tes futurs TP Docker/K8s, **SFTP** sera généralement suffisant pour pousser des fichiers sur tes VMs.
