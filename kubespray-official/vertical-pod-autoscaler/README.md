можно ставить официальную версию но у неё нет helm репозитория:
# выберите актуальную версию с Releases
VER=0.5.0

helm upgrade --install vpa \
  https://github.com/kubernetes/autoscaler/releases/download/vertical-pod-autoscaler-chart-$VER/vertical-pod-autoscaler-$VER.tgz \
  -n vpa --create-namespace

# поэтому я буду ставить из artifacthub https://artifacthub.io/packages/helm/fairwinds-stable/vpa   - она основана на офф версии
helm repo add fairwinds-stable https://charts.fairwinds.com/stable
helm repo update
kubectl create ns vpa


helm install vpa fairwinds-stable/vpa -n vpa -f values-vpa.yaml
helm upgrade --install -n vpa vpa fairwinds-stable/vpa -f values-vpa.yaml
