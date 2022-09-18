#!/bin/bash
## save existing rules
sudo iptables-save > ~/iptables-rules
## modify rules, remove drop and reject lines
grep -v "DROP" iptables-rules > tmpfile && mv tmpfile iptables-rules-mod
grep -v "REJECT" iptables-rules-mod > tmpfile && mv tmpfile iptables-rules-mod
## apply the modifications
sudo iptables-restore < ~/iptables-rules-mod
## check
sudo iptables -L
## save the changes
sudo netfilter-persistent save
sudo systemctl restart iptables


