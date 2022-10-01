client_IP_1=129.152.16.234
client_IP_2=129.152.22.73		
sudo apt update
sudo apt install nfs-kernel-server
sudo mkdir -p /mnt/nfs_share
sudo chown -R nobody:nogroup /mnt/nfs_share/
sudo chmod 777 /mnt/nfs_share/
echo "/mnt/nfs_share  $client_IP_1(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
echo "/mnt/nfs_share  $client_IP_2(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
sudo ufw allow from $client_IP_1 to any port nfs
sudo ufw allow from $client_IP_2 to any port nfs

# allow Port 2049
