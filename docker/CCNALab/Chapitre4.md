# 🔀 Lab jeremysitlab — Chapitre 4 : Rapid Spanning Tree (Rapid PVST+) et Sécurité des Ports

Ce chapitre active Rapid PVST+ sur tous les commutateurs d'accès et de distribution, aligne l’élection du Root Bridge STP avec les routeurs HSRP actifs par VLAN, puis sécurise les ports d’accès avec PortFast et BPDU Guard.

---

## 1. Activer Rapid PVST+ et aligner les Root Bridges avec HSRP
*(Configure Rapid PVST+ on all Access and Distribution switches. Ensure that the Root Bridge for each VLAN aligns with the HSRP Active router by configuring the lowest possible STP priority. Configure the HSRP Standby Router for each VLAN with an STP priority one increment above the lowest priority.)*

**Objectif :** Réduire la convergence STP et éviter les boucles, en s’assurant que le trafic L2 passe préférentiellement par le commutateur qui détient la passerelle HSRP active.

**Principes :**
- Rapid PVST+ (Rapid Per-VLAN Spanning Tree) = RSTP par VLAN.
- Priorité STP la plus basse (meilleure) pour le Root = 0 ou 4096 selon plateformes. Ici on utilisera 0 pour Root, 4096 pour Secondary.
- Alignement avec HSRP du Chapitre 3 :
  - Office A : DSW-A1 Root pour VLAN 99,10 ; DSW-A2 Root pour VLAN 20,40.
  - Office B : DSW-B1 Root pour VLAN 99,10 ; DSW-B2 Root pour VLAN 20,30.

| Site | VLANs Root | Root (priority 0) | Secondary (priority 4096) |
| :--- | :--- | :--- | :--- |
| Office A | 10,99 | DSW-A1 | DSW-A2 |
| Office A | 20,40 | DSW-A2 | DSW-A1 |
| Office B | 10,99 | DSW-B1 | DSW-B2 |
| Office B | 20,30 | DSW-B2 | DSW-B1 |

### Code à copier

**Périphériques : DSW-A1, DSW-A2, DSW-B1, DSW-B2, ASW-A1, ASW-A2, ASW-A3, ASW-B1, ASW-B2, ASW-B3 (activer Rapid PVST+)**
```bash
configure terminal
spanning-tree mode rapid-pvst
end
```

**Périphériques : DSW-A1 (Root VLAN 10,99 ; Secondary VLAN 20,40)**
```bash
configure terminal
spanning-tree vlan 10,99 priority 0
spanning-tree vlan 20,40 priority 4096
end
```

**Périphériques : DSW-A2 (Root VLAN 20,40 ; Secondary VLAN 10,99)**
```bash
configure terminal
spanning-tree vlan 20,40 priority 0
spanning-tree vlan 10,99 priority 4096
end
```

**Périphériques : DSW-B1 (Root VLAN 10,99 ; Secondary VLAN 20,30)**
```bash
configure terminal
spanning-tree vlan 10,99 priority 0
spanning-tree vlan 20,30 priority 4096
end
```

**Périphériques : DSW-B2 (Root VLAN 20,30 ; Secondary VLAN 10,99)**
```bash
configure terminal
spanning-tree vlan 20,30 priority 0
spanning-tree vlan 10,99 priority 4096
end
```

---

## 2. Activer PortFast et BPDU Guard sur ports d’hôtes (y compris WLC1)
*(Enable PortFast and BPDU Guard on all ports connected to end hosts (including WLC1). Perform the configurations in interface config mode.)*

**Objectif :** Accélérer l’activation des ports d’extrémité et protéger contre l’injection de BPDUs par erreur sur ces ports.

**Principes :**
- PortFast sur ports d’hôtes (PC, IP Phone, SRV1, WLC) — pas sur les trunks inter‑commutateurs.
- BPDU Guard coupe le port si un BPDU est reçu — utile pour éviter les boucles via équipements clients.
- Appliquer par interface (mode demandé), exemples ci‑dessous.

### Code à copier

**Périphériques : ASW-A1 (exemples : PC/Phone sur F0/1, WLC sur F0/2)**
```bash
configure terminal
interface fastEthernet0/1
 spanning-tree portfast
 spanning-tree bpduguard enable
exit
interface fastEthernet0/2
 spanning-tree portfast trunk
 spanning-tree bpduguard enable
end
```

**Périphériques : ASW-A2, ASW-A3, ASW-B1, ASW-B2, ASW-B3 (ports d’hôtes typiques F0/1)**
```bash
configure terminal
interface fastEthernet0/1
 spanning-tree portfast
 spanning-tree bpduguard enable
end
```

**Périphériques : DSW-A1, DSW-A2, DSW-B1, DSW-B2 (si ports d’hôtes ou WLC directement connectés)**
```bash
configure terminal
interface fastEthernet0/1
 spanning-tree portfast
 spanning-tree bpduguard enable
end
```

> Remarque : N’activez pas PortFast sur les ports trunk entre commutateurs (ex. G0/1‑2, Port‑Channel1). Pour un lien WLC en trunk (ex. ASW-A1 F0/2), utilisez `spanning-tree portfast trunk`.

---

## Vérifications utiles
- `show spanning-tree` (par VLAN) : vérifier les Root Bridges et rôles de ports.
- `show spanning-tree root` : résumé des roots par VLAN.
- `show spanning-tree interface <if>` : état STP d’une interface.
- `show running-config | section spanning-tree` : confirmer les priorités et le mode rapid-pvst.

## Résumé rapide
- Rapid PVST+ activé sur tous les commutateurs d’accès et de distribution.
- Root/Secondary STP par VLAN alignés avec HSRP (A : A1 root 10/99, A2 root 20/40 ; B : B1 root 10/99, B2 root 20/30).
- PortFast + BPDU Guard déployés sur ports d’hôtes (avec PortFast trunk pour WLC).
