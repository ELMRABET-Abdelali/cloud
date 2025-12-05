# Chapitre 3 : Adressage IP, EtherChannel de Couche 3 et HSRP

Ce chapitre traite de la configuration des adresses IP, de la création d’un EtherChannel L3 entre les commutateurs Core, et de la mise en place d’HSRPv2 pour la redondance des passerelles par VLAN.

---

## 1. Configurer les adresses IP sur R1 et activer les interfaces
*(Configure the following IP addresses on R1’s interfaces and enable them)*

a. G0/0/0: DHCP client  
b. G0/1/0: DHCP client  
c. G0/0: 10.0.0.33/30  
d. G0/1: 10.0.0.37/30  
e. Loopback0: 10.0.0.76/32

**Objectif :** Connecter R1 au WAN via DHCP, et établir les liens /30 vers les Core switches, plus une loopback pour l’identification/OSPF.

**Principes :** 
- `ip address dhcp` + `no shutdown` sur les interfaces WAN. 
- /30 pour liens point-à-point. 
- Loopback /32 pour ID routeur et tests.

| Interface | Adresse | Masque |
| :--- | :--- | :--- |
| G0/0/0 | DHCP client | — |
| G0/1/0 | DHCP client | — |
| G0/0 | 10.0.0.33 | 255.255.255.252 |
| G0/1 | 10.0.0.37 | 255.255.255.252 |
| Lo0 | 10.0.0.76 | 255.255.255.255 |

### Code à copier

**Périphérique : R1**
```bash
configure terminal
interface range gigabitEthernet0/0/0, gigabitEthernet0/1/0
 ip address dhcp
 no shutdown
exit
interface gigabitEthernet0/0
 ip address 10.0.0.33 255.255.255.252
 no shutdown
exit
interface gigabitEthernet0/1
 ip address 10.0.0.37 255.255.255.252
 no shutdown
exit
interface loopback0
 ip address 10.0.0.76 255.255.255.255
 no shutdown
end
do show ip interface brief
```

---

## 2. Activer le routage IPv4 sur les Core et Distribution
*(Enable IPv4 routing on all Core and Distribution switches)*

**Objectif :** Permettre le routage L3 sur les commutateurs qui interconnectent les VLANs et relient les sites.

### Code à copier

**Périphériques : CSW1, CSW2, DSW-A1, DSW-A2, DSW-B1, DSW-B2**
```bash
configure terminal
ip routing
end
```

---

## 3. EtherChannel L3 entre CSW1 et CSW2 (protocole Cisco) + Adresses IP
*(Create a Layer-3 EtherChannel between CSW1 and CSW2 using a Cisco-proprietary protocol. Both switches should actively try to form an EtherChannel. Configure the following IP addresses)*

a. CSW1 PortChannel1: 10.0.0.41/30  
b. CSW2 PortChannel1: 10.0.0.42/30

**Objectif :** Agréger des liens physiques L3 entre Core switches, via protocole propriétaire (PAgP) en mode actif (`desirable`).

**Principes :**
- Passer les interfaces membres en L3 (`no switchport`).
- Créer `Port-Channel1` en PAgP (`channel-group 1 mode desirable`).
- Adresser le Port-Channel en /30.

### Code à copier

**Périphérique : CSW1**
```bash
configure terminal
do show cdp neighbors
interface range gigabitEthernet1/0/2-3
 no switchport
 channel-group 1 mode desirable
exit
interface port-channel1
 no switchport
 ip address 10.0.0.41 255.255.255.252
end
do show etherchannel summary
```

**Périphérique : CSW2**
```bash
configure terminal
interface range gigabitEthernet1/0/2-3
 no switchport
 channel-group 1 mode desirable
exit
interface port-channel1
 no switchport
 ip address 10.0.0.42 255.255.255.252
end
do show etherchannel summary
```

---

## 4. Configurer les adresses IP sur CSW1 et désactiver les interfaces inutilisées
*(Configure the following IP addresses on CSW1. Disable all unused interfaces.)*

a. G1/0/1: 10.0.0.34/30  
b. G1/1/1: 10.0.0.45/30  
c. G1/1/2: 10.0.0.49/30  
d. G1/1/3: 10.0.0.53/30  
e. G1/1/4: 10.0.0.57/30  
f. Loopback0: 10.0.0.77/32

**Objectif :** Adresser tous les liens point-à-point vers les Distribution, prévoir une loopback de gestion, et couper les ports inutiles.

### Code à copier

**Périphérique : CSW1**
```bash
configure terminal
interface gigabitEthernet1/0/1
 no switchport
 ip address 10.0.0.34 255.255.255.252
exit
interface gigabitEthernet1/1/1
 no switchport
 ip address 10.0.0.45 255.255.255.252
exit
interface gigabitEthernet1/1/2
 no switchport
 ip address 10.0.0.49 255.255.255.252
exit
interface gigabitEthernet1/1/3
 no switchport
 ip address 10.0.0.53 255.255.255.252
exit
interface gigabitEthernet1/1/4
 no switchport
 ip address 10.0.0.57 255.255.255.252
exit
interface loopback0
 ip address 10.0.0.77 255.255.255.255
exit
interface range gigabitEthernet1/0/4-24
 shutdown
end
```

---

## 5. Configurer les adresses IP sur CSW2 et désactiver les interfaces inutilisées
*(Configure the following IP addresses on CSW2. Disable all unused interfaces.)*

a. G1/0/1: 10.0.0.38/30  
b. G1/1/1: 10.0.0.61/30  
c. G1/1/2: 10.0.0.65/30  
d. G1/1/3: 10.0.0.69/30  
e. G1/1/4: 10.0.0.73/30  
f. Loopback0: 10.0.0.78/32

### Code à copier

**Périphérique : CSW2**
```bash
configure terminal
interface gigabitEthernet1/0/1
 no switchport
 ip address 10.0.0.38 255.255.255.252
exit
interface gigabitEthernet1/1/1
 no switchport
 ip address 10.0.0.61 255.255.255.252
exit
interface gigabitEthernet1/1/2
 no switchport
 ip address 10.0.0.65 255.255.255.252
exit
interface gigabitEthernet1/1/3
 no switchport
 ip address 10.0.0.69 255.255.255.252
exit
interface gigabitEthernet1/1/4
 no switchport
 ip address 10.0.0.73 255.255.255.252
exit
interface loopback0
 ip address 10.0.0.78 255.255.255.255
exit
interface range gigabitEthernet1/0/4-24
 shutdown
end
```

---

## 6–9. Adresses IP sur DSW-A1 / DSW-A2 / DSW-B1 / DSW-B2
*(Configure the following IP addresses on Distribution switches)*

**Objectif :** Adresser les liens entre Core et Distribution et définir des loopbacks de gestion/IGP.

### Code à copier

**Périphérique : DSW-A1**
```bash
configure terminal
interface gigabitEthernet1/1/1
 no switchport
 ip address 10.0.0.46 255.255.255.252
exit
interface gigabitEthernet1/1/2
 no switchport
 ip address 10.0.0.62 255.255.255.252
exit
interface loopback0
 ip address 10.0.0.79 255.255.255.255
end
```

**Périphérique : DSW-A2**
```bash
configure terminal
interface gigabitEthernet1/1/1
 no switchport
 ip address 10.0.0.50 255.255.255.252
exit
interface gigabitEthernet1/1/2
 no switchport
 ip address 10.0.0.66 255.255.255.252
exit
interface loopback0
 ip address 10.0.0.80 255.255.255.255
end
```

**Périphérique : DSW-B1**
```bash
configure terminal
interface gigabitEthernet1/1/1
 no switchport
 ip address 10.0.0.54 255.255.255.252
exit
interface gigabitEthernet1/1/2
 no switchport
 ip address 10.0.0.70 255.255.255.252
exit
interface loopback0
 ip address 10.0.0.81 255.255.255.255
end
```

**Périphérique : DSW-B2**
```bash
configure terminal
interface gigabitEthernet1/1/1
 no switchport
 ip address 10.0.0.58 255.255.255.252
exit
interface gigabitEthernet1/1/2
 no switchport
 ip address 10.0.0.74 255.255.255.252
exit
interface loopback0
 ip address 10.0.0.82 255.255.255.255
end
```

---

## 10. Configurer l’IP statique de SRV1
*(Manually configure SRV1’s IP settings)*

a. Passerelle par défaut: 10.5.0.1  
b. Adresse IPv4: 10.5.0.4  
c. Masque: 255.255.255.0

**Note :** Se fait via l’interface graphique de SRV1 dans Packet Tracer (Desktop → IP Configuration).

---

## 11. IP de gestion sur les Access (interface VLAN 99) + passerelle
*(Configure the following management IP addresses on the Access switches)*

a. ASW-A1: 10.0.0.4/28 (GW 10.0.0.1)  
b. ASW-A2: 10.0.0.5/28 (GW 10.0.0.1)  
c. ASW-A3: 10.0.0.6/28 (GW 10.0.0.1)  
d. ASW-B1: 10.0.0.20/28 (GW 10.0.0.17)  
e. ASW-B2: 10.0.0.21/28 (GW 10.0.0.17)  
f. ASW-B3: 10.0.0.22/28 (GW 10.0.0.17)

### Code à copier

**Périphériques : ASW-A1, ASW-A2, ASW-A3**
```bash
configure terminal
interface vlan 99
 ip address 10.0.0.4 255.255.255.240
exit
ip default-gateway 10.0.0.1
end
```

```bash
configure terminal
interface vlan 99
 ip address 10.0.0.5 255.255.255.240
exit
ip default-gateway 10.0.0.1
end
```

```bash
configure terminal
interface vlan 99
 ip address 10.0.0.6 255.255.255.240
exit
ip default-gateway 10.0.0.1
end
```

**Périphériques : ASW-B1, ASW-B2, ASW-B3**
```bash
configure terminal
interface vlan 99
 ip address 10.0.0.20 255.255.255.240
exit
ip default-gateway 10.0.0.17
end
```

```bash
configure terminal
interface vlan 99
 ip address 10.0.0.21 255.255.255.240
exit
ip default-gateway 10.0.0.17
end
```

```bash
configure terminal
interface vlan 99
 ip address 10.0.0.22 255.255.255.240
exit
ip default-gateway 10.0.0.17
end
```

---

## 12–15. HSRPv2 pour Office A (VLAN 99, 10, 20, 40)
*(Configure HSRPv2 groups for Office A subnets)*

**Objectif :** Assurer une passerelle virtuelle haute disponibilité via HSRP, avec routeur actif différent selon le VLAN.

### VLAN 99 — Groupe 1 (Active: DSW-A1)
- Subnet: 10.0.0.0/28  
- VIP: 10.0.0.1  
- DSW-A1: 10.0.0.2 (priorité 105, preempt)  
- DSW-A2: 10.0.0.3

**Périphériques : DSW-A1**
```bash
configure terminal
interface vlan 99
 ip address 10.0.0.2 255.255.255.240
 standby version 2
 standby 1 ip 10.0.0.1
 standby 1 priority 105
 standby 1 preempt
end
```

**Périphériques : DSW-A2**
```bash
configure terminal
interface vlan 99
 ip address 10.0.0.3 255.255.255.240
 standby version 2
 standby 1 ip 10.0.0.1
end
```

### VLAN 10 — Groupe 2 (Active: DSW-A1)
- Subnet: 10.1.0.0/24  
- VIP: 10.1.0.1  
- DSW-A1: 10.1.0.2 (priorité 105, preempt)  
- DSW-A2: 10.1.0.3

**Périphériques : DSW-A1**
```bash
configure terminal
interface vlan 10
 ip address 10.1.0.2 255.255.255.0
 standby version 2
 standby 2 ip 10.1.0.1
 standby 2 priority 105
 standby 2 preempt
end
```

**Périphériques : DSW-A2**
```bash
configure terminal
interface vlan 10
 ip address 10.1.0.3 255.255.255.0
 standby version 2
 standby 2 ip 10.1.0.1
end
```

### VLAN 20 — Groupe 3 (Active: DSW-A2)
- Subnet: 10.2.0.0/24  
- VIP: 10.2.0.1  
- DSW-A1: 10.2.0.2  
- DSW-A2: 10.2.0.3 (priorité 105, preempt)

**Périphériques : DSW-A1**
```bash
configure terminal
interface vlan 20
 ip address 10.2.0.2 255.255.255.0
 standby version 2
 standby 3 ip 10.2.0.1
end
```

**Périphériques : DSW-A2**
```bash
configure terminal
interface vlan 20
 ip address 10.2.0.3 255.255.255.0
 standby version 2
 standby 3 ip 10.2.0.1
 standby 3 priority 105
 standby 3 preempt
end
```

### VLAN 40 — Groupe 4 (Active: DSW-A2)
- Subnet: 10.6.0.0/24  
- VIP: 10.6.0.1  
- DSW-A1: 10.6.0.2  
- DSW-A2: 10.6.0.3 (priorité 105, preempt)

**Périphériques : DSW-A1**
```bash
configure terminal
interface vlan 40
 ip address 10.6.0.2 255.255.255.0
 standby version 2
 standby 4 ip 10.6.0.1
end
```

**Périphériques : DSW-A2**
```bash
configure terminal
interface vlan 40
 ip address 10.6.0.3 255.255.255.0
 standby version 2
 standby 4 ip 10.6.0.1
 standby 4 priority 105
 standby 4 preempt
end
```

---

## 16–19. HSRPv2 pour Office B (VLAN 99, 10, 20, 30)
*(Configure HSRPv2 groups for Office B subnets)*

### VLAN 99 — Groupe 1 (Active: DSW-B1)
- Subnet: 10.0.0.16/28  
- VIP: 10.0.0.17  
- DSW-B1: 10.0.0.18 (priorité 105, preempt)  
- DSW-B2: 10.0.0.19

**Périphériques : DSW-B1**
```bash
configure terminal
interface vlan 99
 ip address 10.0.0.18 255.255.255.240
 standby version 2
 standby 1 ip 10.0.0.17
 standby 1 priority 105
 standby 1 preempt
end
```

**Périphériques : DSW-B2**
```bash
configure terminal
interface vlan 99
 ip address 10.0.0.19 255.255.255.240
 standby version 2
 standby 1 ip 10.0.0.17
end
```

### VLAN 10 — Groupe 2 (Active: DSW-B1)
- Subnet: 10.3.0.0/24  
- VIP: 10.3.0.1  
- DSW-B1: 10.3.0.2 (priorité 105, preempt)  
- DSW-B2: 10.3.0.3

**Périphériques : DSW-B1**
```bash
configure terminal
interface vlan 10
 ip address 10.3.0.2 255.255.255.0
 standby version 2
 standby 2 ip 10.3.0.1
 standby 2 priority 105
 standby 2 preempt
end
```

**Périphériques : DSW-B2**
```bash
configure terminal
interface vlan 10
 ip address 10.3.0.3 255.255.255.0
 standby version 2
 standby 2 ip 10.3.0.1
end
```

### VLAN 20 — Groupe 3 (Active: DSW-B2)
- Subnet: 10.4.0.0/24  
- VIP: 10.4.0.1  
- DSW-B1: 10.4.0.2  
- DSW-B2: 10.4.0.3 (priorité 105, preempt)

**Périphériques : DSW-B1**
```bash
configure terminal
interface vlan 20
 ip address 10.4.0.2 255.255.255.0
 standby version 2
 standby 3 ip 10.4.0.1
end
```

**Périphériques : DSW-B2**
```bash
configure terminal
interface vlan 20
 ip address 10.4.0.3 255.255.255.0
 standby version 2
 standby 3 ip 10.4.0.1
 standby 3 priority 105
 standby 3 preempt
end
```

### VLAN 30 — Groupe 4 (Active: DSW-B2)
- Subnet: 10.5.0.0/24  
- VIP: 10.5.0.1  
- DSW-B1: 10.5.0.2  
- DSW-B2: 10.5.0.3 (priorité 105, preempt)

**Périphériques : DSW-B1**
```bash
configure terminal
interface vlan 30
 ip address 10.5.0.2 255.255.255.0
 standby version 2
 standby 4 ip 10.5.0.1
end
```

**Périphériques : DSW-B2**
```bash
configure terminal
interface vlan 30
 ip address 10.5.0.3 255.255.255.0
 standby version 2
 standby 4 ip 10.5.0.1
 standby 4 priority 105
 standby 4 preempt
end
```

---

## Résumé rapide
- R1: interfaces DHCP et /30 configurées + loopback /32.
- Core/Distribution: `ip routing` activé.
- EtherChannel L3 entre CSW1 et CSW2 via PAgP, adresses /30 sur Po1.
- Tous les liens Core↔Distribution adressés en /30, loopbacks /32.
- HSRPv2 opérationnel: passerelles virtuelles par VLAN et priorités adaptées.

> Astuce : Vérifiez avec `show ip interface brief`, `show etherchannel summary`, `show standby brief`, et testez la bascule HSRP en ajustant l’état des liens si nécessaire.
