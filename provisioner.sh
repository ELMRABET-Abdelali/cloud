# change provisioner-deployment ip adress and file directory
kubectl apply -f provisioner-sc.yaml
kubectl apply -f provisioner-rbac.yaml
kubectl apply -f provisioner-deployment.yaml
 
