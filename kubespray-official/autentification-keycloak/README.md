https://github.com/codecentric/helm-charts/tree/master


helm repo add codecentric https://codecentric.github.io/helm-charts
kubectl create ns keycloak

создаём секрет с логином и паролем:
kubectl create secret generic keycloak-admin-settings -n keycloak \
    --from-literal=admin-password=Secret123 \
    --from-literal=admin-username=admin



root@client:~# cd ~/autentification-keycloak/certs/
root@client:~/autentification-keycloak/certs# openssl genrsa -out ca.key 4096
root@client:~/autentification-keycloak/certs# openssl req -x509 -sha256 -new -key ca.key -days 10000 -out ca.crt
root@client:~/autentification-keycloak/certs# openssl genrsa -out keycloak.key 4096
root@client:~/autentification-keycloak/certs# openssl req -new -key keycloak.key -out keycloak.csr -config keycloak_openssl.cnf
root@client:~/autentification-keycloak/certs# openssl x509 -req -in keycloak.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out keycloak.crt -days 10000 -sha256 -extfile ca_openssl.cnf -extensions v3_ca
root@client:~/autentification-keycloak/certs# cat keycloak.key keycloak.crt > keycloak.pem


root@client:~/autentification-keycloak/certs# kubectl create secret tls keycloak-tls --key keycloak.key --cert keycloak.crt --namespace keycloak
root@client:~/autentification-keycloak/certs# kubectl create secret generic keycloak-ca-cert --from-file=ca.crt=./ca.crt -n keycloak



ставим:
root@client:~/autentification-keycloak# helm upgrade --install keycloak oci://ghcr.io/codecentric/helm-charts/keycloak --version 18.9.0 -n keycloak -f values.yaml


заходим:
http://keycloak.test.local/


root@client:~/autentification-keycloak/certs# scp keycloak.crt root@192.168.1.112:/etc/kubernetes/ssl/keycloak.crt
root@client:~/autentification-keycloak/certs# scp keycloak.crt root@192.168.1.113:/etc/kubernetes/ssl/keycloak.crt
root@client:~/autentification-keycloak/certs# scp keycloak.crt root@192.168.1.114:/etc/kubernetes/ssl/keycloak.crt



===========================
runcher
root@client:~# cd ~/autentification-keycloak/cercerts-rancherts/
root@client:~/autentification-keycloak/certs-rancher# openssl genrsa -out ca.key 4096
root@client:~/autentification-keycloak/certs-rancher# openssl req -x509 -sha256 -new -key ca.key -days 10000 -out ca.crt
root@client:~/autentification-keycloak/certs-rancher# openssl genrsa -out rancher.key 4096
root@client:~/autentification-keycloak/certs-rancher# openssl req -new -key rancher.key -out rancher.csr -config rancher_openssl.cnf
root@client:~/autentification-keycloak/certs-rancher# openssl x509 -req -in rancher.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out rancher.crt -days 10000 -sha256 -extfile ca_openssl.cnf -extensions v3_ca
root@client:~/autentification-keycloak/certs-rancher# cat rancher.key rancher.crt > rancher.pem

kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/путь/к/rancher.crt --key=/путь/к/rancher.key





helm install rancher rancher-stable/rancher -n cattle-system --version 2.9.3 -f values-rancher.yaml --set bootstrapPassword=ddjjKKSSlldd345hhRRsd


echo https://rancher.test.local/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')
```

To get just the bootstrap password on its own, run:

```
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'
