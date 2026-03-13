# ArgoCD Развёртывание

## Предварительные требования

1. Kubernetes кластер
2. Установленный ArgoCD
3. Доступ к репозиторию

## Установка ArgoCD (если не установлен)

```bash
# Создать namespace
kubectl create namespace argocd

# Установить ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Дождаться запуска
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s

# Получить пароль admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Развёртывание приложения

### Вариант 1: Через CLI

```bash
# Создать репозиторий в ArgoCD
argocd repo add https://github.com/derunov/argocd-go-example.git --name argocd-go-example

# Создать приложение
argocd app create argocd-go-example \
  --repo https://github.com/derunov/argocd-go-example.git \
  --path deploy/argocd \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd-go-example \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Синхронизировать
argocd app sync argocd-go-example

# Проверить статус
argocd app get argocd-go-example
```

### Вариант 2: Через манифест

```bash
# Применить Application манифест
kubectl apply -f application.yaml

# Отслеживать статус
kubectl get applications.argoproj.io -n argocd -w
```

### Вариант 3: Через Web UI

1. Откройте ArgoCD UI
2. Нажмите "+ New App"
3. Заполните:
   - **Name**: `argocd-go-example`
   - **Project**: `default`
   - **Sync Policy**: `Automatic`
   - **Repository URL**: `https://github.com/derunov/argocd-go-example.git`
   - **Revision**: `HEAD`
   - **Path**: `deploy/argocd`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `argocd-go-example`
4. Нажмите "Create"
5. Нажмите "Sync"

## Проверка развёртывания

```bash
# Проверить поды
kubectl get pods -n argocd-go-example

# Проверить сервисы
kubectl get svc -n argocd-go-example

# Проверить логи
kubectl logs -n argocd-go-example -l app=argocd-go-example

# Тестировать endpoint
kubectl port-forward svc/argocd-go-example 8080:80 -n argocd-go-example
curl http://localhost:8080/health
```

## Обновление приложения

При изменении кода в репозитории ArgoCD автоматически синхронизирует изменения (благодаря `selfHeal: true`).

Для ручной синхронизации:

```bash
argocd app sync argocd-go-example
```

## Удаление

```bash
# Через CLI
argocd app delete argocd-go-example --cascade

# Или через kubectl
kubectl delete -f application.yaml
```
