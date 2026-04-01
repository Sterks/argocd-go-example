# Traefik Ingress Controller

**Helm Chart:** traefik/traefik v39.0.7  
**App Version:** Traefik v3.2.4  
**Namespace:** traefik-system

---

## 📁 Структура

```
deploy/infrastructure/traefik/
├── values.yaml           # Helm values для traefik/traefik chart
├── application.yaml      # ArgoCD Application
├── README.md             # Документация
└── HELM_SETUP.md         # Инструкция по установке
```

---

## 🚀 Установка через ArgoCD

### 1. Применить Application

```bash
kubectl apply -f deploy/infrastructure/traefik/application.yaml
```

### 2. Проверить статус

```bash
argocd app get traefik
argocd app sync traefik
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

### NAT на роутере

```
External 80  →  192.168.0.101:31184  (Traefik HTTP)
External 443 →  192.168.0.101:32648  (Traefik HTTPS)
```

---

## 📊 Доступные сервисы

| Сервис | URL | Namespace | Application |
|--------|-----|-----------|-------------|
| **Vault** | https://vault.techbit.su | vault | deploy/apps/vault |
| **Grafana** | https://grafana.techbit.su | victoriametrics | deploy/apps/victoriametrics |
| **Longhorn** | https://longhorn.techbit.su | longhorn-system | deploy/infrastructure/longhorn |
| **Harbor** | https://harbor.techbit.su | harbor | deploy/infrastructure/harbor |
| **Harbor UI** | https://ui.harbor.techbit.su | harbor | deploy/infrastructure/harbor |

---

## 🔧 Мониторинг

### Access Log

```bash
# Live просмотр
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik -f \
  | grep '^{' \
  | jq -r '"\(.time) | \(.ClientAddr) | \(.RequestMethod) \(.RequestPath) | \(.DownstreamStatus)"'

# Статистика по хостам
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=1000 \
  | grep '^{' \
  | jq -r '.RequestHost' | sort | uniq -c | sort -rn
```

### Metrics (Prometheus)

```bash
# Проверка метрик
kubectl port-forward -n traefik-system svc/traefik-prometheus 9100:9100
curl http://localhost:9100/metrics
```

---

## 📚 Ссылки

- [Helm Chart](https://github.com/traefik/traefik-helm-chart)
- [Документация Traefik](https://doc.traefik.io/traefik/)
- [ArgoCD Application](application.yaml)
