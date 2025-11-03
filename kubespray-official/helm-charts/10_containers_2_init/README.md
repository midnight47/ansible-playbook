Вставь этот блок перед секцией containers: внутри spec.template.spec (на одном уровне с imagePullSecrets, serviceAccountName, securityContext)
```
{{- with .Values.initContainers }}
      initContainers:
        {{- range $i, $ic := . }}
        - name: {{ default (printf "%s-init-%d" $.Chart.Name $i) $ic.name }}
          {{- with $ic.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $ic.image }}
          image: "{{ .repository }}{{- if .tag }}:{{ .tag }}{{- end }}"
          {{- if .pullPolicy }}
          imagePullPolicy: {{ .pullPolicy }}
          {{- end }}
          {{- end }}

          {{- with $ic.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $ic.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $ic.workingDir }}
          workingDir: {{ . | quote }}
          {{- end }}

          {{- with $ic.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $ic.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $ic.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $ic.volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $ic.extraContainerSpec }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        {{- end }}
{{- end }}

```


в values
# Общий том (если нужно готовить файлы/права в init)
volumes:
  - name: app-code
    emptyDir: {}

# Смонтировать общий том в основной контейнер (опционально)
volumeMounts:
  - name: app-code
    mountPath: /var/www/html

# Набор init-контейнеров
initContainers:





ставим
helm upgrade --install app -n app ./common-chart -f ./common-chart/values.yaml

