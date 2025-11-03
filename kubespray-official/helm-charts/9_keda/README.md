Пояснения к ключам в values

scaleTargetRef.* — на что скейлим (обычно Deployment).

pollingInterval — как часто KEDA тянет метрику. Меньше → быстрее реакция, но выше нагрузка на источник.

cooldownPeriod — «тормоз» после падения метрики: столько секунд держит увеличенные реплики перед даунскейлом.

minReplicaCount/maxReplicaCount — нижняя/верхняя граница для создаваемого HPA.

restoreToOriginalReplicaCount — если true, когда триггеры «молчат», KEDA вернёт реплики к тому числу, которое было до включения KEDA.

fallback — если метрика не читается failureThreshold циклов подряд, KEDA выставит фиксированное число replicas.

advanced.horizontalPodAutoscalerConfig.behavior — 1:1 как в HPA autoscaling/v2: окна стабилизации и лимиты скорости роста/сжатия.

advanced.scalingStrategy.multipleScalersCalculation — что делать, если триггеров несколько (берём максимум/минимум/среднее желаемых реплик).

triggers[] — сами скейлеры. Для Prometheus/VictoriaMetrics главные поля: serverAddress, query или metricName+доп.параметры, threshold. Часто полезны activationThreshold, unsafeSsl.

authenticationRef — если Prometheus защищён (базовая auth, токен, TLS и т.п.), тут указываете ссылку на TriggerAuthentication/ClusterTriggerAuthentication (можно добавить отдельный шаблон при необходимости).



нагрузить апку по процу:
kubectl -n app exec -it deploy/app -- sh -c 'yes > /dev/null'

нагрузить апку запросами
for i in {1..5500}; do curl -Ik https://test-app.test.local; done


==============================================
чтобы работали 2 триггера используем values:
/etc/ansible/kubespray-official/helm-charts/9_keda/common-chart/values_2_keda_trigger.yaml
ставим
root@kub-master1:~/helm-charts/9_keda# helm upgrade --install app -n app ./common-chart -f ./common-chart/values_2_keda_trigger.yaml 


запускаем нагрузку по cpu
kubectl -n app exec -it deploy/app -- sh -c 'yes > /dev/null'

и проверяем:
root@kub-master1:~# kubectl get horizontalpodautoscalers.autoscaling -n app -w
NAME           REFERENCE        TARGETS                    MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-app   Deployment/app   0/100 (avg), cpu: 1%/60%   1         5         1          6d20h
keda-hpa-app   Deployment/app   0/100 (avg), cpu: 49%/60%   1         5         1          6d20h
keda-hpa-app   Deployment/app   0/100 (avg), cpu: 101%/60%   1         5         1          6d20h
keda-hpa-app   Deployment/app   0/100 (avg), cpu: 101%/60%   1         5         2          6d20h
keda-hpa-app   Deployment/app   0/100 (avg), cpu: 50%/60%    1         5         2          6d20h

как видим всё ок скейлится.


=====================================================
чтобы эти 2 тригера срабатывали по логике И используй этот values:
/etc/ansible/kubespray-official/helm-charts/9_keda/common-chart/values_2_keda_trigger_logic_AND.yaml

чтобы работала логика ИЛИ можешь закоментить в нём часть относящуюся к scalingModifiers
    scalingModifiers:
      formula: "req >= 100 && cpu >= 60 ? max(req/100, cpu/60) : 0"
      target: "1"              # масштабируемся, когда формула >= 1
      activationTarget: "0"    # при 0 не активируемся
      metricType: "AverageValue"

