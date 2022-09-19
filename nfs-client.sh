serverip=129.152.20.47

sudo apt update
sudo apt install nfs-common

mount -t nfs $serverip:/home/nfsshare /mnt
cd /mnt
