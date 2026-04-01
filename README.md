# ArgoCD Go Example - Infrastructure & Deploy

**Репозиторий для инфраструктуры Kubernetes и конфигураций деплоя**

---

## 📁 Структура репозитория

```
.
├── deploy/
│   ├── applications/          # Приложения для деплоя
│   │   ├── vault/            # HashiCorp Vault
│   │   └── victoriametrics/  # VictoriaMetrics + Grafana
│   │
│   └── infrastructure/        # Инфраструктурные компоненты
│       ├── argocd/           # ArgoCD
│       ├── cert-manager/     # cert-manager + Let's Encrypt
│       ├── gitlab/           # GitLab
│       ├── grafana/          # Grafana (standalone)
│       ├── harbor/           # Harbor Registry
│       ├── longhorn/         # Longhorn Storage
│       ├── pritunl/          # Pritunl VPN
│       └── traefik/          # Traefik Ingress Controller
│
└── scripts/                   # Скрипты для настройки
```

---

## 🚀 Быстрый старт

### 1. Установка Infrastructure

```bash
# Traefik (Ingress Controller)
kubectl apply -f deploy/infrastructure/traefik/application.yaml

# cert-manager (TLS сертификаты)
kubectl apply -f deploy/infrastructure/cert-manager/application.yaml

# ArgoCD (GitOps)
kubectl apply -f deploy/infrastructure/argocd/application.yaml

# Longhorn (Storage)
kubectl apply -f deploy/infrastructure/longhorn/application.yaml

# Harbor (Registry)
kubectl apply -f deploy/infrastructure/harbor/application.yaml

# GitLab
kubectl apply -f deploy/infrastructure/gitlab/application.yaml

# Pritunl (VPN)
kubectl apply -f deploy/infrastructure/pritunl/application.yaml

# Grafana
kubectl apply -f deploy/infrastructure/grafana/application.yaml
```

### 2. Установка Applications

```bash
# Vault
kubectl apply -f deploy/applications/vault/application.yaml

# VictoriaMetrics
kubectl apply -f deploy/applications/victoriametrics/application.yaml
```

---

## 📊 Helm Charts

Все приложения упакованы как Helm charts:

| Приложение | Путь | Тип |
|------------|------|-----|
| **Traefik** | `deploy/infrastructure/traefik/` | external chart |
| **cert-manager** | `deploy/infrastructure/cert-manager/` | local chart |
| **ArgoCD** | `deploy/infrastructure/argocd/` | local chart |
| **Longhorn** | `deploy/infrastructure/longhorn/` | local chart |
| **Harbor** | `deploy/infrastructure/harbor/` | local chart |
| **GitLab** | `deploy/infrastructure/gitlab/` | local chart |
| **Pritunl** | `deploy/infrastructure/pritunl/` | local chart |
| **Grafana** | `deploy/infrastructure/grafana/` | local chart |
| **Vault** | `deploy/applications/vault/` | local chart |
| **VictoriaMetrics** | `deploy/applications/victoriametrics/` | local chart |

---

## 🔧 Структура Helm Chart

Каждый chart имеет стандартную структуру:

```
<chart-name>/
├── Chart.yaml          # Метаданные Helm chart
├── values.yaml         # Конфигурационные значения
├── templates/          # Go templates для манифестов
│   └── *.yaml
└── application.yaml    # ArgoCD Application manifest
```

---

## 🌐 Доступные сервисы

| Сервис | URL | Порт |
|--------|-----|------|
| **ArgoCD** | https://argocd.techbit.su | 443 |
| **Vault** | https://vault.techbit.su | 443 |
| **Grafana** | https://grafana.techbit.su | 443 |
| **Longhorn** | https://longhorn.techbit.su | 443 |
| **Harbor** | https://harbor.techbit.su | 443 |
| **Harbor UI** | https://ui.harbor.techbit.su | 443 |
| **GitLab** | https://gitlab.techbit.su | 443 |

---

## 🔐 NAT Configuration

На роутере должен быть настроен проброс портов:

```
External 80  →  192.168.0.101:31184  (Traefik HTTP)
External 443 →  192.168.0.101:32648  (Traefik HTTPS)
```

---

## 📝 Приложения

### go-app

Go-приложение для примера деплоя вынесено в отдельный репозиторий:
- **Репозиторий:** `https://github.com/Sterks/argocd-go-example-app`
- **Назначение:** Демонстрация CI/CD через ArgoCD

Для деплоя go-приложения:
1. Склонируйте репозиторий с приложением
2. Настройте CI/CD пайплайн для сборки образа
3. Push образа в Harbor Registry
4. ArgoCD автоматически задеплоит новую версию

---

## 📚 Документация

- [Traefik настройка](deploy/infrastructure/traefik/README.md)
- [Vault интеграция](deploy/applications/vault/README.md)
- [Harbor HTTPS](deploy/infrastructure/harbor/README.md)
- [GitLab настройка](deploy/infrastructure/gitlab/README.md)

---

**Last Updated:** 2026-04-01  
**Maintained by:** DevOps Team
