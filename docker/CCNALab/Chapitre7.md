# 🛡️ Lab jeremysitlab — Chapitre 7 : Sécurité (ACL et Fonctions de Sécurité de Couche 2)

Ce chapitre met en place une ACL étendue entre les sous-réseaux PC des deux bureaux et déploie des protections L2 côté accès: Port Security, DHCP Snooping et Dynamic ARP Inspection (DAI).

---

## 1. ACL étendue OfficeA_to_OfficeB
*(Configure extended ACL OfficeA_to_OfficeB where appropriate)*

a. Autoriser l’ICMP du sous-réseau PC du Bureau A vers le sous-réseau PC du Bureau B.  
b. Bloquer tout autre trafic de A-PCs vers B-PCs.  
c. Autoriser tout le reste.  
d. Appliquer l’ACL selon les bonnes pratiques (près de la source, en entrée sur l’interface VLAN source).

**Objectif :** Permettre les tests (ping) depuis A→B, bloquer les autres flux A→B, et ne pas perturber le reste du trafic.

**Principes :**
- Sous-réseaux: Office A PCs = 10.1.0.0/24; Office B PCs = 10.3.0.0/24.
- Placement: inbound sur le SVI du VLAN 10 côté Bureau A (Distribution), proche de la source.

### Code à copier

**Périphériques : DSW-A1, DSW-A2**
```bash
configure terminal
ip access-list extended OfficeA_to_OfficeB
 permit icmp 10.1.0.0 0.0.0.255 10.3.0.0 0.0.0.255
 deny   ip   10.1.0.0 0.0.0.255 10.3.0.0 0.0.0.255
 permit ip any any
exit
interface vlan 10
 ip access-group OfficeA_to_OfficeB in
end
```

> Vérifications: `show ip access-lists OfficeA_to_OfficeB`, `show ip interface vlan 10`.

---

## 2. Port Security sur les ports d’accès F0/1
*(Configure Port Security on each Access switch's F0/1 port)*

a. Autoriser le minimum de MAC par port.  
- SRV1 (pas de virtualisation) = 1 MAC.  
- Ports avec PC+Phone = 2 MAC.  
- Ports management/LWAP uniques = 1 MAC.  
b. Mode de violation: bloquer le trafic invalide sans impacter le valide, avec notifications → `restrict`.  
c. Sauvegarde des MAC apprises dans la running-config → `sticky`.

**Objectif :** Empêcher les usurpations/mini-hubs sur les ports utilisateurs.

### Code à copier

**Périphériques : ASW-A1, ASW-B1 (ports de management typiques), ASW-B3 (SRV1)**
```bash
configure terminal
interface fastEthernet0/1
 switchport port-security
 switchport port-security violation restrict
 switchport port-security mac-address sticky
 ! maximum par défaut = 1 (suffisant pour management/SRV1)
end
```

**Périphériques : ASW-A2, ASW-A3, ASW-B2 (PC + Phone sur le même port via voix/données)**
```bash
configure terminal
interface fastEthernet0/1
 switchport port-security
 switchport port-security maximum 2
 switchport port-security violation restrict
 switchport port-security mac-address sticky
end
```

> Vérifications: `show port-security interface f0/1`.

---

## 3. DHCP Snooping sur tous les Access
*(Enable DHCP Snooping for active VLANs; trust uplinks; disable Option 82; rate limit)*

a. Activer sur tous les VLANs actifs de chaque LAN.  
b. Marquer en `trust` les uplinks vers Distribution (G0/1–2).  
c. Désactiver l’injection Option 82.  
d. Limiter à 15 pps sur ports non‑fiables actifs.  
e. Mettre 100 pps sur le lien ASW-A1 ↔ WLC1 (F0/2).

**Objectif :** Éviter les serveurs DHCP pirates et saturations.

### Code à copier

**Périphériques : ASW-A1**
```bash
configure terminal
ip dhcp snooping
ip dhcp snooping vlan 10,20,40,99
no ip dhcp snooping information option
interface range gigabitEthernet0/1-2
 ip dhcp snooping trust
exit
interface fastEthernet0/1
 ip dhcp snooping limit rate 15
exit
interface fastEthernet0/2
 ip dhcp snooping limit rate 100
end
```

**Périphériques : ASW-A2, ASW-A3**
```bash
configure terminal
ip dhcp snooping
ip dhcp snooping vlan 10,20,40,99
no ip dhcp snooping information option
interface range gigabitEthernet0/1-2
 ip dhcp snooping trust
exit
interface fastEthernet0/1
 ip dhcp snooping limit rate 15
end
```

**Périphériques : ASW-B1, ASW-B2, ASW-B3**
```bash
configure terminal
ip dhcp snooping
ip dhcp snooping vlan 10,20,30,99
no ip dhcp snooping information option
interface range gigabitEthernet0/1-2
 ip dhcp snooping trust
exit
interface fastEthernet0/1
 ip dhcp snooping limit rate 15
end
```

> Vérifications: `show ip dhcp snooping`, `show ip dhcp snooping binding`.

---

## 4. Dynamic ARP Inspection (DAI) sur tous les Access
*(Enable DAI for active VLANs; trust uplinks; validate all checks)*

a. Activer DAI sur tous les VLANs actifs de chaque LAN.  
b. `trust` sur uplinks vers Distribution.  
c. Activer toutes les validations: source MAC, destination MAC et IP.

**Objectif :** Bloquer l’ARP spoofing/poisoning.

### Code à copier

**Périphériques : ASW-A1, ASW-A2, ASW-A3**
```bash
configure terminal
ip arp inspection vlan 10,20,40,99
ip arp inspection validate src-mac dst-mac ip
interface range gigabitEthernet0/1-2
 ip arp inspection trust
end
```

**Périphériques : ASW-B1, ASW-B2, ASW-B3**
```bash
configure terminal
ip arp inspection vlan 10,20,30,99
ip arp inspection validate src-mac dst-mac ip
interface range gigabitEthernet0/1-2
 ip arp inspection trust
end
```

> Remarque : DAI s’appuie sur la base DHCP Snooping; assurez-vous que le snooping est actif et que les liaisons de confiance sont correctement définies.

---

## Résumé rapide
- ACL étendue appliquée en entrée sur `VLAN 10` (Bureau A PCs): ICMP autorisé vers B‑PCs, autres flux A→B bloqués, reste autorisé.
- Port Security: `restrict + sticky`, max 1 pour SRV1/gestion/LWAP, max 2 pour PC+Phone.
- DHCP Snooping: VLANs actifs, uplinks en trust, Option 82 désactivée, limites pps (100 pps pour WLC sur ASW-A1 F0/2).
- DAI: activé sur VLANs actifs, uplinks en trust, validations complètes.
