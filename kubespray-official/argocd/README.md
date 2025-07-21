kubectl create ns argocd
helm repo add argo-cd https://argoproj.github.io/argo-helm

helm upgrade --install argo-cd argo-cd/argo-cd -n argocd --values values.yaml --version 8.1.3

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d



=====================================
# 1) Генерим пароль
kubectl exec -ti -n argocd argo-cd-argocd-server-84c56df477-h6mnl -- bash
argocd account bcrypt --password '4CL8do3zkZzPHfuk22'

получаем:
$2a$10$R1OkCf90A7Kg/aMA.DD3DOv9y12FPLP6eh0ViukCt/NIf.c/Q/oDy


# 2) полученный hash присваиваем переменной
RAW_HASH='$2a$10$R1OkCf90A7Kg/aMA.DD3DOv9y12FPLP6eh0ViukCt/NIf.c/Q/oDy'

# 3) Кодируем его в base64 (это и будет ваше accounts.test.password)
HASH_B64=$(echo -n "$RAW_HASH" | base64 -w0)

# 4) Задаём правильный RFC3339-штамп:
RAW_MTIME='2025-07-14T12:48:50Z'

# 5) Кодируем штамп в base64 (это будет ваше accounts.test.passwordMtime)
MTIME_B64=$(echo -n "$RAW_MTIME" | base64 -w0)

# 6) Добавляем пароль для пользователя test
```
kubectl patch secret argocd-secret -n argocd --type=json -p="[
  {
    \"op\":\"add\",
    \"path\":\"/data/accounts.test.password\",
    \"value\":\"$HASH_B64\"
  },
  {
    \"op\":\"add\",
    \"path\":\"/data/accounts.test.passwordMtime\",
    \"value\":\"$MTIME_B64\"
  }
]"
```

# 7) Добавляем самого пользователя test в конфигмап
```
kubectl patch configmap argocd-cm -n argocd --type=merge -p '{
  "data": {
    "accounts.test":"login",
    "accounts.test.enabled":"true"
  }
}'
```

# 8) Выдать доступы, например пользователь test будет админом а пользователь alice будет иметь доступы readonly

```
kubectl patch configmap argocd-rbac-cm -n argocd --type=merge -p '{
  "data": {
    "policy.csv": "p, role:readonly, applications, get, *, allow\ng, alice, role:readonly\np, role:admin, *, *, *, allow\ng, test, role:admin\n"
  }
}'
```

проверяем:
```
root@kub-master1:~/argocd# kubectl -n argocd get configmap argocd-rbac-cm -o yaml
apiVersion: v1
data:
  policy.csv: |
    p, role:readonly, applications, get, *, allow
    g, alice, role:readonly
    p, role:admin, *, *, *, allow
    g, test, role:admin
  policy.default: ""
  policy.matchMode: glob
  scopes: '[groups]'
```

# 9) Рестартуем и можем проверять аутентификацию 
kubectl rollout restart  -n argocd deployment argo-cd-argocd-server 



============================

для ldap есть отдельный файл  values-ldap.yaml



примерно вот так выглядит конфиг файл для application
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  name: app1
  namespace: argocd
spec:
  destination:
    namespace: test
    server: https://kubernetes.default.svc
  project: project-dev
  source:
    path: .
    repoURL: https://gitlab.test.local/argo/test-app/app1.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

