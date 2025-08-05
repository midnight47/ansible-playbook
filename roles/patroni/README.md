Протестировано на серверах debian 

схема такая нужны 3 ноды для etcd базы будет 2, они будут располагаться на тех же нодах что и etcd, на них же будет haproxy который будет отправлять весь трафик на мастер ноду, реплика не будет получать трафик. так же для удобства настроен keepalived с виртуальным ip на который мы будем обращаться.




ss -ntpl

проверить что etcd кластер запущен
etcdctl member list

проверить что патрони запущен:
patronictl -c /etc/patroni.yml list
ответ должен быть такой:
```
root@debian:~# patronictl -c /etc/patroni.yml list
+ Cluster: my_patroni_cluster (7534615147125032841) +----+-----------+
| Member | Host               | Role    | State     | TL | Lag in MB |
+--------+--------------------+---------+-----------+----+-----------+
| db1    | 192.168.1.152:5430 | Leader  | running   |  9 |           |
| db2    | 192.168.1.153:5430 | Replica | streaming |  9 |         0 |
+--------+--------------------+---------+-----------+----+-----------+
```

если нужно сменить лидера:
patronictl -c /etc/patroni.yml switchover \
    --leader    db2 \
    --candidate db1 \
    --force


проверить подключение:
psql -h 192.168.1.155 -p 5432 -U postgres -c "SELECT pg_is_in_recovery();"
(ip виртуальный а пароль тот который задан в superuser_password)

посмотреть логи:
journalctl -u patroni.service -b --no-pager | tail -n50


