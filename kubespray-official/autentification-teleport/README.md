https://goteleport.com/docs/admin-guides/deploy-a-cluster/helm-deployments/custom/

helm repo add teleport https://charts.releases.teleport.dev
helm repo update

kubectl create ns teleport


создаем сертификаты 
DNS.1 = teleport.test.local
DNS.2 = *.teleport.test.local


openssl genrsa -out ca.key 4096
openssl req -x509 -sha256 -new -key ca.key -days 10000 -out ca.crt
openssl genrsa -out teleport.key 4096
openssl req -new -key teleport.key -out teleport.csr -config teleport_openssl.cnf
openssl x509 -req -in teleport.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out teleport.crt -days 10000 -sha256 -extfile ca_openssl.cnf -extensions v3_ca


kubectl -n teleport create secret generic teleport-ca-cert --from-file=ca.pem=./ca.crt

kubectl create secret generic teleport-tls \
  --from-file=tls.crt=./teleport.crt \
  --from-file=tls.key=./teleport.key \
  --from-file=ca.crt=./ca.crt \
  -n teleport



на клиентах добавляем сертификаты в доверенные
mkdir /usr/local/share/ca-certificates/teleport/
cp teleport.crt ca.crt /usr/local/share/ca-certificates/teleport/
update-ca-certificates



helm upgrade --install teleport-cluster teleport/teleport-cluster -n teleport -f values.yaml --version 17.4.5


создаём админа:
kubectl exec -it -n teleport deploy/teleport-cluster-auth -- tctl users add admin --roles=editor,auditor,access


ставим teleport-connect, вот офф сайт
https://goteleport.com/download/?product=connect

версия сервера 17.4.5  такую же версию ставим и для клиента
вот команда
curl https://goteleport.com/static/install-connect.sh | bash -s 17.4.5


для подключения выполняем команду:
user3@client:~$ tsh login --proxy=teleport.test.local:443 --auth=local --user=admin teleport.test.local --insecure



используем флаг --insecure так как у нас смоподписанный сертификат