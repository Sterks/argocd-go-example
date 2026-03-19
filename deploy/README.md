# Структура проекта ArgoCD Go Example

## 📁 Дерево директорий

```
deploy/
├── apps/                          # Приложения
│   ├── go-app/                    # Go приложение
│   │   ├── application.yaml       # ArgoCD Application
│   │   ├── kustomization.yaml     # Kustomize конфигурация
│   │   ├── namespace.yaml         # Namespace
│   │   ├── deployment.yaml        # Deployment
│   │   └── service.yaml           # Service
│   │
│   ├── registry/                  # Docker Registry
│   │   ├── application.yaml       # ArgoCD Application
│   │   └── manifests.yaml         # Манифесты Registry
│   │
│   ├── victoriametrics/           # VictoriaMetrics + Grafana
│   │   ├── application.yaml       # ArgoCD Application
│   │   ├── grafana-dashboard.yaml # Grafana дашборд
│   │   ├── kustomization.yaml     # Kustomize конфигурация
│   │   ├── operator.yaml          # VictoriaMetrics Operator
│   │   └── vmcluster.yaml         # VMCluster
│   │
│   └── vault/                     # HashiCorp Vault
│       ├── application.yaml       # ArgoCD Application
│       ├── README.md              # Документация Vault
│       └── values.yaml            # Helm values
│
└── infrastructure/                # Инфраструктурные компоненты
    ├── argocd/                    # ArgoCD конфигурация
    │   ├── application.yaml       # Root Application (self-managed)
    │   ├── kustomization.yaml     # Kustomize конфигурация
    │   └── namespace.yaml         # ArgoCD namespace
    │
    ├── longhorn/                  # Longhorn storage (опционально)
    └── ingress-nginx/             # Ingress Controller (опционально)
```

## ➕ Как добавить новое приложение

### 1. Создайте директорию приложения

```bash
mkdir -p deploy/apps/my-app
```

### 2. Создайте манифесты Kubernetes

```yaml
# deploy/apps/my-app/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: app
          image: my-registry/my-app:latest
          ports:
            - containerPort: 8080
```

```yaml
# deploy/apps/my-app/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: my-app
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: my-app
```

### 3. Создайте kustomization.yaml

```yaml
# deploy/apps/my-app/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: my-app

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml

commonLabels:
  app: my-app
```

### 4. Создайте ArgoCD Application

```yaml
# deploy/apps/my-app/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/Sterks/argocd-go-example.git
    targetRevision: HEAD
    path: deploy/apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 5. Примените Application

```bash
kubectl apply -f deploy/apps/my-app/application.yaml
```

### 6. Проверьте статус

```bash
kubectl get application my-app -n argocd
kubectl get pods -n my-app
```

## 🔧 Команды для управления

### Получить все приложения ArgoCD
```bash
kubectl get applications -n argocd
```

### Синхронизировать приложение
```bash
kubectl patch application my-app -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"prune":true}}}'
```

### Пересоздать поды
```bash
kubectl delete pod -n my-app --all
```

### Посмотреть логи
```bash
kubectl logs -n my-app -l app=my-app
```

## 📊 Текущие приложения

| Приложение | Namespace | Статус |
|------------|-----------|--------|
| go-app | argocd-go-example | ✅ Running |
| registry | registry-system | ✅ Running |
| victoriametrics | victoriametrics | ✅ Running |
| vault | vault | ✅ Running |

## 📝 Примечания

- Все приложения используют **Kustomize** для управления манифестами
- ArgoCD автоматически синхронизирует изменения из Git
- Для каждого приложения создаётся отдельный namespace
- Включены `prune` и `selfHeal` для автоматического управления
