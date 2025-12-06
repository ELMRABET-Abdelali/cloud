# Basic TP1 – Connexion SSH à une machine Linux (Oracle Cloud ou autre)

**Objectif du TP :**  
Apprendre à se connecter en **SSH** à une machine Linux distante (par exemple une VM Oracle Cloud) depuis ton PC, et vérifier les premiers éléments système.

Ce TP est fondamental avant tous les autres, car presque toutes les opérations Docker / Kubernetes se font via SSH.

---

## 0. Prérequis

- Un compte sur un fournisseur cloud (Oracle Cloud, etc.).
- Une VM Linux déjà créée (Ubuntu de préférence).  
  Exemple :
  - Nom : `vm-docker`
  - Adresse IP publique : `IP_PUBLIC_VM`
- Une **clé SSH** générée ou un mot de passe root/ubuntu (selon la configuration).
- Sur ton PC :
  - Windows : **PowerShell** ou un client SSH comme **PuTTY**.
  - Linux / macOS : terminal avec la commande `ssh`.

> Ce TP montre les commandes génériques. Adapte les noms d’utilisateur (`ubuntu`, `opc`, etc.) à ton image cloud.

---

## 1. Générer une paire de clés SSH (si besoin)

Si tu n’as pas encore de clé SSH sur ton PC, génère-en une.

### 1.1 – Sous Windows (PowerShell, OpenSSH)

Dans PowerShell :

```powershell
ssh-keygen -t rsa -b 4096 -C "mon-email@example.com"
```

- Appuie sur **Entrée** pour accepter le chemin par défaut (`C:\Users\\TON_USER\\.ssh\\id_rsa`).
- Mets une **passphrase** (mot de passe) ou laisse vide pour les tests.

La clé publique sera dans `id_rsa.pub`, la clé privée dans `id_rsa`.

### 1.2 – Sous Linux / macOS

Même commande :

```bash
ssh-keygen -t rsa -b 4096 -C "mon-email@example.com"
```

Les fichiers seront dans `~/.ssh/`.

---

## 2. Associer la clé SSH à ta VM

Selon ton fournisseur cloud, tu as deux cas :

1. **Clé publique fournie à la création de la VM** (cas le plus courant) :
   - Tu colles le contenu de `id_rsa.pub` dans le champ "SSH key" lors de la création.
   - L’utilisateur sera souvent `ubuntu`, `opc`, ou `ec2-user`.

2. **Ajout manuel après création** (moins recommandé pour débutant) :
   - Tu dois avoir un accès temporaire (mot de passe, console web) pour ajouter la clé dans `~/.ssh/authorized_keys`.

> Réfère-toi à ton PDF Oracle Cloud pour le détail de l’association clé/VM.

---

## 3. Connexion SSH depuis ton PC

### 3.1 – Connaître l’adresse IP

Note l’IP publique de ta VM, par exemple :

```text
IP_PUBLIC_VM = 132.145.xxx.xxx
```

### 3.2 – Sous Windows (PowerShell, OpenSSH)

```powershell
ssh ubuntu@IP_PUBLIC_VM
```

Exemples :

```powershell
ssh ubuntu@132.145.10.20
```

Si tu as utilisé une clé différente (non par défaut) :

```powershell
ssh -i C:\Users\TON_USER\.ssh\id_rsa ubuntu@132.145.10.20
```

### 3.3 – Sous Linux / macOS

```bash
ssh ubuntu@IP_PUBLIC_VM
# ou
ssh -i ~/.ssh/id_rsa ubuntu@IP_PUBLIC_VM
```

### 3.4 – Accepter la clé du serveur

Au premier accès :

```text
The authenticity of host 'IP_PUBLIC_VM (IP_PUBLIC_VM)' can't be established.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Tape :

```text
yes
```

Tu es maintenant connecté (invite du type `ubuntu@vm-docker:~$`).

---

## 4. Vérifications de base après connexion

Une fois connecté en SSH :

### 4.1 – Vérifier l’utilisateur et le hostname

```bash
whoami
hostname
```

### 4.2 – Vérifier la version d’Ubuntu

```bash
lsb_release -a
```

ou :

```bash
cat /etc/os-release
```

### 4.3 – Vérifier la connectivité Internet

```bash
ping -c 3 google.com
```

### 4.4 – Mettre à jour le système (optionnel, mais recommandé)

```bash
sudo apt update
sudo apt upgrade -y
```

---

## 5. Se déconnecter proprement

Pour quitter la session SSH :

```bash
exit
```

ou `Ctrl + D`.

---

## 6. Récapitulatif

Dans ce TP, tu as appris à :

- Générer une paire de clés SSH sur ton PC.
- Associer une clé publique à une VM cloud.
- Te connecter en SSH depuis Windows/Linux/macOS.
- Vérifier quelques informations système sur la VM.
- Te déconnecter proprement.

Ces gestes seront répétés dans pratiquement tous les autres TP (Docker, Swarm, Kubernetes).
