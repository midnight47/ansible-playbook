ставим
helm upgrade --install app -n app ./common-chart -f ./common-chart/values.yaml




1) Политика «default-deny ingress» для всех Pod’ов релиза

(входящий трафик запрещён, исходящий — без ограничений)

networkPolicy:
  enabled: true
  items:
    - name: default-deny-ingress
      policyTypes: ["Ingress"]
      ingress: []                 # ничего не разрешаем

Ожидание: любой внешний pod не дойдёт до app.

# из dev → ДОЛЖНО провалиться (timeout)
kubectl -n dev run tmp --rm -it --image=curlimages/curl -- \
  sh -c 'curl -sS -m 3 -o /dev/null -w "%{http_code}\n" http://app.app.svc.cluster.local || echo FAILED'

# TCP-connect тоже должен падать
kubectl -n dev run tmp --rm -it --image=curlimages/curl -- \
  sh -c 'nc -vz -w 3 app.app.svc.cluster.local 80 || echo "connect failed"'

# из app → тоже 403/timeout (если нет allow внутри ns)
kubectl -n app run tmp --rm -it --image=curlimages/curl -- \
  sh -c 'curl -sS -m 3 http://app.app.svc.cluster.local || echo FAILED'


#########################################

2) Разрешить вход только через Ingress-контроллер на HTTP 80

Ожидание:

из ingress-nginx → проходит
из других ns → блок


networkPolicy:
  enabled: true
  items:
    - name: allow-from-ingress
      policyTypes: ["Ingress"]
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: ingress-nginx   # ns контроллера
              podSelector:
                matchLabels:
                  app.kubernetes.io/name: ingress-nginx
          ports:
            - protocol: TCP
              port: 80        # можно использовать "http" если порт назван в контейнере


# из ingress-namespace → OK (должен вернуть 200/…)
kubectl -n ingress-nginx run tmp --rm -it --image=curlimages/curl -- \
  sh -c 'curl -sS -m 3 -o /dev/null -w "%{http_code}\n" http://app.app.svc.cluster.local'

# из dev → ДОЛЖЕН упасть
kubectl -n dev run tmp --rm -it --image=curlimages/curl -- \
  sh -c 'curl -sS -m 3 -o /dev/null -w "%{http_code}\n" http://app.app.svc.cluster.local || echo DENIED'

##########################################


3) Базовый «default-deny all» + доступ с Ingress + доступ VictoriaMetrics (scrape)
networkPolicy:
  enabled: true
  items:
    # 1) Полный запрет всего (по умолчанию ничего не ходит)
    - name: default-deny-all
      policyTypes: ["Ingress","Egress"]
      ingress: []
      egress:  []

    # 2) Разрешить веб-трафик к приложению только с ingress-nginx (порт 80)
    - name: allow-from-ingress
      policyTypes: ["Ingress"]
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: ingress-nginx
          ports:
            - { protocol: TCP, port: 80 }

    # 3) Разрешить scrape со стороны VictoriaMetrics (порт метрик приложения, напр. 9113)
    #   Вариант через namespaceSelector (проще и надёжнее)
    - name: allow-vm-scrape
      policyTypes: ["Ingress"]
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: monitoring
          ports:
            - { protocol: TCP, port: 9113 }   # замени на свой порт метрик / имя "metrics"

kubectl run -n monitoring test-mon --rm -it --image=curlimages/curl -- s
~ $ curl -sS -m 3 -I  http://app.app.svc.cluster.local
~ $ curl -sS -m 5 http://app.app.svc.cluster.local:9113/metrics | head -n 5 


#############################

4) Разрешить vmagent скрейпить метрики твоего приложения

networkPolicy:
  enabled: true
  items:
    - name: allow-from-ingress
      policyTypes: ["Ingress"]
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: ingress-nginx
          ports:
            - { protocol: TCP, port: 80 }

    # разрешаем scrape из namespace monitoring на порт(ы) метрик приложения
    - name: allow-vmagent-scrape
      policyTypes: ["Ingress"]
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: monitoring
          ports:
            - { protocol: TCP, port: 9113 }   # <— замени на порт(ы) твоего экспортера
            - { protocol: TCP, port: 9153 } # можно добавить ещё порты, если нужно
            - { protocol: TCP, port: 80 } # можно добавить ещё порты, если нужно

root@kub-master3:~# kubectl run -n monitoring test-mon --rm -it --image=curlimages/curl -- sh
~ $ curl -sS -m 3 -I  http://app.app.svc.cluster.local
HTTP/1.1 200 OK