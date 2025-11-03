нагрузить апку по процу:
kubectl -n app exec -it deploy/app -- sh -c 'yes > /dev/null'


нагрузить по оперативке да и процу каждый под через эфимерные контейнеры:
for p in $(kubectl -n app get po -l app.kubernetes.io/instance=app,app.kubernetes.io/name=common-chart -o name); do
  kubectl -n app debug "$p" \
    --target=common-chart \
    --image=polinux/stress \
    -- /bin/sh -lc 'stress --vm 1 --vm-bytes 100M --vm-keep --timeout 600s'
done





behavior.scaleUp — как быстро можно РАСТИ.

stabilizationWindowSeconds: 0
Нет окна стабилизации на апскейл: как только метрика выше цели — масштабируемся сразу (дефолт именно так). 


policies — «ограничители скорости» роста за скользящее окно periodSeconds.
В примере заданы два лимита одновременно:

type: Percent, value: 100, periodSeconds: 60 → не более +100% от текущего числа реплик за 60с;

type: Pods, value: 4, periodSeconds: 60 → не более +4 пода за 60с.

selectPolicy: Max
Если задано несколько политик, берётся та, которая разрешает самое большое изменение (для scaleUp — которая добавит больше подов). 


behavior.scaleDown — как быстро можно УМЕНЬШАТЬ.

stabilizationWindowSeconds: 30
При даунскейле HPA запоминает прошлые «желательные» размеры и берёт наибольший из них в окне 30с — это сглаживает «дёрганье». (По умолчанию окно даунскейла 300с, у меня ускорено до 30с.) 

policies: [{type: Percent, value: 10, periodSeconds: 60}]
Можно уменьшать не больше чем на 10% текущих реплик за 60с.

selectPolicy: Max
При нескольких политиках выбрали бы самую «быструю» (удаляет больше подов). Чтобы ограничивать жёстче — ставь Min