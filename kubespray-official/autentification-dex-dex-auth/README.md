```
root@client:~# mkdir certs
root@client:~# cd certs/
root@client:~/certs# openssl genrsa -out ca.key 4096
root@client:~/certs# openssl req -x509 -sha256 -new -key ca.key -days 10000 -out ca.crt
root@client:~/certs# openssl genrsa -out dex.key 4096
root@client:~/certs# openssl req -new -key dex.key -out dex.csr -config dex_openssl.cnf
root@client:~/certs# openssl x509 -req -in dex.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out dex.crt -days 10000 -sha256 -extfile ca_openssl.cnf -extensions v3_ca

root@client:~/certs# kubectl create ns dex

root@client:~/certs# kubectl create secret tls dex-tls --key dex.key --cert dex.crt --namespace dex
root@client:~/certs# kubectl create secret generic dex-ca-cert --from-file=ca.crt=./ca.crt -n dex

helm repo add dex https://charts.dexidp.io
helm repo update

root@client:~/autentification-dex-dex-auth# helm upgrade --install dex dex/dex -f dex.yaml --namespace dex --version 0.19.1

root@client:~/autentification-dex-dex-auth# helm upgrade --install dex-auth wiremind/dex-k8s-authenticator -n dex -f dex-auth.yaml
```
после установки нужно поправить деплоймены:
```
kubectl edit deployments.apps -n dex  dex
kubectl edit deployments.apps -n dex  dex-auth-dex-k8s-authenticator
```
а именно заменить имеющуюся dnsPolicy на
```
      dnsPolicy: None
      dnsConfig:
        nameservers:
        - 10.233.0.3 # IP вашего coredns ClusterIP (посмотрите `kubectl get svc -n kube-system` чтобы найти coredns)
        searches:
        - cluster.local
        - svc.cluster.local
        - test.local
```

нужно подкинуть сертификаты на клиент тачку с которой будем подключаться, во первых это куберовский серт cat /etc/kubernetes/pki/ca.crt
и серт dex который мы создавали dex.crt
подкидываем их в /usr/local/share/ca-certificates/ и выполняем команду:
root@client:~# sudo update-ca-certificates

далее нужно поправить /etc/kubernetes/manifests/kube-apiserver.yaml на всем мастерах, добавив туда oidc:

```
    - --oidc-issuer-url=https://dex.test.local
    - --oidc-client-id=kubernetes  # берём отсюда  dexK8sAuthenticator -> clusters -> client_id
    - --oidc-ca-file=/etc/kubernetes/ssl/dex.crt
    - --oidc-username-claim=email
    - --oidc-groups-claim=groups
```
после применяем наши roles
root@client:~/autentification-dex-dex-auth# kubectl apply -f group-devops.yaml
root@client:~/autentification-dex-dex-auth# kubectl apply -f group-k8s-users-ro.yaml

