# 🛣️ Lab jeremysitlab — Chapitre 5 : Routage Statique et Dynamique (OSPF)

Ce chapitre active OSPF sur R1 (interfaces LAN) ainsi que sur tous les commutateurs Core et Distribution (interfaces de couche 3), puis configure les routes par défaut statiques vers Internet sur R1, avec redistribution (ASBR) de la route par défaut dans OSPF.

---

## 1. OSPF sur R1, CSW1/CSW2 et DSW-A/B (process 1, area 0)
*(Configure OSPF on R1 (LAN-facing interfaces) and all Core and Distribution switches (all Layer-3 interfaces). Use process ID 1 and Area 0. Manually configure RID per loopback IP. On switches, use network statements to match exact interface IPs. On R1, enable OSPF in interface config mode. Enable OSPF on loopbacks, but make loopbacks passive; Distribution SVIs (except Management) should also be passive. Use point-to-point network type on physical neighbor links; keep default type on CSW Port-Channel.)*

**Objectif :** Mettre en place un IGP OSPF cohérent entre Core et Distribution, avec identifiants stables et paramètres adaptés aux liens point-à-point.

**Principes clés :**
- Processus `router ospf 1` dans `area 0` partout.
- `router-id` forcé sur l’IP de loopback (voir Chapitre 3).
- Sur les commutateurs (CSW/DSW), utiliser `network <ip> 0.0.0.0 area 0` par interface.
- Sur R1, activer OSPF via `ip ospf 1 area 0` sur chaque interface LAN (G0/0 et G0/1) et loopback.
- Rendre `loopback0` passive sur tous les équipements, et SVIs des VLAN (Distribution) passives (sauf VLAN de management 99).
- Type de réseau OSPF `point-to-point` sur les liens physiques entre voisins (Gi...), pas sur `Port-Channel1` (laisser par défaut).

### Code à copier

**Périphérique : R1**
```bash
configure terminal
router ospf 1
 router-id 10.0.0.76
 passive-interface loopback0
exit
interface loopback0
 ip ospf 1 area 0
exit
interface range gigabitEthernet0/0, gigabitEthernet0/1
 ip ospf 1 area 0
 ip ospf network point-to-point
end
```

**Périphérique : CSW1**
```bash
configure terminal
router ospf 1
 router-id 10.0.0.77
 passive-interface loopback0
 ! déclarations précises par interface L3
 network 10.0.0.41 0.0.0.0 area 0   ! Po1 L3
 network 10.0.0.34 0.0.0.0 area 0   ! G1/0/1
 network 10.0.0.45 0.0.0.0 area 0   ! G1/1/1
 network 10.0.0.49 0.0.0.0 area 0   ! G1/1/2
 network 10.0.0.53 0.0.0.0 area 0   ! G1/1/3
 network 10.0.0.57 0.0.0.0 area 0   ! G1/1/4
 network 10.0.0.77 0.0.0.0 area 0   ! Lo0
exit
interface range gigabitEthernet1/0/1, gigabitEthernet1/1/1-4
 ip ospf network point-to-point
end
```

**Périphérique : CSW2**
```bash
configure terminal
router ospf 1
 router-id 10.0.0.78
 passive-interface loopback0
 network 10.0.0.42 0.0.0.0 area 0   ! Po1 L3
 network 10.0.0.38 0.0.0.0 area 0   ! G1/0/1
 network 10.0.0.61 0.0.0.0 area 0   ! G1/1/1
 network 10.0.0.65 0.0.0.0 area 0   ! G1/1/2
 network 10.0.0.69 0.0.0.0 area 0   ! G1/1/3
 network 10.0.0.73 0.0.0.0 area 0   ! G1/1/4
 network 10.0.0.78 0.0.0.0 area 0   ! Lo0
exit
interface range gigabitEthernet1/0/1, gigabitEthernet1/1/1-4
 ip ospf network point-to-point
end
```

**Périphérique : DSW-A1**
```bash
configure terminal
router ospf 1
 router-id 10.0.0.79
 passive-interface loopback0
 passive-interface vlan 10
 passive-interface vlan 20
 passive-interface vlan 40
 ! déclarations précises
 network 10.0.0.46 0.0.0.0 area 0
 network 10.0.0.62 0.0.0.0 area 0
 network 10.0.0.79 0.0.0.0 area 0
 network 10.1.0.2 0.0.0.0 area 0
 network 10.2.0.2 0.0.0.0 area 0
 network 10.6.0.2 0.0.0.0 area 0
 network 10.0.0.2 0.0.0.0 area 0
exit
interface range gigabitEthernet1/1/1-2
 ip ospf network point-to-point
end
```

**Périphérique : DSW-A2**
```bash
configure terminal
router ospf 1
 router-id 10.0.0.80
 passive-interface loopback0
 passive-interface vlan 10
 passive-interface vlan 20
 passive-interface vlan 40
 network 10.0.0.50 0.0.0.0 area 0
 network 10.0.0.66 0.0.0.0 area 0
 network 10.0.0.80 0.0.0.0 area 0
 network 10.1.0.3 0.0.0.0 area 0
 network 10.2.0.3 0.0.0.0 area 0
 network 10.6.0.3 0.0.0.0 area 0
 network 10.0.0.3 0.0.0.0 area 0
exit
interface range gigabitEthernet1/1/1-2
 ip ospf network point-to-point
end
```

**Périphérique : DSW-B1**
```bash
configure terminal
router ospf 1
 router-id 10.0.0.81
 passive-interface loopback0
 passive-interface vlan 10
 passive-interface vlan 20
 passive-interface vlan 30
 network 10.0.0.54 0.0.0.0 area 0
 network 10.0.0.70 0.0.0.0 area 0
 network 10.0.0.81 0.0.0.0 area 0
 network 10.3.0.2 0.0.0.0 area 0
 network 10.4.0.2 0.0.0.0 area 0
 network 10.5.0.2 0.0.0.0 area 0
 network 10.0.0.18 0.0.0.0 area 0
exit
interface range gigabitEthernet1/1/1-2
 ip ospf network point-to-point
end
```

**Périphérique : DSW-B2**
```bash
configure terminal
router ospf 1
 router-id 10.0.0.82
 passive-interface loopback0
 passive-interface vlan 10
 passive-interface vlan 20
 passive-interface vlan 30
 network 10.0.0.58 0.0.0.0 area 0
 network 10.0.0.74 0.0.0.0 area 0
 network 10.0.0.82 0.0.0.0 area 0
 network 10.3.0.3 0.0.0.0 area 0
 network 10.4.0.3 0.0.0.0 area 0
 network 10.5.0.3 0.0.0.0 area 0
 network 10.0.0.19 0.0.0.0 area 0
exit
interface range gigabitEthernet1/1/1-2
 ip ospf network point-to-point
end
```

---

## 2. Routes par défaut statiques (R1) + ASBR (redistribution de la route par défaut)
*(Configure one static default route for each of R1’s Internet connections. They should be recursive routes. Make the route via G0/1/0 a floating static route by configuring an AD value 1 greater than the default. R1 should function as an OSPF ASBR, advertising its default route to other routers in the OSPF domain.)*

**Objectif :** Assurer la sortie Internet avec deux routes par défaut (principale + flottante) et propager la route par défaut via OSPF.

**Principes :**
- Routes par défaut récursives = next-hop IP atteignable via interface WAN (ex. `203.0.113.1` et `203.0.113.5`).
- Route flottante via G0/1/0 avec AD = 2 (1 de plus que la valeur par défaut 1).
- OSPF ASBR : `default-information originate` dans `router ospf 1`.

### Code à copier

**Périphérique : R1**
```bash
configure terminal
! Routes par défaut récursives
ip route 0.0.0.0 0.0.0.0 203.0.113.1
ip route 0.0.0.0 0.0.0.0 203.0.113.5 2
! Redistribuer la route par défaut dans OSPF
router ospf 1
 default-information originate
end
! Vérifications
do show ip route | include 0.0.0.0
do show ip ospf
```

---

## Résumé rapide
- OSPF process 1 sur area 0, RIDs basés sur loopbacks.
- Loopbacks passives, SVIs passives hors management sur Distribution.
- Liens physiques en `point-to-point` pour éviter DR/BDR (PortChannel L3 par défaut).
- R1 : deux routes par défaut récursives, la seconde flottante (AD 2), et OSPF ASBR annonce la route par défaut.

> Astuce : Vérifiez `show ip ospf neighbor` pour confirmer l’adjacence, et `show ip protocols` pour voir les interfaces passives et l’annonce du défaut.
