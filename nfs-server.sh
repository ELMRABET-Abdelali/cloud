apt -y install nfs-kernel-server

# write settings for NFS exports
# for example, set [/home/nfsshare] as NFS share

mkdir /home/nfsshare
systemctl restart nfs-server
