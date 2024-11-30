Данная роль позволяет установить s3 minio 

так же можно вкючать или выкючать устанвку keepalived в файле  /etc/ansible/roles/minio/defaults/main.yml  там есть переменная  keepalived: true.  Отмечу что для дебиана и так ставится версия keepalived 2 а вот у centos версия 1 поэтому 2ую версию нужно будет собирать из исходников, после сборки она будет скопирована на хост ансибла сюда /etc/ansible/roles/vault/files/   но я заранее скомпили и положил бинарник. виртуальный айпишник будет всегда на волте который является мастером.

в файле: /etc/ansible/roles/minio/defaults/main.yaml  можно задать порты, пользователя под которым будет всё работать, сервера на которых будет всё установлено, какие разделы задействовать.


в файле /etc/ansible/hosts  
[minio]
s3-minio-1.test.local ansible_host=192.168.1.118
s3-minio-2.test.local ansible_host=192.168.1.119
[minio:vars]
virtual_address=192.168.1.120


мы задаём имя хостнейма и айпишник, так же мы указываем виртуальный айпишник для keepalived 


перед тем как запускать установку нужно разметить диск я это делаю на LVM томе

pvcreate /dev/sdb 
vgextend debian-vg /dev/sdb 
lvcreate --name minio -L 10g debian-vg 
mkfs.ext4 /dev/mapper/debian--vg-minio 
mkdir /minio 
mount /dev/debian-vg/minio /minio

добавляем этот раздел в fstab
echo "/dev/mapper/debian--vg-minio /minio               ext4    errors=remount-ro 0       1" >> /etc/fstab

в файле
/etc/ansible/roles/minio/defaults/main.yml

указываем наш раздел
minio_server_datadirs: 
  - /minio

а имена серверов
minio_server_cluster_nodes: 
  - s3-minio-1.test.local 
  - s3-minio-2.test.local
должны совпадать с имена которые заданы в /etc/ansible/hosts  

как всё настроили можно запускать установку:
ansible-playbook -u root /etc/ansible/playbooks/roles_play/s3-minio.yml --ask-pass
