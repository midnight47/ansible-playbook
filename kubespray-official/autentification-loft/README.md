helm repo add loft https://charts.loft.sh
helm repo update
[root@ansible ansible]# cd /etc/ansible/kubespray-official/sso-loft/
root@client:~# kubectl create ns loft
root@client:~/sso-loft# helm install loft loft/loft --namespace loft -f values.yaml --version 4.1.0

