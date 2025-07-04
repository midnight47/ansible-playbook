https://github.com/metallb/metallb/tree/main/charts/metallb


helm repo add metallb https://metallb.github.io/metallb
helm upgrade --install metallb metallb/metallb -n metallb-system --create-namespace -f values.yaml
kubectl apply -f ip-pool.yaml



kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
