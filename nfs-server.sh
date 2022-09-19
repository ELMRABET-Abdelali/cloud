client_IP_1=129.152.15.58
client_IP_2=129.152.4.180

sudo apt update
sudo apt install nfs-kernel-server
sudo mkdir -p /home/nfsshare
sudo chown -R nobody:nogroup /home/nfsshare
sudo chmod 777 /mnt/nfs_share/
echo "/home/nfsshare $client_IP_1(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
echo "/home/nfsshare  $client_IP_2(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
sudo ufw allow from $client_IP_1 to any port nfs
sudo ufw allow from $client_IP_2 to any port nfs

# allow Port 2049
sudo ufw enable
sudo ufw status

systemctl enable rpcbind

systemctl enable nfs-server
systemctl restart rpcbind
systemctl restart nfs-server

