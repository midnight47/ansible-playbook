описание темплейта  configmaps-from-files.yaml
---
{{- if and .Values.configmaps .Values.configmaps.enabled }}
{{- $items := default (list) .Values.configmaps.items }}
if and … — создаём ресурсы только если есть секция configmaps и флаг enabled: true.

$items := default (list) … — локальная переменная со списком элементов. Если список не задан, подставится пустой (list) — цикл ниже просто ничего не сделает.
---

---
Цикл по элементам
{{- range $i, $cm := $items }}

Идём по каждому объекту-описанию конфигмапа из values:
$i — индекс (0,1,2,…), удобен для сообщений об ошибке.
$cm — сам элемент (map с полями name, file, key, binary, labels, annotations).
---

---
Обязательные поля и fail-fast
{{- $rawName := required (printf "configmaps.items[%d].name is required" $i) $cm.name }}
{{- $file := required (printf "configmaps.items[%d].file is required" $i) $cm.file }}
{{- if not ($.Files.Get $file) }}
  {{- fail (printf "File '%s' not found in chart for configmaps.items[%d]" $file $i) }}
{{- end }}


required(msg, value) — если value пустое/не задано, рендер оборвётся с msg. Так валидируем, что у каждого элемента есть name и file.
$.Files.Get $file — читаем файл из директории чарта (ключевой момент: путь относителен корня чарта).

Используем корневой контекст $, потому что внутри range . уже указывает на $cm, а не на чарт.
if not (…) fail(…) — если файла нет в чарте то фейлится
---


---
Необязательные поля и нормализация имени
{{- $key := default (base $file) $cm.key }}
{{- $isBin := default false $cm.binary }}
{{- /* Нормализация имени под DNS-1123 */ -}}
{{- $name := $rawName | replace "_" "-" | replace "." "-" | lower | trunc 63 | trimSuffix "-" }}


$key — имя ключа в data/binaryData. По умолчанию — basename(file) (например, из files/conf/app.yaml получится app.yaml).
$isBin — флаг «использовать binaryData» (для бинарных/не-UTF8 файлов).

$name — итоговое имя ресурса:
заменяем _ и . на -, приводим к нижнему регистру,

trunc 63 — ограничиваем длину до 63 символов (требование DNS-1123),
trimSuffix "-" — убираем - в конце, если после обрезки он остался.
---



---
Метаданные ресурса

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $name | quote }}
  namespace: {{ $.Release.Namespace }}
  labels:
    app.kubernetes.io/managed-by: "Helm"
    app.kubernetes.io/part-of: {{ $.Chart.Name | quote }}
    helm.sh/chart: "{{ $.Chart.Name }}-{{ $.Chart.Version }}"
    {{- with $cm.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $cm.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}


name — берём нормализованное имя.
namespace — неймспейс релиза (из helm install … -n), через корень $.Release.Namespace.
Базовые лейблы — полезные метки для отладки/поиска.
with $cm.labels / with $cm.annotations — вставляем блоки только если они есть в values.
toYaml . | nindent 4 — красивое форматирование под 4 пробела.
---


---
Содержимое ConfigMap

{{- if not $isBin }}
data:
  {{ $key }}: |-
{{ $.Files.Get $file | indent 4 }}
{{- else }}
binaryData:
  {{ $key }}: {{ $.Files.GetBytes $file | toString | b64enc }}
{{- end }}

Ветвление по типу:
Текстовый ($isBin == false): кладём в data многострочной строкой (|- сохраняет переносы, indent 4 — отступ).
Бинарный ($isBin == true): кладём в binaryData как base64.
$.Files.GetBytes → toString (Go-tmpl хочет строку) → b64enc.
для бинарей лучше реально использовать binaryData, иначе Kubernetes может ругаться на невалидный UTF-8 в data.
---


---
Разделитель документов и закрывающие теги
---
{{- end }}
{{- end }}
--- — YAML-разделитель между несколькими ресурсами (каждый элемент списка создаёт свой документ).
Два end — закрывают range и внешний if.
---


ставим
helm upgrade --install app -n app ./common-chart -f ./common-chart/values.yaml

