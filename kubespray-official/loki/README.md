официальный репозиторй
https://github.com/grafana/loki/tree/main/production/helm/loki

1. helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

2. создадим namespace loki
kubectl create ns loki

3. нужен s3-minio бакет и пользователь к этому бакету, которого заносим в loki.yaml
4. так же нужен provisioner для PV я использовал nfs  (nfs-client)
5. helm upgrade --install loki grafana/loki --namespace loki --version 6.29.0 -f loki.yaml

6. теперь ставим сборщик логов promtail:
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install prometheus-crds prometheus-community/prometheus-operator-crds --namespace loki
    helm upgrade --install promtail grafana/promtail --namespace loki --values promtail.yaml 


добавляем datasource для grafana
http://loki-read.loki.svc.cluster.local:3100

и ставим борду чтобы смотреть логи:
https://grafana.com/grafana/dashboards/15324-loki-logs-dashboard/
вот ID этой борды  15324
