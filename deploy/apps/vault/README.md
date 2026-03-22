# Vault Agent Injector - Инструкция по использованию

## 📋 Обзор

Vault Agent Injector автоматически внедряет секреты из Vault в поды Kubernetes через Mutating Webhook.

## 🏗️ Архитектура

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Go App Pod    │────▶│ Vault Agent      │────▶│   Vault Server  │
│                 │     │ Injector         │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
       │                        │                        │
       │ 1. Pod создаётся       │                        │
       │◀───────────────────────────────────────────────│
       │ 2. Vault Agent injects secrets                 │
       │ 3. Pod запускается с секретами                 │
```

## 🔧 Установка и настройка

### 1. Проверка Vault Agent Injector

```bash
# Проверка статуса injector
kubectl get pods -n vault -l app.kubernetes.io/name=vault-agent-injector

# Проверка webhook
kubectl get mutatingwebhookconfigurations vault-agent-injector-cfg
```

### 2. Аутентификация в Vault

```bash
# Включение Kubernetes auth method
kubectl exec -it vault-0 -n vault -- vault auth enable kubernetes

# Настройка Kubernetes auth
kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc"

# Создание роли для приложения
kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/role/go-app-role \
  bound_service_account_names=vault-auth \
  bound_service_account_namespaces=argocd-go-example \
  policies=go-app-policy \
  ttl=24h
```

### 3. Создание политики Vault

```bash
# Политика для чтения секретов
kubectl exec -it vault-0 -n vault -- vault policy write go-app-policy - <<EOF
path "kv/data/go-app/*" {
  capabilities = ["read", "list"]
}
path "kv/metadata/go-app/*" {
  capabilities = ["read", "list"]
}
EOF
```

### 4. Создание тестового секрета

```bash
# Включение KV secrets engine (если не включено)
kubectl exec -it vault-0 -n vault -- vault secrets enable kv

# Создание секрета
kubectl exec -it vault-0 -n vault -- vault kv put kv/go-app/config \
  DB_HOST=postgres.default.svc \
  DB_PORT=5432 \
  DB_NAME=myapp \
  DB_USER=appuser \
  DB_PASSWORD=secret123 \
  API_KEY=test-api-key-12345
```

## 📝 Аннотации для инъекции секретов

### Базовые аннотации

```yaml
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-inject-secret: "config.env"
    vault.hashicorp.com/role: "go-app-role"
```

### Шаблон для инъекции

```yaml
vault.hashicorp.com/agent-inject-template: |
  {{- with secret "kv/go-app/config" -}}
  DB_HOST={{ index .Data "DB_HOST" }}
  DB_PORT={{ index .Data "DB_PORT" }}
  DB_NAME={{ index .Data "DB_NAME" }}
  DB_USER={{ index .Data "DB_USER" }}
  DB_PASSWORD={{ index .Data "DB_PASSWORD" }}
  API_KEY={{ index .Data "API_KEY" }}
  {{- end }}
```

## 🧪 Тестирование

### 1. Применение конфигурации

```bash
# Применение ServiceAccount и RBAC
kubectl apply -f deploy/apps/vault/vault-auth-sa.yaml

# Синхронизация приложения через ArgoCD
kubectl patch application go-app -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"prune":true}}}'

# Или напрямую
kubectl apply -f deploy/apps/go-app/deployment.yaml
```

### 2. Проверка статуса pod

```bash
# Проверка pod
kubectl get pods -n argocd-go-example

# Описание pod
kubectl describe pod -n argocd-go-example -l app=argocd-go-example
```

### 3. Проверка инжекции секретов

```bash
# Проверка аннотаций
kubectl get pod -n argocd-go-example -l app=argocd-go-example \
  -o jsonpath='{.items[0].metadata.annotations}'

# Проверка смонтированных секретов
kubectl exec -n argocd-go-example deploy/argocd-go-example -- ls -la /vault/secrets/

# Чтение секрета
kubectl exec -n argocd-go-example deploy/argocd-go-example -- cat /vault/secrets/config.env

# Проверка переменных окружения
kubectl exec -n argocd-go-example deploy/argocd-go-example -- env | grep DB_
```

### 4. Проверка логов Vault Agent

```bash
# Логи injector
kubectl logs -n vault -l app.kubernetes.io/name=vault-agent-injector

# Логи Vault Agent в поде приложения
kubectl logs -n argocd-go-example -l app=argocd-go-example -c vault-agent
```

## 🔐 Обновление секретов

### Изменение секрета в Vault

```bash
# Обновление секрета
kubectl exec -it vault-0 -n vault -- vault kv put kv/go-app/config \
  DB_HOST=new-postgres.default.svc \
  DB_PORT=5432 \
  DB_NAME=newapp \
  DB_USER=newuser \
  DB_PASSWORD=newpassword456 \
  API_KEY=new-api-key-67890
```

### Перезапуск pod для получения новых секретов

```bash
# Rolling restart deployment
kubectl rollout restart deployment/argocd-go-example -n argocd-go-example

# Проверка статуса
kubectl rollout status deployment/argocd-go-example -n argocd-go-example
```

## 🛠️ Troubleshooting

### Pod не запускается

```bash
# Проверка событий pod
kubectl describe pod -n argocd-go-example -l app=argocd-go-example

# Проверка логов
kubectl logs -n argocd-go-example -l app=argocd-go-example
```

### Ошибки аутентификации

```bash
# Проверка ServiceAccount
kubectl get sa vault-auth -n argocd-go-example

# Проверка RBAC
kubectl get clusterrolebinding vault-auth-delegator

# Проверка роли в Vault
kubectl exec -it vault-0 -n vault -- vault read auth/kubernetes/role/go-app-role
```

### Ошибки injector

```bash
# Проверка webhook
kubectl get mutatingwebhookconfigurations vault-agent-injector-cfg -o yaml

# Перезапуск injector
kubectl rollout restart deployment/vault-agent-injector -n vault
```

## 📊 Примеры использования

### 1. Простая инъекция (файл)

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/agent-inject-secret: "secret.txt"
  vault.hashicorp.com/agent-inject-template: |
    {{- with secret "kv/go-app/config" -}}
    {{ .Data.data.API_KEY }}
    {{- end }}
```

### 2. Множественные секреты

```yaml
annotations:
  vault.hashicorp.com/agent-inject-secret-db: "db-config.env"
  vault.hashicorp.com/agent-inject-template-db: |
    {{- with secret "kv/go-app/database" -}}
    DB_HOST={{ index .Data "DB_HOST" }}
    DB_PASSWORD={{ index .Data "DB_PASSWORD" }}
    {{- end }}
  
  vault.hashicorp.com/agent-inject-secret-api: "api-config.env"
  vault.hashicorp.com/agent-inject-template-api: |
    {{- with secret "kv/go-app/api" -}}
    API_KEY={{ index .Data "API_KEY" }}
    API_SECRET={{ index .Data "API_SECRET" }}
    {{- end }}
```

### 3. JSON формат

```yaml
annotations:
  vault.hashicorp.com/agent-inject-secret: "config.json"
  vault.hashicorp.com/agent-inject-template: |
    {
      {{- with secret "kv/go-app/config" -}}
      "database": {
        "host": "{{ index .Data "DB_HOST" }}",
        "port": {{ index .Data "DB_PORT" }},
        "name": "{{ index .Data "DB_NAME" }}"
      },
      "api_key": "{{ index .Data "API_KEY" }}"
      {{- end }}
    }
```

## 🔗 Полезные ссылки

- [Vault Agent Injector Documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [Vault Agent Template](https://developer.hashicorp.com/vault/docs/agent/template)
- [Vault Kubernetes Auth](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
