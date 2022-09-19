ExternalIp=129.152.20.47

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket /run/cri-dockerd.sock  \
  --upload-certs \
  --control-plane-endpoint=$ExternalIp

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# in case of flannel --pod-network-cidr=10.244.0.0/16 in Flannel case 
#Make sure that required ports ( flannel 8285,8472 /udp ) are opened in Virtual cloud network of your cloud provider 
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# join for workernode
echo $(kubeadm token create --print-join-command) "--cri-socket /run/cri-dockerd.sock" 

