# 📚 Lab jeremysitlab — Chapitre 1 : Configuration de Base et Accès Sécurisé

Ce chapitre couvre la configuration initiale indispensable pour sécuriser l'accès et identifier clairement chaque équipement dans le lab.

---

## 1. Configurer le nom d'hôte approprié sur chaque routeur/commutateur
*(Configure the appropriate hostname on each router/switch)*

**Objectif :** Donner un nom unique et parlant à chaque équipement (ex. R1, CSW1, DSW-A1) pour simplifier la gestion, la documentation et le dépannage.

**Principe clé :** Le nom d'hôte apparaît dans l'invite CLI et dans les logs, facilitant l'identification rapide du périphérique.

| Type d'Équipement | Commande Cisco IOS | Exemple |
| :--- | :--- | :--- |
| Tous | `hostname <Nom>` | `hostname R1` |

### Code à copier
- À coller dans les périphériques listés avant chaque bloc.

**Périphériques : R1**
```bash
configure terminal
hostname R1
end
```

**Périphériques : CSW1, CSW2 (Core Switches)**
```bash
configure terminal
hostname CSW1
end
```
```bash
configure terminal
hostname CSW2
end
```

**Périphériques : DSW-A1, DSW-A2, DSW-B1, DSW-B2 (Distribution Switches)**
```bash
configure terminal
hostname DSW-A1
end
```
```bash
configure terminal
hostname DSW-A2
end
```
```bash
configure terminal
hostname DSW-B1
end
```
```bash
configure terminal
hostname DSW-B2
end
```

**Périphériques : ASW-A1, ASW-A2, ASW-A3, ASW-B1, ASW-B2, ASW-B3 (Access Switches)**
```bash
configure terminal
hostname ASW-A1
end
```
```bash
configure terminal
hostname ASW-A2
end
```
```bash
configure terminal
hostname ASW-A3
end
```
```bash
configure terminal
hostname ASW-B1
end
```
```bash
configure terminal
hostname ASW-B2
end
```
```bash
configure terminal
hostname ASW-B3
end
```

---

## 2. Configurer le secret d'activation (enable secret)
*(Configure the enable secret jeremysitlab on each router/switch. Use type 9 hashing if available; otherwise, use type 5.)*

**Objectif :** Sécuriser l'accès au mode privilégié (`enable`) avec un mot de passe chiffré.

**Principes :**
- Type 9 (scrypt) = le plus sûr, disponible sur les plates-formes plus récentes.
- Type 5 (MD5) = par défaut sur certaines plateformes/IOS plus anciennes.

| Type d'Équipement | Commande | Type de hachage |
| :--- | :--- | :--- |
| CSW/DSW (Core/Distribution) | `enable algorithm-type scrypt secret jeremysitlab` | Type 9 (scrypt) |
| R/ASW (Routeurs/Access) | `enable secret jeremysitlab` | Type 5 (MD5 par défaut) |

### Code à copier

**Périphériques : CSW1, CSW2 (Core)**
```bash
configure terminal
enable algorithm-type scrypt secret jeremysitlab
end
```

**Périphériques : DSW-A1, DSW-A2, DSW-B1, DSW-B2 (Distribution)**
```bash
configure terminal
enable algorithm-type scrypt secret jeremysitlab
end
```

**Périphériques : R1, ASW-A1, ASW-A2, ASW-A3, ASW-B1, ASW-B2, ASW-B3 (Routeur/Accès)**
```bash
configure terminal
enable secret jeremysitlab
end
```

---

## 3. Créer le compte utilisateur local `cisco` avec le secret `ccna`
*(Configure the user account cisco with secret ccna on each router/switch. Use type 9 hashing if available; otherwise, use type 5.)*

**Objectif :** Permettre l'authentification locale via la console et les lignes VTY (Telnet/SSH).

**Principe :** Même logique de hachage que pour `enable secret`.

| Type d'Équipement | Commande | Type de hachage |
| :--- | :--- | :--- |
| CSW/DSW (Core/Distribution) | `username cisco algorithm-type scrypt secret ccna` | Type 9 (scrypt) |
| R/ASW (Routeurs/Accès) | `username cisco secret ccna` | Type 5 (MD5) |

### Code à copier

**Périphériques : CSW1, CSW2 (Core)**
```bash
configure terminal
username cisco algorithm-type scrypt secret ccna
end
```

**Périphériques : DSW-A1, DSW-A2, DSW-B1, DSW-B2 (Distribution)**
```bash
configure terminal
username cisco algorithm-type scrypt secret ccna
end
```

**Périphériques : R1, ASW-A1, ASW-A2, ASW-A3, ASW-B1, ASW-B2, ASW-B3 (Routeur/Accès)**
```bash
configure terminal
username cisco secret ccna
end
```

---

## 4. Sécuriser et améliorer la ligne console
*(Configure the console line to require login with a local user account. Set a 30-minute inactivity timeout. Enable synchronous logging.)*

**Objectif :** Exiger une authentification locale, définir un délai d'inactivité et éviter que les logs n'interrompent la saisie.

**Principes :**
- `login local` impose l'usage du compte local (ex. `cisco`/`ccna`).
- `exec-timeout 30 0` déconnecte après 30 minutes (30 minutes, 0 secondes).
- `logging synchronous` aligne les messages pour ne pas gêner la saisie.

| Fonction | Commande | Explication |
| :--- | :--- | :--- |
| Authentification locale | `login local` | Utilise les comptes définis par `username` |
| Délai inactivité | `exec-timeout 30 0` | 30 minutes d'inactivité |
| Logging synchrone | `logging synchronous` | Empêche les messages de couper la saisie |

### Code à copier

**Périphériques : R1, CSW1, CSW2, DSW-A1, DSW-A2, DSW-B1, DSW-B2, ASW-A1, ASW-A2, ASW-A3, ASW-B1, ASW-B2, ASW-B3 (Tous)**
```bash
configure terminal
line console 0
 login local
 exec-timeout 30 0
 logging synchronous
end
```

---

## Résumé rapide
- Noms d'hôte configurés sur tous les équipements.
- Secret `enable` en type 9 (scrypt) pour Core/Distribution, type 5 par défaut pour Routeur/Accès.
- Compte local `cisco/ccna` créé avec hachage approprié.
- Ligne console sécurisée et confortable (login local, timeout, logging sync).

> Astuce : Répétez les blocs pour chaque périphérique concerné. Vous pouvez aussi utiliser des outils d'automatisation (ex. scripts CLI ou Ansible) pour accélérer la configuration sur plusieurs équipements.
