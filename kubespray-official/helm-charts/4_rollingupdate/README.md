RollingUpdate — стандартная стратегия выката Deployment, при которой старые Pod’ы постепенно заменяются новыми, сохраняя доступность сервиса.

Ключевые настройки:

maxSurge — сколько дополнительных Pod’ов (сверх replicas) можно поднять во время обновления. Проценты или число (например, 25% или 1).

maxUnavailable — сколько Pod’ов может быть временно недоступно из желаемого числа во время обновления (например, 0 для минимального даунтайма).

minReadySeconds — сколько секунд Pod должен быть в Ready, прежде чем считается «действительно готовым» для прогресса выката (страхует от «ложной готовности»).

progressDeadlineSeconds — дедлайн на прогресс выката; если не выполняется (например, Pod’ы не становятся Ready), Deployment помечает выкат как застрявший.

revisionHistoryLimit — сколько старых ReplicaSet’ов хранить для отката.



в деплоймент кидаем:
```
spec:
  {{- if .Values.updateStrategy.enabled }}
  strategy:
    type: {{ .Values.updateStrategy.type | default "RollingUpdate" }}
    {{- if ne (.Values.updateStrategy.type | default "RollingUpdate") "Recreate" }}
    rollingUpdate:
      maxSurge: {{ .Values.updateStrategy.rollingUpdate.maxSurge | default "25%" }}
      maxUnavailable: {{ .Values.updateStrategy.rollingUpdate.maxUnavailable | default 0 }}
    {{- end }}
  minReadySeconds: {{ .Values.updateStrategy.minReadySeconds | default 0 }}
  revisionHistoryLimit: {{ .Values.updateStrategy.revisionHistoryLimit | default 10 }}
  progressDeadlineSeconds: {{ .Values.updateStrategy.progressDeadlineSeconds | default 600 }}
  {{- end }}
```

в вельюс докидыыаем
```
updateStrategy:
  enabled: true
  type: RollingUpdate           # или Recreate
  rollingUpdate:
    maxSurge: 25%               # число или проценты; напр. 1 или "25%"
    maxUnavailable: 0           # число или проценты; 0 = без даунтайма по репликам
  minReadySeconds: 10           # сколько pod должен быть Ready перед следующим шагом
  revisionHistoryLimit: 10      # сколько старых ReplicaSet хранить
  progressDeadlineSeconds: 600  # дедлайн на прогресс выката
```

root@kub-master1:~/helm-charts/4_rollingupdate# helm upgrade --install app -n app ./common-chart -f ./common-chart/values.yaml