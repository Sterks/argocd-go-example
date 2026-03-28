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

---

## 🔌 Access Points

### **Traefik NodePort:**
| Protocol | Port | URL |
|----------|------|-----|
| **HTTP** | 30080 | http://192.168.0.101:30080/ |
| **HTTPS** | 30444 | https://192.168.0.101:30444/ |

### **Примеры доступа:**
```bash
# Grafana
curl -H "Host: grafana.techbit.su" http://192.168.0.101:30080/

# Longhorn
curl -H "Host: longhorn.techbit.su" http://192.168.0.101:30080/

# Vault
curl -H "Host: vault.techbit.su" http://192.168.0.101:30080/
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
```

Или используйте один IP для всех:
```
192.168.0.101 *.techbit.su
```

---

**Last Updated:** 2026-03-28  
**Maintained by:** DevOps Team
