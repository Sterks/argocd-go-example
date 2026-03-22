#!/bin/bash
# Скрипт для получения секретов из Vault и создания Kubernetes Secret
# Для аутентификации используйте переменную окружения VAULT_TOKEN или root_token файл

set -e

VAULT_ADDR="${VAULT_ADDR:-https://192.168.0.200/vault}"
NAMESPACE="${NAMESPACE:-argocd-go-example}"
SECRET_NAME="${SECRET_NAME:-vault-go-app-config}"

# Получаем токен из переменной окружения или файла
if [ -n "$VAULT_TOKEN" ]; then
  echo "🔑 Использование VAULT_TOKEN из переменной окружения"
elif [ -f "/root/.vault-token" ]; then
  VAULT_TOKEN=$(cat /root/.vault-token)
  echo "🔑 Использование токена из /root/.vault-token"
else
  echo "❌ VAULT_TOKEN не найден. Установите переменную окружения или создайте /root/.vault-token"
  exit 1
fi

echo "📦 Чтение секретов из Vault..."

# Читаем секреты из Vault
SECRETS=$(curl -k -s -H "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/kv/go-app/config" | jq -r '.data')

if [ "$SECRETS" == "null" ] || [ -z "$SECRETS" ]; then
  echo "❌ Не удалось прочитать секреты из Vault"
  exit 1
fi

echo "✅ Секреты получены:"
echo "$SECRETS" | jq .

# Создаём Kubernetes Secret
echo ""
echo "📝 Создание Kubernetes Secret..."

kubectl create secret generic $SECRET_NAME \
  --from-literal=DB_HOST="$(echo $SECRETS | jq -r '.DB_HOST')" \
  --from-literal=DB_PORT="$(echo $SECRETS | jq -r '.DB_PORT')" \
  --from-literal=DB_NAME="$(echo $SECRETS | jq -r '.DB_NAME')" \
  --from-literal=DB_USER="$(echo $SECRETS | jq -r '.DB_USER')" \
  --from-literal=DB_PASSWORD="$(echo $SECRETS | jq -r '.DB_PASSWORD')" \
  --from-literal=API_KEY="$(echo $SECRETS | jq -r '.API_KEY')" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret '$SECRET_NAME' создан/обновлён"

# Проверяем создание
kubectl get secret $SECRET_NAME -n $NAMESPACE

echo ""
echo "🎉 Готово! Секреты доступны в поде через:"
echo "  env:"
echo "    - name: DB_HOST"
echo "      valueFrom:"
echo "        secretKeyRef:"
echo "          name: $SECRET_NAME"
echo "          key: DB_HOST"
