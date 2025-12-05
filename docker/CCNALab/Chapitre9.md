# 📶 Lab jeremysitlab — Chapitre 9 : Configuration du Réseau Sans Fil (WLC)

Ce chapitre se fait dans l’interface graphique du WLC de Packet Tracer. On crée l’interface dynamique Wi‑Fi, le WLAN, la sécurité WPA2‑PSK, puis on vérifie l’association des LWAPs.

---

## 1. Accéder à l’interface GUI de WLC1
*(Access the GUI of WLC1 (https://10.0.0.7) from one of the PCs. Username: admin, Password: adminPW12)*

**Objectif :** Ouvrir la console web du contrôleur pour effectuer la configuration.

**Étapes GUI (PC1/PC3) :**
1) Desktop → Web Browser → URL: `https://10.0.0.7` (accepter l’alerte de certificat, si proposée).  
2) Login: `admin` / `adminPW12`.

> Astuce: Si la page ne charge pas en HTTPS dans votre version de PT, essayez `http://10.0.0.7`.

---

## 2. Créer l’interface dynamique pour le WLAN Wi‑Fi (10.6.0.0/24)
*(Configure a dynamic interface for the Wi‑Fi WLAN (10.6.0.0/24))*

**Objectif :** Lier le WLAN au VLAN 40 et au sous-réseau 10.6.0.0/24.

**Paramètres requis :**  
- Name: `Wi-Fi`  
- VLAN: `40`  
- Port number: `1`  
- IP address: `10.6.0.4`  
  - Note: La vidéo mentionne `10.6.0.2` (erreur, conflit avec DSW‑A1).  
- Subnet mask: `255.255.255.0`  
- Gateway: `10.6.0.1` (VIP HSRP VLAN 40)  
- DHCP server: `10.0.0.76` (R1 Loopback)

**Étapes GUI (WLC1) :**  
Controller → Interfaces → New  
- Interface Name = `Wi-Fi`  
- VLAN Id = `40` → Apply  
- Port Number = `1`  
- IP Address = `10.6.0.4`  
- Netmask = `255.255.255.0`  
- Gateway = `10.6.0.1`  
- Primary DHCP Server = `10.0.0.76`  
→ Apply / Save Configuration.

---

## 3. Créer et activer le WLAN
*(Configure and enable the following WLAN: Profile name Wi‑Fi, SSID Wi‑Fi, ID 1, Status Enabled, WPA2 with AES and PSK cisco123)*

**Objectif :** Diffuser le SSID et sécuriser l’accès Wi‑Fi.

**Paramètres requis :**  
- Profile Name: `Wi-Fi`  
- SSID: `Wi-Fi`  
- WLAN ID: `1`  
- Status: `Enabled`  
- Interface / Interface Group: `Wi-Fi`  
- Security Layer 2: `WPA+WPA2`  
  - `WPA2 Policy: Enable`  
  - `AES: Enable`  
  - `PSK: Enable`  
  - `PSK Key: cisco123`

**Étapes GUI (WLC1) :**  
WLANs → Go → New  
- Profile Name = `Wi-Fi`  
- SSID = `Wi-Fi`  
- ID = `1` → Apply  
- Status = `Enabled`  
- Interface/Interface Group (G) = `Wi-Fi`  
Security → Layer 2  
- Layer 2 Security = `WPA+WPA2`  
- Check `WPA2 Policy`  
- Cipher = `AES`  
- `PSK` = Enable  
- `PSK Format/Key` = `cisco123`  
→ Apply → Save Configuration.

---

## 4. Vérifier l’association des AP légers (LWAP)
*(Verify that both LWAPs have associated with WLC1)*

**Objectif :** Confirmer que les APs ont rejoint le WLC et qu’ils sont opérationnels.

**Étapes GUI (WLC1) :**  
Monitor / Wireless / Access Points (selon version PT) → vérifier que les 2 LWAPs sont `Registered/Joined` sur `WLC1`.

> Limitation Packet Tracer: Les clients Wi‑Fi ne peuvent pas obtenir d’adresse depuis le pool DHCP Wi‑Fi même si la configuration est correcte.

---

## Vérifications utiles
- `WLANs` → Status du WLAN `Wi‑Fi` = `Enabled` / Interface = `Wi‑Fi`.  
- `Controller → Interfaces` → l’interface `Wi‑Fi` affiche `10.6.0.4/24`, Gateway `10.6.0.1`, DHCP `10.0.0.76`.  
- `Wireless/Access Points` → état `Registered` pour les LWAPs.

---

## Rappels d’infrastructure (déjà faits dans chapitres précédents)
- Trunk `ASW-A1 F0/2` vers `WLC1` avec VLANs `40,99`, VLAN natif `99`, DTP désactivé.  
- HSRP VLAN 40 en place (`10.6.0.1`), DSW-A1/DSW-A2 adresses `.2` et `.3`.

### Code de vérification (si besoin)

**Périphériques : ASW-A1**
```bash
show interfaces trunk
show running-config interface fastEthernet0/2
```

**Périphériques : DSW-A1, DSW-A2**
```bash
show standby brief
show ip interface vlan 40
```

---

## Résumé rapide
- Accès WLC1 via `https://10.0.0.7` (admin/adminPW12).
- Interface dynamique `Wi‑Fi` (VLAN 40) configurée: IP `10.6.0.4/24`, GW `10.6.0.1`, DHCP `10.0.0.76`.
- WLAN `Wi‑Fi` (ID 1) actif, sécurité `WPA2‑AES` PSK `cisco123`.
- Les deux LWAPs sont associés au WLC; les clients Wi‑Fi ne recevront pas d’IP (limitation PT).
