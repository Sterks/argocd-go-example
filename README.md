# ArgoCD Go Example

Пример Go-приложения для развёртывания через ArgoCD с использованием Kustomize.

## Структура проекта

```
.
├── cmd/
│   └── main.go          # Точка входа приложения
├── internal/
│   └── handler/
│       └── handler.go   # HTTP обработчики
├── deploy/
│   └── argocd/          # ArgoCD манифесты
│       ├── namespace.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── kustomization.yaml
├── Dockerfile
├── go.mod
└── README.md
```

## API Endpoints

| Endpoint   | Method | Description           |
|------------|--------|-----------------------|
| /health    | GET    | Проверка здоровья     |
| /api/info  | GET    | Информация о приложении |

## Локальный запуск

```bash
# Запуск приложения
go run cmd/main.go

# Проверка endpoints
curl http://localhost:8080/health
curl http://localhost:8080/api/info
```

## Сборка Docker образа

```bash
docker build -t argocd-go-example:latest .
```

## Развёртывание через ArgoCD

1. Создайте Application в ArgoCD:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-go-example
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/derunov/argocd-go-example.git
    targetRevision: HEAD
    path: deploy/argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd-go-example
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

2. Примените Application:

```bash
kubectl apply -f argocd-application.yaml
```

## Лицензия

MIT
