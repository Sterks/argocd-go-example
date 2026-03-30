# Harbor HTTPS Настройка - Итоговая Инструкция

## 📊 Текущий статус

| Компонент | Статус | Порт | URL |
|-----------|--------|------|-----|
| **Harbor UI (HTTP)** | ✅ Работает | 30080 | http://ui.harbor.techbit.su:30080/ |
| **Registry API (HTTP)** | ✅ Работает | 30080 | http://harbor.techbit.su:30080/v2/_catalog |
| **HTTPS через Traefik** | ⚠️ Требует настройки | 30444 | - |

---

## 🔧 Проблема с HTTPS

Traefik v2.10 в текущей конфигурации использует сертификат по умолчанию вместо сертификатов из Kubernetes Ingress. Это известная особенность при использовании `--providers.kubernetesingress` без дополнительной настройки.

### Решение проблемы (на выбор):

---

## ✅ Решение 1: HTTP + nginx proxy (рекомендуется для локальной сети)

### Быстрая настройка

1. **Добавьте запись в /etc/hosts:**
```bash
sudo bash -c 'echo "192.168.0.101 harbor.techbit.su" >> /etc/hosts'
sudo bash -c 'echo "192.168.0.101 ui.harbor.techbit.su" >> /etc/hosts'
```

2. **Откройте в браузере:**
```
http://ui.harbor.techbit.su:30080/
```

3. **Docker команды:**
```bash
# Логин
docker login harbor.techbit.su:30080

# Push
docker tag myimage:latest harbor.techbit.su:30080/myimage:latest
docker push harbor.techbit.su:30080/myimage:latest
```

---

## 🔒 Решение 2: Full HTTPS с nginx proxy

Создайте файл `harbor-nginx-https.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: harbor-nginx-proxy
  namespace: harbor
data:
  nginx.conf: |
    worker_processes 1;
    events { worker_connections 1024; }
    http {
        server {
            listen 80;
            return 301 https://$host$request_uri;
        }
        
        server {
            listen 443 ssl;
            server_name harbor.techbit.su ui.harbor.techbit.su;
            
            ssl_certificate /etc/nginx/ssl/tls.crt;
            ssl_certificate_key /etc/nginx/ssl/tls.key;
            
            location / {
                proxy_pass http://registry-ui.harbor.svc.cluster.local;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
            }
            
            location /v2/ {
                proxy_pass http://registry.harbor.svc.cluster.local:5000;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_read_timeout 900;
                client_max_body_size 0;
            }
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: harbor-nginx-proxy
  namespace: harbor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: harbor-nginx-proxy
  template:
    metadata:
      labels:
        app: harbor-nginx-proxy
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 443
          name: https
          hostPort: 443
        - containerPort: 80
          name: http
          hostPort: 80
        volumeMounts:
        - name: ssl
          mountPath: /etc/nginx/ssl
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: ssl
        secret:
          secretName: harbor-tls-letsencrypt
      - name: config
        configMap:
          name: harbor-nginx-proxy
```

Примените:
```bash
kubectl apply -f harbor-nginx-https.yaml
```

---

## 🔒 Решение 3: Исправление Traefik (для production)

### Опция A: Использовать Traefik IngressRoute CRD

1. Создайте `harbor-ingressroute.yaml`:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: harbor
  namespace: harbor
spec:
  entryPoints:
    - web
    - websecure
  routes:
  - match: Host(`ui.harbor.techbit.su`)
    kind: Rule
    services:
    - name: registry-ui
      port: 80
  - match: Host(`harbor.techbit.su`)
    kind: Rule
    services:
    - name: registry
      port: 5000
  tls:
    secretName: harbor-tls-letsencrypt
```

2. Примените:
```bash
kubectl apply -f harbor-ingressroute.yaml
```

### Опция B: Настроить Traefik для работы с Ingress TLS

Обновите `deploy/infrastructure/traefik/traefik-deployment.yaml`:

```yaml
args:
  - --providers.kubernetesingress
  - --providers.kubernetesingress.allowCrossNamespace=true
  - --entrypoints.web.address=:80
  - --entrypoints.websecure.address=:443
  - --entrypoints.websecure.http.tls.certresolver=letsencrypt
  - --certresolvers.letsencrypt.acme.email=your-email@example.com
  - --certresolvers.letsencrypt.acme.storage=/data/acme.json
  - --certresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
```

---

## 🩹 Проверка работы

### Скрипт проверки
```bash
bash scripts/check-harbor-https.sh
```

### Ручная проверка

```bash
# HTTP
curl -H "Host: ui.harbor.techbit.su" http://192.168.0.101:30080/

# Registry API
curl -H "Host: harbor.techbit.su" http://192.168.0.101:30080/v2/_catalog

# Проверка сертификата
echo | openssl s_client -connect 192.168.0.101:30444 -servername ui.harbor.techbit.su 2>/dev/null | openssl x509 -noout -subject
```

---

## 📁 Файлы конфигурации

| Файл | Описание |
|------|----------|
| `deploy/infrastructure/harbor/registry-simple.yaml` | Основная конфигурация Harbor |
| `deploy/infrastructure/harbor/harbor-https.yaml` | HTTPS сертификат и Ingress |
| `deploy/infrastructure/harbor/HARBOR_HTTPS.md` | Подробная документация |
| `scripts/check-harbor-https.sh` | Скрипт проверки |

---

## 🔗 Полезные ссылки

- [Traefik HTTPS Documentation](https://doc.traefik.io/traefik/https/overview/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Docker Registry UI](https://github.com/Joxit/docker-registry-ui)

---

**Last Updated:** 2026-03-29
**Status:** HTTP работает, HTTPS требует дополнительной настройки
