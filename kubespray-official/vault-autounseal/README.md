[root@ansible ~]# cd /etc/ansible/kubespray-official/vault-autounseal/
создаём неймспейс
```
root@client:~# kubectl create ns vault
```
добавляем репозиторй
```
root@client:~# helm repo add hashicorp https://helm.releases.hashicorp.com
```
устанавливаем vault
```
root@client:~/vault-autounseal# helm upgrade --install -n vault vault hashicorp/vault -f values.yaml
```

создаём ключи и записываем их в файл:
```
root@client:~/vault-autounseal# kubectl -n vault exec vault-0 -- vault operator init -key-shares=5 -key-threshold=3 -format=json > cluster-keys.json
```

ставим jq
```
root@client:~/vault-autounseal# apt-get install jq -y
```

делаем unseal первого vault
```
root@client:~/vault-autounseal# for i in `cat cluster-keys.json | jq -r ".unseal_keys_b64[]"`; do kubectl -n vault exec vault-0 -- vault operator unseal $i; done
```

собираем raft в кластер:
```
root@client:~/vault-autounseal# kubectl -n vault exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
root@client:~/vault-autounseal# kubectl -n vault exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
```

делаем unseal для второго и третьего vault
```
root@client:~/vault-autounseal# for i in `cat cluster-keys.json | jq -r ".unseal_keys_b64[]"`; do kubectl -n vault exec vault-1 -- vault operator unseal $i; done
root@client:~/vault-autounseal# for i in `cat cluster-keys.json | jq -r ".unseal_keys_b64[]"`; do kubectl -n vault exec vault-2 -- vault operator unseal $i; done
```

создаём конфигмап
```
root@client:~/vault-autounseal# kubectl create configmap vault-unseal-keys --from-file=cluster-keys.json -n vault
```

применяем cronjob для auto-unseal vault в k8s
```
root@client:~/vault-autounseal# kubectl apply -f auto-unseal-cronjob.yaml
```

теперь настраиваем transit autounseal 

kubectl exec -it -n vault vault-0 -- sh
/ $ vault login
/ $ vault secrets enable transit
/ $ vault write -f transit/keys/vault-unseal-key
/ $ cd /tmp/
/tmp $ cat > transit-policy.yaml
```
path "transit/encrypt/vault-unseal-key" {
  capabilities = [ "update" ]
}

path "transit/decrypt/vault-unseal-key" {
  capabilities = [ "update" ]
}
```
/tmp $ vault policy write unseal-policy transit-policy.yaml
/tmp $ vault token create -policy=unseal-policy
результат
```
Key                  Value
---                  -----
token                s.UAiqZBv9lIwDS6ZzOpDdf3XW
token_accessor       kYcVArPi5nVu9o0lKRqdNbNE
token_duration       768h
token_renewable      true
token_policies       ["default" "unseal-policy"]
identity_policies    []
policies             ["default" "unseal-policy"]
```

во все конфиги волтов на виртуалках добавляем:
```
  seal "transit" {
    address = "http://vault-unseal.test.local:80"
    token   = "s.UAiqZBv9lIwDS6ZzOpDdf3XW"
    key_name = "vault-unseal-key"
    mount_path = "transit/"
    disable_renewal = "false"
    tls_skip_verify = "true"
  }
```
вот пример конфига на виртуалке
cat /etc/vault.d/vault.hcl
```
cluster_addr  = "https://vault1.test.local:8201"
api_addr      = "https://vault1.test.local:8200"

disable_mlock = true
ui = true

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_ca_cert_file   = "/opt/vault/tls/my_crt_file.pem"
  tls_cert_file      = "/opt/vault/tls/my_crt_file.pem"
  tls_key_file       = "/opt/vault/tls/my_crt_file.pem"
}

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault1.test.local"

    retry_join {
    leader_tls_servername   = "vault1.test.local"
    leader_api_addr         = "https://vault1.test.local:8200"
    leader_ca_cert_file     = "/opt/vault/tls/my_crt_file.pem"
    leader_client_cert_file = "/opt/vault/tls/my_crt_file.pem"
    leader_client_key_file  = "/opt/vault/tls/my_crt_file.pem"
    }
    retry_join {
    leader_tls_servername   = "vault2.test.local"
    leader_api_addr         = "https://vault2.test.local:8200"
    leader_ca_cert_file     = "/opt/vault/tls/my_crt_file.pem"
    leader_client_cert_file = "/opt/vault/tls/my_crt_file.pem"
    leader_client_key_file  = "/opt/vault/tls/my_crt_file.pem"
    }
    retry_join {
    leader_tls_servername   = "vault3.test.local"
    leader_api_addr         = "https://vault3.test.local:8200"
    leader_ca_cert_file     = "/opt/vault/tls/my_crt_file.pem"
    leader_client_cert_file = "/opt/vault/tls/my_crt_file.pem"
    leader_client_key_file  = "/opt/vault/tls/my_crt_file.pem"
    }
  }


  seal "transit" {
    address = "http://vault-unseal.test.local:80"
    token   = "s.UAiqZBv9lIwDS6ZzOpDdf3XW"
    key_name = "vault-unseal-key"
    mount_path = "transit/"
    disable_renewal = "false"
    tls_skip_verify = "true"
  }
```
так же делаем на остальных виртуалках

добавляем в хосты
root@vault1:~# echo "192.168.1.191 vault-unseal.test.local" >> /etc/hosts
root@vault2:~# echo "192.168.1.191 vault-unseal.test.local" >> /etc/hosts
root@vault3:~# echo "192.168.1.191 vault-unseal.test.local" >> /etc/hosts

далее рестуртауем их
[root@vault1 ~]# systemctl restart vault
[root@vault2 ~]# systemctl restart vault
[root@vault3 ~]# systemctl restart vault

и распечатываем с опцией '-migrate'
[root@vault1 ~]# vault operator unseal -migrate
[root@vault1 ~]# vault operator unseal -migrate
[root@vault1 ~]# vault operator unseal -migrate

[root@vault2 ~]# vault operator unseal -migrate
[root@vault2 ~]# vault operator unseal -migrate
[root@vault2 ~]# vault operator unseal -migrate

[root@vault3 ~]# vault operator unseal -migrate
[root@vault3 ~]# vault operator unseal -migrate
[root@vault3 ~]# vault operator unseal -migrate

всё на этом автоансил закончен. в k8s будет работать cronjob  а на виртуалках будет работать transit к кластеру k8s


#################################

Vault Secrets Operator
вот официальная репка:

https://github.com/hashicorp/vault-secrets-operator

ставим
helm repo add hashicorp https://helm.releases.hashicorp.com

ставим:
helm upgrade --install --namespace vault vault-secrets-operator hashicorp/vault-secrets-operator --version 0.9.0 -f vault-secrets-operator.yaml



смотрим сертификат
root@client:~# kubectl get cm kube-root-ca.crt -o jsonpath="{['data']['ca\.crt']}"


root@client:~/vault-autounseal# kubectl create serviceaccount vault-auth -n kube-system 


root@client:~/vault-autounseal# kubectl create token vault-auth -n kube-system --duration 876000h

переходим в vault

root@vault1:~# export TOKEN_REVIEWER_JWT='eyJhbGciOiJSUzI1NiIsImtpZCI6IkdrQlByYnlkSXBDczR6SUhjalZreDZibnlGX18wVGpqenU2SVRabXVZN1UifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzMyMDkzMDU4LCJpYXQiOjE3MzIwODk0NTgsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJ2YXVsdC1hdXRoIiwidWlkIjoiZDRhZmY3YzktY2Q4My00ODEwLWEyYzYtYWRjZmU5M2VlY2MwIn19LCJuYmYiOjE3MzIwODk0NTgsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTp2YXVsdC1hdXRoIn0.uYsKtd-ClBC9wNLm5vPwCYjamrfmNJNHL4DJd7FxNd5GGyyTIUIqfuAW61APkWpz6gofk90k0N3zHd0oqGWtvGlRBqP_u4sPp8-4UqDHYGH26pO0R6qrQUk75l_XXGwT4E8BAVbyddsfy7Cm6dciWa0JcLmGJ3LR10-tPujuLM4SYHYIrgIW_SymhQLRIHbHIDGRdFmGTxk0RxUlYtDgeB98BSkr806HlSI-1Ouy-nmFeurzuGz6K6Sw8hEK1VC7nnPBTfMd1BeBIAZVNMjLQ4RbXvP2kMoMj0veybsgM74wQf0cII0k1cJ04-1ONKN2vTBA1MPz5hUP7XyG4I9UYg'

root@vault1:~# vault login

теперь настраиваем auth к кластеру:

vault write auth/kubernetes/config \
    kubernetes_host="https://192.168.1.112:6443" \
    kubernetes_ca_cert=@/root/ca.crt \
    token_reviewer_jwt="$TOKEN_REVIEWER_JWT" \
    disable_iss_validation="true"



создаём секрет заполняем его создаём полиси и роль
root@vault1:~# vault secrets enable -path=test/secret/ kv
root@vault1:~# vault kv put test/secret/namespace-test/first-app password="db-secret-password"

vault policy write test-policy - <<EOF
path "test/secret/namespace-test/first-app" {
  capabilities = ["read"]
}
EOF


vault write auth/kubernetes/role/test-role \
    bound_service_account_names=test-serviceaccount \
    bound_service_account_namespaces=test \
    policies=test-policy \
    ttl=10m


создаём namespace serviceaccount
root@client:~# kubectl create ns test
root@client:~# kubectl create serviceaccount test-serviceaccount -n test

далее применяем clusterrole
root@client:~/vault-autounseal# kubectl apply -f vault-secrets-operator-rbac.yaml
vault connection
root@client:~/vault-autounseal# kubectl apply -f vault-secrets-operator-VaultConnection.yaml
авторизацию:
root@client:~/vault-autounseal# kubectl apply -f vault-secrets-operator-VaultAuth.yaml
и сам наш секрет
root@client:~/vault-autounseal# kubectl apply -f vault-secrets-operator-VaultSecret.yaml 
