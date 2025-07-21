kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io --force-update
kubectl create ns cert-manager
helm upgrade --install cert-manager --namespace cert-manager --version v1.18.2 jetstack/cert-manager --values values.yaml

kubectl apply -f issuer-selfsigned.yaml
kubectl apply -f certificate-root-ca.yaml
kubectl apply -f issuer-ca.yaml
kubectl apply -f certificate-wildcard.yaml



Issuer selfSigned (issuer-selfsigned.yaml)
Генерирует корневой ключ/сертификат CA в первом Certificate-шаге.

Certificate Root-CA (certificate-root-ca.yaml)
Сам  Certificate с isCA: true — он подписывается первым Issuer’ом и сохраняет в Secret ваш корневой CA.

Issuer CA (issuer-ca.yaml)
Берёт этот корневой CA-секрет (ключ + cert) и становится «настоящим» подписывающим Issuer’ом для любых downstream-запросов.

Certificate wildcard (certificate-wildcard.yaml)
Запрос сертификата *.test.local, подписанного уже вашим CA-Issuer’ом.



чтобы получать сертификат - нужно добавить в аннотации
```
  annotations:
    cert-manager.io/cluster-issuer: ca-issuer
```

вот пример:
kubectl create ns argocd
kubectl apply -f example-cert.yaml

```
kubectl  get secrets -n argocd 
NAME              TYPE                DATA   AGE
argo-tls-secret   kubernetes.io/tls   3      16m
```
там будут 
  tls.crt:   # публичный сертификат *.test.local
  tls.key:   # приватный ключ к нему
  ca.crt:    # корневой CA-сертификат, на базе которого был подписан tls.crt 

