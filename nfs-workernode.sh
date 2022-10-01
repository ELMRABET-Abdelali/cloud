sudo apt update
client_IP_0=129.152.4.203	
sudo apt install nfs-common
sudo mkdir -p /mnt/nfs_share
sudo mount $client_IP_0:/mnt/nfs_share  /mnt/
cd /mnt

