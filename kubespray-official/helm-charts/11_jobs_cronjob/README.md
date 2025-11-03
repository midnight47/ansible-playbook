Имя ресурса строится как {{ include "common-chart.fullname" . }}-<name> (короткое имя из values).
Можно переиспользовать глобальные nodeSelector/tolerations/affinity/resources/podSecurityContext/imagePullSecrets — или переопределять внутри конкретной задачи.
Для CronJob поля schedule и job.image.repository — обязательны; для Job — name и image.repository.
В restartPolicy для Job/CronJob обычно OnFailure или Never.



ставим
helm upgrade --install app -n app ./common-chart -f ./common-chart/values.yaml

