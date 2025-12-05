# Mega Lab CCNA — Explication générale

Ce document raconte l’histoire complète du lab, chapitre par chapitre, avec des mots simples. Il explique pourquoi chaque étape existe, ce qui se passe dans le réseau, et définit les termes au fur et à mesure.

---

## 1) Configuration de base

On commence par définir l’identité des matériels en les nommant (`hostname`), puis on donne l’accès administrateur local sur la console et en SSH, avec des utilisateurs et mots de passe.
- Pourquoi: savoir précisément quel équipement on administre et empêcher les accès anonymes.
- Comment:
  - Nommer chaque routeur/switch avec `hostname`.
  - Créer des comptes locaux (AAA local) et un `enable secret` pour le mode privilégié.
  - Protéger `console` et `VTY` (SSH v2), ajouter une bannière légale et activer la déconnexion automatique des sessions inactives.
- Résultat: identité claire, accès sécurisé, base saine pour la suite.

Termes clés:
- VTY: accès à distance (Telnet/SSH). On privilégie SSH v2 (chiffré).
- Enable secret: mot de passe chiffré pour le mode privilégié.

---

## 2) VLANs, Trunks, EtherChannel

Dans ce chapitre, on relie les switches de distribution pour assurer la redondance, puis on prépare toutes les liaisons entre ports pour que les VLANs circulent correctement via des trunks et un “gestionnaire” des VLANs (VTP) si utilisé.
- Pourquoi: séparer les usages (postes, téléphones, serveurs, gestion) et garantir des liens L2 robustes entre switches.
- Comment:
  - Créer des VLANs par usage; chacun aura plus tard une passerelle L3 (SVI).
  - Configurer des trunks 802.1Q pour transporter plusieurs VLANs sur un seul lien.
  - Désactiver DTP (`switchport nonegotiate`) pour garder la maîtrise et éviter les bascules automatiques.
  - Mettre en place un EtherChannel L2 (agrégat) pour la redondance et le débit entre switches.
  - Optionnel: VTP pour propager la base VLAN depuis un serveur VTP vers des clients.
- Résultat: un plan L2 propre, segmenté et redondant; les VLANs traversent les trunks de manière fiable.

Termes clés:
- VLAN: réseau logique L2 isolé.
- Trunk 802.1Q: lien taggé multi‑VLAN.
- EtherChannel: agrégat de liens physiques en un seul lien logique.
- VTP: synchronisation des VLANs dans un domaine.

---

## 3) Adressage IP, EtherChannel L3, HSRP

On active le routage sur les switches de distribution et de cœur, on connecte les deux cœurs en Port‑Channel L3, on donne des IP aux SVIs et on active HSRP pour assurer la disponibilité grâce à une adresse virtuelle (VIP).
- Pourquoi: permettre la communication inter‑VLAN et garantir une passerelle qui ne tombe pas.
- Comment:
  - Créer les SVI (interfaces L3 des VLANs) et leur attribuer des adresses IP.
  - Configurer un Port‑Channel L3 (Po1, en mode routé) entre les cœurs.
  - Mettre HSRP v2 par VLAN avec une VIP, définir les priorités et `preempt` pour la reprise automatique.
- Résultat: les hôtes utilisent une passerelle stable; le cœur L3 est redondant et performant.

Termes clés:
- SVI: interface L3 d’un VLAN.
- HSRP v2: passerelle redondante via une IP virtuelle (Active/Standby).

---

## 4) STP (Rapid PVST+) et sécurité des ports

On utilise STP rapide pour le L2 afin d’éviter les boucles, on active `PortFast` pour accélérer l’accès des PC, et `BPDU Guard` pour bloquer un switch non autorisé.
- Pourquoi: un L2 propre, rapide et sécurisé évite les pannes et les détournements.
- Comment:
  - Activer Rapid PVST+ (RSTP) pour une convergence rapide.
  - Mettre `PortFast` sur les ports vers hôtes.
  - Activer `BPDU Guard` pour couper tout port recevant des BPDUs inattendus.
  - Aligner le root STP avec HSRP (même actif) pour des chemins cohérents.
- Résultat: pas de boucles, démarrage rapide des postes, et ports protégés.

Termes clés:
- BPDU: message Spanning Tree.
- Root STP: switch référence du spanning‑tree.

---

## 5) Routage statique et OSPF

On assure la même philosophie de disponibilité côté L3 avec OSPF—comme HSRP côté passerelles—pour que les équipements apprennent automatiquement les chemins, et on diffuse une sortie Internet avec secours.
- Pourquoi: ne pas gérer les routes à la main et garantir une sortie Internet résiliente.
- Comment:
  - Activer OSPF sur les équipements L3 dans l’`Area 0`; définir le Router‑ID via une Loopback; privilégier le type `point‑to‑point`.
  - Mettre certaines interfaces en `passive‑interface` (elles annoncent leur réseau sans voisinage).
  - Ajouter une route par défaut vers Internet et la propager via `default‑information originate` (R1 souvent ASBR).
  - Créer une route statique flottante (distance admin > 1) comme secours.
- Résultat: les chemins L3 s’apprennent automatiquement, et la sortie Internet bascule proprement en cas de panne.

Termes clés:
- OSPF: routage link‑state.
- RID (Router‑ID): identifiant OSPF (souvent une Loopback).
- ASBR: routeur qui injecte des routes externes.
- Floating static: route de secours.

---

## 6) Services réseau (DHCP, DNS, NTP, SNMP, Syslog, SSH, NAT, LLDP)

On assure les services de communication (DHCP pour obtenir une IP automatiquement, DNS pour résoudre les noms, NTP pour l’heure, supervision, SSH sécurisé, et NAT pour sortir vers Internet).
- Pourquoi: rendre le réseau utilisable et gérable au quotidien, avec sécurité et traçabilité.
- Comment:
  - DHCP: pools et exclusions; `ip helper-address` pour relayer vers le serveur; les clients reçoivent IP/gateway/DNS.
  - DNS: configuration côté serveur (SRV1) et clients.
  - NTP: R1 peut être master (clé MD5), les autres en clients → horloge alignée.
  - Syslog/SNMP: envoyer logs/états vers SRV1 pour supervision.
  - SSH durci: RSA, SSH v2, ACL sur VTY; Telnet est désactivé.
  - NAT/PAT: sorties vers Internet (PAT many:1, statique 1:1, éventuellement pool).
  - LLDP/CDP: découverte de voisins multi‑constructeurs.
- Résultat: services distribués, administration sécurisée, visibilité et sortie Internet fonctionnelle.

---

## 7) ACL et protections de couche 2

On pose des règles de protection (ACL) pour n’autoriser que ce qui est voulu—par exemple seulement l’ICMP de PC‑A vers PC‑B—et on active des gardes L2 pour bloquer les faux DHCP et l’usurpation ARP.
- Pourquoi: réduire les surfaces d’attaque et maîtriser les flux.
- Comment:
  - ACL étendue: placement proche de la source; autoriser le ping (ICMP) entre postes spécifiés; bloquer le reste.
  - Port Security: mode restrict + sticky MAC pour lier les postes aux ports.
  - DHCP Snooping: ports trusted/untrusted, rate‑limit, table de baux.
  - DAI: vérifie les ARP en s’appuyant sur la table Snooping (MAC/IP).
- Résultat: trafic propre, faux serveurs DHCP bloqués, ARP malveillants rejetés.

Termes clés:
- ACL étendue: filtrage par IP/protocoles.
- ARP spoofing: usurpation via ARP.

---

## 8) IPv6

On active IPv6 si besoin, on fait l’adressage et on met une sortie par défaut avec secours, comme en IPv4.
- Pourquoi: préparer le réseau à la coexistence IPv4/IPv6.
- Comment:
  - Activer `ipv6 unicast‑routing`.
  - Adresser les liens et SVIs (EUI‑64 possible pour générer l’ID interface).
  - `ipv6 enable` sur Po1 pour link‑local/ND sans global si souhaité.
  - Routes par défaut IPv6: principale récursive et secours entièrement spécifiée (next‑hop + interface).
- Résultat: le réseau parle IPv6 et garde une sortie résiliente.

---

## 9) Réseau sans fil (WLC)

On met en service le Wi‑Fi—interface dynamique du WLC vers le VLAN du Wi‑Fi, SSID sécurisé en WPA2‑AES/PSK, et les APs se joignent au contrôleur.
- Pourquoi: fournir un accès sans fil simple et sécurisé aux utilisateurs.
- Comment:
  - Créer l’interface dynamique du WLC reliée au VLAN 40.
  - Publier un WLAN (SSID) protégé en WPA2‑AES avec clé partagée (PSK).
  - Associer les APs (LWAP) au WLC pour une gestion centralisée.
- Résultat: SSID diffusé, connexions sécurisées, Wi‑Fi opérationnel.

---

## Fils conducteurs et validations

- Cohérence STP/HSRP: même équipement actif pour des chemins stables.
- Trunks explicites (nonegotiate): moins de surprises, configuration maîtrisée.
- OSPF p2p: voisinages simples et robustes.
- Defaults flottantes: bascule propre sans protocole complexe.
- IPv6: ND/LL sur agrégat si on veut éviter des globals inutiles.

Validation pratique:
- `show ip ospf neighbor`, `show standby brief`, `show spanning-tree root`, `show etherchannel summary`.
- `show ip dhcp binding`, `show clock`/`show ntp associations`, `show ip nat translations`, `show logging`.
- `show ipv6 interface brief`, `show ipv6 route`, ping/traceroute entre VLANs et vers l’Internet.
- WLC: statut interface, WLAN, APs "Registered/Joined".

---

## En conclusion

Ce lab construit un réseau d’entreprise complet: organisé en VLANs, redondant en L2/L3, routé dynamiquement avec OSPF, sécurisé en accès et en cœur, équipé des services indispensables, prêt pour IPv6 et le Wi‑Fi. Chaque choix vise la stabilité, la sécurité, et la facilité d’exploitation.
