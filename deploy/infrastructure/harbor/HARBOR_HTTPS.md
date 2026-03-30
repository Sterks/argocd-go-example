# Harbor HTTPS Configuration

## 📊 Обзор

Harbor Registry настроен с HTTPS поддержкой через Traefik Ingress и cert-manager.

### Текущая конфигурация

| Параметр | Значение |
|----------|----------|
| **Registry API** | https://harbor.techbit.su |
| **Registry UI** | https://ui.harbor.techbit.su |
| **NodePort HTTP** | 30080 |
| **NodePort HTTPS** | 30444 |
| **Сертификат** | Self-signed (cert-manager) |
| **Срок действия** | 90 дней |

---

## 🔒 Типы сертификатов

### 1. Self-signed (текущий)
✅ Работает сразу, без настройки DNS
⚠️ Браузеры показывают предупреждение о безопасности

**Используется:** `selfsigned-cluster-issuer`

### 2. Let's Encrypt (требуется публичный DNS)
✅ Доверенный сертификат
⚠️ Требует публичного доступа к домену

**Требуется:**
- Публичные DNS записи A для `harbor.techbit.su` и `ui.harbor.techbit.su`
- Доступ с интернета на порт 80 для HTTP-01 верификации

---

## 🌐 Доступ к Harbor

### Через NodePort (локальная сеть)

```bash
# Добавьте в /etc/hosts на клиентской машине
sudo bash -c 'echo "192.168.0.101 harbor.techbit.su" >> /etc/hosts'
sudo bash -c 'echo "192.168.0.101 ui.harbor.techbit.su" >> /etc/hosts'

# HTTP (не рекомендуется)
http://harbor.techbit.su:30080/
http://ui.harbor.techbit.su:30080/

# HTTPS (рекомендуется)
https://harbor.techbit.su:30444/
https://ui.harbor.techbit.su:30444/
```

### Через NAT (из интернета)

Настройте NAT на роутере:
```
Порт WAN 80   →  192.168.0.101:30080 (HTTP)
Порт WAN 443  →  192.168.0.101:30444 (HTTPS)
```

После настройки:
```bash
# С публичным DNS
https://harbor.techbit.su/
https://ui.harbor.techbit.su/

# С публичным IP
https://109.194.67.168/ -H "Host: harbor.techbit.su"
https://109.194.67.168/ -H "Host: ui.harbor.techbit.su"
```

---

## 🐳 Docker Registry использование

### Логин
```bash
# HTTP (локально)
docker login harbor.techbit.su:30080

# HTTPS (с самоподписанным сертификатом)
docker login harbor.techbit.su:30444
# или с --insecure-registry в /etc/docker/daemon.json
```

### Настройка Docker для self-signed сертификата

**Вариант 1: Добавить в daemon.json**
```json
{
  "insecure-registries": ["harbor.techbit.su:30080"]
}
```

**Вариант 2: Доверять сертификату**
```bash
# Скопируйте сертификат из Kubernetes
kubectl get secret harbor-tls-letsencrypt -n harbor -o jsonpath='{.data.tls\.crt}' | base64 -d | sudo tee /etc/docker/certs.d/harbor.techbit.su:30444/ca.crt

# Перезапустите Docker
sudo systemctl restart docker
```

### Push/Pull
```bash
# Tag образа
docker tag myimage:latest harbor.techbit.su:30444/myimage:latest

# Push
docker push harbor.techbit.su:30444/myimage:latest

# Pull
docker pull harbor.techbit.su:30444/myimage:latest
```

---

## 🔄 Переключение на Let's Encrypt

Если у вас есть публичный DNS:

1. **Создайте DNS записи:**
```
harbor.techbit.su.    A    109.194.67.168
ui.harbor.techbit.su. A    109.194.67.168
```

2. **Обновите harbor-https.yaml:**
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod-traefik
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-traefik-account-key
    solvers:
    - http01:
        ingress:
          class: traefik
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: harbor-tls-letsencrypt
  namespace: harbor
spec:
  # ... остальная конфигурация
  issuerRef:
    name: letsencrypt-prod-traefik  # Измените здесь
    kind: ClusterIssuer
```

3. **Примените:**
```bash
kubectl apply -f deploy/infrastructure/harbor/harbor-https.yaml
```

4. **Проверьте:**
```bash
kubectl get certificate harbor-tls-letsencrypt -n harbor -w
kubectl get challenge -n harbor
```

---

## 🩹 Troubleshooting

### Проверка статуса сертификата
```bash
kubectl get certificate harbor-tls-letsencrypt -n harbor
kubectl describe certificate harbor-tls-letsencrypt -n harbor
```

### Проверка Ingress
```bash
kubectl get ingress -n harbor
kubectl describe ingress registry-ui-ingress -n harbor
```

### Проверка Traefik
```bash
kubectl get pods -n traefik-system
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=100
```

### Проверка ACME вызовов (для Let's Encrypt)
```bash
kubectl get challenge -n harbor
kubectl get order -n harbor
kubectl get certificaterequest -n harbor
```

### Тест HTTPS
```bash
# С игнорированием сертификата
curl -k https://ui.harbor.techbit.su:30444/ -H "Host: ui.harbor.techbit.su"

# С проверкой сертификата (требуется доверять CA)
curl --cacert ca.crt https://ui.harbor.techbit.su:30444/ -H "Host: ui.harbor.techbit.su"
```

### Просмотр сертификата
```bash
# Из Kubernetes
kubectl get secret harbor-tls-letsencrypt -n harbor -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Из HTTPS endpoint
echo | openssl s_client -connect 192.168.0.101:30444 -servername ui.harbor.techbit.su 2>/dev/null | openssl x509 -text -noout
```

---

## 📁 Файлы

| Файл | Описание |
|------|----------|
| `harbor-https.yaml` | HTTPS конфигурация (сертификат + Ingress) |
| `registry-simple.yaml` | Основная конфигурация Harbor |

---

**Last Updated:** 2026-03-29
**Maintained by:** DevOps Team
