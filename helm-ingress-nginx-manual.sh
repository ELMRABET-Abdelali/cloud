# helm repo add nginx-stable https://helm.nginx.com/stable
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm install my-release ingress-nginx/ingress-nginx

kubectl create ns ingress-nginx
helm install myingress ingress-nginx/ingress-nginx -n ingress-nginx --values helm-ingress-nginx.yaml
