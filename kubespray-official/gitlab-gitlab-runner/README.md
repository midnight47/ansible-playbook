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


==================================================

если нужно настроить ldap авторизацию, используйте секрет:
gitlab-ldap-secret.yaml
в котором пароль от системного пользователя gitlab а в качестве values используйте gitlab-ldap.yaml  

```
global:
  appConfig:
    ldap:
      enabled: true
      servers:
        main:
          label: "FreeIPA LDAP"
          host: "192.168.1.100"
          port: 389
          uid: "uid"  # в FreeIPA имя юзера в атрибуте uid
          bind_dn: "uid=gitlab,cn=sysaccounts,cn=etc,dc=test,dc=local"
          password:
            secret: gitlab-ldap-secret
            key: ldap.bindPW
          # Шифрование: plain – без TLS; start_tls – через StartTLS; simple_tls – LDAPS
          encryption: "plain"
          verify_certificates: false
          # Базовая точка поиска пользователей в FreeIPA
          base: "cn=accounts,dc=test,dc=local"
          # Ограничиваем вход только членами группы gitlab
          user_filter: "(memberOf=cn=gitlab,cn=groups,cn=accounts,dc=test,dc=local)"
          # По логину используем uid (или поставьте allow_username_or_email_login: true)
          allow_username_or_email_login: false
          block_auto_created_users: false
```

