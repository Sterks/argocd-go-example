# Настройка Traefik Helm Chart - Итоговый отчёт

**Дата:** 2026-04-01  
**Статус:** ✅ Завершено успешно

---

## 📋 Резюме

Настроена установка Traefik v3.2.4 через Helm chart согласно [официальной документации](https://doc.traefik.io/traefik/).

### Изменения

| Компонент | Было | Стало |
|-----------|------|-------|
| **Версия Traefik** | v2.10 (Deployment) | v3.2.4 (Helm ready) |
| **Установка** | YAML манифесты | Helm chart 39.0.7 |
| **EntryPoints** | 80/443 | 8000/8443 (internal), 80/443 (NodePort) |
| **HTTP→HTTPS Redirect** | ❌ | ✅ |
| **Access Log** | ✅ JSON | ✅ JSON |
| **Metrics** | ❌ | ✅ Prometheus |
| **Security Context** | ❌ | ✅ Hardened |
| **RBAC** | Базовый | ✅ Полный (v3 compatible) |
| **Dashboard** | Insecure | ✅ BasicAuth + HTTPS |

---

## 🚀 Установка через Helm

### 1. Подготовка

```bash
# Добавить Helm репозиторий
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Создать namespace
kubectl create namespace traefik-system
```

### 2. Установка

```bash
helm install traefik traefik/traefik \
  --namespace traefik-system \
  --create-namespace \
  --values deploy/infrastructure/traefik/values.yaml \
  --version 39.0.7
```

### 3. Применить дополнительные ресурсы

```bash
# Dashboard с BasicAuth
kubectl apply -f deploy/infrastructure/traefik/traefik-dashboard.yaml

# RBAC (если не через Helm)
kubectl apply -f deploy/infrastructure/traefik/traefik-rbac.yaml
```

---

## ⚙️ Конфигурация

### Порты

| Имя | Container | Service | NodePort | Описание |
|-----|-----------|---------|----------|----------|
| `web` | 8000 | 80 | 31184 | HTTP → HTTPS redirect |
| `websecure` | 8443 | 443 | 32648 | HTTPS (TLS termination) |
| `traefik` | 8080 | 8080 | - | Admin API (internal) |
| `metrics` | 9100 | - | - | Prometheus metrics |

### Providers

| Provider | Статус | Описание |
|----------|--------|----------|
| **Kubernetes Ingress** | ✅ | Стандартные Ingress ресурсы |
| **Kubernetes CRD** | ✅ | IngressRoute, Middleware, TLSOption, TraefikService |
| **Kubernetes Gateway** | ❌ | Gateway API (experimental) |

### Логирование

```yaml
logs:
  access:
    enabled: true
    format: json
    filters:
      statuscodes: ["100-599"]
```

### Метрики

```yaml
metrics:
  prometheus:
    enabled: true
    addEntryPointsLabels: true
    addRoutersLabels: true
    addServicesLabels: true
```

---

## 🔐 Безопасность

### Security Context

```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]

podSecurityContext:
  runAsGroup: 65532
  runAsNonRoot: true
  runAsUser: 65532
  seccompProfile:
    type: RuntimeDefault
```

### RBAC

Добавлены права для Traefik v3:
- ✅ `endpointslices` (discovery.k8s.io)
- ✅ `nodes` (для topology)
- ✅ Gateway API (на будущее)

### Dashboard

Защищён BasicAuth:
- **URL:** `https://traefik.techbit.su`
- **Логин:** `admin`
- **Пароль:** `admin` (измените в `traefik-dashboard.yaml`)

---

## 📊 Мониторинг

### Prometheus Metrics

```bash
# Через port-forward
kubectl port-forward -n traefik-system svc/traefik-prometheus 9100:9100
curl http://localhost:9100/metrics

# Или через ServiceMonitor (если Prometheus Operator)
# В values.yaml: metrics.prometheus.serviceMonitor.enabled: true
```

### Access Logs

```bash
# Live мониторинг
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik -f \
  | jq 'select(.RequestHost != null)'

# Статистика по хостам
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=1000 \
  | jq -r '.RequestHost' | sort | uniq -c | sort -rn

# Запросы к Vault
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=100 \
  | grep '"RequestHost":"vault.techbit.su"' \
  | jq -r '"\(.time) | \(.ClientAddr) | \(.RequestMethod) \(.RequestPath) | \(.DownstreamStatus)"'
```

---

## 🧪 Проверка

### Тестирование HTTPS

```bash
# Vault
curl -k -H "Host: vault.techbit.su" https://192.168.0.101:32648/ui/ -I

# HTTP → HTTPS Redirect
curl -I -H "Host: vault.techbit.su" http://192.168.0.101:31184/
# Ожидается: 308 Permanent Redirect → https://...
```

### Проверка маршрутов

```bash
# Dashboard API
kubectl port-forward -n traefik-system svc/traefik 8080:8080
curl http://localhost:8080/api/http/routers
curl http://localhost:8080/api/entrypoints
```

---

## 📁 Файлы

```
deploy/infrastructure/traefik/
├── values.yaml                    # Helm chart значения ✅
├── README.md                      # Документация ✅
└── HELM_SETUP.md                  # Итоговый отчёт ✅

deploy/infrastructure/traefik-ingress/
├── vault-ingress.yaml             # Vault IngressRoute ✅
├── grafana-ingress.yaml           # Grafana Ingress ✅
└── longhorn-ingress.yaml          # Longhorn Ingress ✅
```

---

## 🔄 Миграция

### Удаление legacy ресурсов

```bash
# Удалить старые Deployment/Service
kubectl delete -f deploy/infrastructure/traefik/traefik-deployment.yaml
kubectl delete -f deploy/infrastructure/traefik/traefik-service.yaml
# Не удалять RBAC - он используется Helm!
```

### Откат

```bash
# Если что-то пошло не так
helm rollback traefik -n traefik-system

# Или удалить и вернуть legacy
helm uninstall traefik -n traefik-system
kubectl apply -f deploy/infrastructure/traefik/legacy/
```

---

## ⚠️ Известные проблемы

### 1. IngressRoute и entryPoints

IngressRoute должны использовать имена entryPoints, определённые в конфигурации:
- `web` (HTTP)
- `websecure` (HTTPS)

**Пример:**
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
spec:
  entryPoints:
    - websecure  # ✅ Правильно
  routes:
    - match: Host(`app.example.com`)
      ...
```

### 2. NodePort в Helm

Helm chart автоматически назначает NodePort. Для фиксации используйте:
```yaml
ports:
  web:
    nodePort: 31184
  websecure:
    nodePort: 32648
```

---

## 📚 Ссылки

- [Официальная документация Traefik](https://doc.traefik.io/traefik/)
- [Helm Chart Repository](https://github.com/traefik/traefik-helm-chart)
- [Kubernetes Provider](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Access Log Documentation](https://doc.traefik.io/traefik/observability/access-logs/)

---

**Выполнил:** DevOps Team  
**Last Updated:** 2026-04-01
