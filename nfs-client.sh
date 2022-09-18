serverip=129.152.10.212

sudo apt update
sudo apt install nfs-common

mount -t nfs $serverip:/home/nfsshare /mnt
cd /mnt
