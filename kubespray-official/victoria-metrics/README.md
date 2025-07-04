kubectl create ns monitoring

ставим CRD
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update

helm search repo vm/victoria-metrics-operator-crds -l
```
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                   
vm/victoria-metrics-operator-crds       0.2.1           v0.59.2         VictoriaMetrics Operator CRDs 
vm/victoria-metrics-operator-crds       0.2.0           v0.59.0         VictoriaMetrics Operator CRDs 
vm/victoria-metrics-operator-crds       0.1.2           v0.58.0         Victoria Metrics Operator CRDs
vm/victoria-metrics-operator-crds       0.1.1           v0.57.0         Victoria Metrics Operator CRDs
vm/victoria-metrics-operator-crds       0.1.0           v0.56.0         Victoria Metrics Operator CRDs
vm/victoria-metrics-operator-crds       0.0.3           v0.55.0         Victoria Metrics Operator CRDs
vm/victoria-metrics-operator-crds       0.0.2           v0.55.0         Victoria Metrics Operator CRDs
vm/victoria-metrics-operator-crds       0.0.1           v0.54.1         Victoria Metrics Operator CRDs
```

helm install vmoc vm/victoria-metrics-operator-crds -n monitoring --version 0.2.1

```
helm list -n monitoring
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                                   APP VERSION
vmoc    monitoring      1               2025-06-20 17:59:34.415966323 +0600 +06 deployed        victoria-metrics-operator-crds-0.2.1    v0.59.2    
```

ставим викторию:
```
helm search repo vm/victoria-metrics-k8s-stack -l
NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
vm/victoria-metrics-k8s-stack   0.52.0          v1.119.0        Kubernetes monitoring on VictoriaMetrics stack....
vm/victoria-metrics-k8s-stack   0.51.0          v1.119.0        Kubernetes monitoring on VictoriaMetrics stack....
vm/victoria-metrics-k8s-stack   0.50.1          v1.118.0        Kubernetes monitoring on VictoriaMetrics stack....
vm/victoria-metrics-k8s-stack   0.50.0          v1.118.0        Kubernetes monitoring on VictoriaMetrics stack....
vm/victoria-metrics-k8s-stack   0.49.0          v1.118.0        Kubernetes monitoring on VictoriaMetrics stack....
vm/victoria-metrics-k8s-stack   0.48.1          v1.117.1        Kubernetes monitoring on VictoriaMetrics stack....
```

openssl genrsa -out ca.key 4096
openssl req -x509 -sha256 -new -key ca.key -days 10000 -out ca.crt
openssl genrsa -out vmsingle.key 4096
openssl req -new -key vmsingle.key -out vmsingle.csr -config vm_openssl.cnf
openssl x509 -req -in vmsingle.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out vmsingle.crt -days 10000 -sha256 -extfile ca_openssl.cnf -extensions v3_ca


kubectl create secret generic vm-tls \
  --from-file=tls.crt=./vmsingle.crt \
  --from-file=tls.key=./vmsingle.key \
  --from-file=ca.crt=./ca.crt \
  -n monitoring

helm upgrade --install vmks vm/victoria-metrics-k8s-stack -f values.yaml -n monitoring --version 0.52.0


на нодах которые не в кубере мы можем запустить композник чтобы собирать с них метрики
/etc/ansible/kubespray-official/victoria-metrics/docker-compose-vmagent/prometheus.yml
тут указываем job_name: и группируем его по 'node-vault' , т.е. в списке мы будем получать все ноды под этой группой
тут указываем targets: ['192.168.1.103:9100'] это где IP адрес на котором запущен сбор метрик

/etc/ansible/kubespray-official/victoria-metrics/docker-compose-vmagent/docker-compose.yml
тут указываем для vmagent '--remoteWrite.url=http://vmsingle.test.local/api/v1/write'  это адрес нашего vmsingle.
если нету DNS внутреннего то нужно подкинуть в хосты
cat /etc/hosts | grep vms
192.168.1.191 vmsingle.test.local

всё после этого можно стартовать 
docker-compose up -d
