# Chapitre 2 : VLANs et EtherChannel (Couche 2)

Ce chapitre couvre la création des EtherChannels en couche 2, la configuration des trunks (DTP, VLAN natif, listes VLAN), la mise en place de VTPv2 et la création des VLANs, puis l’affectation des ports d’accès et le lien WLC. Chaque question garde la numérotation d’origine en anglais et inclut objectifs, principes, tableau de commandes et blocs à copier selon les équipements.

---

## 1. Office A : EtherChannel L2 PortChannel1 (protocole Cisco), formation active des deux côtés
*(In Office A, configure a Layer-2 EtherChannel named PortChannel1 between DSW-A1 and DSW-A2 using a Cisco-proprietary protocol. Both switches should actively try to form an EtherChannel.)*

**Objectif :** Agréger plusieurs liens physiques (Gi1/0/4-5) entre `DSW-A1` et `DSW-A2` pour augmenter la bande passante et la redondance.

**Principes :**
- Protocole Cisco propriétaire = PAgP.
- Mode `desirable` tente activement d’établir un EtherChannel.
- Vérification avec CDP et résumé EtherChannel.

| Équipement | Commandes clés |
| :--- | :--- |
| DSW-A1/DSW-A2 | `channel-group 1 mode desirable` (PAgP), `do show etherchannel summary`, `do show cdp neighbors` |

### Code à copier

**Périphériques : DSW-A1, DSW-A2**
```bash
configure terminal
do show cdp neighbors
interface range gigabitEthernet1/0/4-5
 channel-group 1 mode desirable
end
do show etherchannel summary
```

---

## 2. Office B : EtherChannel L2 PortChannel1 (standard ouvert), formation active des deux côtés
*(In Office B, configure a Layer-2 EtherChannel named PortChannel1 between DSW-B1 and DSW-B2 using an open standard protocol. Both switches should actively try to form an EtherChannel.)*

**Objectif :** Agrégat L2 avec protocole standard ouvert (LACP) et mode actif.

**Principes :**
- Standard ouvert = LACP.
- Mode `active` tente activement d’établir l’agrégat.

| Équipement | Commandes clés |
| :--- | :--- |
| DSW-B1/DSW-B2 | `channel-group 1 mode active` (LACP), vérifications `do show etherchannel summary` / `do show cdp neighbors` |

### Code à copier

**Périphériques : DSW-B1, DSW-B2**
```bash
configure terminal
do show cdp neighbors
interface range gigabitEthernet1/0/4-5
 channel-group 1 mode active
end
do show etherchannel summary
```

---

## 3. Tous les liens Access↔Distribution (y compris EtherChannels) en trunk
*(Configure all links between Access and Distribution switches, including the EtherChannels, as trunk links.)*

a) Désactiver explicitement DTP.  
b) VLAN natif = 1000 (non utilisé).  
c) Office A : Autoriser VLANs 10,20,40,99.  
d) Office B : Autoriser VLANs 10,20,30,99.

**Objectif :** Normaliser l’acheminement des VLANs entre Accès et Distribution via des ports trunk sécurisés (sans DTP), avec un VLAN natif non utilisé.

**Principes :**
- `switchport nonegotiate` désactive DTP sur trunks.
- `switchport trunk native vlan 1000` fixe le VLAN natif.
- `switchport trunk allowed vlan ...` restreint la liste des VLANs.

| Site | Équipements | VLANs autorisés |
| :--- | :--- | :--- |
| Office A | DSW-A1/DSW-A2, ASW-A1/A2/A3 | 10,20,40,99 |
| Office B | DSW-B1/DSW-B2, ASW-B1/B2/B3 | 10,20,30,99 |

### Code à copier

**Périphériques : DSW-A1, DSW-A2**
```bash
configure terminal
interface range gigabitEthernet1/0/1-3
 switchport mode trunk
 switchport nonegotiate
 switchport trunk native vlan 1000
 switchport trunk allowed vlan 10,20,40,99
interface port-channel1
 switchport mode trunk
 switchport nonegotiate
 switchport trunk native vlan 1000
 switchport trunk allowed vlan 10,20,40,99
end
```

**Périphériques : ASW-A1, ASW-A2, ASW-A3**
```bash
configure terminal
interface range gigabitEthernet0/1-2
 switchport mode trunk
 switchport nonegotiate
 switchport trunk native vlan 1000
 switchport trunk allowed vlan 10,20,40,99
end
```

**Périphériques : DSW-B1, DSW-B2**
```bash
configure terminal
interface range gigabitEthernet1/0/1-3
 switchport mode trunk
 switchport nonegotiate
 switchport trunk native vlan 1000
 switchport trunk allowed vlan 10,20,30,99
interface port-channel1
 switchport mode trunk
 switchport nonegotiate
 switchport trunk native vlan 1000
 switchport trunk allowed vlan 10,20,30,99
end
```

**Périphériques : ASW-B1, ASW-B2, ASW-B3**
```bash
configure terminal
interface range fastEthernet0/1-2
 switchport mode trunk
 switchport nonegotiate
 switchport trunk native vlan 1000
 switchport trunk allowed vlan 10,20,30,99
end
```

---

## 4. VTPv2 : Serveur de domaine JeremysITLab et clients
*(Configure one of each office’s Distribution switches as a VTPv2 server. Use domain name JeremysITLab.)*

a) Vérifier que les autres commutateurs rejoignent le domaine.  
b) Configurer les commutateurs d’accès en clients.

**Objectif :** Propager automatiquement les définitions VLAN dans un même domaine via VTPv2.

**Principes :**
- Un switch Distribution par site en mode `server`.
- Accès en `client` pour recevoir la base VLAN.

| Site | Serveur VTP | Clients |
| :--- | :--- | :--- |
| Office A | DSW-A1 | ASW-A1/A2/A3 |
| Office B | DSW-B1 | ASW-B1/B2/B3 |

### Code à copier

**Périphériques : DSW-A1 (serveur)**
```bash
configure terminal
do show vtp status
vtp domain JeremysITLab
vtp version 2
vtp mode server
end
```

**Périphériques : ASW-A1, ASW-A2, ASW-A3 (clients)**
```bash
configure terminal
vtp domain JeremysITLab
vtp version 2
vtp mode client
end
```

**Périphériques : DSW-B1 (serveur)**
```bash
configure terminal
do show vtp status
vtp domain JeremysITLab
vtp version 2
vtp mode server
end
```

**Périphériques : ASW-B1, ASW-B2, ASW-B3 (clients)**
```bash
configure terminal
vtp domain JeremysITLab
vtp version 2
vtp mode client
end
```

---

## 5. Office A : Créer et nommer VLANs sur un Distribution (propagation VTP)
*(In Office A, create and name the following VLANs on one of the Distribution switches. Ensure that VTP propagates the changes.)*

- VLAN 10: PCs  
- VLAN 20: Phones  
- VLAN 40: Wi-Fi  
- VLAN 99: Management

**Objectif :** Définir les VLANs sur `DSW-A1` (serveur VTP) pour qu’ils se propagent.

### Code à copier

**Périphériques : DSW-A1**
```bash
configure terminal
vlan 10
 name PCs
vlan 20
 name Phones
vlan 40
 name Wi-Fi
vlan 99
 name Management
end
```

---

## 6. Office B : Créer et nommer VLANs sur un Distribution (propagation VTP)
*(In Office B, create and name the following VLANs on one of the Distribution switches. Ensure that VTP propagates the changes.)*

- VLAN 10: PCs  
- VLAN 20: Phones  
- VLAN 30: Servers  
- VLAN 99: Management

### Code à copier

**Périphériques : DSW-B1**
```bash
configure terminal
vlan 10
 name PCs
vlan 20
 name Phones
vlan 30
 name Servers
vlan 99
 name Management
end
```

---

## 7. Configurer les ports d’accès sur chaque commutateur d’accès
*(Configure each Access switch’s access port.)*

a) Les LWAPs ne utilisent pas FlexConnect.  
b) PCs en VLAN 10, Phones en VLAN 20.  
c) SRV1 en VLAN 30.  
d) Mode accès manuel et désactiver DTP.

**Objectif :** Affecter les VLANs aux ports d’accès selon le type d’équipement et sécuriser l’accès.

**Principes :**
- `switchport mode access` + `switchport nonegotiate`.
- `switchport access vlan <id>`.
- `switchport voice vlan <id>` pour téléphones.

### Code à copier

**Périphériques : ASW-A1, ASW-B1 (exemples management ports)**
```bash
configure terminal
interface fastEthernet0/1
 switchport mode access
 switchport nonegotiate
 switchport access vlan 99
end
```

**Périphériques : ASW-A2, ASW-A3, ASW-B2 (PC + Voice)**
```bash
configure terminal
interface fastEthernet0/1
 switchport mode access
 switchport nonegotiate
 switchport access vlan 10
 switchport voice vlan 20
end
```

**Périphériques : ASW-B3 (serveur SRV1)**
```bash
configure terminal
interface fastEthernet0/1
 switchport mode access
 switchport nonegotiate
 switchport access vlan 30
end
```

---

## 8. Lien ASW-A1 ↔ WLC1
*(Configure ASW-A1’s connection to WLC1)*

a) Supporter VLANs Wi‑Fi (40) et Management (99).  
b) VLAN Management non tagué (natif).  
c) Désactiver DTP.

**Objectif :** Relier WLC à l’ASW avec trunk transportant 40 et 99, VLAN 99 en natif.

### Code à copier

**Périphériques : ASW-A1**
```bash
configure terminal
interface fastEthernet0/2
 switchport mode trunk
 switchport trunk allowed vlan 40,99
 switchport trunk native vlan 99
 switchport nonegotiate
end
```

---

## 9. Désactiver administrativement les ports inutilisés (Accès et Distribution)
*(Administratively disable all unused ports on Access and Distribution switches.)*

**Objectif :** Réduire la surface d’attaque et les erreurs liées aux ports non utilisés.

**Principes :**
- Utiliser `show interface status` pour repérer les ports libres.
- `shutdown` sur plages de ports non utilisés.

### Code à copier

**Périphériques : DSW-A1, DSW-A2, DSW-B1, DSW-B2**
```bash
configure terminal
do show interface status
interface range gigabitEthernet1/0/6-24, gigabitEthernet1/1/3-4
 shutdown
end
write memory
```

**Périphériques : ASW-A1 (exemple)**
```bash
configure terminal
do show interface status
interface range fastEthernet0/3-24
 shutdown
end
write memory
```

**Périphériques : ASW-A2, ASW-A3, ASW-B1, ASW-B2, ASW-B3**
```bash
configure terminal
do show interface status
interface range fastEthernet0/2-24
 shutdown
end
write memory
```

---

## Résumé rapide
- EtherChannels configurés : PAgP (Office A, desirable) et LACP (Office B, active).
- Trunks normalisés : DTP désactivé, VLAN natif 1000, listes VLAN par site.
- VTPv2 : domaine JeremysITLab, serveurs sur DSW-A1 et DSW-B1, clients sur ASW.
- VLANs créés et nommés sur Distribution, propagés via VTP.
- Ports d’accès affectés pour PCs/Phones/Serveur, WLC sur trunk (VLAN 99 natif).
- Ports inutilisés administrativement arrêtés.

> Astuce : Après configuration, vérifiez les états avec `show etherchannel summary`, `show interfaces trunk`, `show vtp status`, et `show vlan brief` pour confirmer la cohérence.
