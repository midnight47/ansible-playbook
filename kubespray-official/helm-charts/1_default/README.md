helm create common-chart

kubectl create ns app

root@kub-master1:~/helm-charts/1_default# helm upgrade --install app -n app ./common-chart/ --values ./common-chart/values.yaml 

root@kub-master1:~/helm-charts/1_default# kubectl  get pod -n app
NAME                                READY   STATUS    RESTARTS   AGE
app-common-chart-749cf6bc54-h5jnn   1/1     Running   0          8s

root@kub-master1:~/helm-charts/1_default# helm list -n app
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
app     app             1               2025-08-07 12:55:32.737050736 +0600 +06 deployed        common-chart-0.1.0      1.16.0     


Чтобы убрать из имени пода суффикс common-chart, нужно переопределить шаблон полного имени ресурса в Helm. В стандартном чарте common-chart это делается через значение fullnameOverride.

Добавьте в ваш values.yaml строку:


fullnameOverride: app
Это заставит Helm генерировать имя Deployment (и, соответственно, подов) ровно как <Release.Name>, без добавления имени чарта.

root@kub-master1:~/helm-charts/1_default# helm upgrade --install app -n app ./common-chart/ --values ./common-chart/values.yaml 

root@kub-master1:~/helm-charts/1_default# kubectl  get pod -n app
NAME                   READY   STATUS    RESTARTS   AGE
app-5d588f6bc8-qvwqz   1/1     Running   0          4s

