helm create test-app-keda
kubectl create ns app1
cd ~/keda/example
helm upgrade --install -n app1 app1 ./test-app-keda/
```
root@kub-master1:~/keda/example# kubectl get pod -n app1 
NAME                                  READY   STATUS    RESTARTS   AGE
app1-test-app-keda-65cbf4f4c7-c5zcx   1/1     Running   0          14s
```

```
root@kub-master1:~/keda/example# kubectl get ingress -n app1 
NAME                 CLASS   HOSTS             ADDRESS         PORTS   AGE
app1-test-app-keda   nginx   test.test.local   192.168.1.191   80      69s
```

применяем файл /etc/ansible/kubespray-official/keda/example/scale-object.yaml
он будет смотреть в викторию и в случае если за 2 минуты будет больше 100 запросов он будет скейлить апку вверх

для проверки запускаем 
root@kub-master1:~/keda/example# for i in {1..1000}; do curl -Ik test.test.local ; sleep 1; done

результат такой:
```
root@kub-master1:~# kubectl get hpa -n app1 -w
NAME                           REFERENCE                       TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-v2-ingress-requests   Deployment/app1-test-app-keda   0/100 (avg)   1         5         1          13m
keda-hpa-v2-ingress-requests   Deployment/app1-test-app-keda   797/100 (avg)   1         5         1          14m
keda-hpa-v2-ingress-requests   Deployment/app1-test-app-keda   590500m/100 (avg)   1         5         4          15m


root@kub-master1:~# kubectl get pod -n app1 
NAME                                  READY   STATUS    RESTARTS   AGE
app1-test-app-keda-685c6c455c-mw2nf   1/1     Running   0          38s
app1-test-app-keda-685c6c455c-mzn27   1/1     Running   0          38s
app1-test-app-keda-685c6c455c-rgf2h   1/1     Running   0          23s
app1-test-app-keda-685c6c455c-wqhcg   1/1     Running   0          39m
app1-test-app-keda-685c6c455c-wrt7s   1/1     Running   0          38s
```
сам запрос к victoriametrics может быть любой
