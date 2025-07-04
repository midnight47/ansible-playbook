https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/charts/gitlab

openssl genrsa -out ca.key 4096
openssl req -x509 -sha256 -new -key ca.key -days 10000 -out ca.crt
openssl genrsa -out gitlab.key 4096
openssl req -new -key gitlab.key -out gitlab.csr -config gitlab_openssl.cnf
openssl x509 -req -in gitlab.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out gitlab.crt -days 10000 -sha256 -extfile ca_openssl.cnf -extensions v3_ca

kubectl create ns gitlab

kubectl create secret generic gitlab-tls \
  --from-file=tls.crt=./gitlab.crt \
  --from-file=tls.key=./gitlab.key \
  --from-file=ca.crt=./ca.crt \
  -n gitlab


будем использовать встроенную базу данных, можно использовать и внешнюю базу для этого нужно раскомментировать и заполнить psql часть, а postgresql выключить


kubectl -n gitlab create secret generic gitlab-s3-config --from-file=s3.yml=./s3-conf.yml

helm repo add gitlab https://charts.gitlab.io/
helm repo update

helm upgrade --install gitlab gitlab/gitlab -n gitlab --version 8.9.2 --values gitlab.yaml


так как у нас для ssh порт 2222 и нужно его выкинуть через ingress то в ingress controller добавляем
```
tcp:
  2222: "gitlab/gitlab-gitlab-shell:2222"
```


пароль в гитлаб
kubectl get secrets -n gitlab gitlab-gitlab-initial-root-password -o yaml | grep password: | awk '{print $2}' | base64 -d


ставим gitlab-runner предварительно создаём токен в самом гитлаб
создаём секрет с самоподписанным сертификатом

kubectl create secret generic gitlab-ssl   --namespace gitlab   --from-file=gitlab.test.local.crt=./gitlab.crt

добавляем в values этот сертификат
```
certsSecretName: "gitlab-ssl"
```

ставим:
helm upgrade --install gitlab-runner gitlab/gitlab-runner -n gitlab --version 0.74.1 --values gitlab-runner.yaml 

проверяем:

```
kubectl get pod -n gitlab gitlab-runner-5448bd476d-x8vbs 
NAME                             READY   STATUS    RESTARTS   AGE
gitlab-runner-5448bd476d-x8vbs   1/1     Running   0          34m
```
