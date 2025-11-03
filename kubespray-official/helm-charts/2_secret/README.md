https://github.com/hashicorp/vault-secrets-operator

ставим
helm repo add hashicorp https://helm.releases.hashicorp.com


добавляем адрес нашего vault в values чтоб установить
vault-secrets-operator.yaml

helm upgrade --install --namespace vault vault-secrets-operator hashicorp/vault-secrets-operator --version 0.10.0 -f vault-secrets-operator.yaml

дальше нам надо настроить интеграцию с нашим vault кластером, который на виртуалках, для этого нам понадобится сертификат поэтому выполняем команду:


kubectl get cm kube-root-ca.crt -o jsonpath="{['data']['ca\.crt']}"
получаем наш серт


создаём сервис аккаунт
kubectl create serviceaccount vault-auth -n kube-system

на основе этого сервис аккаунта получаем jwt token  устанавливаю время на 100 лет 876000h
kubectl create token vault-auth -n kube-system --duration 876000h


далее подключаемся к нашему vault который на виртуалках
ssh 192.168.1.103
напоминаю root token  пробелы нужно убрать - гитхаб не позволяет грузить
h  vs.  UuG  0QJvR  RfwUHUTGx  DTjF  aAd
root@vault1:~# vault login

создаём секрет который будем подкидывать:
root@vault1:~# vault secrets enable -path=test/secret/ kv

добавляем туда ключ значение:
root@vault1:~# vault kv put test/secret/app/first-app password="db-secret-password"

включаем аутентификацию в k8s
root@vault1:~# vault auth enable kubernetes



сертификат который получили ранее, кладём в файл /root/ca.crt 

дальше присваиваем переменной TOKEN_REVIEWER_JWT наш jwt токен который мы создали выше
root@vault1:~# export TOKEN_REVIEWER_JWT=''

теперь настраиваем auth к кластеру
vault write auth/kubernetes/config \
    kubernetes_host="https://192.168.1.112:6443" \
    kubernetes_ca_cert=@/root/ca.crt \
    token_reviewer_jwt="$TOKEN_REVIEWER_JWT" \
    disable_iss_validation="true"

создаём policy  "test-policy" на чтение ТОЛЬКО нашего секрета
vault policy write test-policy - <<EOF
path "test/secret/app/first-app" {
  capabilities = ["read"]
}
EOF

создаём роль "test-role"

root@kub-master1:~# kubectl get serviceaccounts -n app
NAME      SECRETS   AGE
app       0         16d
default   0         16d


Роль связывает учетную запись службы Kubernetes(serviceaccaunt), которую назовём app (но лучше использовать уже существующий сервис аккаунт нашего приложения ) в пространстве имен app с политикой Vault, test-policy Токены, возвращенные после аутентификации, действительны в течение 10 минут

На роли должен быть задан audience — с Vault ≥1.21 он обязателен. Значение должно совпадать с aud в JWT сервис-аккаунта, которым логинится pod. Пример обновления роли:

vault write auth/kubernetes/role/test-role \
  bound_service_account_names=app \
  bound_service_account_namespaces=app \
  policies=test-policy \
  audience="vault" \
  ttl=10m

bound_service_account_names: Имя сервисного аккаунта, которому разрешено аутентифицироваться.
bound_service_account_namespaces: Пространство имён, в котором находится сервисный аккаунт.
Как выбрать audience:
Самый надёжный вариант — выдать pod’у projected токен с нужной audience и поставить её же в роли Vault:

```
# фрагмент Pod/Deployment
spec:
  serviceAccountName: app
  volumes:
  - name: sa-token
    projected:
      sources:
      - serviceAccountToken:
          path: token
          audience: vault          # <— то же значение укажете в роли
          expirationSeconds: 3600
```

создаём объект VaultConnection который будет использоваться для подключения к vault во всех неймспейсах

kubectl apply -f vault-connection.yaml
kubectl apply -f vault-auth.yaml

для подключения к VaultConnection  используется запись: kube-system/vault-connection
так же тут указываем 
роль созданную в vault test-role и 
сервис аккаунт app - который так же должен совпадать с тем что мы указали в vault и с тем что у нас уже создан в k8s

kubectl apply -f vault-static-secret.yaml
тут мы указываем как будет называться secret и как часто его обновлять.

теперь создаём несколько объектов ClusterRole  и ClusterRoleBinding
kubectl apply -f vault-rbac.yaml
ClusterRoleBinding смотрит на ServiceAccount  vault-auth расположенный kube-system мы его создавали вручную и jwt token создавали на его основе.

проверить что всё ок можно командами
kubectl describe vaultconnections.secrets.hashicorp.com -n kube-system vault-connection
kubectl describe vaultauths.secrets.hashicorp.com -n app vault-auth-test 
kubectl describe vaultstaticsecrets.secrets.hashicorp.com -n app app-creds 
kubectl get secret -n app app-secret -o yaml

==============================

# сделаем универсальную роль и policy

и секреты можно создавать вида:
<ns>/service/<app>
namespace-test/service/app1
или
namespace-test/service/app2
или
namespace-test2/service/app3
или
namespace-test2/service/app4
и тд.


запускаем на волте:
export K8S_ACC=$(vault auth list -format=json | jq -r '."kubernetes/".accessor')

vault policy write read-service-by-namespace - <<EOF
path "{{identity.entity.aliases.${K8S_ACC}.metadata.service_account_namespace}}/service/*" {
  capabilities = ["read","list"]
}
EOF

vault write auth/kubernetes/role/ns-scoped-read \
  bound_service_account_names="*" \
  bound_service_account_namespaces="*" \
  policies="read-service-by-namespace" \
  audience="https://kubernetes.default.svc" \
  ttl=10m


# всё, deployment поправил + добавил 2 файла vault-secrets-operator-VaultAuth.yaml и vault-secrets-operator-VaultSecret.yaml  перезапуск тоже добавлен (reloader)


vault_secret:
  enabled: true
  name: app2-secret                 # имя k8s Secret, который получит VSO
  secretFullPath: app/service/app2  # путь в Vault: <ns>/service/<app>
  type: kv-v1                       # у меня сейчас kv-v1
  role: ns-scoped-read              # универсальная роль в vault для всех ns

# всё можно ставить:
root@kub-master1:~/helm-charts/2_secret# helm upgrade --install app2 -n app ./common-chart -f ./common-chart/values-minimal.yaml 

проверить можно так:
# смотрим VSO-ресурсы
kubectl -n app describe vaultauth app-va
kubectl -n app describe vaultstaticsecret app-vss | egrep 'Mount:|Path:|Type:'

# появился ли секрет и ключи?
kubectl -n app get secret app1-secret -o json | jq -r '.data | keys[]'