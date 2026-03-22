# Интеграция с HashiCorp Vault

## 📋 Обзор

Приложение `argocd-go-example` получает конфигурационные данные из HashiCorp Vault через Kubernetes Secrets.

## 🏗️ Архитектура

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Go App Pod    │     │  Kubernetes      │     │   Vault Server  │
│                 │────▶│  Secret          │◀────│                 │
│  (env vars)     │     │  vault-go-app-   │     │  kv/go-app/     │
│                 │     │  config          │     │  config         │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## 🔧 Настройка

### 1. Создание секрета в Vault

```bash
# Подключение к Vault
export VAULT_ADDR="https://192.168.0.200/vault"
export VAULT_TOKEN="<YOUR_VAULT_TOKEN>"

# Создание секрета
vault kv put kv/go-app/config \
  DB_HOST=postgres.default.svc \
  DB_PORT=5432 \
  DB_NAME=myapp \
  DB_USER=appuser \
  DB_PASSWORD=secret123 \
  API_KEY=test-api-key-12345
```

### 2. Синхронизация секретов в Kubernetes

```bash
# Ручная синхронизация
export VAULT_TOKEN="<YOUR_VAULT_TOKEN>"
bash scripts/sync-vault-secrets.sh

# Или напрямую
kubectl create secret generic vault-go-app-config \
  --from-literal=DB_HOST=postgres.default.svc \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_NAME=myapp \
  --from-literal=DB_USER=appuser \
  --from-literal=DB_PASSWORD=secret123 \
  --from-literal=API_KEY=test-api-key-12345 \
  --namespace=argocd-go-example \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Проверка переменных в поде

```bash
# Проверка Secret
kubectl get secret vault-go-app-config -n argocd-go-example

# Проверка переменных в поде
kubectl exec -n argocd-go-example deploy/argocd-go-example -- env | grep -E "^(DB_|API_)"

# Вывод:
# DB_PASSWORD=secret123
# API_KEY=test-api-key-12345
# DB_HOST=postgres.default.svc
# DB_PORT=5432
# DB_NAME=myapp
# DB_USER=appuser
```

## 🔄 Автоматическая синхронизация

### Вариант 1: CronJob

```bash
# Создание CronJob для синхронизации
kubectl apply -f deploy/apps/go-app/vault-sync-cronjob.yaml
```

### Вариант 2: ArgoCD + External Secrets Operator

Установите External Secrets Operator и создайте ExternalSecret ресурс.

## 📝 Обновление секретов

### 1. Обновление в Vault

```bash
vault kv put kv/go-app/config \
  DB_HOST=new-postgres.default.svc \
  DB_PASSWORD=newpassword456
```

### 2. Синхронизация в Kubernetes

```bash
export VAULT_TOKEN="<YOUR_VAULT_TOKEN>"
bash scripts/sync-vault-secrets.sh
```

### 3. Перезапуск подов

```bash
kubectl rollout restart deployment argocd-go-example -n argocd-go-example
```

## 🔐 Безопасность

### Хранение токена Vault

**НЕ храните токен в коде!** Используйте:

1. **Environment variable** (рекомендуется для CI/CD):
   ```bash
   export VAULT_TOKEN="<YOUR_VAULT_TOKEN>"
   ```

2. **Kubernetes Secret** для CronJob:
   ```yaml
   env:
     - name: VAULT_TOKEN
       valueFrom:
         secretKeyRef:
           name: vault-token
           key: token
   ```

3. **AppRole аутентификация** (production):
   ```bash
   vault write auth/approle/role/go-app \
     secret_id_ttl=10m \
     token_num_uses=10 \
     token_ttl=20m \
     token_max_ttl=30m \
     secret_id_num_uses=40
   ```

### Политики Vault

```hcl
# deploy/apps/vault/vault-policy.hcl
path "kv/data/go-app/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/go-app/*" {
  capabilities = ["read", "list"]
}
```

## 🛠️ Troubleshooting

### Secret не создаётся

```bash
# Проверка доступа к Vault
curl -k -H "X-Vault-Token: $VAULT_TOKEN" \
  https://192.168.0.200/vault/v1/kv/go-app/config

# Проверка прав токена
vault token lookup $VAULT_TOKEN
```

### Переменные не доступны в поде

```bash
# Проверка Secret
kubectl get secret vault-go-app-config -n argocd-go-example -o yaml

# Проверка deployment
kubectl get deployment argocd-go-example -n argocd-go-example -o yaml | grep -A20 env

# Перезапуск pod
kubectl rollout restart deployment argocd-go-example -n argocd-go-example
```

### Ошибки аутентификации

```bash
# Проверка срока действия токена
vault token lookup $VAULT_TOKEN | grep expire

# Обновление токена
vault token renew $VAULT_TOKEN
```

## 📊 Мониторинг

### Проверка актуальности секретов

```bash
# Время последнего обновления Secret
kubectl get secret vault-go-app-config -n argocd-go-example \
  -o jsonpath='{.metadata.creationTimestamp}'

# Сравнение с Vault
vault kv get -format=json kv/go-app/config | jq '.metadata.created_time'
```

### Логирование изменений

```bash
# Audit лог Vault
vault audit enable file file_path=/var/log/vault/audit.log

# Kubernetes audit
kubectl get events -n argocd-go-example --field-selector reason=Created
```

## 🔗 Полезные ссылки

- [Vault KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv)
- [Vault Kubernetes Auth](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
