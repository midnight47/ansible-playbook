1. если запускаем backup etcd и сохраняем на локальных мастерах то нужно на всех создать директорию:
/var/backups/etcd

 for node in $(kubectl get nodes -o wide | grep -i master | awk '{print $6}' ); do ssh root@$node mkdir -p /var/backups/etcd; done

скрипт будет запускать каждый день в 2 часа ночи, бэкап будет сохраняться на той тачке где запустился job

kubectl apply -f etcd-backup/backup-to-host/backup.yaml


```
root@kub-master1:/var/backups/etcd# ls -lah
total 56M
drwxr-xr-x  2 root root 4.0K Jun 29 16:25 .
drwxr-xr-x 12 root root 4.0K Jun 29 16:16 ..
-rw-------  1 root root  56M Jun 29 16:25 etcd-20250629T102518.db
root@kub-master1:/var/backups/etcd# 
root@kub-master1:/var/backups/etcd# 
root@kub-master1:/var/backups/etcd# kubectl logs job/etcd-backup-now1 -n kube-system
{"level":"info","ts":1751192718.184084,"caller":"snapshot/v3_snapshot.go:68","msg":"created temporary db file","path":"/backup/etcd-20250629T102518.db.part"}
{"level":"info","ts":1751192718.1902862,"logger":"client","caller":"v3/maintenance.go:211","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":1751192718.1904283,"caller":"snapshot/v3_snapshot.go:76","msg":"fetching snapshot","endpoint":"https://127.0.0.1:2379"}
{"level":"info","ts":1751192718.6031828,"logger":"client","caller":"v3/maintenance.go:219","msg":"completed snapshot read; closing"}
{"level":"info","ts":1751192718.6250348,"caller":"snapshot/v3_snapshot.go:91","msg":"fetched snapshot","endpoint":"https://127.0.0.1:2379","size":"58 MB","took":"now"}
{"level":"info","ts":1751192718.6251087,"caller":"snapshot/v3_snapshot.go:100","msg":"saved","path":"/backup/etcd-20250629T102518.db"}
Snapshot saved at /backup/etcd-20250629T102518.db
```

2. если хотим сохранять в s3 бакет то сначала создаём бакет в s3 minio создаём пользователя, 
policy:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::etcd-snapshots",
                "arn:aws:s3:::etcd-snapshots/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::etcd-snapshots",
                "arn:aws:s3:::etcd-snapshots/*"
            ]
        }
    ]
}
```


создаём секрет
kubectl create secret generic s3-credentials \
  --from-literal=access-key=ВАШ_ACCESS_KEY \
  --from-literal=secret-key=ВАШ_SECRET_KEY \
  -n kube-system

в скрипте правим endpoint-url на наш http://192.168.1.120:9000
а так же bucket указав наш созданный etcd-snapshots

после можно аплаить

kubectl apply -f etcd-backup/backup-to-s3-minio/backup.yaml

