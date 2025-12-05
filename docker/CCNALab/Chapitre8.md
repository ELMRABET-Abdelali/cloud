# 🧭 Lab jeremysitlab — Chapitre 8 : Préparation et Routage IPv6

Ce chapitre active le routage IPv6 et configure les adresses IPv6 sur R1, CSW1 et CSW2, puis ajoute deux routes par défaut IPv6 (récursive et entièrement spécifiée/floating).

---

## 1. Activer IPv6 et adresser R1, CSW1, CSW2
*(Enable IPv6 routing and configure IPv6 addresses)*

a. R1 G0/0/0: `2001:db8:a::2/64`  
b. R1 G0/1/0: `2001:db8:b::2/64`  
c. R1 G0/0 et CSW1 G1/0/1: Préfixe `2001:db8:a1::/64` avec EUI‑64  
d. R1 G0/1 et CSW2 G1/0/1: Préfixe `2001:db8:a2::/64` avec EUI‑64  
e. CSW1 Po1 et CSW2 Po1: Activer IPv6 sans `ipv6 address` (link‑local/ND seulement)

**Objectif :** Préparer une migration vers IPv6 avec adressage global unicast cohérent et liens L3 opérationnels. Les Po1 resteront sans adresse globale (activation IPv6 uniquement).

**Principes :**
- Activer `ipv6 unicast-routing` sur tous les routeurs/commutateurs L3 concernés.
- Utiliser `ipv6 address <prefix>/64 eui-64` pour générer l’ID d’interface selon l’EUI-64.
- `ipv6 enable` sur les Port‑Channels L3 crée l’adresse link‑local et active ND/RA.

### Code à copier

**Périphérique : R1**
```bash
configure terminal
ipv6 unicast-routing
interface gigabitEthernet0/0/0
 ipv6 address 2001:db8:a::2/64
 no shutdown
exit
interface gigabitEthernet0/1/0
 ipv6 address 2001:db8:b::2/64
 no shutdown
exit
interface gigabitEthernet0/0
 ipv6 address 2001:db8:a1::/64 eui-64
 no shutdown
exit
interface gigabitEthernet0/1
 ipv6 address 2001:db8:a2::/64 eui-64
 no shutdown
end
```

**Périphérique : CSW1**
```bash
configure terminal
ipv6 unicast-routing
interface gigabitEthernet1/0/1
 ipv6 address 2001:db8:a1::/64 eui-64
 no shutdown
exit
interface port-channel1
 ipv6 enable
end
```

**Périphérique : CSW2**
```bash
configure terminal
ipv6 unicast-routing
interface gigabitEthernet1/0/1
 ipv6 address 2001:db8:a2::/64 eui-64
 no shutdown
exit
interface port-channel1
 ipv6 enable
end
```

> Vérifications: `show ipv6 interface brief`, `show ipv6 route`, `ping ipv6 <addr>`.

---

## 2. Routes par défaut IPv6 sur R1
*(Configure two default static routes on R1)*

a. Route par défaut récursive via next‑hop `2001:db8:a::1`.  
b. Route par défaut entièrement spécifiée via `2001:db8:b::1`, flottante (AD +1 vs défaut).

**Objectif :** Assurer la sortie IPv6 avec une route principale et une route de secours.

**Principe :**
- Défaut AD statique = 1 → pour la route flottante, utiliser 2.
- Entièrement spécifiée = inclure l’interface de sortie.

### Code à copier

**Périphérique : R1**
```bash
configure terminal
! Récursive
ipv6 route ::/0 2001:db8:a::1
! Entièrement spécifiée (floating, AD 2)
ipv6 route ::/0 gigabitEthernet0/1/0 2001:db8:b::1 2
end
! Vérifications
do show ipv6 route ::/0
do ping ipv6 2001:db8:a::1
```

---

## Résumé rapide
- IPv6 activé (ipv6 unicast-routing) sur R1/CSW1/CSW2.
- Adresses globales sur R1 G0/0/0 et G0/1/0; EUI‑64 sur R1 G0/0, G0/1 et CSW1/CSW2 G1/0/1.
- IPv6 activé sans adresse sur Port‑Channel1 des Core switches.
- Deux routes par défaut IPv6 sur R1: récursive et entièrement spécifiée (flottante).
