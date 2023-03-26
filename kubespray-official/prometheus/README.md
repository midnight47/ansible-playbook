создаём namescpase в котором будет всё крутиться:
kubectl create ns monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

cd /etc/ansible/kubespray-official/prometheus

в файле my-values.yaml правим доменные имена:
alertmanager.test.ru
grafana.test.ru
prometheus.test.ru

на нужные нам.

дальше правим 
storageClassName в моём случае это nfs-client  (в 9ом шаге мы настраивали nfs provisioner)
проверить можно так:
kubectl  get storageclasses.storage.k8s.io
NAME            PROVISIONER                                   RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-storage   kubernetes.io/no-provisioner                  Delete          WaitForFirstConsumer   false                  19d
nfs-client      k8s-sigs.io/nfs-subdir-external-provisioner   Delete          Immediate              false                  11d

выставляем необходимые объёмы для persistant volume
в полях storage
и size

после этого можно запускать установку:
root@master1:/etc/ansible/kubespray-official/prometheus# helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring -f my-values.yaml

ставим леблы на все неймспейсы:
kubectl label namespace --all "prometheus=enabled"


отмечу что есть проблема с prometheus-kube-proxy он стартует на 127,0,0,1
а прометеус лезет на айпишник т.е. щимится на ноды а там ни кто не отвечает.
для исправления делаем, НА МАСТЕРАХ правим:

vim /etc/kubernetes/kubeadm-config.yaml
c
metricsBindAddress: 127.0.0.1:10249
на
metricsBindAddress: 0.0.0.0:10249


редактируем конфигмап
root@master1:~# kubectl -n kube-system edit cm kube-proxy

так же правим:
    metricsBindAddress: 127.0.0.1:10249
на
    metricsBindAddress: 0.0.0.0:10249


после чего перезапускаем все kube-proxy:

for i in `kubectl get pod -n kube-system | grep kube-proxy | awk '{print $1}'`; do kubectl delete pod -n kube-system $i; done


у grafana.test.ru  по умолчанию логин admin пароль prom-operator

