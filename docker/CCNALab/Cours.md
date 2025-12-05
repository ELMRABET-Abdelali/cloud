# 🗺️ Mega Lab CCNA — Guide d’explications par chapitre

Ce document accompagne les chapitres 1 à 9 et explique, pour chaque question, ce qui se passe dans le réseau, pourquoi on le configure ainsi, et définit les termes au fil de l’eau pour faciliter la compréhension. Il sert de fil conducteur pédagogique pour réviser et justifier chaque choix.

> Remarque: Les valeurs (adresses, VLANs, priorités, etc.) viennent des chapitres déjà écrits et du scénario Packet Tracer. Quand un terme apparaît pour la première fois, sa définition courte suit immédiatement.

---

## Chapitre 1 — Configuration de base

1) Identité et sécurisation de l’accès
- Pourquoi: Identifier chaque équipement (`hostname`) et sécuriser l’accès administrateur (`enable secret`).
- Termes:
  - "enable secret": mot de passe chiffré pour passer en mode privilégié (type 9 = scrypt; type 5 = MD5, plus ancien).
  - "AAA local": utilisateurs locaux pour l’authentification (`username` + `privilege`).
- Ce qui se passe: On évite l’accès anonyme; on garantit une traçabilité et une base cohérente.

2) Console/VTY
- Pourquoi: Protéger les accès (console/SSH) et définir des bannières légales.
- Termes:
  - "VTY": lignes virtuelles pour accès à distance (Telnet/SSH). SSH est chiffré; Telnet ne l’est pas.
- Ce qui se passe: L’équipement refuse les connexions non authentifiées; l’administrateur se connecte en SSH v2.

---

## Chapitre 2 — VLANs, Trunks, EtherChannel

1) VLANs
- Pourquoi: Séparer des domaines de broadcast (ex. postes, téléphones, serveurs, gestion). 
- Terme: "VLAN" = réseau logique L2 isolé; chaque VLAN aura une passerelle L3.
- Ce qui se passe: On limite le bruit réseau et on applique des politiques différentes par usage.

2) Trunks 802.1Q
- Pourquoi: Transporter plusieurs VLANs sur un même lien entre commutateurs.
- Termes:
  - "DTP" (Dynamic Trunking Protocol): négociation de trunk Cisco; on le désactive (`switchport nonegotiate`) pour éviter des bascules non voulues.
  - "Native VLAN": VLAN non-taggué sur le trunk (ici 99 pour gestion). 
- Ce qui se passe: Les liens inter‑switch taggent chaque VLAN; le VLAN natif reste non taggué.

3) EtherChannel L2
- Pourquoi: Agréger plusieurs liens physiques en un canal logique pour la redondance et le débit.
- Termes: 
  - "PAgP" (Cisco) / "LACP" (standard): protocoles de négociation de l’agrégation.
- Ce qui se passe: Les deux extrémités voient un seul lien logique, les trames sont réparties.

4) VTP
- Pourquoi: Propager la base VLAN depuis des serveurs VTP vers des clients.
- Terme: "VTP domain" = nom du domaine de synchronisation (ex. JeremysITLab).
- Ce qui se passe: Les clients reçoivent la table VLAN; on versionne pour éviter les suppressions accidentelles.

---

## Chapitre 3 — Adressage IP, EtherChannel L3, HSRP

1) SVI et L3 Po1
- Pourquoi: Activer le routage inter‑VLAN et un lien L3 redondant entre les cores.
- Termes:
  - "SVI" (Switch Virtual Interface): interface L3 d’un VLAN sur un switch.
  - "Port‑Channel L3": agrégat configuré en mode routé (pas de `switchport`).
- Ce qui se passe: Les SVIs servent de passerelles; le Po1 L3 relie les cores pour l’acheminement.

2) HSRP (v2)
- Pourquoi: Redondance de passerelle par VLAN (VIP partagée, Active/Standby).
- Termes:
  - "HSRP": Hot Standby Router Protocol; v2 supporte plus de groupes et IPv6.
  - "Preempt": le routeur prioritaire reprend automatiquement le rôle Active quand il revient.
- Ce qui se passe: Les hôtes utilisent l’IP virtuelle; bascule transparente lors de panne.

---

## Chapitre 4 — STP (Rapid PVST+) et sécurité de ports

1) RSTP/PortFast/BPDU Guard
- Pourquoi: Accélérer l’activation des ports vers hôtes et se protéger des boucles.
- Termes:
  - "RSTP" (Rapid Spanning Tree): convergence rapide du Spanning Tree.
  - "PortFast": évite l’attente STP sur ports vers hôtes.
  - "BPDU Guard": désactive un port qui reçoit des BPDUs (protection contre switch non autorisé).
- Ce qui se passe: Les ports d’accès montent vite; les boucles accidentelles sont interrompues.

2) Root primaire/secondaire aligné à HSRP
- Pourquoi: Consistance L2/L3 en choisissant le même équipement actif.
- Ce qui se passe: Le trafic suit des chemins stables, évite les demi‑tours inutiles.

---

## Chapitre 5 — Routage statique et OSPF

1) OSPF area 0
- Pourquoi: Échanger dynamiquement les routes avec contrôle fin.
- Termes:
  - "Router‑ID": identifiant OSPF (souvent Loopback). 
  - "Passive‑interface": ne forme pas de voisinage mais annonce le préfixe.
  - "Network type p2p": point‑à‑point, simplifie le DR/BDR (pas d’élection).
- Ce qui se passe: Les devices deviennent voisins; les préfixes des SVIs et liens sont distribués.

2) Defaults (statique + originate)
- Pourquoi: Injecter la sortie Internet/wan vers le réseau.
- Terme: "Floating static" = route statique de secours avec distance admin > 1.
- Ce qui se passe: La route principale est préférée; la secondaire prend le relais si la première échoue.

---

## Chapitre 6 — Services (DHCP, DNS, NTP, SNMP, Syslog, SSH, NAT, FTP, LLDP)

1) DHCP
- Pourquoi: Fournir des adresses et options dynamiques.
- Termes: "Exclusions" pour réserver des IP; "Helper" pour relayer vers le serveur DHCP.
- Ce qui se passe: Les clients reçoivent IP/gateway/DNS; les relais envoient les requêtes jusqu’à R1.

2) NTP
- Pourquoi: Synchroniser l’heure pour logs et sécurité.
- Terme: "NTP master" (R1) vs clients avec clé MD5.
- Ce qui se passe: Les devices alignent leur temps; les logs sont cohérents.

3) Syslog/SNMP
- Pourquoi: Observer et superviser.
- Terme: "SNMP RO": lecture seule; "Syslog server": collecte d’événements.
- Ce qui se passe: Les alertes et états remontent vers SRV1.

4) SSH durci
- Pourquoi: Sécuriser l’administration.
- Terme: "RSA 4096", "SSH v2", ACL sur VTY.
- Ce qui se passe: Accès chiffré et filtré; Telnet est désactivé.

5) NAT/PAT
- Pourquoi: Traduire les adresses internes vers l’Internet/wan.
- Termes: "NAT statique" (1:1), "PAT" (port address translation, many:1), "pool".
- Ce qui se passe: Les flux sortants utilisent des ports; un serveur interne peut être exposé par NAT.

6) LLDP
- Pourquoi: Découverte de voisins multi‑constructeurs.
- Terme: "CDP": équivalent Cisco; parfois désactivé.
- Ce qui se passe: Les devices s’annoncent; diagnostic facilité.

---

## Chapitre 7 — ACL et protections L2

1) ACL étendue
- Pourquoi: Autoriser/Refuser des flux selon IP/protocoles.
- Terme: "Placement": proche de la source pour réduire le trafic non désiré.
- Ce qui se passe: Les pings sont permis; le reste bloqué entre bureaux selon consigne.

2) Port Security / DHCP Snooping / DAI
- Pourquoi: Empêcher vol d’IP, rogue DHCP, ARP spoofing.
- Termes:
  - "Restrict+Sticky": apprendre MAC, sanction sans shutdown.
  - "DHCP Snooping": liste de baux, ports trusted/untrusted, rate‑limit.
  - "DAI": vérifie ARP avec table Snooping (src/dst MAC/IP).
- Ce qui se passe: Un faux serveur DHCP est bloqué; les ARP malveillants sont rejetés.

---

## Chapitre 8 — IPv6

1) Activation et adressage
- Pourquoi: Préparer la coexistence IPv4/IPv6.
- Termes:
  - `ipv6 unicast-routing`: active le routage IPv6.
  - "EUI‑64": construit l’ID interface à partir de l’adresse MAC.
  - `ipv6 enable` sur Po1: crée link‑local et ND sans adresse globale.
- Ce qui se passe: Les liens L3 parlent IPv6; les routes par défaut permettent la sortie.

2) Routes par défaut
- Pourquoi: Assurer la sortie principale et de secours.
- Terme: "Entièrement spécifiée": next‑hop + interface de sortie.
- Ce qui se passe: La récursive est préférée; la fully‑specified prend le relais si besoin.

---

## Chapitre 9 — Réseau sans fil (WLC)

1) Interface dynamique
- Pourquoi: Relier le WLAN au VLAN 40 et au sous‑réseau Wi‑Fi.
- Terme: "Dynamic interface": interface L3 sur WLC, associée à un WLAN.
- Ce qui se passe: Le WLC fait passerelle pour les clients Wi‑Fi (dans PT, DHCP client est limité).

2) WLAN + sécurité
- Pourquoi: Publier le SSID et chiffrer l’accès utilisateur.
- Termes: "SSID" (nom du réseau), "WPA2‑AES", "PSK" (clé partagée).
- Ce qui se passe: Les APs diffusent le SSID; les clients s’authentifient via la clé.

3) Association LWAP
- Pourquoi: Centraliser la gestion des APs.
- Terme: "LWAP" = Lightweight AP; rejoint un contrôleur (WLC).
- Ce qui se passe: Les APs se registrent; le WLC applique les politiques.

---

## Conseils de validation transversaux

- Chemins de données: ping/gateway par VLAN, traceroute entre sites, `show arp`/`show mac address-table`.
- Chemins de contrôle: `show cdp neighbors` (si activé), `show lldp neighbors`, `show etherchannel summary`, `show vtp status`, `show spanning-tree root`, `show standby brief`, `show ip ospf neighbor`.
- Services: `show clock`, `show ntp associations`, `show ip dhcp binding`, `show ip nat translations`, `show logging`.
- IPv6: `show ipv6 interface brief`, `show ipv6 route`, `ping ipv6`.
- WLC: Interface/WLAN status, APs "Registered/Joined".

---

## Pourquoi ces choix de conception ?

- Alignement STP/HSRP: cohérence L2/L3 pour éviter des chemins sub‑optimaux.
- Trunks contrôlés (nonegotiate): réduire les surprises et rester explicite.
- OSPF p2p: simplifie et stabilise les voisinages.
- Sécurité L2 (Snooping/DAI/PortSecurity): protéger contre les attaques de base sur les réseaux d’accès.
- Defaults flottantes: bascule ordonnée sans protocole complexe.
- IPv6 sans global sur Po1: garder ND/LL uniquement sur l’agrégat, éviter adressage inutile.

---

## Annexes — Définitions rapides (glossaire)

- VLAN: réseau logique L2 isolé.
- Trunk 802.1Q: lien transportant plusieurs VLANs (tag 802.1Q).
- EtherChannel: agrégat de liens (PAgP/LACP).
- SVI: interface L3 d’un VLAN sur un switch.
- HSRP v2: redondance de passerelle (IP virtuelle).
- STP/RSTP: prévention de boucles L2.
- PortFast/BPDU Guard: accélération des ports d’accès et protection contre switch non autorisé.
- OSPF: protocole de routage link‑state.
- NTP/Syslog/SNMP: temps/logs/supervision.
- SSH v2: accès administrateur chifré.
- NAT/PAT: traduction d’adresses.
- DHCP Snooping/DAI: protection DHCP/ARP.
- LLDP/CDP: découverte de voisins.
- IPv6 EUI‑64: génération d’adresse interface à partir MAC.
- WLC/LWAP/SSID/PSK/WPA2‑AES: contrôleur/APs/réseau Wi‑Fi/clé/chiffrement.

---

## Navigation

- Chapitre 1: Base — `Chapter-01-Configuration-de-Base.md`
- Chapitre 2: VLANs — `Chapter-02-VLANs-EtherChannel.md`
- Chapitre 3: IP & HSRP — `Chapter-03-Adresses-IP-EtherChannel-L3-HSRP.md`
- Chapitre 4: RSTP & Port Security — `Chapter-04-RSTP-et-Securite-des-Ports.md`
- Chapitre 5: OSPF & Statique — `Chapter-05-Routage-Statique-et-OSPF.md`
- Chapitre 6: Services — `Chapter-06-Services-Reseau-et-Securite.md`
- Chapitre 7: ACL & L2 Sec — `Chapter-07-ACL-et-Securite-L2.md`
- Chapitre 8: IPv6 — `Chapter-08-IPv6.md`
- Chapitre 9: WLC — `Chapter-09-Reseau-Sans-Fil-WLC.md`
