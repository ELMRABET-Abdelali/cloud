# 📚 Lab jeremysitlab - Chapitre 1 : Configuration de Base et Accès Sécurisé

Ce chapitre couvre la configuration initiale essentielle pour sécuriser l'accès et identifier les équipements dans le laboratoire.

---

## 1. Configurer le Nom d'Hôte Approprié sur Chaque Routeur/Commutateur
*(Configure the appropriate hostname on each router/switch)*

**Objectif :** Attribuer un nom d'hôte unique et identifiable à chaque équipement (ex: R1, CSW1, DSW-A1, etc.) pour faciliter la gestion et le dépannage.

| Type d'Équipement | Commande Cisco IOS | Note |
| :--- | :--- | :--- |
| **Tous les Équipements** | `hostname [Nom_de_l'équipement]` | Exemple : `hostname R1` |

---

## 2. Configurer le Secret d'Activation (`enable secret jeremysitlab`)
*(Configure the enable secret jeremysitlab on each router/switch. Use type 9 hashing if available; otherwise, use type 5.)*

**Objectif :** Sécuriser l'accès au mode privilégié (mode `enable`) avec un mot de passe chiffré.

* **Type 9 (Scrypt)** est le hachage le plus sûr et est utilisé sur les équipements modernes (Core/Distribution Switches).
* **Type 5 (MD5)** est utilisé si le Type 9 n'est pas disponible (Routeurs/Access Switches).

| Type d'Équipement | Commande Cisco IOS | Type de Hachage |
| :--- | :--- | :--- |
| **Commutateurs Cœur (CSW) et de Distribution (DSW)** | `enable algorithm-type scrypt secret jeremysitlab` | Type 9 (Scrypt) |
| **Routeurs (R) et Commutateurs d'Accès (ASW)** | `enable secret jeremysitlab` | Type 5 (MD5) par défaut |

---

## 3. Configurer le Compte Utilisateur `cisco` avec le Secret `ccna`
*(Configure the user account cisco with secret ccna on each router/switch. Use type 9 hashing if available; otherwise, use type 5.)*

**Objectif :** Créer un compte utilisateur local qui sera utilisé pour l'authentification lors de la connexion via la console ou VTY (Telnet/SSH).

| Type d'Équipement | Commande Cisco IOS | Type de Hachage |
| :--- | :--- | :--- |
| **Commutateurs Cœur (CSW) et de Distribution (DSW)** | `username cisco algorithm-type scrypt secret ccna` | Type 9 (Scrypt) |
| **Routeurs (R) et Commutateurs d'Accès (ASW)** | `username cisco secret ccna` | Type 5 (MD5) par défaut |

---

## 4. Configuration de la Ligne Console
*(Configure the console line to require login with a local user account. Set a 30-minute inactivity timeout. Enable synchronous logging.)*

**Objectif :** Sécuriser la ligne d'accès physique (Console) et améliorer l'expérience utilisateur.

| Fonctionnalité | Commande Cisco IOS | Explication |
| :--- | :--- | :--- |
| **Authentification locale** | `login local` | Exige l'utilisation d'un compte utilisateur local (`cisco` / `ccna`). |
| **Délai d'inactivité** | `exec-timeout 30 0` | Déconnecte l'utilisateur après 30 minutes d'inactivité. |
| **Synchronous Logging** | `logging synchronous` | Empêche les messages système d'interrompre la saisie de l'utilisateur. |

```bash
configure terminal
line console 0
 login local
 exec-timeout 30 0
 logging synchronous
end
