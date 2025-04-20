https://goteleport.com/docs/admin-guides/deploy-a-cluster/helm-deployments/custom/

helm repo add teleport https://charts.releases.teleport.dev
helm repo update

kubectl create ns teleport

openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout teleport.key -out teleport.crt \
  -subj "/CN=teleport.test.local" \
  -addext "subjectAltName=DNS:teleport.test.local,DNS:*.teleport.test.local"

kubectl create secret tls teleport-tls --key=teleport.key --cert=teleport.crt -n teleport


helm install teleport-cluster teleport/teleport-cluster -n teleport -f values.yaml



kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
--type=json \
-p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-ssl-passthrough=true"}]'

