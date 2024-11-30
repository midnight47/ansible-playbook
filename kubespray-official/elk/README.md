11. Настройка ELK

root@master1:/etc/ansible/kubespray-official/elk/certs# kubectl create ns elk

helm repo add elastic https://helm.elastic.co

Далее нам надо сгенерировать сертификаты на основе которых будет всё работать.

root@master1:/etc/ansible/kubespray-official/elk# mkdir certs
root@master1:/etc/ansible/kubespray-official/elk# cd certs/

ставим докер

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
root@master1:/etc/ansible/kubespray-official/elk/certs# apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y 

root@master1:/etc/ansible/kubespray-official/elk/certs# systemctl start docker.socket


командой ниже будет сгенерены самоподписанные сертификаты имена задаём через команду --dns
и выполняем команду ниже:

docker run --name elastic-helm-charts-certs -i -w /tmp \
	elasticsearch:8.5.1 \
	/bin/sh -c " \
		elasticsearch-certutil ca --out /tmp/elastic-stack-ca.p12 --pass '' && \
		elasticsearch-certutil cert --name security-master --dns elasticsearch-master --dns kibana-kibana --dns kibana.test.local --dns elasticsearch-master* --dns logstash-logstash-headless --dns logstash* --days 7000  --ca /tmp/elastic-stack-ca.p12 --pass '' --ca-pass '' --out /tmp/elastic-certificates.p12" && \
docker cp elastic-helm-charts-certs:/tmp/elastic-certificates.p12 ./ && \
docker rm -f elastic-helm-charts-certs && \
openssl pkcs12 -nodes -passin pass:'' -in elastic-certificates.p12 -out elastic-certificate.pem && \
openssl x509 -outform der -in elastic-certificate.pem -out elastic-certificate.crt && \
kubectl create secret -n elk generic elastic-certificates --from-file=elastic-certificates.p12 && \
kubectl create secret -n elk generic elastic-certificate-pem --from-file=elastic-certificate.pem && \
kubectl create secret -n elk generic elastic-certificate-crt --from-file=elastic-certificate.crt 

openssl pkey -in elastic-certificate.pem -out cert.key
openssl crl2pkcs7 -nocrl -certfile elastic-certificate.pem | openssl pkcs7 -print_certs -out cert.crt

kubectl create secret tls tls-kibana --namespace elk --key cert.key --cert cert.crt

теперь можно ставить:
root@master1:/etc/ansible/kubespray-official/elk# helm upgrade --install elasticsearch elastic/elasticsearch -n elk -f elastic.yaml


12. Настройка kibana

правим доменное имя kibana.test.local в файле kibana.yaml 

ставим:
root@master1:/etc/ansible/kubespray-official/elk# helm upgrade --install kibana elastic/kibana -n elk -f kibana.yaml

13. Настройка logstash 

root@master1:/etc/ansible/kubespray-official/elk# helm upgrade --install logstash elastic/logstash -n elk -f logstash.yaml

14. Настройа flebeat

root@master1:/etc/ansible/kubespray-official/elk# helm upgrade --install filebeat elastic/filebeat -n elk -f filebeat.yaml

