Topology Spread Constraints (TSC) — это механизм Kubernetes, который заставляет планировщик равномерно распределять Pod’ы по доменам отказа (узлам, зонам, регионам и т.п.), чтобы повысить доступность и избежать «скученности».

Что настраивается:

topologyKey — по какому домену равномерно раскладывать (например, topology.kubernetes.io/zone или kubernetes.io/hostname).

maxSkew — допустимая «косина», т.е. разница в количестве Pod’ов между самыми заполненным и самым пустым доменами.

whenUnsatisfiable — что делать, если условие нельзя соблюсти:

DoNotSchedule — лучше не запускать Pod, чем нарушить правило (жёстко).

ScheduleAnyway — запустить, даже если распределение получится неровным (мягко).

labelSelector — какие Pod’ы считать «своими» для подсчёта баланса.

Дополнительно: minDomains (требуемый минимум доступных доменов), nodeAffinityPolicy, nodeTaintsPolicy.


правим деплоймент 
```
      {{- if and .Values.topologySpread.enabled .Values.topologySpread.constraints }}
      topologySpreadConstraints:
      {{- range .Values.topologySpread.constraints }}
        - maxSkew: {{ .maxSkew | default 1 }}
          topologyKey: {{ .topologyKey | quote }}
          whenUnsatisfiable: {{ .whenUnsatisfiable | default "DoNotSchedule" | quote }}
          {{- if hasKey . "minDomains" }}
          minDomains: {{ .minDomains }}
          {{- end }}
          labelSelector:
            matchLabels:
              {{- include "common-chart.selectorLabels" $ | nindent 14 }}
      {{- end }}
      {{- end }}
```

в values докидываем
topologySpread:
  enabled: true
  constraints:
    - topologyKey: "kubernetes.io/hostname"  # по серверам
      maxSkew: 1
      whenUnsatisfiable: "ScheduleAnyway" # или "DoNotSchedule"


ставим
root@kub-master1:~/helm-charts/3_topolgy_spread_constraints# helm upgrade --install app -n app ./common-chart -f ./common-chart/values.yaml
