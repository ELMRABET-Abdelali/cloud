sudo apt update && sudo apt upgrade
apt install tasksel -y
tasksel
# activate ubuntu desktop by using space button on the specified line
systemctl set-default graphical.target

sudo apt install xrdp -y 
sudo systemctl status xrdp 

sudo usermod -a -G ssl-cert xrdp 
sudo nano /etc/xrdp/startwm.sh 

#add this after the last fi
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
# CTRL+O to write out and then CTRL+X
sudo systemctl restart xrdp 

# open port 3389 in oracle
passwd root
# connect to remmina(ubuntu) or remote desktop connection (wind) (root & psswd)



