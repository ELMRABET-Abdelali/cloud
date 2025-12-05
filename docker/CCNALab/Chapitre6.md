# Chapitre 6 : Services Réseau (DHCP, DNS, NTP, SNMP, Syslog, FTP, SSH, NAT)

Ce chapitre configure les services réseau essentiels sur `R1` et les commutateurs: DHCP (serveur sur R1), DNS (SRV1), NTP (R1 serveur + clients authentifiés), SNMP (lecture seule), Syslog, FTP upgrade d’IOS, SSH sécurisé, NAT statique et PAT avec pool, et enfin LLDP au lieu de CDP.

---

## 1. DHCP sur R1 (pools et exclusions)
*(Configure DHCP pools on R1, exclude first 10 usable addresses of each pool)*

**Objectif :** Faire de `R1` le serveur DHCP des hôtes des deux bureaux, avec exclusions pour les 10 premières adresses utilisables.

**Principes :**
- `ip dhcp excluded-address` pour réserver les 10 premières.
- `ip dhcp pool <name>` + `network`, `default-router`, `dns-server`, `domain-name`.
- WLC option: utiliser `option 43 ascii 10.0.0.7`.

### Code à copier

**Périphérique : R1**
```bash
configure terminal
! Exclusions
ip dhcp excluded-address 10.0.0.1 10.0.0.10
ip dhcp excluded-address 10.1.0.1 10.1.0.10
ip dhcp excluded-address 10.2.0.1 10.2.0.10
ip dhcp excluded-address 10.0.0.17 10.0.0.26
ip dhcp excluded-address 10.3.0.1 10.3.0.10
ip dhcp excluded-address 10.4.0.1 10.4.0.10
ip dhcp excluded-address 10.6.0.1 10.6.0.10
! Pools
ip dhcp pool A-Mgmt
 network 10.0.0.0 255.255.255.240
 default-router 10.0.0.1
 dns-server 10.5.0.4
 domain-name jeremysitlab.com
 option 43 ascii 10.0.0.7
ip dhcp pool A-PC
 network 10.1.0.0 255.255.255.0
 default-router 10.1.0.1
 dns-server 10.5.0.4
 domain-name jeremysitlab.com
ip dhcp pool A-Phone
 network 10.2.0.0 255.255.255.0
 default-router 10.2.0.1
 dns-server 10.5.0.4
 domain-name jeremysitlab.com
ip dhcp pool B-Mgmt
 network 10.0.0.16 255.255.255.240
 default-router 10.0.0.17
 dns-server 10.5.0.4
 domain-name jeremysitlab.com
 option 43 ascii 10.0.0.7
ip dhcp pool B-PC
 network 10.3.0.0 255.255.255.0
 default-router 10.3.0.1
 dns-server 10.5.0.4
 domain-name jeremysitlab.com
ip dhcp pool B-Phone
 network 10.4.0.0 255.255.255.0
 default-router 10.4.0.1
 dns-server 10.5.0.4
 domain-name jeremysitlab.com
ip dhcp pool Wi-Fi
 network 10.6.0.0 255.255.255.0
 default-router 10.6.0.1
 dns-server 10.5.0.4
 domain-name jeremysitlab.com
end
```

---

## 2. Relay DHCP sur Distribution (ip helper-address)
*(Relay DHCP to R1’s Loopback0 IP)*

**Objectif :** Faire relayer les broadcasts DHCP vers l’IP `Lo0` de `R1` (10.0.0.76).

### Code à copier

**Périphériques : DSW-A1, DSW-A2**
```bash
configure terminal
interface vlan 10
 ip helper-address 10.0.0.76
interface vlan 20
 ip helper-address 10.0.0.76
interface vlan 40
 ip helper-address 10.0.0.76
interface vlan 99
 ip helper-address 10.0.0.76
end
```

**Périphériques : DSW-B1, DSW-B2**
```bash
configure terminal
interface vlan 10
 ip helper-address 10.0.0.76
interface vlan 20
 ip helper-address 10.0.0.76
interface vlan 30
 ip helper-address 10.0.0.76
interface vlan 99
 ip helper-address 10.0.0.76
end
```

---

## 3. DNS sur SRV1 (enregistrements A et CNAME)
*(Configure DNS entries on SRV1)*

**Objectif :** Résoudre noms pour tests Internet.

**Action (GUI Packet Tracer) :** SRV1 → Desktop → DNS Service → ajouter:
- `google.com` → `172.253.62.100`
- `youtube.com` → `152.250.31.93`
- `jeremysitlab.com` → `66.235.200.145`
- `www.jeremysitlab.com` → `jeremysitlab.com` (CNAME)

---

## 4. Domaine et DNS sur tous les équipements
*(Use domain name jeremysitlab.com and SRV1 as DNS)*

### Code à copier

**Périphériques : R1, CSW1/CSW2, DSW-A1/A2, DSW-B1/B2, ASW-A1/A2/A3, ASW-B1/B2/B3**
```bash
configure terminal
ip domain name jeremysitlab.com
ip name-server 10.5.0.4
end
```

---

## 5. NTP : R1 stratum 5 + serveur externe
*(Make R1 stratum 5 and learn from 216.239.35.0)*

### Code à copier

**Périphérique : R1**
```bash
configure terminal
ntp master 5
ntp server 216.239.35.0
end
```

> Note : NTP peut prendre longtemps à se synchroniser dans Packet Tracer — poursuivez le lab.

---

## 6. NTP clients (Core/Distribution/Access) avec authentification
*(Use R1 Lo0 as NTP server; authenticate key 1 md5 ccna)*

### Code à copier

**Périphériques : CSW1, CSW2, DSW-A1/A2, DSW-B1/B2, ASW-A1/A2/A3, ASW-B1/B2/B3**
```bash
configure terminal
ntp authentication-key 1 md5 ccna
ntp trusted-key 1
ntp server 10.0.0.76 key 1
end
```

---

## 7. SNMP lecture seule
*(SNMP community string SNMPSTRING, GET only)*

### Code à copier

**Périphériques : R1 et tous les switches**
```bash
configure terminal
snmp-server community SNMPSTRING ro
end
```

---

## 8. Syslog vers SRV1 + buffer local
*(Send Syslog to SRV1; log all severities; buffer 8192)*

### Code à copier

**Périphériques : R1 et tous les switches**
```bash
configure terminal
logging 10.5.0.4
logging trap debugging
logging buffered 8192
end
```

---

## 9. FTP : Upgrade IOS sur R1
*(Default FTP credentials; copy new IOS from SRV1; reboot; delete old)*

### Code à copier

**Périphérique : R1**
```bash
configure terminal
ip ftp username cisco
ip ftp password cisco
end
!
! Copier depuis SRV1 vers la flash
ping 10.5.0.4
copy ftp flash:
  Address or name of remote host []? 10.5.0.4
  Source filename []? c2900-universalk9-mz.SPA.155-3.M4a.bin
  Destination filename []? c2900-universalk9-mz.SPA.155-3.M4a.bin
!
! Booter sur la nouvelle image
show flash
configure terminal
boot system flash:c2900-universalk9-mz.SPA.155-3.M4a.bin
end
write memory
reload
!
! Supprimer l’ancienne image après redémarrage
show flash
delete flash:c2900-universalk9-mz.SPA.151-3.M4a.bin
```

---

## 10. SSH sécurisé sur tous les équipements
*(Largest RSA modulus; SSHv2 only; ACL 1 from Office A PCs; VTY SSH only; login local; logging synchronous)*

### Code à copier

**Périphériques : R1 et tous les switches**
```bash
configure terminal
crypto key generate rsa
  4096
ip ssh version 2
access-list 1 permit 10.1.0.0 0.0.0.255
line vty 0 15
 access-class 1 in
 transport input ssh
 login local
 logging synchronous
end
```

---

## 11. NAT statique vers SRV1
*(Static NAT to expose SRV1 at 203.0.113.113)*

### Code à copier

**Périphérique : R1**
```bash
configure terminal
ip nat inside source static 10.5.0.4 203.0.113.113
interface range gigabitEthernet0/0/0, gigabitEthernet0/1/0
 ip nat outside
exit
interface range gigabitEthernet0/0, gigabitEthernet0/1
 ip nat inside
end
```

---

## 12. PAT dynamique avec pool sur R1
*(ACL 2 for subnets; POOL1 203.0.113.200–207 /29; map ACL to pool with overload; test failover)*

### Code à copier

**Périphérique : R1**
```bash
configure terminal
! ACL subnets in order
access-list 2 permit 10.1.0.0 0.0.0.255
access-list 2 permit 10.2.0.0 0.0.0.255
access-list 2 permit 10.3.0.0 0.0.0.255
access-list 2 permit 10.4.0.0 0.0.0.255
access-list 2 permit 10.6.0.0 0.0.0.255
! Pool /29
ip nat pool POOL1 203.0.113.200 203.0.113.207 netmask 255.255.255.248
! PAT overload via pool
ip nat inside source list 2 pool POOL1 overload
end
!
! Test de connectivité (PCs ping jeremysitlab.com)
!
! Test de basculement lien Internet (Packet Tracer)
configure terminal
interface gigabitEthernet0/0/0
 shutdown
end
!
router ospf 1
 no default-information originate
 default-information originate
!
configure terminal
interface gigabitEthernet0/0/0
 no shutdown
end
router ospf 1
 no default-information originate
 default-information originate
```

---

## 13. LLDP au lieu de CDP
*(Disable CDP; enable LLDP; disable LLDP Tx on Access F0/1)*

### Code à copier

**Périphériques : R1, CSW1/CSW2, DSW-A1/A2, DSW-B1/B2**
```bash
configure terminal
no cdp run
lldp run
end
```

**Périphériques : ASW-A1/A2/A3, ASW-B1/B2/B3**
```bash
configure terminal
no cdp run
lldp run
interface fastEthernet0/1
 no lldp transmit
end
```

---

## Résumé rapide
- DHCP server opérationnel sur R1 et relai DHCP sur Distribution.
- DNS configuré sur SRV1 et utilisé par tous les équipements.
- NTP : R1 maître stratum 5 et clients authentifiés via clé 1.
- SNMP RO, Syslog vers SRV1 + buffer local.
- FTP: upgrade d’IOS sur R1.
- SSH sécurisé (RSA 4096, SSHv2, ACL sur VTY, login local, logging sync).
- NAT statique pour SRV1 et PAT dynamique via POOL1, avec test de basculement OSPF.
- LLDP activé, CDP désactivé, TX LLDP bloqué sur ports d’accès F0/1.
