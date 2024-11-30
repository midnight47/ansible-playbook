настраиваем glusterfs provision

подготоавливаем новый сервер в моём случае это 
192.168.1.109
192.168.1.110

правим hosts 
cat /etc/ansible/hosts

[all_servers]
192.168.1.100 # freeipa1
192.168.1.101 # freeipa2
192.168.1.102 # nexus
192.168.1.103 # vault1
192.168.1.104 # vault2
192.168.1.105 # vault3
192.168.1.106 # gitlab
192.168.1.107 # gitlab-runner
192.168.1.108 # nfs
192.168.1.109 # gluster-fs1
192.168.1.110 # gluster-fs2
192.168.1.112 # kub-master1
192.168.1.113 # kub-master2
192.168.1.114 # kub-master3
192.168.1.115 # kub-worker1
192.168.1.116 # kub-worker2
192.168.1.117 # kub-worker3

для начала прогоням роль по всем серверам

ansible-playbook -u root  playbooks/roles_play/new_server.yml --ask-pass


теперь установим glusterfs сервер и клиенты:
cat /etc/ansible/hosts
[glusterfs:children]
glustermaster
glusterclient
[glustermaster]
gluster-fs1.test.local ansible_host=192.168.1.109
gluster-fs2.test.local ansible_host=192.168.1.110
[glusterclient]
192.168.1.112
192.168.1.113
192.168.1.114
192.168.1.115
192.168.1.116
192.168.1.117


Указываем в какой директории у нас будут хранится glusterfs вольюмы:
cat /etc/ansible/playbooks/roles_play/glusterfs.yml

   - dir_gluster_master: /gluster
   - dir_gluster_client: /gluster-client
   - name_of_gluster_tom: gluster-tom


ставим glusterfs 
ansible-playbook -u root  playbooks/roles_play/glusterfs.yml --ask-pass


провижинет ставим следующим образом

helm repo add olli-ai https://olli-ai.github.io/helm-charts/
helm repo update
helm install glusterfs-client olli-ai/glusterfs-client-provisioner \
--namespace kube-system \
--set glusterfs.server="{192.168.1.109,192.168.1.110}" \
--set glusterfs.volume=gluster-tom \
--set glusterfs.path=/


проверяем:
root@debian:~/glusterfs-provision# kubectl  apply -f test-claim.yaml

root@debian:~/glusterfs-provision# kubectl get pvc
NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
test-claim-gluster   Bound    pvc-6ac72dee-d061-459b-8dc1-b9fb90e249ae   50Mi       RWX            glusterfs-client   9s

root@debian:~/glusterfs-provision# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS       REASON   AGE
pvc-6ac72dee-d061-459b-8dc1-b9fb90e249ae   50Mi       RWX            Delete           Bound    default/test-claim-gluster   glusterfs-client            15s







так же можем пойти ручным методом для этого:






в файле
/etc/ansible/kubespray-official/glusterfs-provision/endpont.yml
указываем наши glusterfs сервера

subsets:
  - addresses:
      #Тут указываем ip наших серверов
      - ip: 192.168.1.109
    ports:
      #Тут просто можно оставить 1, порт роли не играет
      - port: 1
  - addresses:
      - ip: 192.168.1.110
    ports:
      - port: 1

~/glusterfs-provision# kubectl apply -f endpont.yml -f service.yml 


всё можно подключать том /gluster-client
в под или деплоймент

