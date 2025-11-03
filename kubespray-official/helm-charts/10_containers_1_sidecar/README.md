нужно добавить в темплейт деплоймента
```
        {{- /* ===== САЙДКАРЫ: несколько контейнеров через range ===== */}}
        {{- with .Values.sidecars }}
        {{- range $i, $sc := . }}
        - name: {{ default (printf "%s-sidecar-%d" $.Chart.Name $i) $sc.name }}
          {{- with $sc.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $sc.image }}
          image: "{{ .repository }}{{- if .tag }}:{{ .tag }}{{- end }}"
          {{- if .pullPolicy }}
          imagePullPolicy: {{ .pullPolicy }}
          {{- end }}
          {{- end }}

          {{- with $sc.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $sc.workingDir }}
          workingDir: {{ . | quote }}
          {{- end }}

          {{- with $sc.ports }}
          ports:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $sc.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.startupProbe }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $sc.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.lifecycle }}
          lifecycle:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $sc.terminationMessagePath }}
          terminationMessagePath: {{ . | quote }}
          {{- end }}
          {{- with $sc.terminationMessagePolicy }}
          terminationMessagePolicy: {{ . | quote }}
          {{- end }}

          {{- with $sc.extraContainerSpec }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        {{- end }}
        {{- end }}
        {{- /* ===== /САЙДКАРЫ ===== */}}
```


helm upgrade --install app -n app ./common-chart -f ./common-chart/values.yaml

