офф чарт
https://github.com/kedacore/charts/tree/main/keda

helm repo add kedacore https://kedacore.github.io/charts
helm repo update

kubectl create namespace keda

helm upgrade --install keda kedacore/keda --namespace keda --values values.yaml --version 2.17.2

пример можно посмотреть в директории example
