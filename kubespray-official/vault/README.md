настраиваем vault
root@master1:/etc/ansible/kubespray-official/vault#  apt-get install jq


для HA у vault требуется минимум 3 ноды НО на данный момент я ограничен по нодам, поэтому у меня их всего 2, поэтому дальше в примерах их будет только 2.

root@master1:/etc/ansible/kubespray-official# cd vault/
root@master1:/etc/ansible/kubespray-official/vault# kubectl create ns vault

чарт берём оффициальный
https://github.com/hashicorp/vault-helm.git
 я подготовил my-values.yaml

``` 
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install -n vault vault hashicorp/vault -f my-values.yaml

kubectl -n vault exec vault-0 -- vault operator init -key-shares=5 -key-threshold=3 -format=json > cluster-keys.json
for i in `cat cluster-keys.json | jq -r ".unseal_keys_b64[]"`; do kubectl -n vault exec vault-0 -- vault operator unseal $i; done

root@master1:/etc/ansible/kubespray-official/vault# kubectl -n vault exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
root@master1:/etc/ansible/kubespray-official/vault# kubectl -n vault exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200


root@master1:/etc/ansible/kubespray-official/vault# for i in `cat cluster-keys.json | jq -r ".unseal_keys_b64[]"`; do kubectl -n vault exec vault-1 -- vault operator unseal $i; done
root@master1:/etc/ansible/kubespray-official/vault# for i in `cat cluster-keys.json | jq -r ".unseal_keys_b64[]"`; do kubectl -n vault exec vault-2 -- vault operator unseal $i; done
```




добавляем адресс нашего vault 

cat vault-secrets-operator.yaml

```
defaultVaultConnection:
  # toggles the deployment of the VaultAuthMethod CR
  # @type: boolean
  enabled: true

  # Address of the Vault Server
  # @type: string
  # Example: http://vault.default.svc.cluster.local:8200
  address: "http://vault.vault.svc.cluster.local:8200"
```

helm upgrade --install --namespace vault vault-secrets-operator hashicorp/vault-secrets-operator --version 0.1.0-beta -f vault-secrets-operator.yaml

данная версия --version 0.1.0-beta  это версия чарта  https://github.com/hashicorp/vault-secrets-operator/blob/main/chart/Chart.yaml

логинимся в vault

kubectl exec -it vault-0 -n vault -- /bin/sh
vault login s.PAx0C3X0nx9vVBMwgtM9nLH6

пароль берём из файла cluster-keys.json

создаём секрет который будем подкидывать:

vault secrets enable -path=test/secret/ kv


добавляем туда ключ значение:

vault kv put test/secret/namespace-test/first-app password="db-secret-password"

включаем аутентификацию в k8s (если один раз включили последующие разы ещё раз включать аутентификацию НЕ нужно)

vault auth enable kubernetes

```
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    disable_iss_validation="true"
```

создаём policy  "test-policy" на чтение ТОЛЬКО нашего секрета

```
vault policy write test-policy - <<EOF
path "test/secret/namespace-test/first-app" {
  capabilities = ["read"]
}
EOF
```

```
vault write auth/kubernetes/role/test-role \
    bound_service_account_names=test-serviceaccaunt \
    bound_service_account_namespaces=test \
    policies=test-policy \
    ttl=10m
```

kubectl create serviceaccount test-serviceaccaunt -n test

cat vault-auth.yaml
```
apiVersion: secrets.hashicorp.com/v1alpha1
kind: VaultAuth
metadata:
  labels:
    app.kubernetes.io/name: vaultauth
    app.kubernetes.io/instance: vaultauth-sample
    app.kubernetes.io/part-of: vault-secrets-operator
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/created-by: vault-secrets-operator
  name: vaultauth-app1
  namespace: test
spec:
  vaultConnectionRef:
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: test-role
    serviceAccount: test-serviceaccaunt
```

kubectl apply -f vault-auth.yaml -n test


cat vault-secret.yaml

```
---
apiVersion: secrets.hashicorp.com/v1alpha1
kind: VaultStaticSecret
metadata:
  namespace: test
  name: vault-secret-app1
spec:
  vaultAuthRef: vaultauth-app1
  mount: test/secret
  type: kv-v1
  name: namespace-test/first-app
  refreshAfter: 10s
  destination:
    create: true
    name: test-secret-k8s
    type: Opaque

```

kubectl apply -f vault-secret.yaml -n test


создадим чарт и подкинем секрет:

helm create test-chart

добавляем в test-chart/templates/deployment.yaml

```
          envFrom:
           - secretRef:
               name: test-secret-k8s

```

helm install test-work -n test --values test-chart/values.yaml ./test-chart/


чтобы заработал reloader - добавим в vaultstaticecret rollout restart targets
cat vault-secret.yaml

```
apiVersion: secrets.hashicorp.com/v1alpha1
kind: VaultStaticSecret
metadata:
  namespace: test
  name: vault-secret-app1
spec:
  vaultAuthRef: vaultauth-app1
  mount: test/secret
  type: kv-v1
  name: namespace-test/first-app
  refreshAfter: 10s
  destination:
    create: true
    name: test-secret-k8s
    type: Opaque
  rolloutRestartTargets:
    - kind: Deployment
      name: test-work-test-chart
```

kubectl apply -f vault-secret.yaml -n test

всё можно теперь обновлять секреты они будут подкидываться в секрет k8s и deployment будет рестартиться

