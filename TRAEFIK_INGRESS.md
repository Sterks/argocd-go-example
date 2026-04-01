# Traefik Ingress Configuration

**Ingress Controller:** Traefik v2.11.0  
**Namespace:** traefik-system  
**Date:** 2026-03-28

---

## 📊 Архитектура

```
                    INTERNET
                       │
        ┌──────────────┴──────────────┐
        │                             │
   ┌────▼────┐                 ┌────▼────┐
   │ Node 1  │                 │ Node 2  │ ...
   │.101     │                 │.102     │
   │         │                 │         │
   │ ┌─────┐ │                 │ ┌─────┐ │
   │ │Trae │ │                 │ │Trae │ │
   │ │ fik │ │                 │ │ fik │ │
   │ │ :80 │ │                 │ │ :80 │ │
   │ │:443 │ │                 │ │:443 │ │
   │ └──┬──┘ │                 │ └──┬──┘ │
   └────┼────┘                 └────┼────┘
        │                           │
        └───────────┬───────────────┘
                    │
        ┌───────────▼───────────────┐
        │   Traefik Ingress         │
        │   Routes                  │
        └───────────┬───────────────┘
                    │
        ┌───────────┼───────────────┐
        │           │               │
   ┌────▼────┐ ┌───▼────┐    ┌────▼────┐
   │Grafana  │ │Longhorn│    │ Vault   │
   │:3000    │ │:8000   │    │:8200    │
   └─────────┘ └────────┘    └─────────┘
```

---

## 🌐 Доступные сервисы

| Сервис | Host | Port | Backend | Статус |
|--------|------|------|---------|--------|
| **Grafana** | grafana.techbit.su | 80/443 | vm-stack-2-grafana:80 | ✅ |
| **Longhorn** | longhorn.techbit.su | 80/443 | longhorn-frontend:80 | ✅ |
| **Vault** | vault.techbit.su | 80/443 | vault:8200 | ✅ |
| **Harbor (Registry)** | harbor.techbit.su | 80/443 | registry:5000 | ✅ |

---

## 🔌 Access Points

### **Traefik NodePort:**
| Protocol | Port | URL |
|----------|------|-----|
| **HTTP** | 31184 | http://192.168.0.101:31184/ |
| **HTTPS** | 32648 | https://192.168.0.101:32648/ |

### **Domain Access (recommended):**
| Service | HTTP | HTTPS |
|---------|------|-------|
| **Vault** | http://vault.techbit.su | https://vault.techbit.su |
| **Grafana** | http://grafana.techbit.su | https://grafana.techbit.su |
| **Longhorn** | http://longhorn.techbit.su | https://longhorn.techbit.su |
| **Harbor (Registry)** | http://harbor.techbit.su | https://harbor.techbit.su |
| **Harbor UI** | http://ui.harbor.techbit.su | https://ui.harbor.techbit.su |

> **Note:** To access services without specifying the port, configure DNS to point to any node IP (192.168.0.101-106) or add entries to `/etc/hosts`.

### **Примеры доступа:**
```bash
# Vault (через NodePort)
curl -H "Host: vault.techbit.su" http://192.168.0.101:31184/

# Vault (через домен - требуется DNS)
curl http://vault.techbit.su/

# Grafana
curl -H "Host: grafana.techbit.su" http://192.168.0.101:31184/

# Longhorn
curl -H "Host: longhorn.techbit.su" http://192.168.0.101:31184/

# Harbor (Docker Registry)
curl -H "Host: harbor.techbit.su" http://192.168.0.101:31184/v2/_catalog

# Harbor UI (Web интерфейс)
# Откройте в браузере: http://ui.harbor.techbit.su
curl -H "Host: ui.harbor.techbit.su" http://192.168.0.101:31184/

# Docker push/pull (требуется DNS или /etc/hosts)
docker login harbor.techbit.su
docker push harbor.techbit.su/myimage:tag
```

---

## 📁 Файлы конфигурации

```
deploy/infrastructure/traefik-ingress/
├── grafana-ingress.yaml
├── longhorn-ingress.yaml
└── vault-ingress.yaml
```

---

## 🔧 Конфигурация

### **Grafana Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-traefik-ingress
  namespace: victoriametrics
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  rules:
  - host: grafana.techbit.su
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: vm-stack-2-grafana
            port: 80
```

### **Longhorn Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-traefik-ingress
  namespace: longhorn-system
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  rules:
  - host: longhorn.techbit.su
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: longhorn-frontend
            port: 80
```

### **Vault Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault-traefik-ingress
  namespace: vault
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  rules:
  - host: vault.techbit.su
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: vault
            port: 8200
```

---

## 🩹 Troubleshooting

### **Проверка Ingress:**
```bash
kubectl get ingress -A
kubectl describe ingress <name> -n <namespace>
```

### **Проверка Traefik:**
```bash
kubectl get pods -n traefik-system
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik
```

### **Тест доступа:**
```bash
curl -v -H "Host: <host>" http://192.168.0.101:30080/
```

---

## 📝 DNS Настройка

Добавьте в `/etc/hosts` или DNS сервер:

```
192.168.0.101 grafana.techbit.su
192.168.0.101 longhorn.techbit.su
192.168.0.101 vault.techbit.su
192.168.0.101 harbor.techbit.su
192.168.0.101 ui.harbor.techbit.su
```

Или используйте один IP для всех:
```
192.168.0.101 *.techbit.su
```

---

**Last Updated:** 2026-03-28  
**Maintained by:** DevOps Team
