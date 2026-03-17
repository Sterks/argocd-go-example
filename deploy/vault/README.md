# HashiCorp Vault в Kubernetes

Высокодоступная установка Vault с использованием Raft storage backend.

## Требования

- Kubernetes кластер (минимум 3 ноды для HA режима)
- Helm 3+
- StorageClass для динамического выделения PV

## Установка

### 1. Создание namespace

```bash
kubectl create namespace vault
```

### 2. Установка Vault через Helm

```bash
helm install vault hashicorp/vault \
  --namespace vault \
  -f values.yaml
```

### 3. Проверка статуса

```bash
kubectl get pods -n vault -l app.kubernetes.io/name=vault
```

Дождитесь, пока все 3 пода перейдут в статус `Running`.

### 4. Инициализация Vault

После запуска подов необходимо инициализировать Vault:

```bash
# Инициализация с 5 ключами разблокировки и порогом 3
kubectl exec -it vault-0 -n vault -- vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > cluster-keys.json
```

**Важно:** Сохраните файл `cluster-keys.json` в безопасном месте!

### 5. Разблокировка Vault (Unseal)

Разблокируйте каждый под Vault (vault-0, vault-1, vault-2):

```bash
# Извлеките ключи разблокировки из cluster-keys.json
export UNSEAL_KEY_1=<ключ_1>
export UNSEAL_KEY_2=<ключ_2>
export UNSEAL_KEY_3=<ключ_3>

# Разблокировка vault-0
kubectl exec -it vault-0 -n vault -- vault operator unseal $UNSEAL_KEY_1
kubectl exec -it vault-0 -n vault -- vault operator unseal $UNSEAL_KEY_2
kubectl exec -it vault-0 -n vault -- vault operator unseal $UNSEAL_KEY_3

# Разблокировка vault-1
kubectl exec -it vault-1 -n vault -- vault operator unseal $UNSEAL_KEY_1
kubectl exec -it vault-1 -n vault -- vault operator unseal $UNSEAL_KEY_2
kubectl exec -it vault-1 -n vault -- vault operator unseal $UNSEAL_KEY_3

# Разблокировка vault-2
kubectl exec -it vault-2 -n vault -- vault operator unseal $UNSEAL_KEY_1
kubectl exec -it vault-2 -n vault -- vault operator unseal $UNSEAL_KEY_2
kubectl exec -it vault-2 -n vault -- vault operator unseal $UNSEAL_KEY_3
```

### 6. Проверка статуса кластера

```bash
kubectl exec -it vault-0 -n vault -- vault status
```

### 7. Получение root-токена

```bash
export ROOT_TOKEN=$(cat cluster-keys.json | jq -r '.root_token')
kubectl exec -it vault-0 -n vault -- vault login $ROOT_TOKEN
```

## Доступ к Vault UI

### Через port-forward

```bash
kubectl port-forward svc/vault-ui -n vault 8200:8200
```

Откройте браузер: http://localhost:8200

### Через Ingress (опционально)

1. Раскомментируйте секцию `server.ingress` в `values.yaml`
2. Укажите ваш домен и TLS сертификат
3. Примените изменения:
   ```bash
   helm upgrade vault hashicorp/vault --namespace vault -f values.yaml
   ```

## Включение секретных движков

После входа в Vault включите необходимые секретные движки:

```bash
# KV Secrets Engine (версия 2)
vault secrets enable -path=secret kv-v2

# Database Secrets Engine
vault secrets enable database

# PKI Secrets Engine
vault secrets enable pki
```

## Обновление

```bash
helm upgrade vault hashicorp/vault --namespace vault -f values.yaml
```

## Удаление

```bash
helm uninstall vault --namespace vault
kubectl delete namespace vault
```

**Внимание:** Это также удалит все данные Vault!

## Автоматическая разблокировка (Auto-Unseal)

Для продакшена рекомендуется настроить автоматическую разблокировку через:
- AWS KMS
- Azure Key Vault
- GCP Cloud KMS
- Transit Secret Engine

Для этого раскомментируйте секцию `server.autoUnseal` в `values.yaml`.

## Мониторинг

Включите мониторинг через Prometheus:

```bash
vault audit enable file file_path=/vault/logs/audit.log
```

## Полезные команды

```bash
# Проверка статуса подов
kubectl get pods -n vault -l app.kubernetes.io/name=vault

# Проверка сервиса
kubectl get svc -n vault

# Логи Vault
kubectl logs -n vault -l app.kubernetes.io/name=vault

# Проверка статуса Raft кластера
kubectl exec -it vault-0 -n vault -- vault operator raft list-peers
```
